# Roadmap — Fork de Wesnoth com classes estilo FF Tactics

> Projeto pessoal, sem fins comerciais. Desenvolvimento 100% agêntico (Claude Code na nuvem), com o celular como terminal principal de comando, revisão e teste.
> Alvo de execução: **Samsung Galaxy A06** (Helio G85, 4 GB RAM, 720x1600, Android 14).
>
> **Revisão 2026-11-27 (agente):** base trocada para `master` 1.21.0-dev; M0 concluído pelo
> dono (desempenho ok, UI ruim); M1 feito na sessão de abertura; **M3 (UI móvel) passa a vir
> antes do M2**, porque é o bloqueio atual de jogabilidade. Detalhes em `decisoes.md` e na
> seção 11.

---

## 1. Visão

Expandir o motor do Battle for Wesnoth (grade hexagonal, sprites leves, conteúdo orientado a dados) com:

1. **Sistema de classes/jobs** inspirado na diversidade de FF Tactics.
2. **Sistema básico de conquistas**.
3. **Interface e desempenho ajustados** para tela de 6,7" e hardware fraco.

**Fora de escopo (decisão deliberada):** alturas/elevação, grade quadrada e tempo de carga (CT) do FFT. Mexem no núcleo em C++ e custam caro. A diversidade do FFT vem das **classes e habilidades**, não da geometria.

## 2. Premissas

- Fork do **`master` upstream (1.21.0-dev, snapshot de 2026-11-26)**, sem histórico. O port Android vive aí (alpha, pensado para tablet). O 1.20 estável existe, mas é mais antigo.
- Licença **GPL v2+**: sem problema para uso não comercial. Se distribuir o APK, publicar o fork.
- **Regra de ouro:** preferir WML/Lua; tocar em C++ só quando for inevitável.
- Estratégia de upstream: **snapshot já congelado** na importação; correções entram só por cherry-pick.
- O dono não revisa PRs: o agente mergeia ao fim de cada ciclo (ver `CLAUDE.md`).

## 3. Papéis e ferramentas

| Quem | Faz | Onde |
|---|---|---|
| **Você** | Escreve a especificação curta, dispara a sessão, revisa o PR, instala o APK e joga 5–10 min | Celular |
| **Agente (Claude Code web)** | Planeja, edita WML/Lua/C++, roda testes e lint, abre PR | Nuvem |
| **CI (GitHub Actions)** | Compila APK arm64 de debug e publica como artefato | Nuvem |
| **Notebook/desktop** (pontual) | Chaves de assinatura, `adb logcat`/profiling, depurar falha de build Android, edição em lote de sprites | Local |

### Loop de cada ciclo

1. Você abre uma issue/spec curta (objetivo, critério de aceite, o que não mexer) — ou o agente segue o próximo ciclo deste roadmap.
2. Sessão do agente: plano → implementação → testes → PR → **merge pelo agente**.
3. CI publica APK + dados no release `nightly`.
4. Você instala no A06, joga e deixa feedback (issue ou comentário).
5. Feedback vira o próximo ciclo.

### Regras fixas para o agente (colocar no `CLAUDE.md`)

- PRs pequenos, um objetivo por PR.
- Conteúdo novo vai em diretório próprio (era/add-on), sem editar `data/core` sem justificativa.
- Todo PR roda: build desktop, testes do repositório e ferramentas de lint de WML (`wmllint`, `wmlscope`).
- Todo sprite passa pelo validador (seção 6) antes de entrar.
- Nunca commitar chaves, tokens ou keystore (exceção aprovada: keystore só de debug, ver `decisoes.md` D4).

## 4. Orçamento de desempenho (A06)

| Item | Meta inicial (ajustar após M0) |
|---|---|
| FPS em mapa médio | estável e jogável; definir número após a medição do M0 |
| Unidades simultâneas | começar com 8 a 12 por lado |
| Sprites | PNG 72x72, poucos frames, reaproveitar animações |
| Modo "low-end" | velocidade de animação reduzida, menos efeitos, rolagem simples |
| APK | somente arm64-v8a |

## 5. Milestones

### M0 — Linha de base (sem código) — **concluído**

