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

## 2026-11-27 — M5: conquistas

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D31 | 10 conquistas no grupo `content_for=westnorth`, só para o humano local, disparadas pelos eventos do sistema de classes | Conquistas ficam nas preferências do aparelho: dar ao AI ou ao adversário de rede não faria sentido | Agente |

## 2026-11-27 — UI-6: traduções

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D32 | Domínio `wesnoth` pt-BR 100% (171 textos: tempo de jogo, APNM, dicas, ajuda de unidades, comandos de depuração). Listas de nomes e geradores de nome ficam iguais ao original | Textos do jogo em si apareciam em inglês ou com tradução errada (ex.: "Morning" → "Atenção") | Agente |

## 2026-11-27 — UI-4b: legibilidade do HUD

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D33 | Não ampliar a interface inteira por escala fracionária (desenhar em 1200x540 e esticar para 1600x720) | Este upstream exige tela lógica mínima de **1280x720**; o A06 já tem exatamente 720 de altura, então qualquer ampliação global faria diálogos deixarem de caber. A escala de fonte global (preferência avançada "Font size scale") a 125% também corta texto no painel e põe barra de rolagem no diálogo de ataque | Agente |
| D34 | Em vez disso, refazer o HUD do layout de celular: painel lateral de 181 → 240 px, textos de 11–13 → 15–17 px, HP/XP/MP em uma linha cada, raça na linha do alinhamento; barra superior com números de 20 px e ícones de 24 px; botões com texto maior (`font_size=` em `[menu]`/`[action]` do tema, suportado no C++ do fork) | O mapa perde só 58 px de largura e o painel ganha leitura no celular. Diálogos GUI2 (ataque, recrutar) ficam para o próximo passo | Agente |

| D35 | `WESTNORTH_ANDROID=1` faz o desktop montar a GUI com o define `ANDROID` (fontes 22 px), e o smoke test roda nos dois modos | As capturas e o smoke test até aqui usavam as fontes de desktop (17 px); o A06 usa as de Android. Com elas, o diálogo de ataque escondia a segunda arma, por isso os botões dele foram para uma linha só | Agente |

| D36 | No Android, os botões genéricos da GUI2 (tema default) passam de 26 px / texto 16 px para 44 px / texto 20 px; "large" vai a 48 px. O tema Celes não foi mudado | Sim/Não, Salvar, Fechar e a tela inicial ficavam com botões e texto pequenos. 44 px (não 72) mantém a tela inicial e os diálogos altos dentro de 720 px (smoke test nos dois temas) | Agente |

## 2026-11-27 — UI-7: HUD replanejado por hierarquia de informação

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D37 | O layout de celular passa a seguir `manual-ui-android.md`: nível 1 (HP, MP, defesa no hex, tipo, ouro, turno, renda) grande; nível 2 (XP, alinhamento, habilidades, armas) a 18 px; nível 3 (nome próprio, raça, traços, lado, coordenadas, visão, contador 1/6, unidades/manutenção, botões do minimapa) sai da tela. O cartão da unidade vira botão e abre a descrição (`describeunit`) | Pedido do dono: o HUD do upstream dá destaque ao que não decide jogadas (ex.: o nome do personagem) e é preciso replanejar para o fluxo do celular, não só aumentar fontes | Agente |
| D38 | Diálogo de ataque pela mesma hierarquia: cada lado mostra tipo (grande), "Nv · alinhamento" numa linha, HP grande em negrito e XP; o nome próprio e os traços ficam no botão Perfil. Cada arma começa por **dano×golpes e chance de acerto** (grandes, negrito), depois "arma · tipo de dano" e os especiais pequenos | No upstream o nome do personagem era a maior linha e os números decisivos vinham na 3ª e 4ª linhas da arma | Agente |
| D39 | Recrutar/Lista de Unidades: o painel da esquerda mostra o tipo grande e o nome pequeno embaixo; HP/XP/MP em tamanho normal (não "small"); colunas da lista na ordem Tipo, Nv, HP, Movimentos, XP, Nome, Características | Mesma hierarquia (D37). Efeito colateral aceito: no diálogo de depuração "criar unidade" a coluna de raça aparece antes do tipo | Agente |

## Pendências do dono

- [x] D3: repo público (feito pelo dono em 2026-11-27).
- [ ] Apagar o ramo `debug-release-perms` no GitHub (sobra de um teste; o ambiente do agente não consegue apagar ramos).
- [ ] D29: a regra de troca de classe está boa? (vila/castelo, custa o turno)
- [ ] Instalar o APK do release `nightly` no A06 e anotar o que achar (pode ser em issue ou comentário no PR já mergeado).
