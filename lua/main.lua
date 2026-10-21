-- ISSD.challenge_mode v0.4.1 - observacional, sem inputs.
-- Resolve caminhos pelo arquivo main.lua em vez do CWD do BizHawk.
local info=assert(debug and debug.getinfo and debug.getinfo(1,"S"),"debug.getinfo unavailable")
local source=assert(info.source:match("^@(.+)$"),"main.lua precisa ser carregado de arquivo")
local dir=source:match("^(.*)[/\\]main%.lua$")
local root
if dir then
  root=dir:match("^(.*)[/\\]lua$")
  if not root then
    if dir=="lua" then root="."
    else error("Esperado main.lua dentro de <repo>/lua: "..source) end
  end
elseif source=="main.lua" then
  root=".."
else
  error("Caminho inesperado: "..source)
end
if root=="" then root="." end
local function file(name) return root.."/"..name end
package.path=package.path..";"..file("lua/?.lua")..";"..file("lua/?/init.lua")
local probe=require("challenge.probe")
local monitor=require("challenge.monitor")
local context=require("challenge.context")
assert(memory and memory.read_u8 and emu and emu.frameadvance and emu.framecount,
  "BizHawk exige memory.read_u8, emu.framecount e emu.frameadvance")
local session=os.date("!%Y%m%dT%H%M%SZ")
local context_csv=file("challenge_context_v04.csv")
local transition_csv=file("challenge_transitions_v03.csv")
local operator_file=file("operator_events_v03.txt")
print("[ISSD.challenge_mode] v0.4.1 project_root="..root)
print("[ISSD.challenge_mode] transition_csv="..transition_csv)
print("[ISSD.challenge_mode] context_csv="..context_csv)
print("[ISSD.challenge_mode] operator_events="..operator_file)
local m=monitor.new({
  read=function() return probe.read(memory.read_u8) end,
  frame=function() return emu.framecount() end,
  csv=transition_csv,
  events=operator_file,
  session=session,
  context=context.new(context_csv,session)
})
assert(m.context and type(m.context.step)=="function","Context integration missing")
-- Executa snapshot inicial com falha explicita, antes do loop principal.
m:step()
print("[ISSD.challenge_mode] v0.4.1 first contextual step completed (no screen flag validated)")
while true do
  emu.frameadvance()
  m:step()
end
