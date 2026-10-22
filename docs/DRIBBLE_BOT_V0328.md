# DRIBBLE v0.3.2.8 — Deterministic Route Benchmark

## What it does
Observes exactly the **same controller** as v0.3.2.7 (the runner explicitly loads `challenge.dribble_goal_v0325`). Does not alter waypoints, recovery, buttons, aiming or goal policy. On each independently observed remaining-flag decrement, records the player and ball coordinates, current possession, segment duration and deviation from the v0.3.2.7 observed segment timings.

Reference session `20261022T015544Z_1350742`: **176, 244, 204, 172, 192 frames**, totaling **988** from the initial activity candidate to fifth flag. These are experimental observed durations, not guaranteed physical optimum or validated object positions.

Each row's `start_basis` is `active_candidate` for the first flag only when the active-start detector observed a candidate; subsequent rows use the previous flag. If candidate is missing, the first segment starts from ARM and the session is **not comparable**. Additional guards require five sequential decrements and a valid initial gameplay state. Even if comparable by those checks, state and position differences must be reviewed before attributing causal performance gains.

## New files
- `dribble_route_segments_v0328.csv`: one row per flag, with duration, v0327 baseline, delta, start basis, player/ball XY, possession, and start validity.
- `dribble_route_benchmark_v0328.csv`: one-row verdict after summary finalization (five flags required). `reference_time_match` means a *timing match*, **not** identical actions or determinism proven.
- All existing telemetry stays available with `v0328` suffix.

## Run

```powershell
git pull --ff-only origin main
# Stop previous Lua controllers, load dribble_bot_v0328.lua in BizHawk
Add-Content .\dribble_bot_commands_v0328.txt 'ARM'
Import-Csv .\dribble_route_segments_v0328.csv |
  Select-Object flag_number,segment_frames,baseline_frames,delta_frames,start_basis,player_x,player_y |
  Format-Table -AutoSize
Import-Csv .\dribble_route_benchmark_v0328.csv | Format-List
Import-Csv .\dribble_bot_summary_v0328.csv | Format-List
```

If needed, `Add-Content .\dribble_bot_commands_v0328.txt 'STOP'` finalizes summary and benchmark. The exit state alone cannot prove a goal; confirm an observed score with `confirm_dribble_score_v032.py`.

Test if Lua is installed: `lua tests/test_dribble_route_benchmark_v0328.lua`. End-to-end emulator validation is pending.
