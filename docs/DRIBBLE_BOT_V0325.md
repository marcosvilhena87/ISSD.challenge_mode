# DRIBBLE Bot v0.3.2.5 — Start Synchronization

This version **does not change the input policy**, waypoint coordinates, goal shot sequence, or persistent score confirmation. It adds observation at ARM and correlates three distinct timestamps: first >=3-unit ball displacement, first >=3-unit player displacement, and first observed BCD TIME seconds transition at provisional WRAM 0x014F0. Because TIME is sampled in whole seconds, **the first observed seconds transition is NOT proof of the timer's true start frame**. If the timer doesn't change within the 90-frame window, the status is `clock_start_unverified`, not an inferred start.

The new session-scoped `dribble_start_sync_v0325.csv` contains arm frame, first ball/player movement, first timer transition, BCD values and observation status. Existing `dribble_initial_calibration_v0325.csv` and `dribble_bot_trace_v0325.csv` retain initialization telemetry, and `dribble_bot_summary_v0325.csv` retains the per-attempt outcome. The CSV serializer keeps blank optional values and exact column counts.

## BizHawk / PowerShell

```powershell
git pull --ff-only origin main
# Close previous input scripts; load dribble_bot_v0325.lua
# Enter DRIBBLE LV.1, then:
Add-Content .\dribble_bot_commands_v0325.txt 'ARM'
Import-Csv .\dribble_start_sync_v0325.csv | Format-List
Import-Csv .\dribble_initial_calibration_v0325.csv | Format-List
Import-Csv .\dribble_bot_summary_v0325.csv | Format-List
```

If needed: `Add-Content .\dribble_bot_commands_v0325.txt 'STOP'`.
For a visually verified record only, use `python .\confirm_dribble_score_v032.py --summary .\dribble_bot_summary_v0325.csv --session "EXACT_SESSION" --confirm-goal --score SCORE` with the actual score.

Synthetic test: `lua tests/test_dribble_goal_v0325.lua`. Actual BizHawk outcome validation still required.
