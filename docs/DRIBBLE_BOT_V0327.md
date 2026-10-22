# DRIBBLE Bot v0.3.2.7 — Active Start Detection

This release preserves the v0.3.2.5 controller (waypoints, bounded recovery, goal shots) and v0.3.2.6 five-counter-decrement logger. It **adds an independent passive observer**; no direction or button policy is changed.

## Observation logic
- ARM captures snapshot, including seconds and raw u16 TIME fraction.
- Independently detect first TIME fraction change, TIME BCD seconds change, first ball displacement >=3 units, and first player displacement >=3 units relative to ARM.
- Earliest observed signal is stored as an **active candidate**, not validated game start. Raw fraction changes may reflect unrelated or stale states; evidence type is recorded.
- Detection continues **beyond 90 frames** until all three groups are observed (timer, ball, player), the first flag counter decrement, gameplay exit, or operator STOP. Never invent a missing signal.
- Existing v0.3.2.5 90-frame calibration and synchronous logging remain for backward comparison; **only the new Active Start observer** is event-driven. It does not modify the controller watchdog grace.
- Only consider sessions with `valid_start_state=1` (ARM sampled gs=0, ptr=0x0F00, five flags) for cross-session timing comparisons.
- If no credible active candidate exists at completion, `wait_frames` and normalized flag duration remain blank.
- No automatic goal confirmation: the operator still uses `confirm_dribble_score_v032.py`.

New outputs: `dribble_active_start_v0327.csv` has ARM, individual signal frames, evidence, wait duration and completion status; `dribble_active_flag_timing_v0327.csv` shows each collection relative to active-candidate frame plus per-flag intervals. Prior outputs versioned to `v0327`.

## Execute

```powershell
git pull --ff-only origin main
# Stop older controlling Lua scripts and start dribble_bot_v0327.lua
Add-Content .\dribble_bot_commands_v0327.txt 'ARM'
Import-Csv .\dribble_active_start_v0327.csv | Format-List
Import-Csv .\dribble_active_flag_timing_v0327.csv | Format-Table -AutoSize
Import-Csv .\dribble_bot_summary_v0327.csv | Format-List
```

If manually interrupted: `Add-Content .\dribble_bot_commands_v0327.txt 'STOP'`. Synthetic test: `lua tests/test_dribble_start_detection_v0327.lua`. Behavior in BizHawk is not yet experimentally validated.
