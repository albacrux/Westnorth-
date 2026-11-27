# Diagnóstico: como o toque vira ação no mapa (snapshot upstream 1.21.0-dev)

Tarefa de diagnóstico da seção 3 do `ui-mobile-brief.md`, feita lendo o código
(o A06 não está acessível da nuvem). Arquivos: `src/controller_base.cpp`,
`src/mouse_handler_base.cpp`, `src/mouse_events.cpp`, `data/core/hotkeys.cfg`.

## Caminho dos eventos

1. O SDL entrega `SDL_EVENT_MOUSE_BUTTON_DOWN/UP` sintetizados do toque
   (`which == SDL_TOUCH_MOUSEID`, testado por `events::is_touch`) e também
   `SDL_EVENT_FINGER_*`.
2. `controller_base::handle_event`:
   - **DOWN**: inicia um timer de toque longo (`popup_show_delay`), chama
     `mouse_handler_base::mouse_press` e **dispara os atalhos de mouse**
     (`hotkey::mbutton_event`) no próprio *down*.
   - **FINGER_MOTION** → `mouse_handler::touch_motion` (arrasto).
   - **UP**: cancela o timer e chama `mouse_press` de novo (fim do gesto).
3. Atalhos de toque em `data/core/hotkeys.cfg` (`mouse=255`):
   - 1 toque → `touchhex` → `mouse_handler::touch_action`
   - 2 toques (`click=2`, contados pelo SDL) → `selectmoveaction` → `select_or_action`
4. `touch_action` no Android (`#ifdef __ANDROID__`):
   - toque no hex **da unidade já selecionada → desseleciona**;
   - toque em outra unidade → `select_or_action`;
   - toque em hex **vazio → não faz nada**.
5. `select_or_action` no Android: toque em **inimigo → seleciona o inimigo**
   (mostra o alcance dele), nunca ataca.
6. `touch_motion`: o mapa só rola se **não houver unidade selecionada**; com
   unidade selecionada o arrasto desenha rota. Ao soltar,
   `clear_dragging → left_drag_end → move_action` **move/ataca na hora**, sem
   confirmação, a partir do hex sob o dedo.
7. Toque longo: o timer abre o menu de contexto; ao soltar, `right_click` (sem
   efeito no jogo).

## Sequência do cenário que falha ("segurar a unidade selecionada e arrastar")

| Passo | Evento | Efeito |
|---|---|---|
| 1 | toque na unidade (UP depois de DOWN) | `touchhex` no DOWN → seleciona |
| 2 | dedo encosta de novo na unidade (DOWN) | `touchhex` no DOWN → hex == selecionado → **desseleciona** |
| 3 | arrasta | sem unidade selecionada → **o mapa rola** (parece que "a unidade vai para o lado errado") |
| 4 | solta | `left_drag_end → move_action` sem seleção → nada, ou move outra coisa se a seleção mudou no caminho |

**Hipótese do brief, revisada:** a seleção não é desfeita pelo *fim* do toque nem por
um clique direito. Ela é desfeita pelo **início** do segundo toque: o atalho
`touchhex` roda no `DOWN` e, no Android, alterna a seleção. Além disso, **não
existia caminho só com toques para atacar**: tocar no inimigo seleciona o inimigo,
e tocar duas vezes no inimigo também.

## O que mudou no UI-1

- O toque não passa mais pelos atalhos `touchhex`/`selectmoveaction`.
  `mouse_handler_base` classifica o gesto **ao soltar**: arrasto, toque longo ou
  toque. Só o toque chama `touch_tap()`. Toque longo e arrasto nunca mudam a seleção.
- `mouse_handler::touch_tap()` implementa o fluxo do brief:
  - toque na própria unidade → seleciona;
  - toque em hex alcançável → mostra o caminho; tocar de novo no mesmo hex move;
  - toque em inimigo atacável → adjacente: diálogo de ataque direto; longe:
    mostra o caminho e o hex de onde vai atacar, e o 2º toque abre o diálogo.
    Para escolher o hex de ataque, toque nele antes de tocar no inimigo;
  - toque na unidade selecionada → cancela o movimento pendente ou desseleciona;
  - toque em outra unidade → seleciona (mostra alcance); toque fora → desseleciona.
