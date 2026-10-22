# DRIBBLE Bot v0.3.5 — Route Optimization Benchmark

The v0.3.5 runner inherits gameplay and goal evidence from v0.3.4. **CONTROL is the default and uses exactly the historical waypoints**: (555,261), (772,304), (974,356), (1228,293), (1450,367). No optimization is claimed until runtime evidence reproduces it.

Experimental profiles alter only **one coordinate of one waypoint by four game units**, with full reset of all waypoints when switching. Available profiles: CONTROL, FLAG1_X_MINUS_4, FLAG2_X_PLUS_4, FLAG3_Y_MINUS_4, FLAG4_X_MINUS_4, FLAG5_X_MINUS_4.

The experiment has a single goal: reduce active route frames below **985**, the most recently observed stable run (v034). Historical per-flag comparison baseline is 176/244/204/172/192 = **988** frames. The resulting route delta is calculated against 988, while the verdict compares to 985. Neither benchmark is a proven theoretical optimum.

### Run in BizHawk
```powershell
git pull --ff-only origin main
# Stop v034, load dribble_bot_v035.lua.
# Control run (default):
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
# After finishing, switch profiles while disarmed:
Add-Content .\dribble_bot_commands_v035.txt 'PROFILE:FLAG1_X_MINUS_4'
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
# To return to exact historic waypoints:
Add-Content .\dribble_bot_commands_v035.txt 'PROFILE:CONTROL'
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
Import-Csv .\dribble_route_optimization_v035.csv | Format-Table -AutoSize
Import-Csv .\dribble_route_experiments_v035.csv | Format-Table -AutoSize
```

Commands appended to the file after script initialization are consumed on emulated frames. Do not switch profiles while armed or during the finalization grace period. Use `STOP` to finish and return to disarmed state before switching. Never open multiple controlling runners simultaneously.

### Validation
For each profile, compare at least three trials with comparable complete routes and positive goal evidence. Inspect `dribble_route_experiments_v035.csv` to see whether the changed segment improved **without slowing neighboring segments**. Validate that the fifth flag was collected, the shot happened and the goal counter incremented under expected context. Incomplete routes and increments outside the validated DRIBBLE context are not comparable as successful route experiments. Score remains independently verified, not inferred.

Synthetic Lua test: `lua tests/test_dribble_route_optimization_v035.lua`. Real emulator validation is pending.

## Profile-command reliability fix

The latest v0.3.5 queues `PROFILE:<NAME>` for the **next ARM** even if the runner is finishing an attempt. Previously a profile change could be rejected during finalization, silently leaving CONTROL for the next run. Profile changes never alter an attempt already in progress. `ARM` first finalizes any prior attempt and then applies the queued profile. The new `dribble_profile_audit_v035.csv` records `profile_queued` and `arm_applied` (including waypoint 1 coordinates), and the Lua Console prints the applied profile in the ARMED line.

**Restart the Lua script after git pull**; merely pulling files will not change already loaded Lua code. To test:
```powershell
Add-Content .\dribble_bot_commands_v035.txt 'PROFILE:FLAG1_X_MINUS_4'
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
Import-Csv .\dribble_profile_audit_v035.csv | Select-Object -Last 4 | Format-Table -AutoSize
```

Expect `arm_applied` with `applied_profile=FLAG1_X_MINUS_4` and `wp1_x=551`; use `CONTROL` to restore `wp1_x=555`. The target route optimization report should match the applied profile. If they disagree, **do not compare performance** until the discrepancy is resolved.

## Flag 2 target experiment (760,325)

Profile `FLAG2_760_325` moves only the second waypoint from `(772,304)` to `(760,325)` (delta X -12, Y +21); `CONTROL` remains unchanged. Restart the Lua runner after pulling the update so the module loads new profiles. With runner active, send commands in sequence:

```powershell
Add-Content .\dribble_bot_commands_v035.txt 'PROFILE:FLAG2_760_325'
Import-Csv .\dribble_profile_audit_v035.csv | Select-Object -Last 1 | Format-List
# Check profile_queued, then:
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
```

