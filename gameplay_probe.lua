-- Standalone BizHawk Challenge Gameplay Probe v1. No game inputs.
local function exists(path) local f=io.open(path,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/gameplay_probe.lua") then root=p;break end
end
assert(root,"Project root not found; set BizHawk CWD to repository root.")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.gameplay_probe"]=nil
local probe=require("challenge.gameplay_probe")
assert(memory and memory.read_u8 and memory.read_s16_le and memory.read_u16_le,"BizHawk WRAM read API unavailable")
assert(emu and emu.framecount and emu.frameadvance,"BizHawk emulator API unavailable")
local path=root.."/challenge_gameplay_v1.csv"
local eventpath=root.."/gameplay_events_v1.txt"
local interval=30 -- bounded sampling; operator event snapshots taken immediately
local session=os.date("!%Y%m%dT%H%M%SZ")
local monitor=probe.new({csv=path,session=session,read8=memory.read_u8,read16s=memory.read_s16_le,read16u=memory.read_u16_le})
local offset=0
local old=io.open(eventpath,"rb");if old then offset=old:seek("end");old:close() end
local phase="UNLABELED"
local last_sample=nil
print("[ISSD.gameplay_probe] v1 session="..session.." WRAM read-only interval="..interval)
print("[ISSD.gameplay_probe] events="..eventpath.." csv="..path)
print("[ISSD.gameplay_probe] labels START_MENU LOADING PLAYING_IDLE PLAYING_MOVING PAUSE RETURN_MENU OTHER; no automatic gameplay confirmation")
local function capture(kind)
 local frame=emu.framecount()
 local r=monitor:snapshot(frame,phase,kind,interval)
 last_sample=frame
 if kind=="operator" then print(string.format("[ISSD.gameplay_probe] %s frame=%d active=%s ball=(%s,%s) moved=%d errors=%d",phase,frame,tostring(r.gameplay_active),tostring(r.ball_x),tostring(r.ball_y),r.total_moved,r.error_count)) end
end
capture("initial")
while true do
 local f=io.open(eventpath,"rb")
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
    local tail=io.open(eventpath,"rb")
    if tail then tail:seek("set",size-1);local last=tail:read(1);tail:close();if last~="\n" then f:seek("set",start);break end end
   end
   offset=nextpos
   local label=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if probe.labels[label] then phase=label;capture("operator")
   elseif label~="" then print("[ISSD.gameplay_probe] invalid label "..label) end
  end
  f:close()
 end
 if emu.framecount()-(last_sample or 0)>=interval then capture("periodic") end
 emu.frameadvance()
end
