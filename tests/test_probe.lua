package.path = "lua/?.lua;lua/?/init.lua;" .. package.path
local probe = require("challenge.probe")
local a = probe.decode(0, 0, 3)
assert(a.status == "candidate" and a.challenge == "DRIBBLE" and a.level == 4)
assert(probe.decode(0, 1, 0).status == "unknown")
assert(probe.decode(6, 6, 0).status == "unknown")
assert(probe.decode(0, 0, 4).status == "unknown")
assert(probe.decode(nil, 0, 0).status == "unknown")
local r = probe.read(function(address)
  if address == 0xD708 or address == 0xE52C then return 1 end
  if address == 0x1550 then return 2 end
  error("Falha de sonda legada") -- nao deve invalidar sondas principais
end)
assert(r.status == "candidate" and r.challenge == "PASS" and r.level == 3)
print("test_probe.lua: OK (testes sinteticos apenas)")
