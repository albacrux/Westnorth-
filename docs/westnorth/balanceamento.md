# Balanceamento (M7) — partidas IA × IA

Ferramenta: `utils/westnorth/balance.py`. Joga partidas headless no mapa
**2p — Encruzilhada**, com as facções alternando as posições e sementes de RNG
diferentes, e conta as vitórias por facção e por lado. Cada partida dura ~1,5 s.
O resultado vem da linha `westnorth-result` que `data/westnorth/lua/report.lua`
imprime no console; o cenário carrega esse relatório com qualquer era.

```sh
utils/westnorth/balance.py -n 50                                   # Coroa x Sombra, 100 partidas
utils/westnorth/balance.py -n 25 --era era_default --factions Loyalists Loyalists   # mede o mapa
```

## Medições (2026-11-27, snapshot 1.21.0-dev)

| Partidas | Confronto | Resultado |
|---|---|---|
| 100 | Ordem da Coroa × Companhia Sombria (Encruzilhada) | Coroa 57%, Sombra 42%, 1 empate; turno médio ~15 |
| 50 | Leais × Leais (Encruzilhada) | lado 1: 26%, lado 2: 68% |
| 50 | Leais × Leais (**Sablestone Delta, mapa oficial**) | lado 1: 28%, lado 2: 68% |

### Leitura

- **Facções:** 57/42 em 100 partidas é aceitável para um protótipo, mas a Coroa
  parece um pouco mais forte. Primeiro candidato a ajuste, se as partidas no A06
  confirmarem: o custo do Cavaleiro (18) ou a cura do Mago Branco.
- **Lado 2 vence ~68%** tanto na Encruzilhada quanto num mapa oficial: é um efeito
  da IA jogando contra si mesma (quem joga depois reage ao avanço do outro), não do
  mapa. A Encruzilhada é tão justa quanto os mapas oficiais. Por isso o script
  alterna as posições das facções.
- Limites: a IA nunca troca de classe e não explora bem Ladino/Arqueiro. Os números
  servem para pegar algo muito desequilibrado, não para o ajuste fino. O ajuste
  fino vem das partidas no A06.
