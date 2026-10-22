-- Context-Aware DRIBBLE Goal Evidence v4; passive, no joypad calls.
local root="."
local f=io.open(root.."/lua/challenge/dribble_goal_evidence_v4.lua","rb")
if f then f:close() else root="C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode" end
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
local E=require("challenge.dribble_goal_evidence_v4")
local events=root.."/goal_evidence_events_v4.txt"
local trace=root.."/goal_evidence_trace_v4.csv"
local sessions=root.."/goal_evidence_sessions_v4.csv"
local function setup(p,h)
 local f=io.open(p,"rb")
 if f then local first=f:read("*l");f:close()
  assert(first==h,"CSV header mismatch: "..p.." (back up and repair before running)")
 else local o=assert(io.open(p,"wb"));o:write(h.."\n");o:close() end
end
setup(trace,"session,frame,event,operator_event,goal_u16,delta,gs,ptr,remaining,flags_frame,shot_frame,shot_marker,increment_frame,classification")
setup(sessions,"session,arm_frame,start_goal,valid_start,fifth_flag_frame,shot_frame,shot_marker_frame,increment_frame,increment_delta,increment_gs,increment_remaining,increment_count,reset_count,byte_mismatch,visual,negative,final_frame,final_goal,classification,close_reason")
local function write(p,values,n)
 local a={};for i=1,n do a[i]=values[i]==nil and "" or tostring(values[i]) end
 local o=assert(io.open(p,"ab"));o:write(table.concat(a,",").."\n");o:close()
end
local function rd(fn,a) local ok,v=pcall(fn,a,"WRAM");if ok then return v end end
local function snap()
 return {frame=emu.framecount(),goal=rd(memory.read_u16_le,0x0DA2),
 lo=rd(memory.read_u8,0x0DA2),hi=rd(memory.read_u8,0x0DA3),
 gs=rd(memory.read_u16_le,0x00BA),ptr=rd(memory.read_u16_le,0x1ACC),
 remaining=rd(memory.read_u8,0x06B4)}
end
local q=nil;local serial=0;local stamp=os.date("!%Y%m%dT%H%M%SZ")
local function log(s,ev,operator,delta)
 write(trace,{q and q.id,s.frame,ev,operator,s.goal,delta,s.gs,s.ptr,s.remaining,
 q and q.state.flags_frame,q and q.state.shot_frame,q and q.state.shot_marker,
 q and q.state.increment_frame,q and E.classify(q.state)},14)
end
local function finish(s,why)
 if not q then return end
 local st=q.state
 write(sessions,{q.id,st.arm,st.base,st.valid_start and 1 or 0,st.flags_frame,
 st.shot_frame,st.shot_marker,st.increment_frame,st.delta,st.increment_gs,
 st.increment_remaining,st.increment_count,st.reset_count,st.byte_mismatch,
 st.visual and 1 or 0,st.negative and 1 or 0,s.frame,s.goal,E.classify(st),why},20)
 log(s,"session_closed",why)
 q=nil
end
local pos=0;local ef=io.open(events,"rb");if ef then pos=ef:seek("end");ef:close() end
local function poll(s)
 local f=io.open(events,"rb");if not f then return end
 local size=f:seek("end");if size<pos then pos=0 end;f:seek("set",pos)
 while true do
  local begin=f:seek();local line=f:read("*l");if not line then break end
  local after=f:seek()
  if after==size and size>0 then
   local t=io.open(events,"rb")
   if t then t:seek("set",size-1);local last=t:read(1);t:close()
    if last~="\n" then f:seek("set",begin);break end
   end
  end
  pos=after
  local cmd=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
  if cmd=="START" then
   if q then finish(s,"restarted") end
   serial=serial+1;q={id=stamp.."_"..s.frame.."_"..serial,state=E.new(s)}
   log(s,"session_started",cmd)
  elseif q and cmd=="STOP" then finish(s,"operator_stop")
  elseif q and (cmd=="BEFORE_SHOT" or cmd=="SHOT_STARTED" or
   cmd=="GOAL_VISUAL_CONFIRMED" or cmd=="SHOT_MISSED" or cmd=="NO_GOAL_EXIT") then
   E.marker(q.state,cmd,s.frame);log(s,"operator_marker",cmd)
  elseif q and (cmd=="RESULT_SCREEN" or cmd=="MENU_TRANSITION") then
   log(s,"operator_marker",cmd)
  elseif cmd~="" then print("[GOAL v4] ignored command: "..cmd) end
 end
 f:close()
end
print("[GOAL v4] passive contextual evidence, events="..events)
while true do
 local s=snap()
 if q then
  local before=q.state.last_goal
  local event=E.step(q.state,s)
  if event then log(s,event,"",(type(before)=="number" and type(s.goal)=="number") and s.goal-before or nil) end
 end
 poll(s)
 emu.frameadvance()
end
