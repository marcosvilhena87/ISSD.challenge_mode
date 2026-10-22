# DRIBBLE Bot v0.3.2.1 — Stuck Recovery Fix

**Scope**: adds a bounded recovery wrapper around the *unchanged* v0.3.1 movement policy. The five waypoints, goal target, shot control, score confirmation tool and WRAM addresses remain untouched.

When the 45-frame, under-3-unit displacement watchdog reports `stuck` in the flag phase, v0.3.2.1 starts a maximum 24-frame escape probe: six-frame alternate Down/Right pulses, then Up/Left on a second probe. Once displacement reaches 3 units, it resets the motion watchdog and resumes the original policy. If two probes fail, it auto-disarms as `stuck_recovery_exhausted`. The probe is never used in the goal phase. Stuck recovery events are `stuck_recovery_started`, `stuck_recovered`, `stuck_recovery_retry` and `stuck_recovery_exhausted`. Escape directions are experimental, not experimentally validated. Never run more than one input script at a time.

**Execution**:

1. `git pull --ff-only origin main`.
2. In BizHawk Lua Console, load `dribble_bot_v0321.lua`.
3. With DRIBBLE LV.1 active: `Add-Content .\dribble_bot_commands_v0321.txt 'ARM'`.
4. Inspect `dribble_bot_trace_v0321.csv`, especially `event` and `reason`.
5. If it reaches gameplay exit, the summary is written in `dribble_bot_summary_v0321.csv` after a 300-frame observation window. Alternatively `Add-Content .\dribble_bot_commands_v0321.txt 'STOP'` finalizes immediately.
6. If visually confirmed, use the **same existing** Python confirmation tool pointed to this summary:
   `python .\confirm_dribble_score_v032.py --summary .\dribble_bot_summary_v0321.csv --session "<exact-session>" --confirm-goal --score <real-score>`.
7. Test with `lua tests/test_dribble_goal_v0321.lua` if Lua standalone is available. BizHawk is still required for gameplay validation.

The unchanged score confirmation utility writes its audit file `dribble_bot_score_audit_v032.csv` alongside the specified summary. Event duplicates remain suppressed; gameplay exit alone does not confirm success. Recovery uses a strict cap rather than perpetual input.
