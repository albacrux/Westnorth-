# Manual resumido de UI para Android (Westnorth)

Referência de tamanhos, estilo e hierarquia de informação para a interface no celular.
Alvo: Samsung Galaxy A06, 1600x720 em paisagem, 6,7", **262 ppi**. Fontes no fim.

## 1. Conversão para o A06

O Android mede em **dp** (tamanhos) e **sp** (texto); 1 dp = 1/160 de polegada.
No A06: `px = dp × 262 / 160 ≈ dp × 1,64` (a Samsung pode arredondar a densidade
lógica para cima; trate os valores abaixo como mínimos).

| Referência | dp/sp | px no A06 |
|---|---|---|
| Alvo de toque mínimo (Android, WCAG 2.5.5) | 48 dp (≈ 9 mm) | **79 px** |
| Espaço entre alvos de toque | 8 dp | 13 px |
| Piso absoluto de alvo (WCAG 2.5.8) | 24 dp | 39 px |
| Material 3 — Label Small (menor texto) | 11 sp | **18 px** |
| Label Medium / Body Small | 12 sp | 20 px |
| Label Large / Body Medium | 14 sp | **23 px** |
| Body Large / Title Medium | 16 sp | 26 px |
| Title Large | 22 sp | 36 px |

O guia de acessibilidade do Xbox pede texto de pelo menos **26 px a 1080p** num console
(tela grande, longe) e manda escalar linearmente pela densidade em telas de celular; o
mercado de TV usa 28 px como piso. Em todos os guias, o jogador deve poder aumentar o
texto (Xbox: até 200% sem perder conteúdo).

## 2. Regras de tamanho para o Westnorth (1600x720)

| Papel | Tamanho | Peso | Exemplos |
|---|---|---|---|
| Número primário de gameplay | **24 px** (mín. 22) | normal/negrito | Vida, Movimento, Defesa no hex, Ouro, Turno |
| Título do item em foco | 20–22 px | negrito se possível | Tipo da unidade, título de diálogo |
| Texto secundário | **18–20 px** | normal | XP, alinhamento, habilidades, armas, nome do terreno |
| Piso (nunca abaixo) | 18 px | — | rótulos "HP", "MP", legendas |
| Texto corrido (ajuda, descrições) | 22–23 px | normal | diálogos com Android: 22 px (`GUI_FONT_SIZE_DEFAULT`) |
| Botão de ação principal | ≥ 76–80 px de altura, texto 19–20 px | — | Terminar Turno, Atacar, Recrutar |
| Botão comum | ≥ 44 px de altura (ideal 79), texto 20 px | — | Sim/Não, Fechar, Salvar |

- **Contraste:** 4,5:1 para texto normal, 3:1 para texto grande; cores (verde/azul/
  amarelo) só como reforço — o número tem que bastar.
- **Fonte:** a sans-serif do jogo (Lato/DejaVu) serve; evitar itálico e versalete em
  números; não usar fonte "decorativa" em informação.
- **Alinhamento:** rótulo curto à esquerda + valor alinhado na mesma coluna; uma
  informação por linha; números do mesmo tipo sempre no mesmo lugar (memória espacial).

## 3. Hierarquia de informação (revelação progressiva)

Princípio: **a tela mostra o que decide a jogada agora**; o resto fica a um toque
(segundo nível) ou em menu/ajuda (terceiro nível). Cada elemento do HUD recebe uma nota
de importância e só os de nota alta ganham espaço fixo.

| Nível | Onde | Critério |
|---|---|---|
| **1 — sempre visível, grande** | Painel/barra | Muda a decisão deste movimento ou deste turno |
| **2 — um toque** | Botão "Detalhes", toque longo, diálogo | Útil para planejar, não a cada movimento |
| **3 — menu/ajuda** | Menu, Ajuda, Tabela de Estatísticas | Curiosidade, história, informação rara |

Classificação atual do HUD do Wesnoth (aplicada no layout de celular):