The Lua Console ARMED line now prints `wp2=(760,325)` when the profile is applied. Confirm `arm_applied` reports `FLAG2_760_325`. Then consult `dribble_route_experiments_v035.csv` and `dribble_route_optimization_v035.csv` to compare the second segment with its historical 244-frame reference. Changes are experimental, no efficiency claim yet.

## CSV header repair after BizHawk restart

Some older v035 CSVs were created without their header because the old append-mode `seek("end")` check was not reliable. Symptoms in PowerShell include `Import-Csv: O membro "1" já está presente`. New runner startup now **refuses malformed files**, rather than adding data to ambiguous CSVs. Before loading the updated runner, close/stop the Lua script and run:

```powershell
git pull --ff-only origin main
python .\repair_dribble_csv_v035.py
# Reopen dribble_bot_v035.lua in BizHawk AFTER repairing.
```

The repair script checks all v035 CSVs, preserves originals as `.bak`, and restores missing headers only if the original first row has the expected number of columns. Files with mismatched column counts are left untouched for manual inspection. It also removes a UTF-8 BOM from an otherwise correct header if present. To select the new waypoint (760,325), append `PROFILE:FLAG2_760_325` **after starting** the runner, wait for `profile_queued`, then append `ARM` and confirm `arm_applied`. A `git pull` alone does not reload the script in BizHawk.

## Reversible proximity approach experiment (v0.3.5)

Movement policy is independent of the route profile. Default `APPROACH:CONTROL` retains the existing precision behavior (movement pulses on frames divisible by four near waypoints). Experimental `APPROACH:CONTINUOUS_PRECISION` uses continuous direction input when `reason=precision_approach`, with the same coordinate deadzone. The `local_search` timing/pulses, `recover_ball` steering, stuck handling, flag counter and shot/goal phases are **not modified**. No speedup is assumed until recorded.

Stop Lua, `git pull --ff-only origin main`, restart the Lua runner, and only then append the commands, one at a time:

```powershell
Add-Content .\dribble_bot_commands_v035.txt 'PROFILE:CONTROL'
Add-Content .\dribble_bot_commands_v035.txt 'APPROACH:CONTROL'
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
```

For the experimental arm:

```powershell
Add-Content .\dribble_bot_commands_v035.txt 'APPROACH:CONTINUOUS_PRECISION'
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
```

For the rollback:

```powershell
Add-Content .\dribble_bot_commands_v035.txt 'APPROACH:CONTROL'
Add-Content .\dribble_bot_commands_v035.txt 'ARM'
```

Wait for `approach queued=` before each `ARM`; confirm `approach applied=` in the Lua Console. The second profile stays selected until changed. Keep `PROFILE:CONTROL` fixed while comparing approaches so waypoint geometry is identical.

The new **`dribble_approach_proximity_v035.csv`** records one row per flag and attempt: `observed_frames`, `near24_frames`, `near12_frames`, `precision_frames`, `local_search_frames`, `recover_ball_frames`, `precision_idle_frames`, and `complete`. Proximity is measured against each selected waypoint with both x/y within +/-24 or +/-12; the counters are observation frames, not necessarily contiguous wall time, and some counters overlap. Rows marked `complete=0` must not be treated as successful flag collections. Compare route/goal eligibility against `dribble_route_optimization_v035.csv` by `session`. The existing CSV schemas are unchanged.

Pure Lua regression test: `lua tests/test_dribble_approach_v035.lua` (requires a local Lua interpreter).

## Combined waypoint experiment: Flag 2 and Flag 5

Route profile `FLAG2_760_330_FLAG5_1460_360` changes two waypoints relative to `CONTROL`: Flag 2 from `(772,304)` to `(760,330)`, and Flag 5 from `(1450,367)` to `(1460,360)`. Other waypoints remain unchanged. The route change is reversible and independent of `APPROACH:CONTROL` vs `APPROACH:CONTINUOUS_PRECISION`.

After `git pull --ff-only origin main`, **restart** the Lua runner. Append `PROFILE:FLAG2_760_330_FLAG5_1460_360`, wait for `profile queued`, then append `ARM`. Restore the historical waypoints with `PROFILE:CONTROL` then `ARM`. Compare route timing and per-flag proximity by session; do not attribute changes to route alone if the approach profile also changes.