- Arrastar com um dedo **sempre rola o mapa**, exceto quando o arrasto começa
  sobre a unidade selecionada (arrastar-e-soltar continua opcional). Soltar
  equivale a tocar no hex de destino, ou seja, também pede confirmação.
- Limiar de arrasto: de 14 para 20 px por 1080p (≈ 16 px ≈ 10 dp no A06).
- Preferência avançada **"Touch: move without confirmation"**
  (`touch_move_immediately`, desligada por padrão).
- Toque longo × toque: a duração passa a ser medida pelos carimbos de tempo dos
  eventos (antes era o relógio na hora de *processar* o evento; com o jogo ocupado,
  num celular lento, um toque curto virava "toque longo").
- Depois de rolar o mapa, o jogo não "passa o mouse" no ponto onde o dedo saiu
  (antes desenhava um caminho até lá).

## Como testar no desktop

A emulação de toque do upstream (`MOUSE_TOUCH_EMULATION`: botão direito = dedo)
estava quebrada no SDL3 e descartava eventos; foi corrigida. Build:

```sh
printf '#!/bin/sh\nexec ccache "$@" -DMOUSE_TOUCH_EMULATION\n' > /tmp/touchcc.sh && chmod +x /tmp/touchcc.sh
cmake -S . -B ../build-touch -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_SERVER=OFF \
  -DCMAKE_CXX_COMPILER_LAUNCHER=/tmp/touchcc.sh
ninja -C ../build-touch wesnoth
utils/westnorth/screenshot.sh -b ../build-touch/wesnoth -s utils/westnorth/touch-flow.txt out -- -t westnorth_touch
```

(`EXTRA_FLAGS_CONFIG` não chega aos alvos com o gerador Ninja; por isso o *launcher*.)
Resultado do roteiro: `capturas/ui-1-fluxo-toque.jpg` (1 seleciona, 2 inimigo distante
mostra caminho e hex de ataque, 3 segundo toque abre o diálogo, 4 caminho até hex
vazio, 5 segundo toque move, 6 inimigo adjacente abre o diálogo direto, 7 arrasto
mantém a seleção, 8 toque longo abre o menu e mantém a seleção).

Limitação da emulação: no X11 o ponteiro continua "pairando" sobre o mapa, então
a captura 7 mostra uma prévia de caminho que não aparece no aparelho. Conferir no A06.

## Coordenadas dos eventos de dedo (SDL3)

`events.cpp` chama `SDL_ConvertEventToRenderCoordinates` em todo evento. No SDL3 isso
transforma a posição dos eventos de dedo (`tfinger.x/y/dx/dy`) de fração da janela
(0 a 1) em **pixels**. Todo o código do Wesnoth que lê esses eventos (handler da GUI2,
rolagem por arrasto em `scrollarea.cpp`, a emulação) ainda espera a fração do SDL2 e
multiplica pelo tamanho da tela de novo. No aparelho, isso joga os toques da GUI2 para
fora da tela (ex.: listas que não rolam com o dedo). A emulação não mostra o problema
porque cria os eventos de dedo já como fração.

Correção do fork: logo depois da conversão, os eventos de dedo voltam a ser fração da
tela do jogo. Não dá para testar no Xvfb (sem toque real): **conferir no A06** se as
listas (recrutar, carregar jogo, ajuda) rolam arrastando o dedo.

## Ainda não coberto (próximos ciclos)

- Marcar visualmente os inimigos atacáveis ao selecionar (UI-4, com o cartão da unidade).
- Botões "Confirmar"/"Desfazer" na tela. O Desfazer já existe no menu "Ações" (UI-4).
- Zoom com dois dedos: o SDL3 tem eventos de pinça, mas o jogo não os trata (UI-5).
