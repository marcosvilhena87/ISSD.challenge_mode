# DRIBBLE Bot v0.3.3 — Integrated Goal Evidence

`dribble_bot_v033.lua` integrates the previously isolated contextual goal evidence module `lua/challenge/dribble_goal_evidence_v4.lua` into the existing v0.3.2.8 gameplay runner. **The controller remains `challenge.dribble_goal_v0325`: waypoint directions, stuck recovery and goal shot logic are unchanged.** No parallel validator is necessary for the integrated evidence.

At ARM the runner snapshots `0x0DA2` u16 and its low/high bytes. It observes the fifth flag counter transition, imports the runner's **actual `shot_started` event frame** as shot evidence, then observes a potential `+1` increment at `GS=5` and zero remaining flags. It preserves sessions beginning with nonzero goal counters. Without a valid fifth-flag context or shot, an increment is recorded as outside the validated challenge context.

New files:
- `dribble_goal_events_v033.csv`: timestamped evidence events, including fifth flag, shot, increment, and classifier status.
- `dribble_goal_evidence_v033.csv`: one row per completed attempt with initial count, fifth flag, shot, increment, final count and classification.
- All existing baseline/trace/summary telemetry now uses `v033` suffix.

Classification `contextual_goal_candidate` means **memory evidence, not operator-verified goal**. The existing `dribble_bot_summary_v033.csv` continues using `outcome=unverified` pending the separate `confirm_dribble_score_v032.py` workflow. Do not infer points or a record score from the goal counter.

## Run
```powershell
git pull --ff-only origin main
# Stop the v0328 controller and any other control scripts.
# Load dribble_bot_v033.lua in BizHawk.
Add-Content .\dribble_bot_commands_v033.txt 'ARM'
Import-Csv .\dribble_goal_events_v033.csv | Format-Table -AutoSize
Import-Csv .\dribble_goal_evidence_v033.csv | Format-List
Import-Csv .\dribble_bot_summary_v033.csv | Format-List
```

At the end of a run, allow the 300-frame closing grace to finish, or send `STOP`. To record a visually verified score, use the existing operator confirmation tool with `--summary .\dribble_bot_summary_v033.csv`, the exact session identifier and the score genuinely observed.

Synthetic contract: `lua tests/test_dribble_goal_integration_v033.lua`. BizHawk runtime validation is still required.
