# DRIBBLE Goal Evidence v4 — Context-Aware Confirmation

## Status
Experimental passive observer only. No automatic goal verification or score submission. Reuses the two positive visual correlations v1 (0→1, GS=5, remaining 0) and v2 (1→2, GS=5, remaining 0), two negative controls v3 (3→3), and preserves the unexplained +1 with remaining 5 (2→3) as **out of DRIBBLE context**, not proof of a challenge goal.

## Contextual conditions
A contextual candidate requires: START with gs=0, ptr=0x0F00 and five flags; fifth observed counter transition 1→0; operator BEFORE_SHOT or SHOT_STARTED marker before the increment; exactly one +1 at 0x0DA2 with GS=5 and remaining=0, after fifth flag; no counter reset or low/high byte mismatch. Visual confirmation is a separate operator marker and upgrades **correlation** only. Scores remain unconfirmed. Both `SHOT_MISSED` and `NO_GOAL_EXIT` are negative observations, and override positive classifications as conflicts.

The observer does not automatically infer a shot event from controller activity. To avoid claiming a shot was confirmed solely by WRAM, use the manual `BEFORE_SHOT` marker close to the actual shot. Same-frame command markers are observational timestamps; event-file commands entered late cannot be backdated.

## Run
```powershell
git pull --ff-only origin main
# Stop validators v1/v2/v3 and load goal_evidence_v4.lua alongside one dribble bot.
# From the DRIBBLE LV.1 active state, with 5 flags remaining:
Add-Content .\goal_evidence_events_v4.txt 'START'
# When the shot is about to begin:
Add-Content .\goal_evidence_events_v4.txt 'BEFORE_SHOT'
# Only after visually observing a goal:
Add-Content .\goal_evidence_events_v4.txt 'GOAL_VISUAL_CONFIRMED'
Add-Content .\goal_evidence_events_v4.txt 'RESULT_SCREEN'
Add-Content .\goal_evidence_events_v4.txt 'STOP'
Import-Csv .\goal_evidence_sessions_v4.csv | Format-List
Import-Csv .\goal_evidence_trace_v4.csv |
 Select-Object frame,event,goal_u16,delta,gs,remaining,classification |
 Format-Table -AutoSize
```

For a real negative control, mark `SHOT_MISSED` or `NO_GOAL_EXIT` only when truly observed; then STOP. For menu movement, `MENU_TRANSITION` records a marker but does not assert success. No inferred goal from mere gameplay exit.

Test (with Lua CLI): `lua tests/test_dribble_goal_evidence_v4.lua`. Runtime validation with BizHawk remains pending.
