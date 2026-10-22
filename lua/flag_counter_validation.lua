-- Flag Counter Validation v1: standalone passive BizHawk monitor.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/flag_counter_validation.lua") then root=p;break end
end
assert(root,"project root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.flag_counter_validation"]=nil
local M=require("challenge.flag_counter_validation")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.framecount and emu.frameadvance,"BizHawk APIs unavailable")
local events=root.."/flag_counter_events_v1.txt"
local csv=root.."/flag_counter_validation_v1.csv"
local o=io.open(events,"rb");local offset=0;if o then offset=o:seek("end");o:close() end
local m=M.new({u8=memory.read_u8,u16=memory.read_u16_le,s16=memory.read_s16_le,csv=csv,session=os.date("!%Y%m%dT%H%M%SZ")})
local label="UNLABELED"
print("[ISSD.flag_counter] v1 read-only, every-frame csv="..csv.." events="..events)
print("[ISSD.flag_counter] labels START_MENU PLAYING NO_COLLECTION FLAG_COLLECTED SUCCESS FAILURE RETURN_MENU OTHER")
local function sample(kind)
 local v=m:sample(emu.framecount(),kind,label)
 if kind=="operator" or (v.delta_06b4 and v.delta_06b4~=0) then
  print(string.format("[ISSD.flag_counter] frame=%d label=%s count=%s delta=%s gs=%s",v.frame,label,tostring(v.remaining_06b4),tostring(v.delta_06b4),tostring(v.game_state)))
 end
end
sample("initial")
while true do
 local f=io.open(events,"rb")
 if f then
  local size=f:seek("end");if size<offset then offset=0 end;f:seek("set",offset)
  while true do
   local pos=f:seek();local line=f:read("*l");if not line then break end
   local endpos=f:seek()
   if endpos==size and size>0 then
    local tail=io.open(events,"rb")
    if tail then tail:seek("set",size-1);local last=tail:read(1);tail:close();if last~="\n" then f:seek("set",pos);break end end
   end
   offset=endpos
   local event=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if M.labels[event] then label=event;sample("operator")
   elseif event~="" then print("[ISSD.flag_counter] ignored "..event) end
  end
  f:close()
 end
 emu.frameadvance()
 sample("frame")
end
