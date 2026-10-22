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

## DRIBBLE LV.1 State Validation v1

Run `dribble_state_validation.lua` alone in BizHawk. Observe `0x00BA`, `0x1ACC`, geometry and position changes every five frames; manually label SUCCESS, FAILURE and RETURN_MENU in `dribble_state_events_v1.txt`. Data in `dribble_state_validation_v1.csv`; see [docs/DRIBBLE_STATE_VALIDATION_V1.md](docs/DRIBBLE_STATE_VALIDATION_V1.md). No automatic outcome confirmation.

## DRIBBLE LV.1 Bot v0.1 — experimental

Run `dribble_bot.lua` alone in BizHawk. Starts DISARMED; send `ARM` only once the DRIBBLE LV.1 player is visibly on the field using `dribble_bot_commands_v01.txt`. Inspect `dribble_bot_trace_v01.csv`. The initial policy assumes X increasing toward the goal and has **not** been validated as a winning strategy. Details: [docs/DRIBBLE_BOT_V01.md](docs/DRIBBLE_BOT_V01.md).

## DRIBBLE Flag Discovery v1

Run `flag_discovery.lua` alone in BizHawk. Send `ARM` via `flag_discovery_events_v1.txt` once DRIBBLE LV.1 starts; it captures full WRAM periodically and ranks step-like byte candidates, writing `flag_candidates_v1.csv` and `flag_timeline_v1.csv`. This does not yet identify flag coordinates or prove collected count. See [docs/FLAG_DISCOVERY_V1.md](docs/FLAG_DISCOVERY_V1.md).

## DRIBBLE Flag Discovery v2

Run `flag_discovery_v2.lua` alone in BizHawk; ARM using `flag_discovery_events_v2.txt` when gameplay starts. Samples the full WRAM every 60 frames only when GS=0 and PTR=0x0F00; exports candidate counters and bitmasks with transition frames to `flag_candidates_v2.csv` and telemetry to `flag_timeline_v2.csv`. See [docs/FLAG_DISCOVERY_V2.md](docs/FLAG_DISCOVERY_V2.md). Experimental, not a confirmed flag detector.

## DRIBBLE Flag Counter Validation v1

Run `flag_counter_validation.lua` alone in BizHawk to log `0x006B4`, `0x00F2B` and `0x00EE9` **every emulated frame**, including resets in menus. Optional manual labels via `flag_counter_events_v1.txt`; results in `flag_counter_validation_v1.csv`. See [docs/FLAG_COUNTER_VALIDATION_V1.md](docs/FLAG_COUNTER_VALIDATION_V1.md). Candidate addresses, not confirmed mappings.

## DRIBBLE Flag Position Discovery v1

Load `flag_position_discovery.lua` alone in BizHawk. It reads the experimentally supported `0x006B4` remaining-flags counter each frame and records player/ball world coordinates at every decrement in `flag_positions_v1.csv`; no `ARM` or automatic input. These are *collection encounter positions*, not confirmed object coordinates. [Protocol](docs/FLAG_POSITION_DISCOVERY_V1.md).

## DRIBBLE Bot v0.2 — Waypoint Navigation

Run `dribble_bot_v02.lua` alone in BizHawk. Arm only once gameplay is visible by appending `ARM` to `dribble_bot_commands_v02.txt` (stop with `STOP`). Navigates five experimentally observed encounter points and advances only when the `0x006B4` count decreases. Generates `dribble_bot_trace_v02.csv`; automatic safeguards on state transitions, stalls and invalid counters. See [docs/DRIBBLE_BOT_V02.md](docs/DRIBBLE_BOT_V02.md). Experimental: automatic success is not yet validated.

## DRIBBLE Bot v0.2.1 — Precision Approach

Load `dribble_bot_v021.lua` alone in BizHawk. ARM via `dribble_bot_commands_v021.txt` once in DRIBBLE LV.1. Near waypoints it uses short direction pulses and bounded local search; collection progression still requires `0x006B4` decrement. Trace: `dribble_bot_trace_v021.csv`. See [docs/DRIBBLE_BOT_V021.md](docs/DRIBBLE_BOT_V021.md). Experimental; BizHawk test pending.

## DRIBBLE Bot v0.2.2 — Waypoint Transition Fix

Use `dribble_bot_v022.lua` alone in BizHawk, arm with `dribble_bot_commands_v022.txt`, and inspect `dribble_bot_trace_v022.csv`. A detected flag decrement resets the movement watchdog, gives a 60-frame grace period and emits an explicit `flag_collected` event. [Protocol](docs/DRIBBLE_BOT_V022.md). Experimental; playtest pending.

## DRIBBLE Timer Discovery v1

Run `dribble_timer_discovery.lua` alone in BizHawk, append `ARM` to `dribble_timer_events_v1.txt` after challenge start and collect all five flags. It samples WRAM at 30-frame intervals, correlates changes with the fifth collection and exports `dribble_timer_candidates_v1.csv` and `dribble_timer_timeline_v1.csv`. Addresses remain **unvalidated**. [Protocol](docs/DRIBBLE_TIMER_DISCOVERY_V1.md).

