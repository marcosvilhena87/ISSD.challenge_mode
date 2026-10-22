# DRIBBLE Bot v0.3.2.3 — Delayed Movement Detection

Experimental extension of v0.3.2.2. The original five-waypoint movement policy, goal approach/shooting sequence, timer addresses, and operator score confirmation remain unchanged.

After an unsuccessful 12-frame recovery probe, **observe up to 18 additional frames with no inputs**, independently measuring Manhattan displacement of player and ball. A >=3-unit player displacement produces `delayed_player_movement` and resets recovery budget/watchdog. Ball displacement alone is recorded as `delayed_ball_only` but **not** proof that the player has recovered. A motionless window emits `delayed_no_movement`. Events and diagnostics are recorded in `dribble_bot_trace_v0323.csv`.

The CSV header now matches all 20 written columns, including `recovery_diagnostics`. Raw diagnostics in that field use `|` between values. The `delayed_observation` rows are sampled every frame; routine navigation keeps the five-frame sampling interval.

Safety: observation is limited to 18 frames; gameplay state and flag counter are checked throughout. If movement never resumes, the existing two-probe limit still applies. The approach is hypothesis-driven and has not been validated in BizHawk.

## Run

```powershell
git pull --ff-only origin main
# Load dribble_bot_v0323.lua alone in BizHawk after starting DRIBBLE LV.1
Add-Content .\dribble_bot_commands_v0323.txt 'ARM'
Import-Csv .\dribble_bot_trace_v0323.csv |
  Where-Object { $_.reason -match 'recovery|delayed|movement_' } |
  Select-Object frame,event,reason,player_x,player_y,ball_x,ball_y,recovery_diagnostics |
  Format-Table -AutoSize
```

If needed, stop with `Add-Content .\dribble_bot_commands_v0323.txt 'STOP'`. Summary: `dribble_bot_summary_v0323.csv`. Operator confirmation (only for a visually verified goal) still uses:

```powershell
python .\confirm_dribble_score_v032.py --summary .\dribble_bot_summary_v0323.csv --session "EXACT_SESSION" --confirm-goal --score 403
```

Replace session and score with the current run. Lua synthetic tests: `lua tests/test_dribble_goal_v0323.lua`.
