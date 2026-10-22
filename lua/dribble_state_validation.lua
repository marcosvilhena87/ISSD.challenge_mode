-- Standalone DRIBBLE state validation; do not run other Lua scripts.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/state_validation.lua") then root=p;break end
end
assert(root,"Project root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.state_validation"]=nil
local M=require("challenge.state_validation")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.framecount and emu.frameadvance,"BizHawk read APIs missing")
local csv=root.."/dribble_state_validation_v1.csv"
local events=root.."/dribble_state_events_v1.txt"
local old=io.open(events,"rb");local offset=0
if old then offset=old:seek("end");old:close() end
local m=M.new({r8=memory.read_u8,ru16=memory.read_u16_le,rs16=memory.read_s16_le,csv=csv,session=os.date("!%Y%m%dT%H%M%SZ")})
local label="UNKNOWN"
local last=nil
local interval=5
print("[ISSD.state_validation] v1 read-only csv="..csv.." events="..events)
print("[ISSD.state_validation] Labels: PLAYING SUCCESS FAILURE RETURN_MENU START_MENU TRANSITION UNKNOWN")
local function capture(kind)
 local frame=emu.framecount()
 local v=m:sample(frame,kind,label);last=frame
 if kind=="operator" or v.state_changed==1 or v.pointer_changed==1 or v.field_changed==1 then
  print(string.format("[ISSD.state_validation] frame=%d kind=%s label=%s gs=%s ptr=%s candidate=%s",frame,kind,label,tostring(v.game_state),v.my_pointer_hex,v.candidate_state))
 end
end
capture("initial")
while true do
 local f=io.open(events,"rb")
 if f then
  local size=f:seek("end");if size<offset then offset=0 end;f:seek("set",offset)
  while true do
   local begin=f:seek();local line=f:read("*l");if not line then break end
   local finish=f:seek()
   if finish==size and size>0 then
    local t=io.open(events,"rb")
    if t then t:seek("set",size-1);local ch=t:read(1);t:close();if ch~="\n" then f:seek("set",begin);break end end
   end
   offset=finish
   local event=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if M.labels[event] then label=event;capture("operator")
   elseif event~="" then print("[ISSD.state_validation] ignored event "..event) end
  end
  f:close()
 end
 if not last or emu.framecount()-last>=interval then capture("periodic") end
 emu.frameadvance()
end
