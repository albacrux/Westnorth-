# Brief de UI mobile — Wesnoth no Galaxy A06

> Documento para o agente (Claude Code). Baseado em 14 capturas reais do A06 rodando o Wesnoth 1.19.29 em pt-BR.
> Prioridade do projeto agora: **usabilidade por toque**. Desempenho já foi validado (roda leve, sem travar).

## 1. Contexto técnico

| Item | Valor |
|---|---|
| Tela | 6,7", 720x1600, 262 ppi, usada em **paisagem (1600x720)** |
| Conversão | 1 dp ≈ 1,64 px → **48 dp ≈ 79 px**, **56 dp ≈ 92 px** |
| Alvo mínimo de toque | 48 dp (79 px); recomendado 56 dp (92 px) |
| Espaço entre alvos | ≥ 8 dp (13 px); mais para ações destrutivas ou opostas |
| Texto mínimo | ≥ 14 sp (≈ 23 px) para informação lida; ≥ 16 sp para botões |

Medidas abaixo são **estimativas feitas nas capturas** (1 px da captura = 1 px físico).

## 2. Inventário de problemas por tela

| # | Tela | Observado | Estimativa | Camada |
|---|---|---|---|---|
| 1 | Mapa: botões "Menu" e "Ações" (topo esquerdo) | Faixa fina colada na borda | ~22 px (≈ 13 dp) | Tema do HUD |
| 2 | Mapa: barra de status (turno, ouro, vilas, unidades, upkeep, renda, hora) | Números pequenos, 7 itens em uma linha | fonte ≈ 8 dp | Tema do HUD |
| 3 | Barra lateral direita (minimapa, 6 ícones, terreno, relógio, painel da unidade) | Ocupa ~11% da largura; ícones e textos minúsculos; quadro vazio quando nada está selecionado | ícones ~24 px (≈ 15 dp) | Tema do HUD |
| 4 | "Terminar Turno" (canto inferior direito) | Botão mais importante é um dos menores, colado na borda/gesto de navegação | ~22 px (≈ 13 dp) | Tema do HUD |
| 5 | **Atacar por toque** | Exige segurar a unidade selecionada e arrastar até o inimigo; a seleção se desfaz antes e a unidade anda na direção errada | — | **C++ (entrada)** |
| 6 | Zoom ("Aproximar") | Borra os sprites, só afeta o mapa; aparecem faixas horizontais nas texturas (capturas 3 e 11) | — | C++ (render) / Preferências |
| 7 | Menus "Menu" e "Ações" | Linhas legíveis, mas 15 itens ocupam a tela inteira; coluna de atalhos de teclado (ctrl+r, alt+u…) inútil no celular | linhas ~42 px (≈ 26 dp) | GUI2 / HUD |
| 8 | Menu de contexto (toque no castelo) | Mesmo problema: atalhos de teclado ocupando espaço | ~42 px | GUI2 |
| 9 | Diálogo "Atacar Inimigo" | Layout bom, mas "Atacar" e "Cancelar" lado a lado, pequenos e sem espaço; "Perfil" e "Cálculo de Dano" também pequenos | ~30 px (≈ 18 dp) | GUI2 |
| 10 | Diálogo "Recrutar Unidade" | Lista boa (linhas ~80 px); botões "Recrutar/Cancelar", "?" e busca pequenos | ~30 px | GUI2 |
| 11 | Ajuda (cronograma) | Ocupa a tela toda e fica sobre o HUD; botão "Fechar" pequeno; "Show Topics" sem tradução | ~30 px | GUI2 |
| 12 | Popup de objetivos | Sem botão de fechar visível | — | GUI2 |
| 13 | Menu inicial | Menu principal legível; botões do rodapé ("Anterior", "Próximo", "Tip of the Day", "About") pequenos e parte em inglês | ~30 px | GUI2 |
| 14 | Gerenciador de Add-ons | Filtros truncados ("Nenhum Selecion…"); botões +/− pequenos e colados | ~40 px | GUI2 |

## 3. Problema crítico: atacar por toque (prioridade 1)

**Sintoma:** para atacar é preciso segurar a unidade aliada já selecionada e arrastar até o inimigo. Na prática a seleção se desfaz e a unidade se move imediatamente para o lado errado.

### Comportamento desejado (fluxo por toques, sem arrastar)

1. **Toque numa unidade aliada** → seleciona, destaca o alcance e **marca os inimigos atacáveis**.
2. **Toque num hex vazio** → mostra o caminho e um botão **"Confirmar"**. A unidade só se move depois de confirmar (opção "mover imediatamente" disponível nas preferências).
3. **Toque num inimigo atacável** → abre o diálogo de ataque. Se não estiver adjacente, mostra de qual hex a unidade atacará e pede confirmação.
4. Botão **"Desfazer"** sempre visível após mover.
5. Gesto de segurar-e-arrastar continua opcional, não obrigatório.

### Regras de entrada

- Limiar de arrasto (slop) ≥ 8 dp: abaixo disso é toque, acima é arrasto.
- Um dedo arrastando = rolar o mapa; dois dedos = zoom.
- Toque longo **não** deve cancelar a seleção.
- Toque fora de qualquer unidade só desseleciona se não houver arrasto nem toque longo.

### Tarefa de diagnóstico (antes de mudar código)

