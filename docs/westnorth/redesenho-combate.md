# Redesenho das telas de combate (UI-8)

Pedido do dono (2026-11-27): os ajustes de fonte e tamanho trouxeram ganhos pequenos,
mas nenhuma tela "parece um jogo de celular" — a estrutura é a do Wesnoth de desktop.
Objetivo: **replanejar do zero a diagramação** das telas usadas no combate, **mantendo
a tabela de cores e as fontes** do jogo.

Protótipos (1600x720, A06 em paisagem): `docs/westnorth/prototipos/*.jpg`. Fontes em HTML
no mesmo diretório (`node render.js 1-mapa.html ...` regenera as imagens).

## 1. Inventário: telas do combate, por frequência

| # | Tela | Quando aparece | O que decide | Hoje |
|---|---|---|---|---|
| 1 | **Mapa (HUD)** | O tempo todo | Para onde mover, quem atacar, quando terminar o turno | Barra lateral fixa de 240 px com tudo; barra de topo de desktop |
| 2 | **Ataque** (`unit_attack`) | A cada ataque | Com qual arma atacar, se vale a pena | Lista de armas com texto; sem "chance de matar" |
| 3 | **Recrutar** (`units_dialog`) | Início de cada turno com ouro | Quem recrutar | Lista + painel de detalhes de desktop |
| 4 | **Evolução** (`unit_advance`) | Quando uma unidade sobe com opções | Caminho da unidade | Lista estreita |
| 5 | **Toque longo** (menu de contexto) | Recrutar, mudar de classe, informações | Ação contextual | Menu de texto do desktop, com zoom e depuração misturados |
| — | Cálculo de dano, falas, objetivos, fim de cenário | Raro / leitura | — | Ficam para depois |

## 2. Princípios da nova cara

1. **O mapa é a tela.** Nada fixo ocupa uma faixa inteira: só cartões flutuantes,
   translúcidos, nos cantos. O mapa vai de borda a borda.
2. **Informação aparece quando importa.** O cartão da unidade só existe com unidade
   selecionada; a linha do terreno só com hex sob o dedo; o resto fica a um toque
   (`manual-ui-android.md`, níveis 1/2/3).
3. **Polegares.** Ações frequentes no canto inferior direito (Terminar Turno, Desfazer,
   Próxima); o topo é só leitura (turno, ouro, aldeias, renda, hora do dia) e o menu ☰.
4. **Números grandes, palavras pequenas.** HP, dano×golpes, acerto e defesa em 28–38 px
   negrito; rótulos em versalete pequeno.
5. **Diálogos de combate em tela cheia** com retratos grandes (arte de `portraits/`), no
   estilo "duelo": o jogador compara os dois lados de relance.
6. **Mesma identidade:** fonte Lato (400/700/900); cores do jogo — dourado de título
   `186,172,125`, texto `215,215,215`, creme dos números `245,230,193`, bordas
   `114,79,46` / `162,127,68` / `185,158,75`, verde `0,181,26`, vermelho `255,0,0`,
   azul de XP; botões no gradiente azul com borda dourada dos botões do Wesnoth.

## 3. Telas

### 3.1 Mapa (`1-mapa.jpg`)
- Topo esquerdo: botão **☰** (menu do jogo).
- Topo centro: pílula com **turno, ouro, renda, aldeias e hora do dia**.
- Topo direito: **minimapa** em moldura.
- Inferior esquerdo, só com unidade: **cartão** com retrato saindo da moldura, tipo,
  nível/alinhamento, **barra de HP larga** com número grande, XP, MP, armas como fichas.
  Toque no cartão → ficha completa.
- Acima do cartão: **linha do terreno** sob o dedo ("Campo · Defesa 40% · Mov. 1").
- Inferior direito: **Terminar Turno** grande + Desfazer / Próxima redondos.

Viabilidade: o motor desenha painéis, relatórios e minimapa **depois** do mapa
(`display::expose`), então cartões sobre o mapa funcionam. Implementação como **tema
novo "Westnorth"** (`data/themes/westnorth.cfg`), padrão no Android e escolhível no
desktop; o tema Default volta a ser o do upstream. C++ necessário:
fundo de cartão que só aparece quando o relatório não está vazio (`[status]` com
`background=`), relatório de barra de HP, retrato (`unit_profile` já existe).

### 3.2 Ataque (`2-ataque.jpg`)
- Tela cheia sobre o mapa escurecido. Atacante à esquerda, defensor à direita, com
  retrato grande, tipo, alinhamento/bônus, defesa do terreno e **HP atual → HP esperado**
  com barra (parte perdida hachurada).
- Centro: **abas das armas** (arma × resposta do inimigo), linhas **Dano**, **Acerto**,
  **Especial** com números grandes, e dois quadros: **Derrotar o inimigo %** e
  **Sua unidade morrer %**.
- Embaixo: Cancelar (esquerda), **Atacar** (direita, grande). "Cálculo detalhado" no topo.

Viabilidade: novo layout de `unit_attack.cfg`; HP esperado e chances vêm do
`battle_context` (distribuição de HP do combatente), já calculados para o "Cálculo de Dano".

### 3.3 Recrutar (`3-recrutar.jpg`)
- **Grade de cartões** (3×2) com sprite grande, nome, papel em uma linha e **custo** em
  pílula; sem ouro → cartão apagado com custo em vermelho. Detalhes da escolhida à direita
  com retrato, HP/MP/XP/custo grandes, armas, e **Recrutar · 14** grande.

Viabilidade: janela de recrutamento própria (o diálogo de unidades do upstream serve a
quatro telas); a lista vira grade (`[grid_listbox]`/`horizontal_listbox`).

### 3.4 Evolução (`4-evolucao.jpg`)
- Um **cartão por caminho**, lado a lado, com arte grande e só o que muda (HP antes →
  depois, arma nova, resistência). Confirmar embaixo.

### 3.5 Toque longo (`5-toque-longo.jpg`)
- **Folha de ações** com ícone e linhas de 72 px: ações principais primeiro (Recrutar,
  Convocar, Mudar de classe), informações depois. Zoom sai do menu e vira **＋/－** fixos
  na borda direita. Comandos de depuração continuam só no modo de depuração.

## 4. Ordem de implementação

| Ordem | Tela | Entrega |
|---|---|---|
| 1 | Mapa | Tema "Westnorth" em tela cheia, cartões condicionais, cluster de polegar |
| 2 | Ataque | Layout duelo + HP esperado + chances |
| 3 | Recrutar | Grade de cartões |
| 4 | Evolução | Cartões lado a lado |
| 5 | Toque longo | Folha de ações com ícones, zoom fixo |

Cada etapa é um PR com captura do jogo real ao lado do protótipo.
