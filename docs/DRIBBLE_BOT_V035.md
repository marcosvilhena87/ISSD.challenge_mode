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
