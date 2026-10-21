-- Candidatos provenientes de ISSD.mapping/docs/CHALLENGE_MODE.md
-- Enderecos antigos: hipoteses; 0x01542: correlacao reproduzida, sem flag validada.
local M = {
  source = "https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/CHALLENGE_MODE.md",
  status = "hypothesis",
  domain = "WRAM",
  addresses = {
    challenge_a = 0xD708,
    challenge_b = 0xE52C,
    selected_level = 0x1550,
    challenge_start_cursor = 0x1542,
    legacy_level_a = 0xD70A,
    legacy_level_b = 0xE52E,
  },
  names = {"DRIBBLE", "PASS", "SHOOT", "DEFENSE", "CORNER KICK", "FREE KICK"},
}
return M
