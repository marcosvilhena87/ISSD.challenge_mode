# DRIBBLE Bot v0.3.2.6 — Flag Timing & Start-State Validation

Preserves the gameplay policy from v0.3.2.5. In prior versions the `flag_collected` event was deduplicated by an older layer after the first flag. v0.3.2.6 records **each observed 1-step decrement** in the WRAM candidate remaining counter (`0x006B4`) independently of that event stream. It doesn't claim verified flag-object coordinates.

New output:
- `dribble_flag_timing_v0326.csv`: one row per observed single decrement; flag number, frames since ARM/previous decrement, positions, raw TIME/BONUS seconds candidate values.
- `dribble_start_state_v0326.csv`: snapshot at ARM including GS, PTR, possession, position, remaining flags, BCD seconds and raw 16-bit timer fractions.
- All existing v0.3.2.5 output files now have versioned v0326 names, including `dribble_start_sync_v0326.csv`, `dribble_initial_calibration_v0326.csv`, `dribble_bot_trace_v0326.csv` and `dribble_bot_summary_v0326.csv`.

Abnormal counter drops are not split into invented collections. A manual ARM during active gameplay can yield a partial session; only attempts armed with five flags remaining should be compared as full runs. The first seconds BCD transition is observational, not proof of exact clock start. Gameplay exit is not proof of goal.

## Running

```powershell
git pull --ff-only origin main
# Stop all previous input scripts; load dribble_bot_v0326.lua in BizHawk.
# Start DRIBBLE LV.1, then:
Add-Content .\dribble_bot_commands_v0326.txt 'ARM'
Import-Csv .\dribble_flag_timing_v0326.csv | Format-Table -AutoSize
Import-Csv .\dribble_start_state_v0326.csv | Format-List
Import-Csv .\dribble_start_sync_v0326.csv | Format-List
Import-Csv .\dribble_bot_summary_v0326.csv | Format-List
```

If you need to finalize the summary immediately: `Add-Content .\dribble_bot_commands_v0326.txt 'STOP'`. If the game displays a winning record, confirm the exact session with the existing `confirm_dribble_score_v032.py --summary dribble_bot_summary_v0326.csv --session ... --confirm-goal --score ...` tool.

Regression source tests: `python -m unittest discover -s tests -p test_dribble_v0326.py`. Actual emulated gameplay performance requires BizHawk validation.
