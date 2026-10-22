-- DRIBBLE Flag Discovery v1. Standalone, READ ONLY, no buttons.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/flag_discovery.lua") then root=p;break end
end
assert(root,"project root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.flag_discovery"]=nil
local D=require("challenge.flag_discovery")
assert(memory and memory.read_u8 and memory.read_u16_le and emu and emu.framecount and emu.frameadvance,"BizHawk API missing")
local events=root.."/flag_discovery_events_v1.txt"
local csv=root.."/flag_candidates_v1.csv"
local timeline=root.."/flag_timeline_v1.csv"
local session=os.date("!%Y%m%dT%H%M%SZ")
local offset=0
local of=io.open(events,"rb");if of then offset=of:seek("end");of:close() end
local tf=assert(io.open(timeline,"a+"))
if tf:seek("end")==0 then tf:write("session,frame,event,game_state,controlled_pointer,player_x,player_y,ball_x,ball_y,snapshot_index\n") end;tf:close()
local snaps,frames={},{}
local armed=false;local started=nil;local interval=180
local last=nil;local maxsnaps=16
local function u16(a) local ok,v=pcall(memory.read_u16_le,a,"WRAM");if ok then return v end end
local function s16(a) local lo=memory.read_u8(a,"WRAM");local hi=memory.read_u8(a+1,"WRAM");local v=lo+hi*256;return v>=32768 and v-65536 or v end
local function line(event,index)
 local row={session,emu.framecount(),event,u16(0x00BA),u16(0x1ACC),s16(0x0F2A),s16(0x0F2C),s16(0x042A),s16(0x042C),index or ""}
 local out=assert(io.open(timeline,"a"));for i,v in ipairs(row) do row[i]=tostring(v or "") end;out:write(table.concat(row,",").."\n");out:close()
end
local function capture(event)
 if #snaps>=maxsnaps then return end
 print("[ISSD.flag_discovery] scanning WRAM "..(#snaps+1).."/"..maxsnaps)
 snaps[#snaps+1]=D.snapshot(memory.read_u8)
 frames[#frames+1]=emu.framecount()
 line(event,#snaps)
 print("[ISSD.flag_discovery] captured frame="..frames[#frames].." samples="..#snaps)
end
local function finish()
 armed=false
 if #snaps>=2 then
  local hits,n=D.rank(snaps,300)
  D.write(csv,session,frames,hits,n)
  print("[ISSD.flag_discovery] ranked="..n.." exported="..#hits.." path="..csv)
 else print("[ISSD.flag_discovery] need at least 2 captures") end
 print("[ISSD.flag_discovery] stop this Lua script before another session")
end
print("[ISSD.flag_discovery] v1 DISARMED. events="..events.." csv="..csv)
print("[ISSD.flag_discovery] ARM starts capture; automatic 180-frame snapshots; STOP ranks. Heavy WRAM scans may slow BizHawk.")
while true do
 local f=io.open(events,"rb")
 if f then
  local size=f:seek("end");if size<offset then offset=0 end;f:seek("set",offset)
  while true do
   local pos=f:seek();local input=f:read("*l");if not input then break end
   local nextpos=f:seek()
   if nextpos==size and size>0 then
    local endfile=io.open(events,"rb")
    if endfile then endfile:seek("set",size-1);local ch=endfile:read(1);endfile:close();if ch~="\n" then f:seek("set",pos);break end end
   end
   offset=nextpos
   local event=input:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if event=="ARM" and not armed and #snaps==0 then
    armed=true;started=emu.framecount();capture("ARM");last=emu.framecount()
   elseif event=="STOP" then line("STOP");finish();return
   elseif event=="MARK" then line("MARK");if armed then capture("MARK");last=emu.framecount() end
   elseif event~="" then print("[ISSD.flag_discovery] ignored event="..event) end
  end
  f:close()
 end
 if armed and emu.framecount()-last>=interval then capture("PERIODIC");last=emu.framecount() end
 if armed and (emu.framecount()-started>=2100 or #snaps>=maxsnaps) then line("AUTO_STOP");finish();return end
 emu.frameadvance()
end
