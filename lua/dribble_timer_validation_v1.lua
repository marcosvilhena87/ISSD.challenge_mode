-- DRIBBLE Timer Validation v1: read-only, per-frame candidate trace.
-- Candidate addresses are NOT canonical clock mappings.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/timer_discovery_v2.lua") then root=p;break end end
assert(root,"repository root not found")
assert(memory and memory.read_u8 and memory.read_u16_le and emu and emu.frameadvance and emu.framecount,"BizHawk API missing")
local session=os.date("!%Y%m%dT%H%M%SZ")
local events=root.."/dribble_timer_validation_events_v1.txt"
local output=root.."/dribble_timer_validation_v1.csv"
local columns={"session","frame","phase","event","gs","ptr","remaining","visual_note"}
for i=0,7 do columns[#columns+1]=string.format("b_014F%X",i) end
for _,x in ipairs({"w_014F0","w_014F2","w_014F4","w_014F6","d_014F0","d_014F4"}) do columns[#columns+1]=x end
local out=assert(io.open(output,"a+"));if out:seek("end")==0 then out:write(table.concat(columns,",").."\n") end;out:close()
local offset=0;local e=io.open(events,"rb");if e then offset=e:seek("end");e:close() end
local armed=false;local seen=false;local finished=false;local note="";local previous=nil;local counter=0;local bonus_frames=0
local function state()
 local f=emu.framecount()
 local gs=memory.read_u16_le(0x00BA,"WRAM")
 local ptr=memory.read_u16_le(0x1ACC,"WRAM")
 local rem=memory.read_u8(0x006B4,"WRAM")
 local phase=(gs==0 and ptr==0x0F00) and (rem==0 and "bonus_candidate" or rem>=1 and rem<=5 and "time_candidate" or "invalid_count") or "outside_gameplay"
 local b={};for i=0,7 do b[i+1]=memory.read_u8(0x014F0+i,"WRAM") end
 local function w(i) return b[i+1]+b[i+2]*256 end
 local function d(i) return w(i)+w(i+2)*65536 end
 return {frame=f,gs=gs,ptr=ptr,remaining=rem,phase=phase,bytes=b,values={w(0),w(2),w(4),w(6),d(0),d(4)}}
end
local function emit(s,event)
 local v={session,s.frame,s.phase,event,s.gs,s.ptr,s.remaining,note}
 for i=1,8 do v[#v+1]=s.bytes[i] end
 for i=1,6 do v[#v+1]=s.values[i] end
 for i,x in ipairs(v) do v[i]=tostring(x):gsub(",",";"):gsub("[\r\n]"," ") end
 local f=assert(io.open(output,"a"));f:write(table.concat(v,",").."\n");f:close()
end
local function handle(cmd)
 local upper=cmd:upper()
 if upper=="ARM" and not armed and not finished then armed=true;previous=nil;print("[ISSD.timer_validation] ARMED")
 elseif upper=="STOP" then finished=true;armed=false;print("[ISSD.timer_validation] STOP records="..counter)
 elseif upper:sub(1,5)=="NOTE:" then note=cmd:sub(6);if armed then emit(state(),"visual_note") end
 elseif upper~="" then print("[ISSD.timer_validation] ignored "..cmd) end
end
print("[ISSD.timer_validation] v1 READ-ONLY, DISARMED; commands="..events.." output="..output)
print("[ISSD.timer_validation] ARM during DRIBBLE LV.1; STOP to end; NOTE:TIME=... BONUS=... to annotate")
while not finished do
 local input=io.open(events,"rb")
 if input then
  local size=input:seek("end");if size<offset then offset=0 end;input:seek("set",offset)
  while true do
   local pos=input:seek();local line=input:read("*l");if not line then break end
   local endpoint=input:seek()
   if endpoint==size and size>0 then
    local tail=io.open(events,"rb")
    if tail then tail:seek("set",size-1);local c=tail:read(1);tail:close();if c~="\n" then input:seek("set",pos);break end end
   end
   offset=endpoint;handle(line:gsub("\r$",""):match("^%s*(.-)%s*$"))
  end
  input:close()
 end
 if finished then break end
 if armed then
  local s=state()
  local event="sample"
  if previous then
   if s.phase~=previous.phase then event="phase_changed"
   elseif s.remaining<previous.remaining and s.phase~="outside_gameplay" then event="flag_collected"
   elseif s.remaining>previous.remaining then event="counter_increased" end
  else event="first_sample" end
  if s.phase~="outside_gameplay" then seen=true end
  emit(s,event);counter=counter+1
  if s.phase=="bonus_candidate" then bonus_frames=bonus_frames+1 end
  if seen and s.phase=="outside_gameplay" then
   print("[ISSD.timer_validation] gameplay_exit frame="..s.frame.." records="..counter)
   finished=true
  elseif counter>=2400 then
   print("[ISSD.timer_validation] max_frames reached: "..counter);finished=true
  end
  previous=s
 end
 if not finished then emu.frameadvance() end
end
print("[ISSD.timer_validation] saved="..output)
