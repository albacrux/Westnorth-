# Classes do Westnorth (M4, rodada 1)

Fatia vertical do sistema de classes inspirado em tática por turnos com troca de
"job". Código: `data/westnorth/` (unidades, era, mapa, Lua). Testes:
`data/test/scenarios/wml_tests/Westnorth/classes.cfg` (rodam no CI).

## Princípio

Cada classe muda **o que o jogador faz**, não só números. Se a diferença de uma
classe se resume a "mais dano" ou "mais vida", ela não entra.

## As 6 classes

| Classe | Nível 1 | Nível 2 | O que muda no jogo | Arte provisória (id upstream) |
|---|---|---|---|---|
| Escudeiro | Escudeiro (14 de ouro) | Guardião (26) | Segura a linha: **firme** (resistências dobram na defesa). No nível 2, **liderança** (aliados de nível menor ao lado causam +25%) | Spearman / Pikeman |
| Cavaleiro | Cavaleiro (18) | Cavaleiro Rúnico (30) | Rápido; o golpe deixa o alvo **lento** (causa metade do dano até o fim do turno dele) | Cavalryman / Dragoon |
| Arqueiro | Arqueiro (16) | Atirador de Elite (27) | Arco **certeiro**: no mínimo 60% de acerto, mesmo em florestas e castelos | Bowman / Longbowman |
| Ladino | Ladino (14) | Sombra (26) | **Escaramuçador** (ignora zonas de controle) e **apunhalada** (dano dobrado com aliado atrás do alvo). No nível 2, facas **envenenadas** | Thief / Rogue |
| Mago Branco | Mago Branco (20) | Sacerdote da Luz (32) | **Cura** os aliados ao lado (+4; +8 e remove veneno no nível 2). Dano arcano, bom contra mortos-vivos | Mage / White Mage |
| Mago Negro | Mago Negro (17) | Feiticeiro Sombrio (34) | Magia que acerta 70%, mas **sem ataque corpo a corpo** no nível 1: precisa de proteção | Dark Adept / Dark Sorcerer |

Os números são o ponto de partida, sem teste de balanceamento. As unidades herdam
arte, animações e atributos do upstream com `[base_unit]`. Os sprites próprios vêm
depois (pipeline de sprites no desktop do dono, M6).

## Troca de classe

- **Onde:** com a unidade numa vila ou num castelo/fortaleza.
- **Como:** toque longo na unidade (botão direito no desktop) → **Mudar de classe...**
  → escolher. A lista mostra a arte de cada classe e o papel dela.
- **Custo:** a unidade termina o turno (movimento e ataque zerados). Não pode trocar
  depois de atacar.
- **O que preserva:** nível (nível 1 → nível 1 da nova classe), **experiência**
  (limitada a 1 abaixo do máximo da nova classe, para não evoluir na hora),
  **traços** e a **proporção de vida**.
- Implementação: `data/westnorth/lua/classes.lua` (`classes.change`), menu em
  `data/westnorth/macros/classes.cfg` (`{WN_CLASS_SYSTEM}`).

## Onde jogar

- **Multiplayer → era "Westnorth: Classes (protótipo)"**, com duas facções:
  - **Ordem da Coroa**: recruta Escudeiro, Cavaleiro, Arqueiro e Mago Branco.
  - **Companhia Sombria**: recruta Ladino, Mago Negro, Arqueiro e Escudeiro.
- Mapa **2p — Encruzilhada (Westnorth)**: 22x12 hexes, rio com dois vaus e 8 vilas,
  pensado para caber na tela do celular. Dá para jogar contra a IA.
- Teste rápido no desktop: `wesnoth -t westnorth_classes_demo`.

## Conquistas (M5)

Grupo **"Westnorth: Classes"** na tela de Conquistas (`data/westnorth/achievements.cfg`,
concedidas por `data/westnorth/lua/achievements.lua`). Valem só para o jogador humano
deste aparelho, em partidas que usam as classes (era do Westnorth ou cenário com
`{WN_CLASS_SYSTEM}`).

| Conquista | Como conseguir |
|---|---|
| Nova Vocação | Mudar a classe de uma unidade |
| Mestre de Todos os Ofícios | Ter cada uma das 6 classes no exército (recrutando ou trocando); progresso 0/6 |
| Promovido | Levar uma unidade de classe ao nível 2 |
| Segunda Carreira | Mudar a classe de uma unidade de nível 2 |
| Freio de Mão | Acertar 10 golpes corpo a corpo com Cavaleiros (progresso 0/10) |
| Pelas Costas | Derrotar um inimigo com Ladino ou Sombra |
| Magia Negra | Derrotar um inimigo com Mago Negro ou Feiticeiro Sombrio |
| Senhor da Encruzilhada | Vencer no mapa 2p — Encruzilhada |
| Sem Baixas | Vencer sem perder nenhuma unidade |
| Guerra Relâmpago | Vencer em até 12 turnos |

## Fica para as próximas rodadas

- Habilidades aprendidas por pontos ("JP"); hoje a experiência é única por unidade.
- Rodada 2 de classes (Monge, Lanceiro, Invocador, Geomante, Ninja, Samurai — nomes provisórios).
- Balanceamento por partidas IA × IA headless e por partidas no A06 (M7).
- Sprites próprios (M6).