- Localizar no código como eventos de toque (`SDL_FINGER*`) são convertidos em cliques, toque longo e arrasto.
- Registrar a sequência de eventos do cenário que falha.
- **Hipótese a verificar, não afirmada:** o fim do toque está sendo interpretado como clique fora da unidade (ou como clique direito) e cancela a seleção antes do arrasto terminar.

## 4. Proposta de layout do HUD (paisagem 1600x720)

| Elemento | Proposta |
|---|---|
| Barra superior | Altura ≥ 56 dp (≈ 92 px)? **Avaliar**: o mapa já é pequeno. Alternativa: ≥ 40 dp com ícones + número, só os 4 indicadores principais (turno, ouro, vilas, renda); o resto em painel expansível |
| "Menu"/"Ações" | Fundir em um botão ☰ de ≥ 48 dp, canto superior esquerdo, fora da área do recorte (notch) |
| Barra lateral | Remover a barra fixa. Minimapa sob demanda (botão). Info da unidade em **cartão inferior** que aparece ao selecionar |
| Ações contextuais | Barra inferior ao selecionar: Atacar, Esperar/Terminar movimento, Info, Desfazer |
| "Terminar Turno" | Botão grande (≥ 56 dp) com proteção: confirmação se houver unidades que ainda podem agir |
| Margens seguras | Respeitar recorte da tela e barra de gestos nas bordas |

## 5. Diálogos e menus

- **Botões:** altura ≥ 56 dp, largura ≥ 96 dp, ação primária à direita, secundária separada (≥ 16 dp) para evitar toque errado em "Cancelar".
- **Menus:** ocultar a coluna de atalhos de teclado em dispositivos de toque; linhas ≥ 48 dp; agrupar itens raros em "Mais…" ou usar duas colunas.
- **Atacar Inimigo:** manter a visão lado a lado; "Atacar" grande, "Cancelar" afastado; "Perfil" e "Cálculo de Dano" como botões secundários de 48 dp.
- **Recrutar:** manter a lista; aumentar botões e a busca; permitir recrutar com um toque duplo na linha.
- **Add-ons:** trocar a linha de 5 filtros por um botão "Filtros"; ações da linha ≥ 48 dp com espaço entre elas.
- **Traduções:** corrigir "Show Topics", "Tip of the Day" e "About" em pt-BR (baixa prioridade).

## 6. Zoom e nitidez

- O botão de zoom borra os sprites e deixa faixas horizontais nas texturas (capturas 3 e 11).
- Investigar: (a) passos de zoom com **escala inteira**; (b) filtro de reamostragem nítido (nearest ou "sharp bilinear") nos passos não inteiros; (c) opções de escala de pixel e de interface nas Preferências.
- Os hexes de 72 px ficam pequenos nesta tela (≈ 7 mm). Escolher um zoom padrão maior **sem** perder a visão do campo: comparar 1x, 1,5x e 2x em um mapa médio.

## 7. Camadas de implementação (do mais barato ao mais caro)

| Camada | O que muda | Observação |
|---|---|---|
| 0. Preferências | Escala da interface, animações, zoom padrão | Sem código. Registrar o que existe no Android |
| 1. Diálogos (GUI2) | Blocos `[resolution]` por tamanho de janela; tema `[gui]` em um **add-on** (suportado desde a 1.19.4) | Layout é relativo, sem coordenadas fixas |
| 2. HUD do mapa | Tema do HUD (barra superior, lateral, botões) | Verificar se o sistema é separado do GUI2 e se um add-on consegue substituí-lo |
| 3. Entrada por toque | C++ em tratamento de eventos | Só onde as camadas 0–2 não resolvem (item 3 deste brief) |

## 8. Ciclos sugeridos (um PR por ciclo)

1. **UI-1:** diagnóstico + novo fluxo de ataque por toques (seção 3).
2. **UI-2:** "Terminar Turno", diálogos Atacar e Recrutar com botões grandes.
3. **UI-3:** barra superior e menus (sem atalhos de teclado).
4. **UI-4:** cartão da unidade e barra de ações inferior (remove a barra lateral).
5. **UI-5:** zoom e nitidez.
6. **UI-6:** menu inicial, ajuda, add-ons e traduções.

## 9. Critérios de aceite

- Todo alvo de toque ≥ 48 dp (79 px); ações principais ≥ 56 dp.
- Atacar a partir da seleção em **no máximo 3 toques**, sem segurar nem arrastar.
- Nenhum movimento acontece sem confirmação (ou com a opção de mover imediato ligada).
- Seleção nunca se desfaz durante um toque longo ou arrasto.
- Zoom padrão sem borrão nem faixas.
- "Terminar Turno" não pode ser tocado por engano junto com a borda do sistema.
- Cada PR traz capturas antes/depois **em 1600x720**.

## 10. Como verificar

- **Na nuvem:** tentar rodar a build desktop com resolução 1600x720 (ex.: virtual display) e capturar telas para comparar layouts.
- **No A06:** o usuário instala o APK do CI, joga 5–10 min e anexa capturas ao PR.
- **Verificar:** se mudanças só em WML dispensam recompilar o APK (dados na pasta `gamedata` do app).

## 11. Perguntas abertas

- Quais opções de escala existem nas Preferências no Android?
- O que acontece hoje ao tocar **direto num inimigo** com um aliado selecionado?
- O recorte (notch) do A06 invade a área do HUD em paisagem?
