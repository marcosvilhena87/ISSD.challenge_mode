# Shared Player Control v1
The player controller is pure Lua: `lua/challenge/player_control.lua`. It does not read or write memory, control BizHawk directly, detect challenge screens, or select a challenge automatically.

- Policies are keyed by explicit challenge name; only one policy runs per decision.
- An unarmed controller returns no buttons.
- Unknown challenges, policy exceptions, and invalid button tables return no buttons and demand disarm.
- The existing DRIBBLE policy remains unchanged, including its experimental game-state assumptions and 1800-frame budget.
- PASS, SHOOT, DEFENSE, CORNER KICK and FREE KICK deliberately have **no enabled policies**. No fallback to DRIBBLE is permitted.
- Scripts must release held buttons on disarm and call `joypad.set({},1)` on STOP.
- Full visual verification in BizHawk is still necessary. Synthetic tests are not evidence of a validated gameplay flag.

Run `lua tests/test_player_control.lua` and `lua tests/test_dribble_bot.lua`. Other tests remain unmodified.
