-- ISSD.challenge_mode v0.4.9 - entrypoint na raiz; BizHawk NLua carrega como [string "main"].
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
assert(root,"Raiz do projeto nao encontrada. Configure o diretorio de trabalho na raiz do repositorio.")
local function file(name) return root.."/"..name end
os.execute('mkdir "'..file("csv")..'" >nul 2>&1')
local csv_probe,csv_error=io.open(file("csv/.write_probe"),"wb")
assert(csv_probe,"Nao foi possivel acessar csv/: "..tostring(csv_error))
csv_probe:close()
os.remove(file("csv/.write_probe"))
-- Prioriza modulos desta copia do repositorio (BizHawk pode ter outro Lua no path).
package.path=file("lua/?.lua")..";"..file("lua/?/init.lua")..";"..package.path
-- Modo de execução escolhido antes de iniciar o Lua, sem mudar durante a sessão.
-- Sem arquivo de configuração, preserva o monitor contextual original.
local mode_file=file("challenge_mode.txt")
local function selected_mode()
 local h,open_error=io.open(mode_file,"rb")
 if not h then
  -- Apenas ausencia do arquivo permite o modo padrao; outros erros devem ser visiveis.
  -- io.open nao diferencia falta de arquivo em todos os ambientes: informe a
  -- falha se houver erro de acesso diferente de "not found"/"No such file".
  local message=tostring(open_error or "")
  if message~="" and not message:find("No such file",1,true)
     and not message:find("not found",1,true)
     and not message:find("nao foi possivel encontrar",1,true) then
   error("Nao foi possivel ler "..mode_file..": "..message,0)
  end
  return "MONITOR"
 end
 local raw=h:read("*a")
 h:close()
 if not raw then error("Falha ao ler "..mode_file,0) end
 if raw:sub(1,3)=="\239\187\191" then raw=raw:sub(4) end -- BOM UTF-8
 if raw:sub(1,2)=="\255\254" or raw:sub(1,2)=="\254\255" then
  error("Codificacao UTF-16 nao suportada em "..mode_file..
   ". Salve como UTF-8 ou UTF-8 com BOM (PowerShell: Set-Content -Encoding utf8).",0)
 end
 if raw:find("\0",1,true) then
  error("Arquivo "..mode_file..
   " contem bytes NUL (possivel UTF-16). Use UTF-8 ou ASCII.",0)
 end
 local value=raw:match("^%s*([%a_]+)") or ""
 value=value:upper()
 if value~="MONITOR" and value~="DRIBBLE" and value~="SCORE_PROBE" then
  local shown=raw:gsub("[\r\n\t]"," "):sub(1,70)
  error("Modo invalido em "..mode_file..": '"..shown..
   "'. Valores permitidos: MONITOR, DRIBBLE ou SCORE_PROBE. Verifique a codificacao (UTF-8/ASCII).",0)
 end
 return value
end
local mode=selected_mode()
print("[ISSD.challenge_mode] boot mode="..mode.." root="..root)
if mode=="SCORE_PROBE" then
 _G.ISSD_PROJECT_ROOT=root
 dofile(file("lua/score_probe.lua"))
 return
end
if mode=="DRIBBLE" then
 -- All runners receive the same root and package path from main.
 _G.ISSD_PROJECT_ROOT=root
 dofile(file("lua/dribble_bot.lua"))
 return
end
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
local context_csv=file("csv/challenge_context_v04.csv")
local transition_csv=file("csv/challenge_transitions_v03.csv")
local operator_file=file("operator_events_v03.txt")
print("[ISSD.challenge_mode] v0.4.9 project_root="..root)
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
print("[ISSD.challenge_mode] v0.4.9 first contextual step completed (no screen flag validated)")
while true do
  emu.frameadvance()
  m:step()
end
