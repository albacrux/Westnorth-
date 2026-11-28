# Achados de UI e armadilhas conhecidas (referência rápida)

Registro do que **já foi verificado** sobre como a UI funciona neste snapshot
(upstream 1.21.0-dev) e no ambiente de nuvem. Leia antes de investigar algo de UI:
se o assunto estiver aqui, parta da conclusão em vez de repetir a verificação.
Acrescente novos achados no fim da seção certa (data + PR).

Manual de tamanhos e hierarquia de informação: `manual-ui-android.md` (fonte das
regras do layout de celular). Documentos detalhados: `diagnostico-toque.md` (eventos de toque), `diagnostico-zoom.md`
(zoom/nitidez), `decisoes.md` (D1–D36: o que foi decidido e por quê).

## 1. Tela e escala

- **Resolução lógica mínima do upstream é 1280x720** (`pref_constants::min_window_*` em
  `src/preferences/preferences.hpp`). O A06 tem 1600x720: não há folga vertical.
  **Não dá para ampliar a interface inteira** por escala fracionária (desenhar em
  1200x540 e esticar): diálogos deixam de caber. Investigado e descartado (D33, #17).
- A escala de pixels do jogo é inteira (`video.cpp`, `update_framebuffer`); no A06 é 1.
- A preferência avançada **"Font size scale"** (`font_scale`, 80–150) já existe e afeta
  GUI2 **e** o tema do HUD. A 125%: menus ok, mas o painel lateral corta texto (alturas
  fixas nos `rect`) e o diálogo de ataque ganha rolagem. Default continua 100.

## 2. Android × desktop (afeta toda captura)

- No Android o jogo liga o define **`ANDROID`** (`src/gui/gui.cpp`, `game_config_manager.cpp`).
  Com ele a GUI2 usa fontes maiores (`data/gui/macros/_initial.cfg`: DEFAULT 22 em vez
  de 17, SMALL 18, TITLE 28...).
- **Capturas sem `WESTNORTH_ANDROID=1` não mostram o que o A06 exibe.** O smoke test roda
  nos dois modos (#19). O valor precisa ser não vazio e diferente de `0`.
- O tamanho do texto dos botões GUI2 genéricos era fixo (16), fora do esquema de fontes do
  Android; o fork usa 44 px / texto 20 px só com `ANDROID` (#20, D36).

## 3. Tema do HUD (`data/themes/default.cfg`)

- Seleção de layout (`theme::set_resolution`): o **primeiro** `[resolution]`/
  `[partialresolution]` em que largura e altura cabem; senão o de menor área.
  1600x720 (e janelas de desktop 1280x720) caem no **`1024x600`**, que o fork trata como
  layout de celular. O `800x600` herda dele e não é alcançável (mínimo 1280x720).
- `[change]`/`[remove]` acham o **primeiro** elemento com aquele `id`, em busca
  recursiva (`find_ref`). Ids duplicados enganam: `MINIMAP_THEME` define um
  `[terrain] id=terrain-description` solto, inútil; o fork o remove antes do `[change]`.
- `[add]` aceita **um** filho por bloco (schema). Vários elementos = vários `[add]` (#9).
- Sem `ref=`, o `rect` é relativo ao **elemento anterior na ordem do arquivo**. Ao
  reposicionar, ponha `ref=` explícito nos vizinhos (ex.: `unit-traits` → `unit-abilities`).
- `ref=` só encontra elementos **anteriores no arquivo** (`do_resolve_rects` procura no
  config já resolvido). Ordem no `[resolution]` base: painéis (caixas de status), menus,
  ações, `[label]`s (label-hp...), depois os itens do `[status]`. Um `[label]` não pode
  usar `ref=` de um item do `[status]`; ref inexistente cai no elemento anterior em
  silêncio (só um ERR no log).
- `[change]` não troca o nome da tag; para um relatório novo no layout de celular, o item
  vai no `[status]` base com `rect="0,0,0,0"` (nunca desenhado) e o `[change]` do layout
  parcial o posiciona (`westnorth_hex`, #24). Só o primeiro `[status]` é lido.
- Imagens de `[panel]` são desenhadas **em mosaico** (`draw::tiled`), não esticadas:
  painel mais largo precisa de imagem nova (`images/themes/westnorth/*-240.png`).
- Ícones de `[label]` são esticados para o tamanho do `rect`.
- Texto dos botões do tema: tamanho fixo `SIZE_BUTTON_SMALL` (14) no upstream. O fork lê
  `font_size=` em `[menu]` e `[action]` (#17; schema atualizado).
- Imagens de botão do tema não esticam: gere cada tamanho (`end_turn_W228`, `action_W112`,
  `menu_H40`, 4 estados cada) cortando em 3 partes a imagem original.
- O `[no_battery]` do `[resolution]` base reaplica mudanças na caixa da bateria/relógio
  depois do layout parcial; o relógio "11:00" continua pequeno (sem importância).
- Limite vertical do painel em 720 px: conteúdo até y≈545, botões de 550 a 712.
  Unidade com 3 ataques pode ter a última linha cortada (o relatório de armas não rola).
- Tema Westnorth (`westnorth.cfg`): painéis e relatórios **não bloqueiam** toques; o que
  fica sobre o mapa e deve bloquear é um `[action]` com imagem transparente do mesmo
  tamanho (`hud_card`, `hud_pill`, `hud_chip`, 4 estados, `make_hud_images.py`). Botões
  ligados a um relatório que some são escondidos em `display::refresh_report`. O mouse
  sobre um botão do HUD não muda o hex sob o cursor (`display::point_in_hud_button`).

## 4. GUI2 (diálogos)

- Resolução da janela: escolhe a maior `window_width/height` que cabe. `GUI_BIG_RESOLUTION`
  (1200x900) **não** vale em 720 de altura. `GUI_TOUCH_RESOLUTION` (1500x700) é do fork e
  vale no A06 **e** em desktops 1080p.
- **Botões de 72 px em todas as definições quebraram a tela inicial** (não coube em
  720 px e o jogo fechou, #6). Por isso: definição `touch` (72 px) só onde cabe; genéricos
  com 44 px só no Android.
- Diálogo de ataque com fontes de Android: com botões em duas linhas, a segunda arma
  ficava atrás de rolagem; agora uma linha só (#19).
- Uma definição de widget que não existe num tema (ex.: `touch` no Celes) cai em
  silêncio na `default` daquele tema; nada no log. Ao criar definição nova no tema
  default, crie também no Celes.
- "Criar Jogo" (`mp_create_game`): tem layout `default` (≥1200x700) e `tiny` (800x600).
  No A06 vale o `default`; a largura estourava por causa dos nomes das abas. O `tiny`
  com fontes de Android estoura na altura (descrição do mapa não encolhe). O log
  "Failed to fit horizontal list…" aparece nos dois casos e não indica o problema:
  confira a captura (`utils/westnorth/local-game-flow.txt`). O smoke test não abre essa tela.
- `.po` com a entrada só como obsoleta (`#~`): o texto aparece em inglês no jogo. Tabelas
  `<domínio>-new.py` reativam (o script remove a cópia obsoleta antes de acrescentar).
- Diálogos verificados no modo Android (cabem): tela inicial, ataque, recrutar, menu,
  carregar, salvar, sair, ajuda. O tema Celes tem as mesmas definições de toque (#29).

## 5. Toque

- Toque chega como eventos de **mouse sintetizados** pelo SDL (`events::is_touch`) e como
  eventos de dedo. O mapa usa os de mouse; GUI2 e rolagem usam os de dedo.
- SDL3: `SDL_ConvertEventToRenderCoordinates` transforma `tfinger` em **pixels**; o código
  do Wesnoth espera fração 0–1. O fork renormaliza logo após a conversão (#18). **Não
  verificável no Xvfb** — pendente de teste no A06 (rolar listas com o dedo).
- Emulação de toque (`-DMOUSE_TOUCH_EMULATION`, build em `../build-touch`): o botão
  direito vira dedo. Só funciona com o *compiler launcher* (ver `diagnostico-toque.md`).
  A emulação cria eventos de dedo já como fração, por isso escondeu o bug acima.

- Botões do HUD (GUI1: Terminar Turno, Desfazer, cartão da unidade) só respondem ao
  botão **esquerdo**. Na emulação de toque o "dedo" é o botão direito, então `tap` não
  os aciona: teste com `click`. No aparelho o SDL gera clique esquerdo a partir do toque.
- `describeunit` (cartão da unidade) abre a página de **tipo** da unidade na ajuda, não
  o nome/traços daquela unidade; esses ficam na Lista de Unidades.

- Indicadores no mapa (`src/units/drawer.cpp`): esfera, coroa e ícones de leal/herói
  são imagens 72x72 com o desenho no canto superior esquerdo (x 14–27, y 1–12) e são
  desenhados sobre o retângulo do hex; as barras usam coordenadas relativas ao hex de
  72 px. Tudo o que sai do retângulo do hex deixa rastro, porque só o hex é redesenhado.

- Toque em itens do painel lateral: move o "mouse" para lá, então o tooltip do item
  aparece (ex.: arma → "Arma, Dano, Golpes"), e itens com página de ajuda abrem a Ajuda
  (hora do dia → página do período). É o substituto do hover no toque; os tooltips
  usam 20 px desde o UI-7i (`src/tooltips.cpp`).

- Tema "Westnorth" (UI-8): o `id` de `[resolution]` precisa ter a forma `LARGURAxALTURA`
  (o schema rejeita `id=westnorth`). Âncoras: `left`/`top` esticam, `right`/`bottom`
  acompanham a borda, `fixed` fica parado. Relatórios em `[status]` são desenhados em
  ordem **alfabética do nome do relatório**, por isso os fundos de cartão (`background=`)
  são desenhados numa primeira passada em `display::draw_reports`. Imagem de relatório é
  esticada para o retângulo (sem manter proporção): retratos pedem retângulo quadrado.
  Captura com o tema: `WESTNORTH_THEME=Westnorth` no `screenshot.sh`; o smoke test tem
  uma execução com ele.

- `[grid_listbox]` (lista em grade, já no schema) quebra os itens por largura; não cria
  `_header_grid`. Para cartões de largura uniforme, um `[spacer] width=` dentro do item.
  Texto com `<img>` (ex.: custo com ícone de ouro) precisa de `[rich_label]`.
  No `rich_label`, `<span size=...>` some (a linha fica em branco); use só `color`.
- **Retrato que some** (tema Westnorth): quando o relatório `unit_profile` do cartão
  desenhava o mesmo arquivo do retrato de uma fala (`[message]`), os dois sumiam a partir
  da 2ª fala nas capturas. Sem o relatório o retrato voltava. O relatório agora usa
  `small_profile()~SCALE_INTO(200,200)` (textura própria). Causa exata não achada (pode
  ser do renderizador do Xvfb); se algo parecido aparecer, compare com e sem o elemento
  do HUD que usa a mesma imagem.
- Menus do jogo (`command_executor::show_menu`, `drop_down_menu`): não há título; uma
  linha pode ganhar rótulo/ícone próprios com `westnorth_label`/`westnorth_icon` no
  config do item (o `populate_menu_item_info` sobrescreve `label` antes). O hex do toque
  longo é `mouse_handler::get_last_hex()`.
- Temas de UI sem uma definição de widget (ex.: `unit_preview_pane` `westnorth_portrait`
  só no default) usam a do tema default (Celes testado no #49).
  Um mesmo diálogo C++ pode usar outra `[window]` (construtor com id, ver
  `units_dialog`), sem quebrar o teste de diálogos registrados.

- Multitoque: o SDL gera eventos de mouse só do **primeiro** dedo; os outros só chegam
  como `SDL_EVENT_FINGER_*`. O `controller_base` juntava os `FINGER_MOTION` da fila e
  usava só o último (de qualquer dedo); a pinça precisa de todos. Xvfb/xdotool não faz
  multitoque: para testar, empurre eventos sintéticos com `SDL_PushEvent` (dedos com
  x/y em fração da janela; mouse com `which = SDL_TOUCH_MOUSEID`) num ajuste local
  temporário. Arquivos novos em `source_lists/` exigem rodar o `cmake` de novo.
- Para conferir o ponto fixo da pinça use um **mapa maior que a tela** (ex.: cenário
  temporário com `map_file=multiplayer/maps/2p_Caves_of_the_Basilisk.map`): em mapa
  pequeno o `bounds_check_position` centraliza o mapa e esconde o efeito. Nos cenários
  `-t`, um clique fecha o balão de objetivos; `Escape` abre "Sair".

## 6. Ambiente de teste na nuvem

- `run_boost_tests` precisa de **`SDL_VIDEODRIVER=dummy`** (senão os 285 falham por
  timeout com "Could not initialise SDL_video") e de **recompilar `boost_unit_tests`**
  depois de mudar C++ (o link `./boost_unit_tests` aponta para `../build-desktop`).
- Não rode `run_boost_tests` e o smoke test ao mesmo tempo (timeouts).
- `run_wml_tests` também precisa de **`SDL_VIDEODRIVER=dummy`**; sem ele cada teste tenta
  abrir vídeo 10 vezes e o script quebra com `'NoneType' object has no attribute 'returncode'`.
- **Antes de mergear WML**, rode o que o job `checks` roda:
  `./utils/CI/fix_whitespace.sh && git diff --exit-code`, `wmllint`, `check_wml_images.sh`,
  `luacheck .` e **`python3 utils/westnorth/validate_content.py`** (validador do fork;
  esquecê-lo quebrou o CI no #54 quando `[base_unit]` ganhou `inherit_animations=`).
  `check_utf8.sh` precisa de `isutf8` (moreutils), ausente aqui.
  O wmlindent reindenta corpo de `#define` feito dentro de blocos: defina macros no topo
  do arquivo (quebrou o CI no #17, corrigido no #21).
- Xvfb/Mesa: zoom diferente de 1x desenha hexes pretos (também sem mudanças do fork).
  Não conclua nada sobre nitidez de zoom pelas capturas (`diagnostico-zoom.md`).
- `apply_translations.py`: remover uma entrada obsoleta (`#~`) desloca as linhas; o
  script relê o `.po` depois disso (antes dava `KeyError` em `spans[entry.linenum]`).
  Confira com `msgfmt -c -o /dev/null po/<domínio>/pt_BR.po`.
- **Indicadores no mapa** (`units/drawer.cpp`): esfera, coroa e sobreposições são imagens
  72×72 desenhadas a partir do canto superior esquerdo do hex, ampliadas por
  `indicator_scale` (1,35) e **nunca espelhadas**; o sprite da unidade espelha quando ela
  olha para a esquerda (um `~BLIT` na imagem espelha junto). Habilidade sem nome com
  `overlay_image` = sobreposição fixa sem estado por unidade. Só o **primeiro**
  `[abilities]` do tipo é lido (`add_registry_entries`).
- **Arquivos do Drive do dono**: o conector Google Drive (`download_file_content`) salva
  binários em disco (pasta `tool-results` da sessão), não na conversa: dá para baixar os
  pacotes de sprites. A rede do ambiente bloqueia `drive.google.com` direto (curl).
- **No A06 o tema de UI padrão é o Celes**: na primeira execução
  `prefs::set_initial_gui2_theme` escolhe `modern` quando a tela tem ≥ 1280x720 (o A06
  tem 1600x720). Para ver o que o celular mostra, capture com
  `WESTNORTH_GUI_THEME=celes WESTNORTH_ANDROID=1` (sem a variável, o `screenshot.sh`
  usa o default).
- Tela inicial do Celes no Android: os 7 itens secundários (36 px) já ocupam a coluna
  até o rodapé; 48 px não cabe (janela 734 > 720) e 46 px encosta "Sair" na versão.
  Para crescer precisa mudar a estrutura (logo menor ou itens em outra área).
- O tema de UI **Celes tem id `modern`** (`data/gui/themes/celes/_main.cfg`). Com
  `gui2_theme="celes"` o jogo cai no default só com um `error gui/parse: Missing [gui]
  definition` no log: até o #49 as rodadas "celes" do smoke testavam o default. O
  `screenshot.sh` agora traduz `celes` → `modern`.
- Em `bash`, não use `S=... && (cmd) &`: a variável não chega aos outros comandos; e
  `rm` com variável vazia é bloqueado pela proteção do ambiente.

## 7. Receitas de captura (1600x720, `utils/westnorth/screenshot.sh`)

- Cenário `-t westnorth_touch` (build de toque): `tap 1200 650` fecha os objetivos;
  lanceiro em (626,425); meliante distante em (788,389); roteiro completo em
  `utils/westnorth/touch-flow.txt`.
- Cenário `-t westnorth_classes_demo`: `key n` percorre as unidades (bom para ver o
  painel). Recrutar e Lista de Unidades: `utils/westnorth/dialogs-flow.txt` (cliques:
  castelo 490,345; Ações 300,20 → Recrutar 300,132; Menu 100,20 → Lista 150,192).
- **Atalhos com modificador (`key ctrl+r`, `ctrl+u`) falham de forma intermitente no
  Xvfb/xdotool**: o diálogo simplesmente não abre, sem nada no log. Isso já foi
  confundido com bug de WML (reordenação de colunas da lista, 2026-11-27). Prefira
  abrir diálogos pelos menus com `click`, e espere ≥ 30 s antes do primeiro passo (o
  carregamento varia de 12 a 25 s).
- Ajuda `key F1`, carregar `key ctrl+o`, salvar `key ctrl+s`.
- Variáveis: `WESTNORTH_ANDROID=1`, `WESTNORTH_GUI_THEME=celes`, `WESTNORTH_FONT_SCALE=125`,
  `WESTNORTH_DISPLAY=N` (rodar capturas em paralelo com displays diferentes).
- Falas e escolhas: `-t westnorth_message` com `utils/westnorth/message-flow.txt`.
  Tabela de Estatísticas: Menu (100,20) → item (150,132). Menu de toque longo:
  `utils/westnorth/context-menu-flow.txt`.
- Comparar antes/depois: `PIL.ImageChops.difference(a, b).getbbox()` (None = idêntico).

## 8. Repositório e CI

- `GITHUB_TOKEN` não cria ref apontando para commit com workflows diferentes: as tags
  `core-data-<N>` apontam para `$GITHUB_SHA`.
- Depois de squash merge, recomece o ramo de trabalho a partir de `origin/main`
  (`git checkout -B ... origin/main`) antes do próximo ciclo; senão o PR seguinte conflita.
- APK: o Maven Central às vezes responde 429 ao Gradle (run #20 do Android). O workflow
  tem cache do Gradle e tenta o build 3 vezes; uma falha isolada desse tipo não é código.
- Mudança só de WML/imagens chega ao A06 pelo pacote `patch` (sem APK novo); C++ exige
  o APK do `nightly`.
