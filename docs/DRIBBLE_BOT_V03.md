# DRIBBLE Bot v0.3 — Goal Completion (experimental)

Goal: minimize emulated frames used for 5 flags + goal. v0.3 preserves the v0.2.2 waypoint policy verbatim and *does not claim confirmed goal scoring*.

- Phase `flags`: experimental count `0x006B4` decreases. Five flags collected -> `goal` phase; no early disarm.
- Phase `goal`: experimental approach toward `(1650,365)` (NOT calibrated goal mouth coordinates), re-approaches loose ball, attempts B charge for 20 frames then releases. Logs `shot_started`, `shot_released` and `await_goal_observation`; there is **no validated goal detector**.
- Gameplay exits are `gameplay_exit_unverified`, NOT a success confirmation. Explicit `STOP` and 900-frame goal timeout are safety exits. Script only controls player 1; never run two input scripts simultaneously.
- Logs frame count, position, ball and possession plus event, phase, goal_elapsed and number of shot attempts to `dribble_bot_trace_v03.csv`. No automatic success claim.
- Target coordinates, B charge duration and shooting direction are hypotheses and require BizHawk testing, especially since shooting control has not been experimentally calibrated in DRIBBLE LV.1.

## PowerShell / BizHawk
1. `git pull --ff-only origin main`
2. Open **`dribble_bot_v03.lua`** in BizHawk Lua Console after stopping all other input scripts.
3. Start DRIBBLE LV.1. Run `Add-Content .\dribble_bot_commands_v03.txt 'ARM'`.
4. Observe five flags and then goal behavior. Use `Add-Content .\dribble_bot_commands_v03.txt 'STOP'` to stop immediately.
5. Send `dribble_bot_trace_v03.csv` and state whether the goal actually scored or missed, with the emulated frame if possible. The runner can auto-disarm on game exit but cannot distinguish SUCCESS/FAILURE yet.

For regression checks, `lua tests/test_dribble_goal_v03.lua` with an installed Lua interpreter.
