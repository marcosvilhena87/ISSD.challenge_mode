# DRIBBLE Timer Decoder v1 — Experimental

The prior per-frame trace provides strong evidence that `0x014F0` and `0x014F4` contain BCD seconds for TIME and BONUS TIME respectively. **This is not yet a canonical mapping**. Register pairs `0x014F2/3` and `0x014F6/7` change rapidly and are exposed as raw little-endian u16 values without guessing their fraction scale.

## Run offline (no BizHawk required)

From the repository root, place the existing `dribble_timer_validation_v1.csv` next to the script and execute:

```powershell
lua .\decode_dribble_timers_v1.lua
```

Or supply input and output names as arguments:

```powershell
lua .\decode_dribble_timers_v1.lua .\dribble_timer_validation_v1.csv .\dribble_timer_decoded_v1.csv .\dribble_timer_decoder_summary_v1.csv
```

Outputs:
- `dribble_timer_decoded_v1.csv`: seconds BCD interpretation, u16 fractional candidates, source frame and phase;
- `dribble_timer_decoder_summary_v1.csv`: counts, validity, first/last seconds and transitions per phase.

Run synthetic tests with `lua .\tests\test_timer_decoder_v1.lua`, if Lua is installed.

**Do not equate these raw u16 fractions with hundredths or frames until independently tested.** Compare a screenshot of the HUD and its frame number to a decoded row. A further controlled capture can establish whether a fixed-rate fractional counter or another encoding is in use. The decoder is read-only, never changes game inputs or WRAM, and does not affect other challenge modes.
