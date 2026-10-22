# DRIBBLE Goal Counter Validation v3 — Negative Controls & Goal Evidence

This is **passive experimental validation**, not automatic goal verification in the DRIBBLE bot.

## Why
In v1, candidate WRAM `0x0DA2` u16 changed 0→1 on frame 1415603 (GS=5; remaining=0), with later visual goal confirmation. In v2 it changed 1→2 at frame 1443947 in the same transition context and with another visual confirmation. A session also showed no increment but was **unverified**, not a legitimate negative control. The address can persist across attempts; do not require a zero baseline.

## v3 behavior
- Captures a **fresh baseline at each operator START**, ensuring changes between sessions cannot be misattributed.
- Reads candidate u16 and low/high bytes; records consistency, increments, decrements/reset, GS transitions and remaining flags.
- Calls an increment **plausible** only when it is exactly +1, u16 agrees with constituent bytes, GS=5, remaining=0. This is a hypothesis grounded in the two positive observations, not a proven rule.
- Uses explicit `GOAL_VISUAL_CONFIRMED` or `SHOT_MISSED` / `NO_GOAL_EXIT` as operator evidence. A negative control without an increment is recorded as such; an increment with a negative marker becomes a **conflict**.
- Preserves positive-but-unverified, visual-goal-without-increment, and menu reset classifications. No automated score mutation or goal confirmation.
- Event file: `goal_counter_events_v3.txt`. Detailed trace: `goal_counter_validation_v3.csv`. Session summary: `goal_counter_sessions_v3.csv`.
- Never controls the joypad.

## Run in BizHawk
```powershell
git pull --ff-only origin main
# Stop v1/v2 validators. Load goal_counter_validation_v3.lua, alongside ONE controlling dribble bot.
Add-Content .\goal_counter_events_v3.txt 'START'
# Send the following only WHEN observed; not as a batch afterwards:
Add-Content .\goal_counter_events_v3.txt 'BEFORE_SHOT'
Add-Content .\goal_counter_events_v3.txt 'GOAL_VISUAL_CONFIRMED'
Add-Content .\goal_counter_events_v3.txt 'RESULT_SCREEN'
Add-Content .\goal_counter_events_v3.txt 'STOP'
Import-Csv .\goal_counter_sessions_v3.csv | Format-List
Import-Csv .\goal_counter_validation_v3.csv |
 Select-Object frame,event,goal_u16,delta_goal,gs_u16,remaining_u8,classification_note |
 Format-Table -AutoSize
```

For a true negative control, only if the shot **visibly misses**:
```powershell
Add-Content .\goal_counter_events_v3.txt 'SHOT_MISSED'
Add-Content .\goal_counter_events_v3.txt 'STOP'
```

For a confirmed exit with no goal, use `NO_GOAL_EXIT`. Use `NEW_ATTEMPT` and `MENU_TRANSITION` markers as appropriate. The session is only summarized at STOP or a new START. If the game is paused, it cannot consume operator file changes until emulated frames resume.

The label `correlated_goal_candidate` is NOT final validation. Demonstrating no false positives requires repeated negative tests, including resets/menus. An externally visually confirmed score remains distinct from evidence derived from this address.
