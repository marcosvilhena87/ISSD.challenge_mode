# ISSD.challenge_mode

Projeto reiniciado do zero em 21/10/2026. **v0.4 experimental**, BizHawk + Lua, International Superstar Soccer Deluxe (SNES).

Fonte canônica dos endereços e da avaliação das evidências: [ISSD.mapping/docs/CHALLENGE_MODE.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/CHALLENGE_MODE.md). Os cinco bytes são **hipóteses**, não mapeamento validado. Ver [docs/MAPPING_INTEGRATION.md](docs/MAPPING_INTEGRATION.md).

Carregue `main.lua` (na raiz do repositório) no console Lua do BizHawk. Os CSVs e eventos são gravados na raiz do projeto. O monitor grava `challenge_transitions_v03.csv`, com frames, alterações brutas e duração dos estados. Registre mudanças de tela pelo PowerShell em `operator_events_v03.txt`, conforme [docs/MONITOR_V03.md](docs/MONITOR_V03.md).

Com Lua instalado, rode `lua tests/test_probe.lua` e `lua tests/test_monitor.lua`. Esses testes são sintéticos, não equivalem a testes na ROM.

**Não existe flag de presença do menu validada**. O monitor nunca envia inputs ao jogo, e `candidate` não significa reconhecimento confirmado.

## Reconhecedor contextual v0.4

A camada observacional v0.3 foi preservada. A v0.4 grava tambem `challenge_context_v04.csv`, requer anotacoes visuais do operador e **nunca** publica `confirmed`. Consulte [docs/CONTEXT_V04.md](docs/CONTEXT_V04.md). Teste sintetico: `lua tests/test_context.lua`.

## WRAM Cursor Discovery v1

Execute `cursor_discovery.lua` **em vez de** `main.lua` para investigar o cursor de Challenge Start Menu. Capture as quatro posicoes A-B-C-A usando `cursor_capture_events_v1.txt`; os candidatos serao registrados em `cursor_candidates_v1.csv`. Leia [docs/CURSOR_DISCOVERY_V1.md](docs/CURSOR_DISCOVERY_V1.md). Os resultados sao apenas hipoteses.

## WRAM Cursor Validation v2

Execute `cursor_validation.lua` sozinho no BizHawk para testar o candidato `0x01542` com sequencia A-C-B-A e controles negativos. Instrucao: [docs/CURSOR_VALIDATION_V2.md](docs/CURSOR_VALIDATION_V2.md). Nao promove evidencias automaticamente.

## Challenge Gameplay Probe v1

Execute `gameplay_probe.lua` sozinho no BizHawk. Capture WRAM gameplay flags and signed world X/Y for ball and 22 players every 30 frames, with operator phase labels from `gameplay_events_v1.txt`. Output: `challenge_gameplay_v1.csv`. Protocol: [docs/GAMEPLAY_PROBE_V1.md](docs/GAMEPLAY_PROBE_V1.md). All readings are exploratory in Challenge Mode; no automatic playing flag is confirmed.

## Challenge Controlled Player Probe v1

Run `controlled_player_probe.lua` alone in BizHawk to investigate `0x1ACC` and the single visible player of DRIBBLE LV.1. Annotate phases in `controlled_player_events_v1.txt`; review `controlled_player_v1.csv`. See [docs/CONTROLLED_PLAYER_PROBE_V1.md](docs/CONTROLLED_PLAYER_PROBE_V1.md). Read-only; no gameplay status confirmed.

## DRIBBLE LV.1 Focused Probe v1

Run `dribble_focused_probe.lua` alone in BizHawk before selecting CHALLENGE START. Reads ball, My Team No.11, gameplay fields, stadium and geometry every 5 emulated frames; no PowerShell interaction needed during the 30-second challenge. Output: `dribble_lv1_focused_v1.csv`. See [docs/DRIBBLE_FOCUSED_PROBE_V1.md](docs/DRIBBLE_FOCUSED_PROBE_V1.md). Observational only.
