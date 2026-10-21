-- Standalone DRIBBLE LV.1 focused capture. No operator input required during run.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/dribble_focused_probe.lua") then root=p;break end
end
assert(root,"Project root not found: set BizHawk CWD to repository root")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.dribble_focused_probe"]=nil
local P=require("challenge.dribble_focused_probe")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.framecount and emu.frameadvance,"BizHawk API unavailable")
local csv=root.."/dribble_lv1_focused_v1.csv"
local p=P.new({csv=csv,session=os.date("!%Y%m%dT%H%M%SZ"),r8=memory.read_u8,ru16=memory.read_u16_le,rs16=memory.read_s16_le})
local interval=5 -- 12 samples per second at 60 emulated FPS; continuous across transitions
print("[ISSD.dribble_focused] v1 READ ONLY; csv="..csv.." interval_frames="..interval)
print("[ISSD.dribble_focused] Start before CHALLENGE START; capture continues through gameplay and return menu. No operator commands needed.")
local last=nil
while true do
 local frame=emu.framecount()
 if not last or frame-last>=interval then
  local r=p:sample(frame,last and "periodic" or "initial")
  last=frame
  if r.read_errors>0 then print("[ISSD.dribble_focused] read_errors="..r.read_errors.." frame="..frame) end
 end
 emu.frameadvance()
end
