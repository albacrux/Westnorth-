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
| D40 | Menu de toque longo: descrição da unidade antes da do terreno; "Renomear Unidade" sai (fica na Lista de Unidades); rótulos de mapa ficam no fim com nome claro ("Rótulo no Mapa", "Apagar Rótulos" em vez de "Definir Nome"/"Apagar Nomes") | O menu de contexto é o atalho mais usado no toque; "Definir Nome" parecia renomear a unidade | Agente |
| D41 | Tabela de Estatísticas com os números (ouro, aldeias, unidades, manutenção, receita) no tamanho normal; escolhas das falas ([message] com [option]) com linhas de ~72 px no Android | A tabela passou a guardar o que saiu da barra superior (D37) e tinha os números menores que o nome do líder; as escolhas tinham ~38 px de altura, abaixo do alvo de toque | Agente |
| D42 | Tema Celes com os mesmos tamanhos de toque do default: definição `touch` (72 px nos botões principais) e botões comuns de 44/48 px no Android. Substitui a ressalva do D36 | O Celes não tinha a definição `touch`, então Atacar/Recrutar/Cancelar ficavam pequenos nesse tema | Agente |
| D43 | Indicadores no mapa (esfera, coroa, ícones de leal/herói e barras de HP/XP) desenhados 1,35× maiores a partir do canto do hex; barras com 6 px de largura de base (8 px depois da escala) em vez de 4 | No celular a barra de vida era uma linha de ~0,4 mm e a esfera ~1 mm: a informação mais olhada da partida. Escalar o grupo inteiro mantém coroa e ícones alinhados à esfera; as barras continuam dentro do hex (só ele é redesenhado). Risco aceito: ícones de campanha (`overlays`) também crescem | Agente |
| D44 | Números escritos no mapa ~1,4× maiores: defesa no hex de destino (26/24 px em vez de 18/16), turnos até o destino (24 em vez de 17), alcance do inimigo (22 em vez de 16) e números flutuantes de dano/cura/XP (34 em vez de 24) | A defesa do destino decide onde parar; com o toque em dois passos (D-UI-1) ela aparece entre o primeiro e o segundo toque | Agente |
| D45 | Tooltips do HUD com texto de 20 px (era 15) e caixa de 540 px | No toque, o tooltip aparece ao tocar num item do painel e é o único jeito de ver detalhes como os de uma arma | Agente |
| D46 | Fluxo de partida local no celular: abas do "Criar Jogo" com nomes curtos ("Opções", "Ajustes"), menus suspensos de 44 px no Android, facção "Aleatória" traduzida | Com as fontes de Android o "Criar Jogo" passava da largura da tela (coluna da direita e botões cortados): é o caminho para jogar a era das classes contra a IA. A versão compacta do diálogo foi testada e descartada (estoura na altura) | Agente |

## 2026-11-27 — UI-8: redesenho das telas de combate

