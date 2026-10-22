-- Run this script ALONE in BizHawk Lua Console. Read-only.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/controlled_player_probe.lua") then root=p;break end
end
assert(root,"Project root not found; run with repository CWD")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.controlled_player_probe"]=nil
local P=require("challenge.controlled_player_probe")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.framecount and emu.frameadvance,"BizHawk API unavailable")
local events=root.."/controlled_player_events_v1.txt"
local csv=root.."/controlled_player_v1.csv"
local mon=P.new({r8=memory.read_u8,ru16=memory.read_u16_le,rs16=memory.read_s16_le,csv=csv,session=os.date("!%Y%m%dT%H%M%SZ")})
local offset=0
local f=io.open(events,"rb");if f then offset=f:seek("end");f:close() end
local phase="UNLABELED"
local last=nil
local interval=15
print("[ISSD.controlled_player] v1 read-only csv="..csv.." events="..events)
print("[ISSD.controlled_player] labels START_MENU PLAYING_IDLE MOVE_LEFT MOVE_RIGHT MOVE_UP MOVE_DOWN DRIBBLING PAUSE RETURN_MENU OTHER")
local function snap(kind)
 local frame=emu.framecount()
 local r=mon:sample(frame,phase,kind)
 last=frame
 if kind=="operator" then print(string.format("[ISSD.controlled_player] frame=%d phase=%s my=%s slot=%s x=%s y=%s dx=%s dy=%s errors=%d",frame,phase,r.my_ptr_hex,tostring(r.my_slot),tostring(r.controlled_x),tostring(r.controlled_y),tostring(r.controlled_dx),tostring(r.controlled_dy),r.error_count)) end
end
snap("initial")
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
   local label=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if P.labels[label] then phase=label;snap("operator")
   elseif label~="" then print("[ISSD.controlled_player] ignored label "..label) end
  end
  f:close()
 end
 if emu.framecount()-(last or 0)>=interval then snap("periodic") end
 emu.frameadvance()
end
