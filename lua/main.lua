-- ISSD.challenge_mode v0.2 - somente leitura, sem enviar inputs ao jogo.
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"
local probe = require("challenge.probe")
if not memory or not memory.read_u8 then
  error("Este script requer BizHawk com memory.read_u8 e dominio WRAM")
end
print("[ISSD.challenge_mode] v0.2: sondas exploratorias; sem flag validada do menu")
local previous
while true do
  local r = probe.read(memory.read_u8)
  local raw = r.raw
  local key = table.concat({r.status, tostring(r.challenge_id), tostring(r.level),
    tostring(raw.challenge_a), tostring(raw.challenge_b), tostring(raw.selected_level)}, ":")
  if key ~= previous then
    print(string.format("[ISSD.challenge_mode] %s challenge=%s level=%s reason=%s a=%s b=%s selected_level=%s",
      r.status, tostring(r.challenge), tostring(r.level), r.reason,
      tostring(raw.challenge_a), tostring(raw.challenge_b), tostring(raw.selected_level)))
    previous = key
  end
  emu.frameadvance()
end