| Informação | Nível | Motivo |
|---|---|---|
| Vida (HP) atual/máx. | 1 | Decide atacar/recuar |
| Movimento (MP) restante | 1 | Decide para onde ir |
| Defesa no hex sob o dedo/destino | 1 | Decide onde parar |
| Tipo da unidade | 1 | Diz o que ela faz (o "job") |
| Armas: dano×golpes, alcance | 1–2 | Decide se ataca; especiais em linha menor |
| Ouro, turno, renda | 1 | Decide recrutar/terminar turno |
| Hora do dia (imagem) | 1–2 | Leal/caótico; a imagem basta |
| XP atual/máx. | 2 | Planejamento de evolução |
| Alinhamento e bônus (+25%) | 2 | Já implícito na hora do dia |
| Habilidades (cura, liderança...) | 2 | Importa para a formação |
| Status (envenenado, lento) | 1 | Ícone sobre o retrato |
| **Nome próprio da unidade** | 3 | Não muda nenhuma jogada |
| Raça | 3 | Só curiosidade/afinidades raras |
| Traços (forte, rápido...) | 2–3 | Já refletidos nos números |
| Lado/bandeira | 3 | O anel colorido no mapa já mostra |
| Coordenadas do hex | 3 | Só para depuração/editor |
| Visão/interferência | 3 | Raro |
| Contador "1/6" do ciclo do dia | 3 | A imagem já mostra |
| Unidades e manutenção na barra | 2 | A renda já desconta a manutenção |
| Botões de modo do minimapa | 3 | Alvos de 25 px; função rara |
| Relógio/bateria | 3 | O sistema já mostra |

## 4. Fluxo no celular (paisagem, dois polegares)

- Polegar direito: Terminar Turno, Desfazer, Detalhes, Próxima (canto inferior direito).
- Polegar esquerdo/área central: mapa (tocar, tocar de novo, arrastar).
- Topo: só leitura (ouro, turno) e os menus, que são usados raramente.
- Nada importante a menos de 8 px da borda (gestos do sistema).
- Diálogos: ação principal à direita, cancelar afastado (≥ 32 px), ação secundária à
  esquerda.

## Fontes

- Google, *Touch target size* (48×48 dp, 8 dp de espaço, ≈ 9 mm):
  https://support.google.com/accessibility/android/answer/7101858
- Android Developers, *Make apps more accessible*:
  https://developer.android.com/guide/topics/ui/accessibility/apps
- Material 3, escala tipográfica (valores conferidos em implementações e tabelas que
  repetem a especificação): https://m3.material.io/styles/typography/type-scale-tokens ,
  https://astordev.github.io/articles/material-typography ,
  https://docs.rs/crate/bevy_material_ui/latest/source/src/typography.rs
- Xbox Accessibility Guideline 101 (tamanho de texto; 26 px a 1080p; escalar por DPI no
  celular; ajuste até 200%):
  https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101
- Game Accessibility Guidelines, tamanho de fonte padrão legível e ajustável:
  https://gameaccessibilityguidelines.com/?p=3285
- Unity, *Accessibility basics* (contraste 4,5:1 / 3:1):
  https://unity.com/blog/video-game-accessibility-basics
- Hierarquia e revelação progressiva em HUD: https://uxdesign.cc/how-to-not-overwhelm-players-c0e1d14c6b4c ,
  https://www.gamedeveloper.com/design/ui-strategy-game-design-dos-and-don-ts ,
  https://medium.com/hypemasters/mobile-rts-interface-the-story-of-how-hypemasters-rediscovered-the-genre-dc7fbaa5b05c
- Galaxy A06, 720x1600, 6,7", ~262 ppi: https://www.gsmarena.com/samsung_galaxy_a06-13265.php

Observação: as páginas da Microsoft não puderam ser abertas deste ambiente (rede); os
números do Xbox vêm dos resumos da busca e devem ser conferidos na página.
