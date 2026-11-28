# Plano: unidades maiores e mais legíveis no mapa (M6)

Pedido do dono (2026-11-27): os personagens no campo ficam muito pequenos no celular.

## 1. Diagnóstico (medido)

- O Wesnoth desenha o mapa com hexágonos de **72 px** (zoom 1×, `game_config::tile_size`).
  Cada sprite de unidade é uma imagem 72×72 px **do tamanho do hex**.
- A figura ocupa só parte dessa imagem (caixa delimitadora medida nos arquivos):

  | Unidade | Figura (L×A) | % da altura do hex |
  |---|---|---|
  | Lanceiro | 32×42 | 58% |
  | Arqueiro | 29×41 | 57% |
  | Mago | 34×42 | 58% |
  | Ladrão | 32×42 | 58% |
  | Tenente (líder) | 37×53 | 74% |
  | Cavaleiro (montado) | 45×59 | 82% |

- No A06 (6,7", 262 ppi ≈ **10,3 px/mm**), com zoom 1×, um soldado tem **≈ 4 mm de
  altura** e o hex ≈ 7 mm. No desktop, para o qual a arte foi feita, o mesmo soldado tem
  ≈ 11 mm num monitor de 96 ppi. **No celular a unidade fica ~2,7× menor que o projetado.**
- Meta (manual `manual-ui-android.md`: alvo de toque 48 dp ≈ 9 mm): figura de
  **≥ 7 mm (≈ 72 px de altura)** e hex de ≥ 10 mm (≈ 104 px) no aparelho.

## 2. Alavancas (do mais barato ao mais caro)

| # | Alavanca | Ganho | Custo / risco |
|---|---|---|---|
| A | **Zoom com dois dedos** | O jogador escolhe | Feito (#41) |
| B | **Zoom inicial maior no celular** (ex.: 108 = 1,5×) | Figura 42 → 63 px (6 mm) | Mostra menos mapa na tela de 1600×720 (≈ 20×7 hexes em vez de ≈ 30×10). Escala não inteira pode gerar faixas (`diagnostico-zoom.md`) |
| C | **Indicadores maiores** (esfera, coroa, barras) | Leitura de estado | Feito (#32) |
| D | **Ícone de classe sobre a unidade** (selo pequeno do "job") | Distinguir classes sem ver o sprite | WML/Lua (overlay), barato |
| E | **Sprites em alta resolução (@2x)** — arte 144×144 desenhada para hex de 72 | Nitidez no zoom 1,5×–2× (sem borrar/faixas) | Arte nova + suporte no motor para escolher o @2x |
| F | **Sprites que preenchem mais o hex** (proporção mais "chibi", contorno mais grosso) | Figura 58% → 75–80% da altura do hex: 42 → 56 px a 1× | Arte nova (direção de arte própria do Westnorth) |

A combinação recomendada é **B + E + F** (com D como apoio): no zoom inicial de 1,5×
(hex 108 px ≈ 10,5 mm), uma figura que ocupa 78% do hex tem ≈ 84 px ≈ **8 mm**, o dobro
de hoje, e fica nítida porque vem de arte 2×.

## 3. Etapas

### Etapa 1 — motor e medição (nuvem, sem arte nova)
1. **Zoom inicial por plataforma**: no Android, começar em 108 (novo nível 1,5× na lista
   `zoom_levels`). A pinça continua livre. *Decisão pendente do dono: quanto mapa ele
   aceita perder.*
2. **Qualidade da escala**: testar no A06 o modo `PIXELART` do SDL 3.4 e o nível 108
   (1,5×) contra os 100 atuais (1,39×), que é a causa provável das faixas.
   Precisa de captura do aparelho (pendência de `diagnostico-zoom.md`).
3. **Selo de classe** (alavanca D): ícone de 16–20 px do job no canto do hex das
   unidades de classe (`overlays` via Lua no `classes.lua`), para leitura a distância.

### Etapa 2 — suporte a arte @2x no motor (nuvem)
1. Quando a imagem `xxx@2x.png` existir **e** o zoom for ≥ 100, desenhar a @2x reduzida
   ao hex, em vez de ampliar a 1×. Ponto de entrada: carregamento das imagens de unidade
   (`image::locator` + desenho em `units/drawer.cpp`); o jogo já usa `@2x` em cursores e
   ícones da interface.
2. Prova com **uma** classe (Escudeiro: parado, ataque, defesa) usando um @2x provisório
   (a arte atual ampliada sem filtro) para validar alinhamento, cor de time e animações.
3. Medir no A06: memória e tempo de carregamento (4× mais pixels por imagem).

### Etapa 3 — arte nova (desktop do dono, pipeline validado)
Especificação para o gerador/artista:

| Item | Especificação |
|---|---|
| Tela | **144×144 px** por quadro (2× do hex de 72); exportar também a 1× (72×72) reduzida |
| Ocupação | Figura com **75–80% da altura** do quadro (≈ 110 px a 2×), centralizada na horizontal |
| Pés | Linha dos pés em **y ≈ 118/144** (≈ 59/72), como as unidades do Wesnoth, para assentar na elipse |
| Contorno | 2 px escuros a 2× (1 px a 1×); silhueta legível a 48 px de altura |
| Proporção | Cabeça e arma maiores que o realista (estilo tático, "chibi" leve): a classe se reconhece pela silhueta |
| Cor de time | Faixa **magenta** padrão do Wesnoth (TC) em capa/estandarte/escudo; nada de magenta fora disso |
| Paleta | Até ~24 cores por unidade, luz vinda do alto à esquerda, sem anti-serrilhado no contorno externo |
| Quadros mínimos (por unidade) | parado (1), ataque corpo a corpo (3–4), ataque à distância se tiver (3–4), defesa (2), morte opcional |
| Escopo inicial | 6 classes × 2 níveis = 12 unidades (≈ 120 quadros) |
| Retratos | Opcionais nesta fase (o jogo usa os do upstream) |

Checklist do validador (antes de entrar no repositório):
1. Tamanho exato 144×144 (e 72×72 na versão 1×); fundo transparente.
2. Caixa da figura entre 70% e 82% da altura; pés na faixa y 112–122.
3. Só a faixa magenta de TC muda com o time (testar com 2 cores).
4. Sem pixels semitransparentes no contorno externo.
5. Quadros da mesma animação alinhados (sem "pulo" entre quadros).
6. Captura no jogo nos zooms 72, 108 e 144, lado a lado com a unidade do upstream.

### Situação (2026-11-28)
- **Rodada 1 integrada** (12 classes × 6 quadros): sprites 72×72 e @2x vindos da pasta
  do dono no Drive (blocos 1–4), todos `ok` no validador (`docs/westnorth/sprites/`).
  Ficam em `data/westnorth/images/units/westnorth/`; as animações estão em
  `data/westnorth/macros/class_art.cfg`. O @4x (288 px) fica no Drive até ser usado.
- No Drive também há a rodada 2 (Monge, Lanceiro, Samurai, Ninja, Invocador, Geomante
  e evoluções), selos de classe, retratos 400×400 e terrenos/estruturas HD: ainda não
  integrados (rodada 2 precisa das classes; retratos e selos são o próximo passo).
- Retratos da rodada 1 integrados (D64; nível 2 usa o do nível 1).
- Selos de classe no mapa (D65, etapa 1.3 feita).
- O motor ainda desenha a versão 72×72 (o @2x espera a etapa 2).

### Etapa 4 — integração e teste
Arquivos em `data/westnorth/images/units/` referenciados pelas classes
(`data/westnorth/units/classes.cfg`, hoje com `[base_unit]` do upstream), capturas
antes/depois e teste no A06.

## 4. Decisões pendentes do dono
- [ ] Zoom inicial no celular: 100 (atual), **108 (recomendado)** ou 144.
- [ ] Direção de arte das classes: proporção realista (como o Wesnoth) ou **estilo tático
      com cabeça maior (recomendado para leitura no celular)**.
- [ ] Ferramenta de geração dos sprites no desktop e quem roda o validador.
