# Diagnóstico: zoom e nitidez (UI-5, em aberto)

## O que o brief relata (A06, 1.19.29)

O zoom ("Aproximar") borra os sprites e deixa faixas horizontais nas texturas
(capturas 3 e 11 do brief).

## O que foi verificado na nuvem (master 1.21.0-dev, 1600x720, Xvfb)

- Níveis de zoom (`data/game_config.cfg`): 16, 24, 36, 52, **72**, 100, 144, 216, 288.
  Ao aproximar a partir de 72 (1x), o próximo nível é 100 (×1,39).
- O mapa usa texturas com amostragem *nearest* (`src/sdl/texture.cpp`). Numa escala
  não-inteira, *nearest* repete uma linha de pixels a cada duas ou três. É a causa
  mais provável das **faixas horizontais**: um padrão irregular de linhas duplicadas.
- O "borrado" pode vir do mesmo efeito (sprites com pixels de tamanhos desiguais) ou
  do escalonamento final da janela no Android. Não dá para separar os dois sem o aparelho.

### Tentativas

| Tentativa | Resultado |
|---|---|
| `SDL_SCALEMODE_PIXELART` (SDL 3.4) nas texturas *nearest* | Inconclusivo: a captura mostrou hexes pretos, mas eles aparecem **também sem** essa mudança (ver abaixo). Não mergeado |
| Níveis só com razões "regulares" (16, 36, 72, 108, 144, 216, 288) | 108 (×1,5) duplica uma linha a cada duas, de forma regular. Não validado no aparelho. Não mergeado |

### Problema encontrado no ambiente de teste

Com qualquer zoom diferente de 72, alguns hexes de transição (bordas de água,
floresta, estrada) ficam **pretos ou com o terreno errado**. Isso continua depois de
rolar o mapa e acontece nos renderers OpenGL (llvmpipe) e software do Mesa. Não há
erro no log e não há issue parecida no upstream. As capturas do A06 em zoom não
mostram isso, então pode ser artefato do Xvfb/Mesa.

## Próximos passos (precisam do aparelho)

1. No A06, com o APK do fork, aproximar uma vez e capturar a tela. Verificar se há
   hexes pretos e se as faixas continuam.
2. Se houver faixas e não hexes pretos: testar um APK com `SDL_SCALEMODE_PIXELART`
   (mudança de 1 linha em `src/sdl/texture.cpp`) e outro com os níveis regulares.
3. Se houver hexes pretos: investigar o cache de terreno do `terrain_builder` ao mudar
   o zoom (`display::set_zoom`).