## DRIBBLE Timer Discovery v2 — Phase-Aware Ranking

Load `dribble_timer_discovery_v2.lua` alone in BizHawk; append `ARM` to `dribble_timer_events_v2.txt`. This read-only probe ranks TIME and BONUS candidates separately, excluding GS=6/post-game samples, and auto-finalizes after the bonus phase or gameplay exit. Outputs `dribble_time_candidates_v2.csv`, `dribble_bonus_candidates_v2.csv` and `dribble_timer_timeline_v2.csv`. [Protocol](docs/DRIBBLE_TIMER_DISCOVERY_V2.md). No clock addresses validated yet.

## DRIBBLE Timer Validation v1

Run the read-only `dribble_timer_validation_v1.lua` to record per-frame u8/u16/u32 interpretations of WRAM `0x014F0..0x014F7` across TIME, fifth-flag and BONUS phases. Send `ARM`/`STOP` using `dribble_timer_validation_events_v1.txt`; output is `dribble_timer_validation_v1.csv`. [Protocol](docs/DRIBBLE_TIMER_VALIDATION_V1.md). Clock address hypotheses remain unvalidated.

## DRIBBLE Timer Decoder v1

Run `lua decode_dribble_timers_v1.lua` on `dribble_timer_validation_v1.csv` to interpret experimental `0x014F0` (TIME) and `0x014F4` (BONUS TIME) seconds as packed BCD, and export the raw fractional u16 registers without presuming a scale. Produces `dribble_timer_decoded_v1.csv` and `dribble_timer_decoder_summary_v1.csv`. [Protocol](docs/DRIBBLE_TIMER_DECODER_V1.md). These addresses are not canonical until checked against HUD frames.

## DRIBBLE Bot v0.3 — Goal Completion (experimental)

Run `dribble_bot_v03.lua` alone in BizHawk, using `dribble_bot_commands_v03.txt` for ARM/STOP. Preserves v0.2.2 five-flag policy and transitions to an experimental goal approach and B charge/release instead of stopping at five flags. Logs `dribble_bot_trace_v03.csv` with phases and frames. **Goal target / shooting behavior uncalibrated; gameplay exit is NOT verified success.** [Protocol](docs/DRIBBLE_BOT_V03.md).

## DRIBBLE Bot v0.3.1 — Goal & Score Validation

Use `dribble_bot_v031.lua` in BizHawk, `ARM`/`STOP` via `dribble_bot_commands_v031.txt`. The v0.3 control logic is preserved; trace includes timer BCD candidates and deduplicated events. An attempt summary is written once into `dribble_bot_summary_v031.csv`. Use `CONFIRM_GOAL` and optionally `SCORE:<number>` **only after visually verifying that same attempt**. Otherwise the outcome stays `unverified`. See [docs/DRIBBLE_BOT_V031.md](docs/DRIBBLE_BOT_V031.md).

## DRIBBLE Bot v0.3.2 — Persistent Score Validation

Run `dribble_bot_v032.lua` with `ARM`/`STOP` via `dribble_bot_commands_v032.txt`. Unique attempt session IDs are logged in `dribble_bot_summary_v032.csv`. After the summary is written, confirm a visually verified goal/score with `python confirm_dribble_score_v032.py --session <exact_session> --confirm-goal --score <score>` even if BizHawk is closed. Updates are session-targeted, idempotent and audited in `dribble_bot_score_audit_v032.csv`; all unconfirmed game exits remain `unverified`. [Protocol](docs/DRIBBLE_BOT_V032.md).

## DRIBBLE Bot v0.3.2.1 — Stuck Recovery Fix

Run `dribble_bot_v0321.lua` alone in BizHawk; send `ARM`/`STOP` to `dribble_bot_commands_v0321.txt`. This version preserves flag waypoints and goal control, adds at most two 24-frame directional recovery probes for flag-phase stalls, and records recovery events to `dribble_bot_trace_v0321.csv`. See [docs/DRIBBLE_BOT_V0321.md](docs/DRIBBLE_BOT_V0321.md). Goal and score confirmation remains operator-driven via `confirm_dribble_score_v032.py --summary dribble_bot_summary_v0321.csv`.

## DRIBBLE Bot v0.3.2.2 — Recovery Diagnostics & Optimization

Run `dribble_bot_v0322.lua` in BizHawk, arm via `dribble_bot_commands_v0322.txt`. Adaptive bounded recovery uses at most two 12-frame probes with per-frame diagnostics in `dribble_bot_trace_v0322.csv`, preserving the existing five waypoints and goal policy. [Protocol and score confirmation](docs/DRIBBLE_BOT_V0322.md). Experimental until ROM validation.

## DRIBBLE Bot v0.3.2.3 — Delayed Movement Detection

Run `dribble_bot_v0323.lua` in BizHawk. After failed escape probes, the bot observes player and ball movements separately for up to 18 frames before retrying or stopping. Trace has a corrected 20-column header and records delayed-response diagnostics. See [docs/DRIBBLE_BOT_V0323.md](docs/DRIBBLE_BOT_V0323.md). Confirmation remains operator-driven.

