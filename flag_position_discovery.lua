-- Standalone; does not press buttons or modify RAM.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/flag_position_discovery.lua") then root=p;break end end
assert(root,"project root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.flag_position_discovery"]=nil
local P=require("challenge.flag_position_discovery")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.framecount and emu.frameadvance,"BizHawk APIs missing")
local path=root.."/flag_positions_v1.csv"
local p=P.new({path=path,session=os.date("!%Y%m%dT%H%M%SZ"),read8=memory.read_u8,read16=memory.read_u16_le,reads16=memory.read_s16_le})
print("[ISSD.flag_position] v1 READ ONLY; every frame; file="..path)
print("[ISSD.flag_position] Play DRIBBLE LV.1; stop script after result. 0x006B4 candidate validated in trials, but player coordinate is only an approximation of flag position.")
while true do
 emu.frameadvance()
 local row=p:step(emu.framecount())
 if row.event=="collection_candidate" then
  print(string.format("[ISSD.flag_position] FLAG candidate #%d frame=%d player=(%s,%s) ball=(%s,%s) remaining=%d",row.collection_index,row.frame,tostring(row.player_x),tostring(row.player_y),tostring(row.ball_x),tostring(row.ball_y),row.remaining_after))
 end
end
