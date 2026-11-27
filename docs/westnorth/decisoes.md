# Registro de decisões

Formato: data — decisão — motivo — quem decidiu. Acrescentar no fim; não reescrever
entradas antigas (se mudar, criar nova entrada que substitui a anterior).

## 2026-11-27 — sessão de abertura

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D1 | Base do fork = `master` upstream em `260ce914` (1.21.0-dev, 2026-11-26), importado **sem histórico** num único commit | "Ponto mais avançado" pedido pelo dono; é onde o port Android e o CI Android vivem. Sem histórico, o push cabe e o repo fica leve; correções do upstream entram por cherry-pick (funciona sem ancestral comum) | Agente |
| D2 | Repo de trabalho = `albacrux/Westnorth-` (já existia, privado) | O ambiente só tem acesso a esse repo; criar outro repo não é possível daqui | Agente |
| D3 | **Tornar o repo público** | Minutos ilimitados de GitHub Actions; a GPL exige publicar o código de qualquer forma ao distribuir o APK; e o app baixa os dados do jogo dos releases do repo, o que só funciona sem login se o repo for público | **Dono** — falta executar (Settings → General → Change visibility) |
| D4 | Chave de assinatura **debug** commitada (`packaging/android/app/westnorth-debug.keystore`, senha `android`) | Cada APK novo instala por cima do anterior e preserva saves/add-ons. Chave sem valor; regra "nunca commitar chaves" continua para chaves reais | **Dono** |
| D5 | Pacote Android próprio `io.github.albacrux.westnorth`, nome "Westnorth" | Convive com o Wesnoth oficial no A06 para comparar lado a lado | Agente |
| D6 | APK só `arm64-v8a`, build de debug, publicado no release `nightly` a cada push na `main` | Alvo é o A06; reduz o tempo de CI para ~1/4 | Agente |
| D7 | Dados do jogo servidos pelo fork: pacote `core` (snapshot upstream, raramente muda) + `patch` cumulativo (só o que o fork mudou) + `music` do upstream | O app não traz dados no APK; o upstream só publica dados de versões oficiais. Mudanças só em WML chegam ao celular sem APK novo | Agente |
| D8 | O dono não revisa PRs: o agente mergeia cada ciclo ao terminar (critério em `CLAUDE.md`) | Pedido do dono | **Dono** |
| D9 | Ordem dos ciclos mantida (UI-1 toque primeiro). Mudanças de C++ marcadas com `// Westnorth:` | Toque é o bloqueio nº 1 de jogabilidade; marcação facilita cherry-pick do upstream | Agente |
| D10 | Confirmação de movimento por toque = **tocar de novo no mesmo hex** (o caminho fica desenhado no 1º toque). Botões "Confirmar/Desfazer" na tela entram no ciclo do HUD (UI-4) | Resolve sem mexer no tema do HUD; um botão na tela depende do redesenho do HUD | Agente |
| D11 | Upstream do `master` usa SDL3 (o 1.19.29 testado no A06 usa SDL2). Seguimos com SDL3 | É o caminho do upstream; o comportamento de toque foi reescrito com base no código atual | Agente |

## 2026-11-27 — UI-1

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D12 | `CORE_GEN` = 2 | O script de pacotes gerava o `core` sem traduções (lista de domínios mal lida). O 1º build ainda não tinha publicado nada (403 no release com o repo privado) | Agente |
| D13 | Toque processado ao soltar; atalhos de toque (`touchhex`, `selectmoveaction`) desligados para toque | Causa raiz da seleção que se desfaz (ver `diagnostico-toque.md`) | Agente |
| D14 | Emulação de toque do desktop corrigida e usada nos testes de UI | Única forma de validar toque na nuvem | Agente |

## 2026-11-27 — UI-2

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D15 | Confirmação de "Terminar Turno" ligada por padrão quando alguma unidade ainda pode se mover (pref `confirm_end_turn` vazia = "yellow") | Brief: botão grande precisa de proteção contra toque acidental | Agente |
| D16 | Nova resolução GUI2 `GUI_TOUCH_RESOLUTION` (tela ≥ 1500x700, perde para `GUI_BIG_RESOLUTION` em telas maiores) com botões de 72 px | Diálogos tocáveis sem afetar desktops comuns | Agente |
| D17 | O layout `1024x600` do tema do HUD vira o layout de celular (é o que telas 1600x720 recebem): barra superior 40 px, Menu/Ações 200x40, "Terminar Turno" 172x80 | O tema escolhe o 1º layout que cabe; criar outro antes dele exigiria reordenar o tema | Agente |
| D18 | Meta de 48 dp (79 px) atingida no "Terminar Turno" (80 px) e quase nos botões de diálogo (72 px ≈ 44 dp); Menu/Ações ficaram com 40 px de altura (≈ 24 dp, mas 200 px de largura) | Barra de 79 px tiraria 11% da altura do mapa. Resolver de vez no UI-4 (menu ☰ e barra de ações) | Agente |

