-- Candidatos provenientes de ISSD.mapping/docs/CHALLENGE_MODE.md
-- Status: HIPOTESE; NAO confirmados experimentalmente.
local M = {
  source = "https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/CHALLENGE_MODE.md",
  status = "hypothesis",
  domain = "WRAM",
  addresses = {
    challenge_a = 0xD708,
    challenge_b = 0xE52C,
    selected_level = 0x1550,
    legacy_level_a = 0xD70A,
    legacy_level_b = 0xE52E,
  },
  names = {"DRIBBLE", "PASS", "SHOOT", "DEFENSE", "CORNER KICK", "FREE KICK"},
}
return M