- [x] Instalar o APK oficial 1.19.x no A06 e jogar mapas pequeno e médio. (1.19.29: roda leve)
- [x] Anotar: fluidez, tamanho dos botões, legibilidade. → `ui-mobile-brief.md`
- [x] Criar o fork no GitHub e o `CLAUDE.md`.
- [x] Testar o que a sandbox consegue baixar e compilar: GitHub (git), apt, Docker Hub ok; build desktop SDL3 ok. Download de tarballs do GitHub (codeload) bloqueado → usar `git clone`.
- [ ] Salvar o setup de dependências como setup script do ambiente cloud (economiza ~10 min por sessão).
- [ ] Meta numérica de FPS (adiada: desempenho não é problema hoje).

**Gate:** decisão go/no-go e definição das metas numéricas de FPS.

### M1 — Build reprodutível na nuvem — **feito na abertura (aguarda 1º APK no A06)**

- [x] Agente compila a versão desktop e roda os testes do repositório.
- [x] GitHub Actions gera APK arm64 de debug a cada merge na `main` e publica no release `nightly`, junto com os dados do jogo.
- [ ] Você baixa e instala o APK no A06 direto pelo celular. (Depende do repo público: D3)

**Gate:** um PR vira APK instalável sem intervenção do notebook.
**Plano B:** se o build Android falhar na nuvem, depurar uma vez no notebook e codificar a solução no CI.

### M2 — Camada de conteúdo isolada

- [ ] Era/add-on próprio com 1 mapa de teste e 2 facções mínimas.
- [ ] Script de validação de dados (IDs, referências a sprites, balanceamento básico).
- [ ] Snapshot do upstream congelado.

**Gate:** partida completa no A06 com conteúdo próprio.

### M3 — UI móvel e modo low-end

- [ ] Ajustar layouts de interface (definidos em WML): botões maiores, HUD enxuto, painéis menores.
- [ ] Implementar o modo low-end (opções de animação e efeitos).
- [ ] Gestos: toque, arrastar mapa, confirmar movimento com um polegar.

**Gate:** partida inteira jogável só com um polegar, dentro das metas do M0.

### M4 — Sistema de classes (fatia vertical)

- [ ] 6 classes na primeira rodada, cada uma com 2 níveis e habilidades próprias.
- [ ] Troca de classe via evento Lua, preservando XP e traços.
- [ ] Habilidades aprendidas por pontos (reaproveitar XP como "JP", a validar).
- [ ] Testes automatizados por classe: stats, avanço, troca, habilidades.

**Gate:** um mapa jogável em que classes diferentes mudam de fato a tática.

### M5 — Conquistas básicas

- [ ] O Wesnoth já define `[achievement_group]` por campanha em `achievements.cfg`; usar esse mecanismo.
- [ ] 10 a 15 conquistas (ex.: vencer sem perdas, usar N classes, vitória em X turnos).
- [ ] Verificar a tela de conquistas no layout móvel.

**Gate:** conquistas desbloqueiam e persistem entre sessões no A06.

### M6 — Sprites em lote

- [ ] Pipeline da seção 6 funcionando.
- [ ] Classes 7 a 12 com arte completa.
- [ ] Retrabalho de consistência visual (paleta e contorno).

### M7 — Mini-campanha e balanceamento

- [ ] 3 a 5 cenários.
- [ ] Balanceamento por partidas IA vs IA em modo headless (se o build suportar) e playtests no A06.
- [ ] Congelar uma versão 0.1 jogável.

## 6. Pipeline de sprites (assinatura Google)