## 2026-11-27 — UI-3

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D19 | Menus escondem a coluna de atalhos quando há tela de toque (Android sempre) | Atalhos não servem no celular e ocupavam 1/3 de cada linha | Agente |
| D20 | Itens raros de Menu e Ações vão para um submenu "Mais..." (conquistas, estatísticas, replays, salvar mapa, log de conversa / planejamento, melhores movimentos, falar, rótulos, comando) | Linhas de ~53 px; com 19 itens o menu não caberia em 720 px | Agente |
| D21 | Tradução pt-BR de strings novas do fork vai direto em `po/*/pt_BR.po` | O fork não sincroniza `.pot` com o upstream; simples e reversível | Agente |

## 2026-11-27 — Correção do UI-2 e traduções

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D22 | Botões de 72 px só na definição nova `touch` (Atacar, Cálculo de Dano, Cancelar, Recrutar); `default`/`large`/`transparent` voltam ao tamanho do upstream | Aplicar em todos os botões fazia a tela inicial não caber em 720 px e o jogo fechava ao abrir (regressão do UI-2, nunca chegou a um APK publicado) | Agente |
| D23 | Smoke test `utils/westnorth/smoke_1600x720.sh` no CI | Pega layouts que não cabem na tela do A06 | Agente |
| D24 | `wesnoth-lib` pt-BR 100% traduzido (188 textos: 88 sem tradução + 100 "fuzzy", que o jogo ignorava) | Itens do brief ("Show Topics", "Tip of the Day", "About") e outros textos em inglês ou com tradução errada | Agente |

## 2026-11-27 — UI-4 (parte 1) e UI-5 (diagnóstico)

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D25 | Botões "Desfazer" e "Próxima" (84x76 px) no painel lateral, logo acima do "Terminar Turno" | Brief: Desfazer sempre visível depois de mover; o canto inferior direito é onde o polegar já está. O tema desabilita o botão quando a ação não está disponível | Agente |
| D26 | Zoom: nenhuma mudança por enquanto; diagnóstico em `diagnostico-zoom.md` | O ambiente de teste mostra hexes pretos com zoom diferente de 1x, com ou sem as correções. Sem o aparelho não dá para separar bug do jogo de artefato do Mesa | Agente |

## 2026-11-27 — M2/M4: classes (rodada 1)

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D27 | Conteúdo do fork em `data/westnorth/`, carregado por `data/_main.cfg`, com textos escritos direto em pt-BR | Vai no pacote `patch` (sem APK novo) e evita a infraestrutura de tradução enquanto o projeto é pessoal. Tradução para outros idiomas fica para depois (`.po` do domínio `wesnoth-westnorth`) | Agente |
| D28 | Classes herdam arte e animações do upstream com `[base_unit]` até existirem sprites próprios | Permite jogar e balancear já; os sprites vêm do desktop do dono (M6) | Agente |
| D29 | **Troca de classe** só em vila ou castelo, custa o resto do turno, não é permitida depois de atacar, mantém nível, experiência (abaixo do máximo), traços e proporção de vida | Era decisão em aberto no roadmap ("livre, só em cidade, ou custo"). Escolhi a opção que cria decisão tática sem burocracia. **Pendente de validação do dono** | Agente |
| D30 | Facções do protótipo: Ordem da Coroa (Escudeiro, Cavaleiro, Arqueiro, Mago Branco) e Companhia Sombria (Ladino, Mago Negro, Arqueiro, Escudeiro) | Duas facções mínimas pedidas no M2, com estilos opostos (linha firme × infiltração/magia) | Agente |

## Pendências do dono

- [x] D3: repo público (feito pelo dono em 2026-11-27).
- [ ] Apagar o ramo `debug-release-perms` no GitHub (sobra de um teste; o ambiente do agente não consegue apagar ramos).
- [ ] D29: a regra de troca de classe está boa? (vila/castelo, custa o turno)
- [ ] Instalar o APK do release `nightly` no A06 e anotar o que achar (pode ser em issue ou comentário no PR já mergeado).
