# DRIBBLE Flag Discovery v1 — five simultaneous flags

The five flags are visible simultaneously in DRIBBLE LV.1, but their WRAM positions and collection status are unknown. This probe searches for small **step-like** byte changes across the 128 KiB of WRAM. It is exploratory, **not** an automatic detector of collected flags. It never sends input or changes memory.

## Protocol

1. Close other Lua scripts, update repo, load `flag_discovery.lua` in BizHawk Lua Console.
2. Go to DRIBBLE LV.1; the script starts **DISARMED**. When the actual challenge begins, issue:
   `Add-Content .\flag_discovery_events_v1.txt 'ARM'`
3. Attempt to collect several flags. No further PowerShell commands required during 30-second challenge. The program captures 128 KiB at ARM, then every 180 emulated frames (~3 seconds at 60 FPS). Each scan can cause noticeable emulator lag.
4. Probe stops automatically after 2100 frames (~35 seconds emulated) or 16 snapshots. To finish early, send `Add-Content .\flag_discovery_events_v1.txt 'STOP'`. `MARK` takes an extra snapshot if helpful, but is not required.
5. Inspect `flag_timeline_v1.csv` (frame, GS, controlled pointer, ball/player positions) and `flag_candidates_v1.csv` (top 300 candidate bytes, ranked by rare discrete changes). Upload both files and state how many flags were visibly collected, whether the outcome was SUCCESS or FAILURE, and approximate collection times/frames if available.

**Interpretation:** rank favors small byte ranges (0..16 difference) and few transitions over the sampling window, but many unrelated menu counters or physics flags will also qualify. Sampling every 3 seconds can miss brief transition-only fields. To isolate all five flag coordinates or an exact count, repeat trials that collect different subsets and compare candidate values with visual/video evidence. Avoid interpreting a changing byte as a confirmed flag counter; **no direct 5/5 progress validation exists yet**. Snapshots remain in Lua memory temporarily; raw memory snapshots are not exported. CSVs have session IDs for cross-trial analysis. Frame time is emulated, not wall clock.

Synthetic test: `lua tests/test_flag_discovery.lua`.
