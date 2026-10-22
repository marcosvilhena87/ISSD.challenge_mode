-- WRAM Cursor Validation v2 - independente e somente leitura.
-- Rode sozinho no BizHawk. Rotulos sao informados pelo operador, nao inferidos.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/cursor_validation.lua") then root=p;break end
end
assert(root,"Raiz do projeto nao encontrada")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.cursor_validation"]=nil
local validation=require("challenge.cursor_validation")
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance,"BizHawk API unavailable")
local events=root.."/cursor_validation_events_v2.txt"
local csv=root.."/cursor_validation_v2.csv"
local f=io.open(events,"rb")
local offset=0
if f then offset=f:seek("end");f:close() end
local session=os.date("!%Y%m%dT%H%M%SZ")
local m=validation.new({read=memory.read_u8,csv=csv,session=session})
local label="UNLABELED"
print("[ISSD.cursor_validation] v2 address=0x01542 (hypothesis only) session="..session)
print("[ISSD.cursor_validation] events="..events.." csv="..csv)
m:sample(emu.framecount(),"initial",label)
while true do
 local f=io.open(events,"rb")
 if f then
  local size=f:seek("end")
  if size<offset then offset=0 end
  f:seek("set",offset)
  while true do
   local start=f:seek()
   local line=f:read("*l")
   if not line then break end
   local nextpos=f:seek()
   if nextpos==size and size>0 then
    local tail=io.open(events,"rb")
    if tail then tail:seek("set",size-1);local ch=tail:read(1);tail:close()
      if ch~="\n" then f:seek("set",start);break end
    end
   end
   offset=nextpos
   local event=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if validation.valid_label(event) then
    label=event
    local _,v,match=m:sample(emu.framecount(),"operator",label)
    print("[ISSD.cursor_validation] label="..label.." value="..tostring(v).." match="..tostring(match).." frame="..emu.framecount())
   elseif event~="" then print("[ISSD.cursor_validation] ignored invalid label="..event) end
  end
  f:close()
 end
 local wrote,value=m:sample(emu.framecount(),"transition",label)
 if wrote then print("[ISSD.cursor_validation] change value="..tostring(value).." label="..label.." frame="..emu.framecount()) end
 emu.frameadvance()
end
