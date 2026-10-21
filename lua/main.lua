-- ISSD.challenge_mode v0.4.3 - BizHawk NLua carrega como [string "main"].
-- A raiz e resolvida por arquivos conhecidos, sem depender de debug.getinfo.
local function exists(path)
  local f=io.open(path,"rb")
  if f then f:close();return true end
  return false
end
local roots={".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}
local root=nil
for _,candidate in ipairs(roots) do
  if exists(candidate.."/lua/challenge/probe.lua") and
     exists(candidate.."/lua/challenge/context.lua") then
    root=candidate
    break
  end
end
assert(root,"Raiz do projeto nao encontrada. Execute com diretorio de trabalho na raiz ou em <repo>/lua.")
local function file(name) return root.."/"..name end
-- Prioriza modulos desta copia do repositorio (BizHawk pode ter outro Lua no path).
package.path=file("lua/?.lua")..";"..file("lua/?/init.lua")..";"..package.path
-- Descarta modulos de execucoes anteriores no mesmo estado Lua.
for _,name in ipairs({"challenge.mapping","challenge.probe","challenge.monitor","challenge.context"}) do
  package.loaded[name]=nil
end
local probe=require("challenge.probe")
local monitor=require("challenge.monitor")
local context=require("challenge.context")
assert(memory and memory.read_u8 and emu and emu.frameadvance and emu.framecount,
  "BizHawk exige memory.read_u8, emu.framecount e emu.frameadvance")
local session=os.date("!%Y%m%dT%H%M%SZ")
local context_csv=file("challenge_context_v04.csv")
local transition_csv=file("challenge_transitions_v03.csv")
local operator_file=file("operator_events_v03.txt")
print("[ISSD.challenge_mode] v0.4.3 project_root="..root)
print("[ISSD.challenge_mode] transition_csv="..transition_csv)
print("[ISSD.challenge_mode] context_csv="..context_csv)
print("[ISSD.challenge_mode] operator_events="..operator_file)
local ctx=context.new(context_csv,session)
assert(type(ctx.step)=="function","Context module lacks step()")
local m=monitor.new({
  read=function() return probe.read(memory.read_u8) end,
  frame=function() return emu.framecount() end,
  csv=transition_csv,
  events=operator_file,
  session=session,
  context=ctx
})
assert(m.context, "Monitor loaded without context support; loaded from "..tostring(package.searchpath and package.searchpath("challenge.monitor",package.path) or "unknown path"))
assert(type(m.context.step)=="function","Context object has no step method")
m:step()
print("[ISSD.challenge_mode] v0.4.3 first contextual step completed (no screen flag validated)")
while true do
  emu.frameadvance()
  m:step()
end
