# DRIBBLE Bot v0.3.4 — Goal Evidence & Performance Benchmark

The v0.3.4 runner is `dribble_bot_v034.lua`. Control policy is still `challenge.dribble_goal_v0325`, with existing start detection and waypoint route benchmarking; no new gameplay behavior or scoring logic is introduced.

## Output
- `dribble_summary_integrated_v034.csv`: separate goal counter evidence, contextual classification, *unconfirmed visual status*, blank record_score, and phase metrics.
- `dribble_performance_v034.csv`: arm→active, active→fifth, arm→fifth, fifth→shot, shot→counter increment, fifth→increment, arm→increment, and comparable route delta.
- `dribble_goal_events_v034.csv`, `dribble_goal_evidence_v034.csv`: inherited detailed contextual evidence.
- `dribble_bot_summary_v034.csv`: backward-compatible summary format with existing externally-confirmed score workflow.
- Other trace/benchmark CSVs use v034 suffix.

**Important:** `goal_classification=contextual_goal_candidate` is evidence of a memory increment within the DRIBBLE challenge. It does **not** imply visual confirmation or a verified score. `visual_confirmation` remains 0 and `record_score` blank until an external operator confirmation workflow is carried out. This runner does not read external confirmation files, so historical externally-confirmed scores do not retroactively populate these CSVs.

Benchmarks use **emulated frame differences**; blank metrics indicate absent events. A comparable route delta is only shown when the original benchmark reports `comparable=true`. Arm→fifth is not the same as active→fifth.

## Run
```powershell
git pull --ff-only origin main
# Stop v033 runner. Load dribble_bot_v034.lua in BizHawk.
Add-Content .\dribble_bot_commands_v034.txt 'ARM'
# After attempt finished (or send STOP to finalize):
Import-Csv .\dribble_summary_integrated_v034.csv | Format-List
Import-Csv .\dribble_performance_v034.csv | Format-List
Import-Csv .\dribble_goal_events_v034.csv | Select-Object frame,event,goal_u16,remaining,gs,shot_frame,classification | Format-Table -AutoSize
```

Unit test: `lua tests/test_dribble_performance_v034.lua` (external Lua CLI). Runtime validation in BizHawk pending.
