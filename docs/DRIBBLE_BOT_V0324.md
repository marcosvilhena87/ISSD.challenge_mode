# DRIBBLE v0.3.2.4 — Initial Movement Calibration

The five waypoints, goal target, shot charge, and persistent operator score confirmation are unchanged. This version adds an **observational** 90-frame startup calibration from ARM while active DRIBBLE LV.1 gameplay indicates 5 flags remaining. It measures first >=3-unit player movement, first >=3-unit ball movement, and first possession change independently, in emulated frames. It ends early on flag counter change or gameplay exit.

During the window, the existing control policy continues to issue the same directional inputs; **only the first watchdog's grace is extended** to avoid premature stuck recovery. After calibration, the original bounded recovery policy remains. The calibration does not assume that the ball moving implies the player has moved.

The 20-column `dribble_bot_trace_v0324.csv` includes `recovery_diagnostics` and samples every startup frame. The additional `dribble_initial_calibration_v0324.csv` summarizes calibration start/end, first movement events, classification and end reason per attempt. `dribble_bot_summary_v0324.csv` remains the unchanged per-attempt outcome schema.

## Run

```powershell
git pull --ff-only origin main
# Stop previous input scripts, load dribble_bot_v0324.lua in BizHawk
Add-Content .\dribble_bot_commands_v0324.txt 'ARM'
Import-Csv .\dribble_initial_calibration_v0324.csv | Format-Table -AutoSize
Import-Csv .\dribble_bot_trace_v0324.csv |
  Where-Object { $_.event -match 'initial_|stuck|delayed' } |
  Select-Object frame,event,reason,player_x,player_y,ball_x,ball_y,recovery_diagnostics |
  Format-Table -AutoSize
```

STOP: `Add-Content .\dribble_bot_commands_v0324.txt 'STOP'`. If a goal and score are visually verified, run the existing `confirm_dribble_score_v032.py` with `--summary .\dribble_bot_summary_v0324.csv` and the exact session. No game-state change alone confirms a goal.

Synthetic test (Lua installed): `lua tests/test_dribble_goal_v0324.lua`. Actual BizHawk calibration and improved speed are still unverified.
