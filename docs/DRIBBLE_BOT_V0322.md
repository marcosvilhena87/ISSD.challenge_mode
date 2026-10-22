# DRIBBLE v0.3.2.2 — Recovery Diagnostics & Optimization

The five experimentally observed waypoints, original collection logic, and v0.3 goal-shot behavior have **not changed**.

When the unchanged 45-frame movement watchdog reports stuck during the flag phase, the new wrapper performs **up to two 12-frame probes** (rather than two 24-frame probes). Probe direction uses observed ball displacement if the ball is far and possession is not with player; otherwise it favors vertical displacement toward the current waypoint on attempt 1 and horizontal displacement on attempt 2. This policy is still experimental, not a validated obstacle-avoidance strategy.

Each probe frame now records `recovery_diagnostics` in the new `dribble_bot_trace_v0322.csv`: kind, attempt number, player X/Y, ball X/Y, possession, remaining flags, probe direction and strategy, separated by `|`. Events: `stuck_recovery_started`, `stuck_recovery_retry`, `stuck_recovered`, `stuck_recovery_exhausted`.

Run `git pull --ff-only origin main`, stop other input scripts, then load `dribble_bot_v0322.lua` in BizHawk. During DRIBBLE LV.1:

```powershell
Add-Content .\dribble_bot_commands_v0322.txt 'ARM'
Import-Csv .\dribble_bot_trace_v0322.csv | Where-Object { $_.reason -match 'recovery' } | Select-Object frame,event,reason,player_x,player_y,buttons,recovery_diagnostics | Format-Table -AutoSize
```

To finish immediately: `Add-Content .\dribble_bot_commands_v0322.txt 'STOP'`. The summary is `dribble_bot_summary_v0322.csv`, still `unverified` without visual evidence. For confirmed runs, use `python .\confirm_dribble_score_v032.py --summary .\dribble_bot_summary_v0322.csv --session "<exact-session>" --confirm-goal --score <real-score>`. The recovery trace may contain additional rows, but other challenges and older scripts remain unchanged.

Synthetic regression: `lua tests/test_dribble_goal_v0322.lua` if a standalone Lua interpreter is available.