## DRIBBLE Bot v0.3.2.4 — Initial Movement Calibration

Use `dribble_bot_v0324.lua` alone in BizHawk with `dribble_bot_commands_v0324.txt` ARM/STOP. A passive 90-frame startup calibration logs first player/ball movement and possession changes in `dribble_initial_calibration_v0324.csv`; this postpones premature initial stuck detection without changing waypoint or goal inputs. [Protocol](docs/DRIBBLE_BOT_V0324.md). Not yet validated in the emulator.

## DRIBBLE Bot v0.3.2.5 — Start Synchronization

Load `dribble_bot_v0325.lua` alone in BizHawk; ARM/STOP through `dribble_bot_commands_v0325.txt`. Logs first player and ball motion versus ARM and first observed BCD TIME transition to `dribble_start_sync_v0325.csv`. This measures start latency without assuming BCD-second transitions are exact clock-start evidence; steering and shooting are unchanged. See [docs/DRIBBLE_BOT_V0325.md](docs/DRIBBLE_BOT_V0325.md).

## DRIBBLE Bot v0.3.2.6 — Flag Timing & Start-State Validation

Run `dribble_bot_v0326.lua` alone in BizHawk and ARM via `dribble_bot_commands_v0326.txt`. Every observed single decrement of the remaining-flags counter is recorded separately in `dribble_flag_timing_v0326.csv`, bypassing deduplication of the old event name. The ARM snapshot is recorded in `dribble_start_state_v0326.csv`. Movement, timer synchronization, and shot policies remain unchanged. [Protocol](docs/DRIBBLE_BOT_V0326.md).

## DRIBBLE Bot v0.3.2.7 — Active Start Detection

Start `dribble_bot_v0327.lua` in BizHawk and ARM via `dribble_bot_commands_v0327.txt`. The independent passive detector records TIME fraction/seconds changes, first ball/player movement, and an active-start **candidate**, continuing beyond 90 frames if needed. See `dribble_active_start_v0327.csv` and `dribble_active_flag_timing_v0327.csv`. The controller is unchanged; this is not a validated game-start flag. [Protocol](docs/DRIBBLE_BOT_V0327.md).

## DRIBBLE Bot v0.3.2.8 — Deterministic Route Benchmark

Run `dribble_bot_v0328.lua` alone in BizHawk. Records five per-flag segment durations and positions in `dribble_route_segments_v0328.csv` and session comparability in `dribble_route_benchmark_v0328.csv`. The reference is the observed v0327 vector 176/244/204/172/192; **no gameplay commands are changed**. See [protocol](docs/DRIBBLE_BOT_V0328.md).

## DRIBBLE Goal Counter Validation v2

Passive BizHawk observer `goal_counter_validation_v2.lua` tests the experimental goal count at `WRAM 0x0DA2` with explicit START/STOP sessions, visual operator markers and negative controls. **Correlation is not yet an automatic goal confirmation**. See [protocol](docs/GOAL_COUNTER_VALIDATION_V2.md).

## DRIBBLE Goal Counter Validation v3 — Negative Controls & Goal Evidence

Passive observer `goal_counter_validation_v3.lua` tracks WRAM `0x0DA2` u16 with per-session START/STOP baselines, explicit negative controls, byte consistency, resets, and correlated positive evidence. This **does not automatically verify goals or scores**. See [validation protocol](docs/GOAL_COUNTER_VALIDATION_V3.md).

## DRIBBLE Goal Evidence v4 — Context-Aware Confirmation

Passive script `goal_evidence_v4.lua` correlates 0x0DA2 increments with a complete five-flag sequence, operator shot marker and GS=5, distinguishing out-of-context increments and negative controls. It does **not** automatically confirm goals or scores. See [protocol](docs/DRIBBLE_GOAL_EVIDENCE_V4.md).

## DRIBBLE Bot v0.3.3 — Integrated Goal Evidence

The single gameplay runner `dribble_bot_v033.lua` samples experimental goal counter `0x0DA2` and combines increment evidence with the fifth flag and its own shot event. Inspect `dribble_goal_evidence_v033.csv` and `dribble_goal_events_v033.csv`. Route and shot commands remain unchanged and point scores are **never automatically confirmed**. [Protocol](docs/DRIBBLE_BOT_V033.md).

## DRIBBLE Bot v0.3.4 — Goal Evidence & Performance Benchmark

Run `dribble_bot_v034.lua` for contextual goal counter evidence, integrated `dribble_summary_integrated_v034.csv` and per-phase timings in `dribble_performance_v034.csv`. Control strategy is unchanged; scores still require independent operator verification. [Usage and metrics](docs/DRIBBLE_BOT_V034.md).

## DRIBBLE Bot v0.3.5 — Route Optimization Benchmark

`dribble_bot_v035.lua` introduces reversible, isolated four-unit waypoint experiments (default `CONTROL`) with `dribble_route_optimization_v035.csv` and `dribble_route_experiments_v035.csv`. The goal and shot logic remain unchanged; no route improvement is asserted without emulator evidence. [Protocol](docs/DRIBBLE_BOT_V035.md).
