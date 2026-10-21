-- ISSD.challenge_mode v0.4 - monitor observacional, sem controle do jogo.
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"
local probe=require("challenge.probe")
local monitor=require("challenge.monitor")
local context=require("challenge.context")
assert(memory and memory.read_u8 and emu and emu.frameadvance and emu.framecount,
  "BizHawk exige memory.read_u8, emu.framecount e emu.frameadvance")
local m=monitor.new({
  read=function() return probe.read(memory.read_u8) end,
  frame=function() return emu.framecount() end,
  csv="challenge_transitions_v03.csv",
  events="operator_events_v03.txt",
  context=context.new("challenge_context_v04.csv",os.date("!%Y%m%dT%H%M%SZ"))
})
print("[ISSD.challenge_mode] v0.4 recording challenge_transitions_v03.csv; NO menu flag validated")
print("[ISSD.challenge_mode] contextual CSV: challenge_context_v04.csv (operator labels required)")
print("[ISSD.challenge_mode] operator file: operator_events_v03.txt (one event per line)")
while true do
  m:step()
  emu.frameadvance()
end
