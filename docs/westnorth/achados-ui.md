# Achados de UI e armadilhas conhecidas (referência rápida)

Registro do que **já foi verificado** sobre como a UI funciona neste snapshot
(upstream 1.21.0-dev) e no ambiente de nuvem. Leia antes de investigar algo de UI:
se o assunto estiver aqui, parta da conclusão em vez de repetir a verificação.
Acrescente novos achados no fim da seção certa (data + PR).

Documentos detalhados: `diagnostico-toque.md` (eventos de toque), `diagnostico-zoom.md`
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

## 4. GUI2 (diálogos)

- Resolução da janela: escolhe a maior `window_width/height` que cabe. `GUI_BIG_RESOLUTION`
  (1200x900) **não** vale em 720 de altura. `GUI_TOUCH_RESOLUTION` (1500x700) é do fork e
  vale no A06 **e** em desktops 1080p.
- **Botões de 72 px em todas as definições quebraram a tela inicial** (não coube em
  720 px e o jogo fechou, #6). Por isso: definição `touch` (72 px) só onde cabe; genéricos
  com 44 px só no Android.
- Diálogo de ataque com fontes de Android: com botões em duas linhas, a segunda arma
  ficava atrás de rolagem; agora uma linha só (#19).
- Diálogos verificados no modo Android (cabem): tela inicial, ataque, recrutar, menu,
  carregar, salvar, sair, ajuda. O tema Celes ainda usa botões pequenos.

## 5. Toque

- Toque chega como eventos de **mouse sintetizados** pelo SDL (`events::is_touch`) e como
  eventos de dedo. O mapa usa os de mouse; GUI2 e rolagem usam os de dedo.
- SDL3: `SDL_ConvertEventToRenderCoordinates` transforma `tfinger` em **pixels**; o código
  do Wesnoth espera fração 0–1. O fork renormaliza logo após a conversão (#18). **Não
  verificável no Xvfb** — pendente de teste no A06 (rolar listas com o dedo).
- Emulação de toque (`-DMOUSE_TOUCH_EMULATION`, build em `../build-touch`): o botão
  direito vira dedo. Só funciona com o *compiler launcher* (ver `diagnostico-toque.md`).
  A emulação cria eventos de dedo já como fração, por isso escondeu o bug acima.

## 6. Ambiente de teste na nuvem

- `run_boost_tests` precisa de **`SDL_VIDEODRIVER=dummy`** (senão os 285 falham por
  timeout com "Could not initialise SDL_video") e de **recompilar `boost_unit_tests`**
  depois de mudar C++ (o link `./boost_unit_tests` aponta para `../build-desktop`).
- Não rode `run_boost_tests` e o smoke test ao mesmo tempo (timeouts).
- **Antes de mergear WML**, rode o que o job `checks` roda:
  `./utils/CI/fix_whitespace.sh && git diff --exit-code`, `wmllint`, `check_wml_images.sh`.
  O wmlindent reindenta corpo de `#define` feito dentro de blocos: defina macros no topo
  do arquivo (quebrou o CI no #17, corrigido no #21).
- Xvfb/Mesa: zoom diferente de 1x desenha hexes pretos (também sem mudanças do fork).
  Não conclua nada sobre nitidez de zoom pelas capturas (`diagnostico-zoom.md`).
- Em `bash`, não use `S=... && (cmd) &`: a variável não chega aos outros comandos; e
  `rm` com variável vazia é bloqueado pela proteção do ambiente.

## 7. Receitas de captura (1600x720, `utils/westnorth/screenshot.sh`)

- Cenário `-t westnorth_touch` (build de toque): `tap 1200 650` fecha os objetivos;
  lanceiro em (626,425); meliante distante em (788,389); roteiro completo em
  `utils/westnorth/touch-flow.txt`.
- Cenário `-t westnorth_classes_demo`: `key n` percorre as unidades (bom para ver o
  painel); recrutar = `click 490 345` (castelo) e depois `key ctrl+r`.
- Ajuda `key F1`, carregar `key ctrl+o`, salvar `key ctrl+s`.
- Variáveis: `WESTNORTH_ANDROID=1`, `WESTNORTH_GUI_THEME=celes`, `WESTNORTH_FONT_SCALE=125`,
  `WESTNORTH_DISPLAY=N` (rodar capturas em paralelo com displays diferentes).
- Comparar antes/depois: `PIL.ImageChops.difference(a, b).getbbox()` (None = idêntico).

## 8. Repositório e CI

- `GITHUB_TOKEN` não cria ref apontando para commit com workflows diferentes: as tags
  `core-data-<N>` apontam para `$GITHUB_SHA`.
- Depois de squash merge, recomece o ramo de trabalho a partir de `origin/main`
  (`git checkout -B ... origin/main`) antes do próximo ciclo; senão o PR seguinte conflita.
- Mudança só de WML/imagens chega ao A06 pelo pacote `patch` (sem APK novo); C++ exige
  o APK do `nightly`.
