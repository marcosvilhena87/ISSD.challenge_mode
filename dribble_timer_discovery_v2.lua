-- Standalone DRIBBLE timer probe. Passive; no joypad or WRAM writes.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/timer_discovery_v2.lua") then root=p;break end end
assert(root,"repository root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.timer_discovery_v2"]=nil
local M=require("challenge.timer_discovery_v2")
assert(memory and memory.read_u8 and memory.read_u16_le and emu and emu.frameadvance and emu.framecount,"BizHawk APIs missing")
local session=os.date("!%Y%m%dT%H%M%SZ")
local csv=root.."/dribble_time_candidates_v2.csv"
local bonuscsv=root.."/dribble_bonus_candidates_v2.csv"
local timeline=root.."/dribble_timer_timeline_v2.csv"
local events=root.."/dribble_timer_events_v2.txt"
local tf=assert(io.open(timeline,"a+"));if tf:seek("end")==0 then tf:write("session,frame,event,gs,ptr,remaining,gameplay,snapshot,visual_note\n") end;tf:close()
local offset=0;local f=io.open(events,"rb");if f then offset=f:seek("end");f:close() end
local armed=false;local snapshots={};local interval=30;local maxshots=75;local last=-10000
local had_gameplay=false;local fifth_seen=false;local note="";local post_count=0
local function readw(a) return memory.read_u16_le(a,"WRAM") end
local function log(event,frame,gs,ptr,remaining,gameplay,idx)
 local v={session,frame,event,gs,ptr,remaining,gameplay and 1 or 0,idx or "",note}
 local f=assert(io.open(timeline,"a"));for i,x in ipairs(v) do v[i]=tostring(x) end;f:write(table.concat(v,",").."\n");f:close()
end
local function capture(reason)
 local frame=emu.framecount();local gs=readw(0x00BA);local ptr=readw(0x1ACC);local rem=memory.read_u8(0x006B4,"WRAM")
 local gameplay=(gs==0 and ptr==0x0F00)
 local buf={}
 for a=0,M.SIZE-1 do buf[a+1]=memory.read_u8(a,"WRAM") end
 snapshots[#snapshots+1]={frame=frame,remaining=rem,gameplay=gameplay,bytes=buf}
 log(reason,frame,gs,ptr,rem,gameplay,#snapshots)
 last=frame
 if gameplay then had_gameplay=true end
 if had_gameplay and rem==0 and gameplay then fifth_seen=true;post_count=post_count+1 end
 print(string.format("[ISSD.timer_discovery] snapshot=%d frame=%d rem=%d gs=%d",#snapshots,frame,rem,gs))
end
local function finish()
 if #snapshots>=3 then
  local a,an,b,bn=M.rank(snapshots,500)
  M.write(csv,session,"time",a,an)
  M.write(bonuscsv,session,"bonus",b,bn)
  print("[ISSD.timer_discovery_v2] TIME candidates="..an.." BONUS candidates="..bn.." exported="..#a.."/"..#b)
 else print("[ISSD.timer_discovery] need at least 3 snapshots") end
 print("[ISSD.timer_discovery] output="..csv.." and "..bonuscsv.." and "..timeline)
end
print("[ISSD.timer_discovery] READ ONLY, DISARMED. ARM at challenge start; snapshots every 30 frames. May slow emulation.")
print("[ISSD.timer_discovery] commands in "..events..": ARM, STOP, NOTE:<visual Time/Bonus Time observation>")
while true do
 local input=io.open(events,"rb")
 if input then
  local sz=input:seek("end");if sz<offset then offset=0 end;input:seek("set",offset)
  while true do
   local pos=input:seek();local line=input:read("*l");if not line then break end
   local nextpos=input:seek()
   if nextpos==sz and sz>0 then local tail=io.open(events,"rb");if tail then tail:seek("set",sz-1);local lastchar=tail:read(1);tail:close();if lastchar~="\n" then input:seek("set",pos);break end end end
   offset=nextpos
   local cmd=line:gsub("\r$",""):match("^%s*(.-)%s*$")
   if cmd:upper()=="ARM" and not armed and #snapshots==0 then armed=true;last=-10000;print("[ISSD.timer_discovery] ARMED")
   elseif cmd:upper()=="STOP" then finish();return
   elseif cmd:sub(1,5):upper()=="NOTE:" then note=cmd:sub(6):gsub(",",";")
   elseif cmd~="" then print("[ISSD.timer_discovery] ignored "..cmd) end
  end;input:close()
 end
 if armed and emu.framecount()-last>=interval then
  local gs=readw(0x00BA);local ptr=readw(0x1ACC)
  if had_gameplay and not (gs==0 and ptr==0x0F00) then
   local rem=memory.read_u8(0x006B4,"WRAM");log("gameplay_exit",emu.framecount(),gs,ptr,rem,false,"");finish();return
  end
  capture("periodic")
 end
 if armed and (#snapshots>=maxshots or (fifth_seen and post_count>=8)) then finish();return end
 emu.frameadvance()
end
