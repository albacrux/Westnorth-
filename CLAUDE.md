# Westnorth — regras para o agente

Fork do Battle for Wesnoth (snapshot do `master` upstream, 1.21.0-dev) focado em
jogar no celular (Samsung Galaxy A06, 1600x720 em paisagem) e, depois, em um sistema
de classes estilo tática. Documentos de projeto em `docs/westnorth/`:

- `roadmap.md` — milestones e ciclos (fonte de verdade do que vem a seguir)
- `ui-mobile-brief.md` — problemas de UI observados no A06 e metas de toque
- `decisoes.md` — registro de decisões (data, decisão, motivo). Acrescente, não reescreva.
- `diagnostico-toque.md` — como o toque vira clique hoje no código
- `redesenho-combate.md` + `prototipos/` — nova cara das telas de combate (alvo visual
  das próximas etapas de UI; implementar na ordem do documento)
- `plano-sprites.md` — plano para unidades maiores no mapa (medições, especificação da
  arte 2×, checklist do validador)
- `manual-ui-android.md` — tamanhos (px no A06), estilo e hierarquia de informação
  (nível 1/2/3) que toda mudança de UI deve seguir
- `achados-ui.md` — **ler antes de investigar UI**: o que já foi verificado (tema, GUI2,
  Android × desktop, toque, ambiente de teste) e armadilhas que custaram ciclos.
  Ao descobrir algo novo de UI ou do ambiente, registrar lá no mesmo PR.

## Fluxo de trabalho (vale para toda sessão)

1. **O dono não revisa PRs.** Cada ciclo termina com PR aberto e **mergeado na `main`
   pelo próprio agente**, assim que o critério de merge abaixo for cumprido.
   Squash merge, título no formato `UI-1: ...`.
2. Critério de merge: build desktop local passa, `run_boost_tests` passa, os testes
   WML afetados passam e as verificações do job `checks` passam (`fix_whitespace.sh` sem
   diff, `wmllint`). Se o CI desktop (`.github/workflows/ci.yml`) já tiver terminado,
   ele precisa estar verde; se ainda estiver rodando, pode mergear e conferir depois.
   Se o CI quebrar na `main`, o próximo ciclo começa consertando isso.
3. Um objetivo por PR. Descrição do PR em português: o que mudou, como foi testado,
   capturas 1600x720 antes/depois quando mexer em UI, o que o dono deve testar no A06.
4. O APK (arm64) e os dados do jogo são publicados automaticamente no release
   `nightly` a cada push na `main` (`.github/workflows/android.yml`). O dono instala
   pelo celular a partir de lá.
5. Decisões que o dono precisa tomar: registrar em `decisoes.md` como "pendente",
   seguir com a opção recomendada quando ela for reversível, e avisar no fim do ciclo.

## Regras de código

- **Preferir WML/Lua; C++ só quando inevitável** (entrada por toque, render).
- Mudanças de C++ do fork ficam marcadas com um comentário `// Westnorth:` explicando
  o porquê, para facilitar cherry-pick do upstream.
- Conteúdo novo (eras, facções, classes, conquistas) vai em diretório próprio
  (add-on/era), não em `data/core`, sem justificativa registrada.
- Código e comentários em inglês; documentação do projeto e PRs em português.
- Upstream: o snapshot é congelado (commit `Import upstream Wesnoth master snapshot`).
  Correções do upstream entram só por `git cherry-pick` a partir de
  `https://github.com/wesnoth/wesnoth`. Não fazer merge do upstream inteiro.
- Sprites: gerados e validados no desktop do dono (fora da nuvem). O agente só integra
  sprites que já passaram pelo validador.

## Chaves e segredos

- Nunca commitar chaves reais, tokens ou senhas.
- **Exceção aprovada pelo dono (2026-11-27):** `packaging/android/app/westnorth-debug.keystore`
  é uma chave só de desenvolvimento (senha `android`), sem valor, usada para que cada APK
  de debug instale por cima do anterior e preserve saves. Não serve para loja.

## Build e testes locais (ambiente cloud)

Dependências: pacotes apt listados no CI + SDL3 3.4.2 / SDL3_image 3.4.0 /
SDL3_mixer 3.2.0 compilados de `github.com/libsdl-org` em `/usr/local`
(ver `utils/dockerbuilds/CI/Dockerfile-base-2404-sdl3`).

```sh
git submodule update --init --recursive
cmake -S . -B ../build-desktop -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SERVER=OFF -DENABLE_TESTS=ON -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
ninja -C ../build-desktop wesnoth boost_unit_tests
SDL_VIDEODRIVER=dummy ./run_boost_tests  # a partir da raiz; recompile boost_unit_tests antes
SDL_VIDEODRIVER=dummy ./run_wml_tests -g -c -t 20  # testes WML
```

Capturas em 1600x720: `utils/westnorth/screenshot.sh` (Xvfb). **No Android a GUI2 usa
fontes maiores** (`#ifdef ANDROID` em `data/gui/macros/_initial.cfg`: 22 px em vez de 17);
para ver o que o A06 mostra, capture com `WESTNORTH_ANDROID=1`, que também escolhe o
tema de UI **Celes**, o padrão do jogo em telas ≥ 1280x720 como a do A06.
**Antes de mergear mudança de UI**, rode `utils/westnorth/smoke_1600x720.sh` (abre a tela
inicial e um cenário nos temas default e celes, com fontes de desktop e de Android;
falha se um diálogo não couber em 720 px).
Testar só dentro de uma campanha não basta: a tela inicial já quebrou assim.
**`run_boost_tests` vale também para mudanças só de WML**: vários testes unitários
pré-processam `data/` (e `data/test` sozinho). Por isso nada em `data/test` pode usar
macros de `data/westnorth` (use as funções Lua, ex. `westnorth_classes.add_menu_item()`).
Traduções pt-BR do fork: tabelas em `utils/westnorth/translations/`, aplicadas por
`utils/westnorth/apply_translations.py` (precisa de `pip install polib`).
Lint de WML: `data/tools/wmllint`, `data/tools/wmlscope`, `luacheck .`.

## Android

- Pacote `io.github.albacrux.westnorth`, nome "Westnorth", convive com o Wesnoth oficial.
- Só `arm64-v8a`. Imagem de build: `wesnoth/wesnoth:android` (Docker Hub).
- O APK não carrega dados: `InitActivity` baixa `manifest.txt` do release `nightly`.
  Pacotes gerados por `packaging/android/westnorth/make-data-packages.sh`:
  `core` (snapshot upstream, release `core-data-<N>`), `patch` (cumulativo, o que o
  fork mudou) e `music` (upstream, SourceForge). Mudança só em WML/imagens
  **não exige APK novo**: basta o `patch` novo; o app baixa ao abrir.
- Se o snapshot do upstream mudar, incrementar `CORE_GEN` no workflow.