| # | Decisão | Motivo | Quem |
|---|---|---|---|
| D47 | Parar os ajustes incrementais e redesenhar do zero as 5 telas de combate (mapa, ataque, recrutar, evolução, toque longo), mantendo cores e fontes; protótipos em `docs/westnorth/prototipos/` | Pedido do dono: as telas ainda tinham a estrutura do desktop | Dono/Agente |
| D48 | O HUD novo será um **tema próprio "Westnorth"** (padrão no Android), e não mais mudanças no tema Default | Permite diagramação livre (mapa em tela cheia, cartões flutuantes) e mantém o Default próximo do upstream para cherry-picks | Agente |
| D49 | Etapa 1 implementada: tema "Westnorth (celular)" (`data/themes/westnorth.cfg`), padrão no Android, escolhível no computador em Preferências → Tema. Itens de `[status]` ganharam `background=`/`padding=` (cartão só com relatório não vazio) e relatórios novos (`westnorth_unit_card`, barras de HP/XP, linha do terreno). Por ora, toques nos cartões do topo e na linha do terreno passam para o mapa | Fiel ao protótipo `1-mapa.jpg`; o cartão da unidade bloqueia o mapa só enquanto aparece (botão de detalhes escondido junto) | Agente |
| D50 | Etapa 2: diálogo de ataque em tela cheia no formato "duelo" — retratos grandes, nível/alinhamento/bônus/defesa, **HP atual → esperado** com barra, lista de armas no centro e chances de **derrotar** e de **morrer** (da simulação de combate que o "Cálculo de Dano" já usa). Os painéis de pré-visualização com botão "Perfil" saem | Protótipo `2-ataque.jpg`; as duas chances e o HP esperado eram a informação que faltava para decidir o ataque no celular | Agente |
| D51 | Etapa 3: Recrutar numa janela própria (`westnorth_recruit`, mesmo C++ do diálogo de unidades) em tela cheia com **grade de cartões** (arte 144 px, nome, custo; sem ouro → cinza), detalhes da escolhida ao lado. Recrutar e Convocar também no menu ☰ do tema Westnorth | Protótipo `3-recrutar.jpg`. Pendências: papel da classe no cartão e retrato grande no painel de detalhes | Agente |
| D52 | Zoom com dois dedos implementado a partir dos eventos de dedo (não dos eventos de pinça do SDL 3.4, que dependem do backend); um nível de zoom por 25% de variação da distância; centrado na tela | Pedido do dono; funciona igual em qualquer aparelho e é testável por teste unitário | Agente |
| D53 | Etapa 4: escolha de evolução em tela cheia com um cartão por caminho, lado a lado (retrato, nome, HP/MP/XP, armas, habilidades); o painel de detalhes antigo sai. Ainda sem o "antes → depois" do protótipo (o diálogo não recebe a unidade original) | Protótipo `4-evolucao.jpg` | Agente |
| D54 | Etapa 5: no celular os menus usam ícones de 36 px (`icons/action/<comando>_36.png` quando existir, senão o ícone de 18 px dobrado), com ícones novos em dourado para Recrutar, Convocar, descrições, rótulos e Continuar; no tema Westnorth o zoom sai do toque longo e vira botões ＋/− fixos na borda direita (além da pinça) | Protótipo `5-toque-longo.jpg`. Sem cabeçalho com nome da unidade/terreno (o menu do motor não tem título) | Agente |
| D55 | Evolução: o diálogo recebe a unidade original; nos cartões, HP e MP que mudam aparecem "antes → depois" (novo em verde), armas com o mesmo id mostram o dano antigo → novo e armas que a unidade não tinha ganham a etiqueta "nova" | Pendência de D53 (protótipo `4-evolucao.jpg`) | Agente |
| D56 | Pinça amplia em volta do ponto entre os dedos (`display::set_zoom_at`), não do centro da tela; os botões ＋/− continuam no centro | Pendência de #41; é o comportamento esperado em mapas de celular | Agente |
| D57 | No tema Westnorth, tocar na pílula de recursos abre a Tabela de Estatísticas (ouro, aldeias e unidades de todos os lados) e tocar na linha do terreno abre a descrição daquele terreno; os dois deixam de passar o toque para o mapa | Pendência de D49; segue o manual (nível 2 a um toque do nível 1) | Agente |
| D58 | Recrutar: cada cartão ganha uma linha de papel automática (habilidades da unidade; senão especiais das armas; senão "corpo a corpo"/"à distância"), e o painel de detalhes mostra o retrato grande (240 px) quando o tipo tem um (`unit_preview_pane` `portrait = true`, definição `westnorth_portrait`) | Pendência de D51. Automático para servir às classes e ao upstream sem texto novo por unidade | Agente |
| D59 | Menu de toque longo começa com o que foi tocado: sprite + tipo da unidade + terreno e defesa (ou ícone e nome do terreno); a linha é o antigo "Descrição da Unidade/Terreno" (tocar abre a descrição), sem item duplicado | Pendência de D54 (o menu do motor não tem título; o cabeçalho é uma linha do próprio menu) | Agente |
| D60 | Falas: retrato do cartão do HUD pré-reduzido a 200 px (corrige o retrato da fala que sumia no tema Westnorth) e, no Android, OK das escolhas com o botão `touch` | Achado ao revisar as telas fora do combate | Agente |
| D61 | Capturas e smoke passam a refletir o celular: com `WESTNORTH_ANDROID=1` o `screenshot.sh` usa o tema de UI Celes (o que o jogo escolhe no A06), e a rodada do HUD Westnorth no smoke usa o Celes. A tela inicial do Celes fica como está (itens de 36 px; ampliar exige reestruturar) | O jogo escolhe `modern` (Celes) em telas ≥ 1280x720; as capturas usavam o default | Agente |
| D62 | Tema Westnorth: botão redondo **Recrutar** no grupo do polegar (Recrutar, Desfazer, Próxima com 84 px e 24 px de folga, alinhados à largura de Terminar Turno) e sem "Sair para o Desktop" no ☰ | Pedido do dono (UI-8b, patch na pasta do Drive), aplicado sobre a versão atual do tema | Dono |
| D63 | Sprites da rodada 1 das classes integrados: 1× e @2x em `data/westnorth/images/units/westnorth/` (o @4x fica no Drive, 3,2 MB, até haver uso). As classes usam `[base_unit] inherit_animations=no` (C++ pequeno em `units/types.cpp`): herdam atributos e retratos da unidade do upstream, mas nenhuma imagem/animação, para não sobrar quadro antigo (morte, ociosidade, variante feminina). Morte e movimento usam as animações padrão do motor | Arte validada pelo dono (relatórios em `docs/westnorth/sprites/`); o `[base_unit]` junta as tags por posição e não tem como remover animações herdadas | Agente |
| D64 | Retratos 400×400 do dono (Drive, bloco 10) nas 6 classes de nível 1; o nível 2 usa o retrato da mesma linhagem até ter o seu | Os retratos do upstream não combinavam com os sprites novos (ex.: Guardião com o retrato do Piqueiro) | Agente |
| D65 | Selo da classe (Drive, bloco 9; 20 px) desenhado na imagem parada da unidade (`~BLIT` no `WN_ART`), no alto à direita do hex; espelha junto com a unidade quando ela olha para a esquerda. Não aparece nos quadros de ataque/defesa | Alavanca D do plano dos sprites: reconhecer o job de longe no celular. Sem estado por unidade nem eventos Lua; aparece também nos cartões de recrutar | Agente |
| D66 | Barras de HP/XP encostadas na borda esquerda do hex (x 3 em vez de 14, antes da escala 1,35); XP mais fina (4 px) que HP (6 px). O selo da classe passa a ser sobreposição de uma habilidade oculta (`[dummy]` sem nome, `overlay_image`), desenhada com a esfera e as barras e nunca espelhada: fica sempre no alto à direita. O painel de unidade ignora habilidades sem nome | Pedido do dono: as barras cobriam os sprites novos (figura a partir de x≈20). O selo pelo `~BLIT` espelhava e caía sobre as barras nas unidades viradas para a esquerda (substitui o D65) | Agente |

## Pendências do dono

- [x] D3: repo público (feito pelo dono em 2026-11-27).
- [ ] Apagar o ramo `debug-release-perms` no GitHub (sobra de um teste; o ambiente do agente não consegue apagar ramos).
- [ ] D29: a regra de troca de classe está boa? (vila/castelo, custa o turno)
- [ ] Sprites (`plano-sprites.md`, seção 4): zoom inicial no celular (recomendado 108 = 1,5×), direção de arte das classes (recomendado: estilo tático com cabeça maior) e ferramenta/validador no desktop.
- [ ] Instalar o APK do release `nightly` no A06 e anotar o que achar (pode ser em issue ou comentário no PR já mergeado).
