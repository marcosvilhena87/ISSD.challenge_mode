# Challenge Gameplay Probe v1

Standalone, read-only WRAM telemetry for challenge start and playing. Canonical reference: [ISSD.mapping/docs/RAM_MAP.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/RAM_MAP.md). This probe does **not** validate that match-mode addresses retain identical meanings in Challenge Mode, nor identify screens without operator labels.

## Setup

1. Stop `main.lua` and all other BizHawk Lua scripts.
2. Load `gameplay_probe.lua` from repository root in BizHawk Lua Console. Project root must be BizHawk CWD or a known relative candidate.
3. Observe paths printed for `gameplay_events_v1.txt` and `challenge_gameplay_v1.csv`.
4. With the highlighted start menu on screen, in PowerShell in repo root run `Add-Content .\\gameplay_events_v1.txt 'START_MENU'`.
5. Choose CHALLENGE START; while loading run `Add-Content .\\gameplay_events_v1.txt 'LOADING'` (omit if loading screen is too brief).
6. After gameplay visibly begins but before movement run `Add-Content .\\gameplay_events_v1.txt 'PLAYING_IDLE'`.
7. While moving players / ball, run `Add-Content .\\gameplay_events_v1.txt 'PLAYING_MOVING'`.
8. If pause exists run `Add-Content .\\gameplay_events_v1.txt 'PAUSE'`.
9. Once back at a menu, run `Add-Content .\\gameplay_events_v1.txt 'RETURN_MENU'`.
10. `Import-Csv .\\challenge_gameplay_v1.csv | Select-Object -Last 20 | Format-Table frame,phase,gameplay_active,game_state,ball_x,ball_y,ball_moved,my_moved,cpu_moved,total_moved,valid_positions,error_count`.

Samples are captured immediately on operator events and every 30 emulator frames. `kind=initial` starts with `UNLABELED`, `kind=periodic` is periodic, and `kind=operator` is manually labeled. Events existing before starting the script are ignored. Send one event when the corresponding phase is **visually present**, ideally with the frame stable. Screens may go by too quickly for manual labels; the log is not a ground-truth automatic classifier. The CSV is append-only and session-coded; restart the probe for an independent session.

## Addresses & schema

* `0x0006` u8 Gameplay Active; `0x00BA` u16 LE Game State; `0x00A6` u16 LE Player Possession; `0x104C` u8 Team Possession.
* Ball X/Y `0x042A/0x042C`, s16 LE.
* MY 11 X/Y `0x052A/0x052C + n*0x100`, CPU 11 X/Y `0x102A/0x102C + n*0x100`, n=0..10, s16 LE.
* CSV holds all 46 signed X/Y values, counts of changed complete position pairs compared with previous sample (ball separately), valid pairs (up to 23), and read failures.
* Movement count is not a gameplay assertion. Values may remain residual or update in menus, and a stationary player is not evidence of a stopped simulation. The first sample's movement count is zero by design. Pausing resets neither the change baseline nor existing memory.
* No memory writes, input simulation, gameplay-state confirmation, ROM distribution, or automatic edits to `ISSD.mapping`.

## Test
Run `lua tests/test_gameplay_probe.lua` from repo root (synthetic; does not test BizHawk or the ROM).