**Especificação Wesnoth:** PNG, canvas 72x72, contorno em tom escuro (nunca preto puro #000000), frame base + ataque (mínimo 4 frames, ideal cerca de 6) + defesa (cerca de 2 frames).

1. Definir **guia de estilo** (paleta fixa, tipo de contorno, proporção) e reutilizá-lo como referência em todo prompt.
2. Gerar em resolução maior; manter sempre a mesma descrição de estilo.
3. Script (agente escreve): reduzir para 72x72, quantizar paleta, checar transparência e contorno.
4. **Validador** rejeita: tamanho errado, preto puro, fundo opaco, nome fora do padrão.
5. Começar com **frame base + ataque curto (4 frames) + defesa (2 frames)** e reaproveitar o resto.
6. Usar nomes e arte originais (sem personagens ou nomes de marcas do FF), para evitar problemas de direitos.

## 7. Design das classes (proposta a validar)

Rodada 1 (6 classes): Escudeiro, Cavaleiro, Arqueiro, Ladino, Mago Branco, Mago Negro.
Rodada 2 (6 classes): Monge, Lanceiro, Invocador, Geomante, Ninja, Samurai (nomes provisórios).

Princípios: cada classe deve mudar **o que o jogador faz**, não só números. Habilidade que se reduz a "mais dano" ou "mais vida" não entra.

## 8. Riscos

| Risco | Mitigação |
|---|---|
| Port Android em alpha, voltado a tablet | M0 mede cedo; M3 dedicado à UI |
| Desempenho no Helio G85 desconhecido | Medir no M0; modo low-end no M3 |
| Sandbox da nuvem pode não compilar Android | CI no GitHub Actions; notebook como plano B |
| Sprites de IA inconsistentes | Guia de estilo + validador + escopo mínimo de animação |
| Escopo crescendo com ideias do FFT | Seção 1 (fora de escopo) e gates por milestone |
| Código C++ grande e difícil para o agente | Regra de ouro: WML/Lua primeiro |

## 9. Decisões em aberto (ver também `decisoes.md`)

- Limite de FPS aceitável (definir no M0).
- Quantas classes entram na v0.1.
- Como funciona a troca de classe (livre, só em cidade, ou custo).
- ~~Publicar o fork no GitHub como público ou privado.~~ Público (D3).

## 10. Fontes consultadas

- Port Android do Wesnoth: https://wiki.wesnoth.org/Android
- Builds do Android no F-Droid: https://f-droid.org/en/packages/org.wesnoth.Wesnoth/
- Arte de unidades: https://wiki.wesnoth.org/Creating_Unit_Art
- Referência WML: https://wiki.wesnoth.org/Referencewml
- Repositório: https://github.com/wesnoth/wesnoth
- Ambientes cloud do Claude Code: https://code.claude.com/docs/en/cloud-environments.md
- Claude Code na web: https://code.claude.com/docs/en/claude-code-on-the-web.md

## 11. Ordem de execução revisada e status (atualizado 2026-11-27)

| Ordem | Ciclo | Conteúdo | Status |
|---|---|---|---|
| 0 | Fundação | `CLAUDE.md`, CI desktop, APK + dados no `nightly`, keystore debug | **Feito** (#1, #4, #7) |
| 1 | UI-1 | Fluxo de toque: tocar para selecionar, tocar 2x para mover, tocar no inimigo para atacar, arrastar = rolar mapa | **Feito** (#2) — falta validar no A06 |
| 2 | UI-2 | "Terminar Turno" grande e protegido; botões dos diálogos Atacar/Recrutar | **Feito** (#3, corrigido em #6) |
| 3 | UI-3 | Menus sem coluna de atalhos, linhas maiores, submenu "Mais..." | **Feito** (#5) |
| 4 | UI-4 | Botões Desfazer/Próxima no painel | **Parte 1 feita** (#8, #9). Falta: cartão da unidade, botão Confirmar, menu ☰ |
| 5 | UI-5 | Zoom nítido | **Diagnóstico** (`diagnostico-zoom.md`), precisa de capturas do A06 |
| 6 | UI-6 | Traduções pt-BR | **`wesnoth-lib` e `wesnoth` 100%**. Faltam a ajuda (`wesnoth-help`), menu inicial e add-ons |
| 7 | M2 + M4 | Conteúdo próprio: 6 classes × 2 níveis, troca de classe, era com 2 facções, mapa 2p, testes e validador | **Rodada 1 feita** (este PR) — ver `classes.md` |
| 8 | M5 | 10 conquistas do sistema de classes | **Feito** — ver `classes.md` |
| 9 | M7 (parte) | Ferramenta de balanceamento IA × IA e primeira medição | **Feito** — ver `balanceamento.md` |
| 10+ | M6–M7 | Sprites (desktop), mini-campanha, ajuste fino | A fazer |

O modo low-end do M3 foi rebaixado: o A06 já roda bem. Volta se o sistema de classes pesar.
