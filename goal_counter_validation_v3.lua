-- DRIBBLE Goal Counter Validation v3: passive experimental evidence, no inputs.
local root="."
local marker="lua/challenge/dribble_goal_v0325.lua"
local f=io.open(root.."/"..marker,"rb")
if f then f:close() else root="C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode" end
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
local Evidence=require("challenge.goal_counter_evidence_v3")
local events=root.."/goal_counter_events_v3.txt"
local trace=root.."/goal_counter_validation_v3.csv"
local sessions=root.."/goal_counter_sessions_v3.csv"
local function setup(p,h)
 local f=assert(io.open(p,"a+"));if f:seek("end")==0 then f:write(h.."\n") end;f:close()
end
setup(trace,"session,frame,event,operator_event,goal_u16,goal_low_u8,goal_high_u8,gs_u16,remaining_u8,delta_goal,read_consistent,classification_note")
setup(sessions,"session,start_frame,start_goal,final_frame,final_goal,positive_changes,plausible_increments,resets_or_decrements,read_mismatches,invalid_reads,negative_control,visual_goal,exit_observed,first_positive_frame,gs_at_first_positive,remaining_at_first_positive,classification,quality,close_reason")
local function read(fn,a) local ok,v=pcall(fn,a,"WRAM");if ok then return v end end
local function snap()
 return {frame=emu.framecount(),goal=read(memory.read_u16_le,0x0DA2),lo=read(memory.read_u8,0x0DA2),
 hi=read(memory.read_u8,0x0DA3),gs=read(memory.read_u16_le,0x00BA),
 remaining=read(memory.read_u8,0x06B4)}
end
local function csv(path,cols,n)
 local a={};for i=1,n do a[i]=cols[i]==nil and "" or tostring(cols[i]) end
 local f=assert(io.open(path,"a"));f:write(table.concat(a,",").."\n");f:close()
end
local q=nil;local prev=nil;local serial=0;local prefix=os.date("!%Y%m%dT%H%M%SZ")
local function consistent(s)
 return type(s.goal)=="number" and type(s.lo)=="number" and type(s.hi)=="number"
 and s.goal==s.lo+256*s.hi
end
local function log(s,kind,operator,delta,note)
 csv(trace,{q and q.id,s.frame,kind,operator,s.goal,s.lo,s.hi,s.gs,s.remaining,delta,
 consistent(s) and 1 or 0,note},12)
end
local function begin(s)
 serial=serial+1
 q={id=prefix.."_"..s.frame.."_"..serial,started=s.frame,initial=s.goal,
 positive=0,plausible=0,resets=0,inconsistent=0,invalid=0,
 negative=false,visual=false,exit=false,first_frame=nil,first_gs=nil,first_remaining=nil}
 prev=s -- prevent cross-session counter changes from being attributed to new session
 log(s,"session_start","START",nil,"baseline_captured")
end
local function close(s,why)
 if not q then return end
 local cls=Evidence.classify(q);local quality=Evidence.quality(q)
 csv(sessions,{q.id,q.started,q.initial,s.frame,s.goal,q.positive,q.plausible,q.resets,
 q.inconsistent,q.invalid,q.negative and 1 or 0,q.visual and 1 or 0,q.exit and 1 or 0,
 q.first_frame,q.first_gs,q.first_remaining,cls,quality,why},19)
 log(s,"session_end","",nil,cls)
 q=nil;prev=s
end
local pos=0;local ef=io.open(events,"rb")
if ef then pos=ef:seek("end");ef:close() end
local function poll(s)
 local e=io.open(events,"rb");if not e then return end
 local size=e:seek("end");if size<pos then pos=0 end;e:seek("set",pos)
 while true do
  local at=e:seek();local line=e:read("*l");if not line then break end
  local after=e:seek()
  if after==size and size>0 then
   local t=io.open(events,"rb")
   if t then t:seek("set",size-1);local last=t:read(1);t:close()
    if last~="\n" then e:seek("set",at);break end
   end
  end
  pos=after
  local cmd=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
  if cmd=="START" then
   if q then close(s,"restarted_by_operator") end
   begin(s)
  elseif q and cmd=="STOP" then close(s,"operator_stop")
  elseif q and cmd=="GOAL_VISUAL_CONFIRMED" then q.visual=true;log(s,"operator_visual",cmd)
  elseif q and (cmd=="SHOT_MISSED" or cmd=="NO_GOAL_EXIT") then
   q.negative=true;log(s,"negative_control",cmd)
  elseif q and (cmd=="BEFORE_SHOT" or cmd=="RESULT_SCREEN" or cmd=="NEW_ATTEMPT" or cmd=="MENU_TRANSITION") then
   log(s,"operator_marker",cmd)
  elseif cmd~="" then
   print("[GOAL v3] unknown/out-of-session event: "..cmd)
  end
 end
 e:close()
end
print("[GOAL v3] passive WRAM 0x0DA2; commands="..events)
while true do
 local s=snap()
 if q then
  local ok=consistent(s)
  if type(s.goal)~="number" then q.invalid=q.invalid+1;log(s,"invalid_read","",nil,"goal_missing")
  elseif not ok then q.inconsistent=q.inconsistent+1;log(s,"byte_mismatch","",nil,"u16_vs_bytes") end
  if prev and type(prev.goal)=="number" and type(s.goal)=="number" and prev.goal~=s.goal then
   local delta=s.goal-prev.goal
   if delta>0 then
    q.positive=q.positive+1
    if delta==1 and s.gs==5 and s.remaining==0 and ok then q.plausible=q.plausible+1 end
    if not q.first_frame then q.first_frame=s.frame;q.first_gs=s.gs;q.first_remaining=s.remaining end
    log(s,"counter_increment","",delta,(delta==1 and s.gs==5 and s.remaining==0) and "candidate_goal_transition" or "unexpected_context")
   else
    q.resets=q.resets+1
    log(s,"counter_decrease_or_reset","",delta,"not_a_goal")
   end
  elseif prev and (prev.gs~=s.gs or prev.remaining~=s.remaining) then
   log(s,"game_state_transition","",nil,"")
  end
  if prev and prev.gs==0 and s.gs~=0 then q.exit=true end
 end
 poll(s)
 prev=s
 emu.frameadvance()
end
