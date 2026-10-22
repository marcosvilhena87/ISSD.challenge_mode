-- Flag Discovery v2: autonomous gameplay-only scanning, READ ONLY.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/flag_discovery_v2.lua") then root=p;break end end
assert(root,"project root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.flag_discovery_v2"]=nil
local D=require("challenge.flag_discovery_v2")
assert(memory and memory.read_u8 and memory.read_u16_le and emu and emu.framecount and emu.frameadvance,"BizHawk API missing")
local session=os.date("!%Y%m%dT%H%M%SZ")
local eventpath=root.."/flag_discovery_events_v2.txt"
local result=root.."/flag_candidates_v2.csv"
local timeline=root.."/flag_timeline_v2.csv"
local f=assert(io.open(timeline,"a+"));if f:seek("end")==0 then f:write("session,frame,stage,gs,ptr,player_x,player_y,ball_x,ball_y,snapshot\n") end;f:close()
local offset=0;local prev=io.open(eventpath,"rb");if prev then offset=prev:seek("end");prev:close() end
local function word(a) return memory.read_u16_le(a,"WRAM") end
local function signed(a) local lo=memory.read_u8(a,"WRAM");local hi=memory.read_u8(a+1,"WRAM");local v=lo+hi*256;return v>=32768 and v-65536 or v end
local function stage() local gs,ptr=word(0x00BA),word(0x1ACC);return (gs==0 and ptr==0x0F00) and "gameplay_candidate" or "excluded" end
local snapshots,frames={},{}
local armed=false;local active=false;local interval=60;local maxshots=32;local last=-100000
local function capture()
 local frame=emu.framecount()
 local st=stage()
 local count=""
 if st=="gameplay_candidate" and armed and #snapshots<maxshots then
  local s={}
  for a=0,D.SIZE-1 do s[a+1]=memory.read_u8(a,"WRAM") end
  snapshots[#snapshots+1]=s;frames[#frames+1]=frame;count=#snapshots
 end
 local fields={session,frame,st,word(0x00BA),word(0x1ACC),signed(0x0F2A),signed(0x0F2C),signed(0x042A),signed(0x042C),count}
 local f=assert(io.open(timeline,"a"));for i,v in ipairs(fields) do fields[i]=tostring(v) end;f:write(table.concat(fields,",").."\n");f:close()
 last=frame
end
local function finish()
 armed=false
 if #snapshots>=3 then
  local hits,total=D.analyze(snapshots,frames,500)
  D.write(result,session,hits,total)
  print("[ISSD.flag_discovery_v2] snapshots="..#snapshots.." candidates="..total.." exported="..#hits.." csv="..result)
 else print("[ISSD.flag_discovery_v2] insufficient gameplay snapshots="..#snapshots) end
end
print("[ISSD.flag_discovery_v2] v2 DISARMED; events="..eventpath.." results="..result)
print("[ISSD.flag_discovery_v2] ARM at challenge start. Auto capture only GS=0 PTR=0x0F00, every 60 frames (possible slowdown); STOP or max 32.")
while true do
 local f=io.open(eventpath,"rb")
 if f then
  local size=f:seek("end");if size<offset then offset=0 end;f:seek("set",offset)
  while true do
   local pos=f:seek();local line=f:read("*l");if not line then break end
   local finishpos=f:seek()
   if finishpos==size and size>0 then
    local tail=io.open(eventpath,"rb")
    if tail then tail:seek("set",size-1);local ch=tail:read(1);tail:close();if ch~="\n" then f:seek("set",pos);break end end
   end
   offset=finishpos
   local cmd=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if cmd=="ARM" and not armed and #snapshots==0 then armed=true;active=false;last=-100000;print("[ISSD.flag_discovery_v2] ARMED")
   elseif cmd=="STOP" then finish();return
   elseif cmd~="" then print("[ISSD.flag_discovery_v2] ignored "..cmd) end
  end
  f:close()
 end
 if armed then
  if stage()=="gameplay_candidate" then active=true;if emu.framecount()-last>=interval then capture() end
  elseif active then capture();finish();return end
  if #snapshots>=maxshots then finish();return end
 end
 emu.frameadvance()
end
