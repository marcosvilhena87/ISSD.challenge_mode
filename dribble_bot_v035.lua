-- DRIBBLE Bot v0.3.5: two-phase pilot + conservative outcome evidence.
-- Only the operator can CONFIRM_GOAL; post-game state is not proof of success.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode","C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/dribble_goal_v0325.lua") then root=p;break end end
assert(root,"repository root not found: expected lua/challenge/dribble_goal_v0325.lua. Check working directory and git pull.")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.dribble_goal_v0325"]=nil
local P=require("challenge.dribble_goal_v0325")
local Start=require("challenge.dribble_start_detection_v0327")
local Benchmark=require("challenge.dribble_route_benchmark_v0328")
local Goal=require("challenge.dribble_goal_evidence_v4")
local Performance=require("challenge.dribble_performance_v034")
local Optimization=require("challenge.dribble_route_optimization_v035")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.frameadvance and emu.framecount and joypad and joypad.set,"BizHawk API missing")
local session=os.date("!%Y%m%dT%H%M%SZ")
local command=root.."/dribble_bot_commands_v035.txt"
local trace=root.."/dribble_bot_trace_v035.csv"
local summary=root.."/dribble_bot_summary_v035.csv"
local function setup(path,header)
 local f=io.open(path,"rb")
 if f then
  local first=f:read("*l");f:close()
  assert(first==header,"CSV header missing/invalid: "..path.."; stop Lua and repair existing CSV (preserve data) before restarting")
 else
  local created=assert(io.open(path,"wb"));created:write(header.."\n");created:close()
 end
end
setup(trace,"session,frame,armed,phase,event,reason,gs,ptr,remaining,poss,player_x,player_y,ball_x,ball_y,buttons,time_bcd,bonus_bcd,time_frac_u16,bonus_frac_u16,recovery_diagnostics")
setup(summary,"session,started_frame,flags_frame,shot_frame,exit_frame,flags_elapsed_frames,goal_elapsed_frames,total_elapsed_frames,flags_remaining,time_start_bcd,time_at_fifth_bcd,bonus_at_fifth_bcd,time_at_exit_bcd,bonus_at_exit_bcd,shot_attempts,exit_reason,outcome,evidence,record_score")
setup(root.."/dribble_initial_calibration_v035.csv","session,start_frame,end_frame,first_player_frame,first_ball_frame,first_possession_change_frame,classification,finish_reason")
setup(root.."/dribble_flag_timing_v035.csv","session,flag_number,frame,remaining_before,remaining_after,elapsed_since_arm,frames_since_previous,player_x,player_y,ball_x,ball_y,time_bcd,bonus_bcd")
setup(root.."/dribble_start_state_v035.csv","session,arm_frame,gs,ptr,remaining,poss,player_x,player_y,ball_x,ball_y,time_bcd,time_frac_u16,bonus_bcd,bonus_frac_u16")
setup(root.."/dribble_start_sync_v035.csv","session,arm_frame,first_ball_frame,first_player_frame,first_timer_transition_frame,initial_time_bcd,last_time_bcd,end_frame,clock_status")
setup(root.."/dribble_active_start_v035.csv","session,arm_frame,first_timer_fraction_frame,first_timer_second_frame,first_ball_frame,first_player_frame,active_candidate_frame,active_candidate_evidence,wait_frames,finish_frame,finish_reason,valid_start_state")
setup(root.."/dribble_active_flag_timing_v035.csv","session,flag_number,flag_frame,active_candidate_frame,frames_since_active_candidate,frames_since_previous_flag")
setup(root.."/dribble_route_segments_v035.csv","session,flag_number,frame,segment_frames,baseline_frames,delta_frames,start_basis,player_x,player_y,ball_x,ball_y,poss,time_bcd,remaining,active_candidate_frame,valid_start_state")
setup(root.."/dribble_goal_evidence_v035.csv","session,arm_frame,initial_goal,fifth_flag_frame,shot_frame,increment_frame,increment_delta,gs_at_increment,remaining_at_increment,increment_count,reset_count,byte_mismatch,final_goal,classification,record_score")
setup(root.."/dribble_goal_events_v035.csv","session,frame,event,goal_u16,remaining,gs,shot_frame,classification")
setup(root.."/dribble_performance_v035.csv","session,arm_frame,active_frame,fifth_flag_frame,shot_frame,increment_frame,arm_to_active_frames,active_to_fifth_frames,arm_to_fifth_frames,fifth_to_shot_frames,shot_to_increment_frames,fifth_to_increment_frames,arm_to_increment_frames,route_comparable,route_delta_frames,goal_classification,record_score")
setup(root.."/dribble_summary_integrated_v035.csv","session,arm_frame,fifth_flag_frame,shot_frame,increment_frame,goal_initial,goal_final,goal_classification,goal_evidence,visual_confirmation,record_score,flags_elapsed_frames,preparation_frames,shot_to_increment_frames,total_to_increment_frames,route_comparable,route_delta_frames")
setup(root.."/dribble_route_benchmark_v035.csv","session,observed_flags,comparable,delta_total_frames,status,arm_frame,active_candidate_frame,fifth_flag_frame,exit_frame")
setup(root.."/dribble_route_optimization_v035.csv","session,profile,active_route_frames,baseline_delta_frames,complete,goal_classification,eligible,verdict")
setup(root.."/dribble_profile_audit_v035.csv","frame,event,requested_profile,applied_profile,session,wp1_x,wp1_y")
setup(root.."/dribble_route_experiments_v035.csv","session,profile,flag_number,segment_frames,baseline_frames,delta_frames,valid_start,player_x,player_y")
local selected_profile="CONTROL"
local requested_profile=nil
assert(Optimization.apply(selected_profile))
local pos=0;local f=io.open(command,"rb");if f then pos=f:seek("end");f:close() end
local armed=false;local attempt=nil;local state=P.new();local pending=false;local grace_exit=nil
local function release() joypad.set({},1) end
local function read(fn,a) local ok,v=pcall(fn,a,"WRAM");if ok then return v end end
local function bcd(b) if type(b)~="number" then return nil end;local lo=b%16;local hi=math.floor(b/16);if lo>9 or hi>9 then return nil end;return hi*10+lo end
local function fields(s)
 s.time=bcd(read(memory.read_u8,0x014F0));s.bonus=bcd(read(memory.read_u8,0x014F4))
 s.timefrac=read(memory.read_u16_le,0x014F2);s.bonusfrac=read(memory.read_u16_le,0x014F6)
end
local function textval(v) return v==nil and "" or tostring(v) end
local function write(path,columns,n)
 -- Use explicit column counts: ipairs stops at the first nil value.
 local values={}
 for i=1,n do values[i]=textval(columns[i]) end
 local f=assert(io.open(path,"a"));f:write(table.concat(values,",").."\n");f:close()
end
local function snapshot()
 local s={frame=emu.framecount(),gs=read(memory.read_u16_le,0x00BA),ptr=read(memory.read_u16_le,0x1ACC),remaining=read(memory.read_u8,0x006B4),poss=read(memory.read_u16_le,0x00A6),px=read(memory.read_s16_le,0x0F2A),py=read(memory.read_s16_le,0x0F2C),bx=read(memory.read_s16_le,0x042A),by=read(memory.read_s16_le,0x042C)}
 fields(s);s.goal=read(memory.read_u16_le,0x0DA2);s.lo=read(memory.read_u8,0x0DA2);s.hi=read(memory.read_u8,0x0DA3);return s
end
local function flush_start(a,frame,reason)
 if not a or a.active_written then return end
 local q=a.active
 if not q.complete then Start.finish(q,frame,reason) end
 write(root.."/dribble_active_start_v035.csv",{a.id,q.arm_frame,q.first_time_fraction,
  q.first_time_bcd,q.first_ball,q.first_player,q.active_frame,q.active_evidence,
  q.active_frame and q.active_frame-q.arm_frame or nil,q.finish_frame,q.final_reason,
  q.valid_start and 1 or 0},12)
 a.active_written=true
end
local function log_goal(a,ss,event)
 write(root.."/dribble_goal_events_v035.csv",{a.id,ss.frame,event,ss.goal,ss.remaining,ss.gs,a.goal.shot_frame,Goal.classify(a.goal)},8)
end
local function end_attempt()
 if not attempt or attempt.final then return end
 attempt.final=true;armed=false;pending=false;release()
 local gs=attempt.last or snapshot()
 write(root.."/dribble_goal_evidence_v035.csv",{attempt.id,attempt.started,attempt.goal.base,
  attempt.goal.flags_frame,attempt.goal.shot_frame,attempt.goal.increment_frame,attempt.goal.delta,
  attempt.goal.increment_gs,attempt.goal.increment_remaining,attempt.goal.increment_count,
  attempt.goal.reset_count,attempt.goal.byte_mismatch,gs.goal,Goal.classify(attempt.goal),attempt.score},15)
 local verdict=Benchmark.result(attempt.route)
 local opt=Optimization.result(attempt.route,attempt.profile,{classification=Goal.classify(attempt.goal)})
 write(root.."/dribble_route_optimization_v035.csv",{attempt.id,attempt.profile,opt.active_frames,opt.baseline_delta,
  opt.complete,opt.goal_classification,opt.eligible,opt.verdict},8)
 for _,seg in ipairs(Optimization.rows(attempt.route,attempt.profile)) do
  write(root.."/dribble_route_experiments_v035.csv",{attempt.id,seg.profile,seg.flag,seg.frames,
   seg.reference,seg.delta,seg.valid and 1 or 0,seg.px,seg.py},9)
 end
 local perf=Performance.calculate(attempt,attempt.goal,attempt.active,verdict)
 local cls=Goal.classify(attempt.goal)
 write(root.."/dribble_performance_v035.csv",{attempt.id,attempt.started,attempt.active.active_frame,
  attempt.goal.flags_frame,attempt.goal.shot_frame,attempt.goal.increment_frame,
  perf.arm_to_active,perf.active_to_fifth,perf.arm_to_fifth,perf.fifth_to_shot,
  perf.shot_to_increment,perf.fifth_to_increment,perf.arm_to_increment,
  perf.route_comparable,perf.route_delta,cls,attempt.score},17)
 write(root.."/dribble_summary_integrated_v035.csv",{attempt.id,attempt.started,
  attempt.goal.flags_frame,attempt.goal.shot_frame,attempt.goal.increment_frame,
  attempt.goal.base,gs.goal,cls,
  cls=="contextual_goal_candidate" and "memory_context_only" or "not_contextually_supported",
  attempt.confirmed and 1 or 0,attempt.score,
  perf.arm_to_fifth,perf.fifth_to_shot,perf.shot_to_increment,
  perf.arm_to_increment,perf.route_comparable,perf.route_delta},17)
 write(root.."/dribble_route_benchmark_v035.csv",{attempt.id,verdict.observed,verdict.comparable and 1 or 0,verdict.delta_total,verdict.status,attempt.started,attempt.active.active_frame,state.flags_frame,state.exit_frame},9)
 flush_start(attempt,(attempt.last and attempt.last.frame) or emu.framecount(),"attempt_finalized")
 local s=attempt.last or snapshot()
 local ff=state.flags_frame;local xf=state.exit_frame
 local n=attempt.started
 write(summary,{attempt.id,n,ff,state.shot_frame,xf,ff and ff-n,nil ~= xf and ff and xf-ff or nil,xf and xf-n,s.remaining,attempt.time_start,attempt.time_fifth,attempt.bonus_fifth,attempt.time_exit,attempt.bonus_exit,state.base.base.base.base.base.shot_attempts,attempt.exit_reason,attempt.confirmed and "goal_confirmed_operator" or "unverified",attempt.confirmed and "operator_visual_confirmation" or "no_verified_goal_flag",attempt.score},19)
 print("[ISSD.dribble_bot] v0.3.5 summary saved session="..attempt.id.." outcome=unverified. Confirm with Python.")
end
local function command_handle(cmd)
 local c=cmd:upper()
 if c:match("^PROFILE:") then
  local candidate=c:match("^PROFILE:(.+)$")
  local known=false
  for _,name in ipairs(Optimization.names) do if name==candidate then known=true;break end end
  if known then
   requested_profile=candidate
   print("[ISSD.dribble_bot] profile queued="..candidate.." next ARM")
   write(root.."/dribble_profile_audit_v035.csv",{emu.framecount(),"profile_queued",candidate,selected_profile,attempt and attempt.id or "",nil,nil},7)
  else print("[ISSD.dribble_bot] invalid profile="..tostring(candidate)) end
 elseif c=="ARM" then
  if attempt and not attempt.final then end_attempt() end
  if requested_profile then selected_profile=requested_profile;requested_profile=nil end
  assert(Optimization.apply(selected_profile))
  state=P.new();armed=true;pending=false;grace_exit=nil
  local s=snapshot();attempt={id=session.."_"..tostring(s.frame),started=s.frame,profile=selected_profile,time_start=s.time,last=s,last_remaining=s.remaining,last_flag_frame=s.frame,flags_seen=0,active=Start.new(s),route=Benchmark.new(s.frame),goal=Goal.new(s),confirmed=false,score=nil,final=false}
  write(root.."/dribble_start_state_v035.csv",{attempt.id,s.frame,s.gs,s.ptr,s.remaining,s.poss,s.px,s.py,s.bx,s.by,s.time,s.timefrac,s.bonus,s.bonusfrac},14)
  local W=require("challenge.dribble_waypoints_v022")
  write(root.."/dribble_profile_audit_v035.csv",{s.frame,"arm_applied",selected_profile,selected_profile,attempt.id,W.waypoints[1][1],W.waypoints[1][2]},7)
  print("[ISSD.dribble_bot] v0.3.5 ARMED profile="..selected_profile.." session="..attempt.id.." frame="..s.frame.." wp2=("..W.waypoints[2][1]..","..W.waypoints[2][2]..")")
 elseif c=="STOP" then
  if attempt then attempt.exit_reason=attempt.exit_reason or "operator_stop" end
  end_attempt()
 elseif c=="CONFIRM_GOAL" or c:match("^SCORE:%d+$") then
  print("[ISSD.dribble_bot] v0.3.5 use confirm_dribble_score_v032.py --session "..(attempt and attempt.id or "<session>").." after summary generation")
 elseif c~="" then print("[ISSD.dribble_bot] ignored command: "..cmd) end
end
print("[ISSD.dribble_bot] v0.3.5 DISARMED; commands="..command)
release()
while true do
 local cf=io.open(command,"rb")
 if cf then
  local size=cf:seek("end");if size<pos then pos=0 end;cf:seek("set",pos)
  while true do
   local start=cf:seek();local line=cf:read("*l");if not line then break end
   local after=cf:seek()
   if after==size and size>0 then
    local tail=io.open(command,"rb")
    if tail then tail:seek("set",size-1);local ch=tail:read(1);tail:close();if ch~="\n" then cf:seek("set",start);break end end
   end
   pos=after;command_handle(line:gsub("\r$",""):match("^%s*(.-)%s*$"))
  end
  cf:close()
 end
 if armed then
  local s=snapshot();local buttons;local reason
  Start.observe(attempt.active,s)
  if attempt.active.complete then flush_start(attempt,s.frame,attempt.active.final_reason) end
  buttons,state,reason=P.step(s,state)
  if state.shot_frame and not attempt.goal_shot_marked then
   Goal.marker(attempt.goal,"SHOT_STARTED",state.shot_frame)
   attempt.goal_shot_marked=true
   log_goal(attempt,s,"shot_started_from_controller")
  end
  local ge=Goal.step(attempt.goal,s)
  if ge then log_goal(attempt,s,ge) end
  local names={};for _,k in ipairs({"Left","Right","Up","Down","B"}) do if buttons[k] then names[#names+1]=k end end
  local keys=table.concat(names,"+")
  local allowed={waypoint=true,recover_ball=true,precision_approach=true,local_search=true,goal_approach=true,shot_charge=true,shot_release=true,await_goal_observation=true,stuck_recovery=true,recovery_completed=true,recovery_retry=true,delayed_observation=true,movement_detected=true,movement_observed_ball_only=true}
  if allowed[reason] then joypad.set(buttons,1) else release();armed=false;pending=true;grace_exit=s.frame+300;attempt.exit_reason=reason end
  if attempt.last_remaining and s.remaining and s.remaining<attempt.last_remaining and s.remaining>=0 and s.remaining<=5 then
   local drop=attempt.last_remaining-s.remaining
   if drop==1 then
    attempt.flags_seen=attempt.flags_seen+1
    write(root.."/dribble_flag_timing_v035.csv",{attempt.id,attempt.flags_seen,s.frame,attempt.last_remaining,s.remaining,
      s.frame-attempt.started,s.frame-attempt.last_flag_frame,s.px,s.py,s.bx,s.by,s.time,s.bonus},13)
    write(root.."/dribble_active_flag_timing_v035.csv",{attempt.id,attempt.flags_seen,s.frame,
      attempt.active.active_frame,
      attempt.active.active_frame and s.frame-attempt.active.active_frame or nil,
      s.frame-attempt.last_flag_frame},6)
    local segment=Benchmark.flag(attempt.route,attempt.flags_seen,s,attempt.active)
    if segment then
     write(root.."/dribble_route_segments_v035.csv",{attempt.id,segment.number,segment.frame,
      segment.segment_frames,segment.baseline_frames,segment.delta_frames,segment.start_basis,
      segment.px,segment.py,segment.bx,segment.by,segment.poss,segment.time,
      segment.remaining,segment.active_frame,segment.valid_start and 1 or 0},16)
    end
    attempt.last_flag_frame=s.frame
    print("[ISSD.dribble_bot] flag_collected number="..attempt.flags_seen.." frame="..s.frame)
   else print("[ISSD.dribble_bot] counter discontinuity: flag timing not inferred") end
  end
  attempt.last_remaining=s.remaining
  attempt.last=s
  if state.flags_frame==s.frame then attempt.time_fifth=s.time;attempt.bonus_fifth=s.bonus end
  if state.exit_frame==s.frame then attempt.time_exit=s.time;attempt.bonus_exit=s.bonus end
  if s.frame%5==0 or state.event~="" or state.calibration or state.sync or reason=="stuck_recovery" or reason=="delayed_observation" or not allowed[reason] then
   write(trace,{attempt.id,s.frame,armed and 1 or 0,state.phase,state.event,reason,s.gs,s.ptr,s.remaining,s.poss,s.px,s.py,s.bx,s.by,keys,s.time,s.bonus,s.timefrac,s.bonusfrac,state.diag},20)
  end
  if state.calibration_result and not attempt.calibration_written then
   local c=state.calibration_result
   write(root.."/dribble_initial_calibration_v035.csv",{attempt.id,c.start,c.finish,
     c.first_player,c.first_ball,c.first_possession_change,c.classification,c.outcome},8)
   attempt.calibration_written=true
  end
  if state.sync_result and not attempt.sync_written then
   local q=state.sync_result
   write(root.."/dribble_start_sync_v035.csv",{attempt.id,q.arm,q.first_ball,
    q.first_player,q.timer_change,q.initial_time,q.final_time,q.finish,q.clock_status},9)
   attempt.sync_written=true
  end
  if state.event~="" then print("[ISSD.dribble_bot] "..state.event.." frame="..s.frame) end
 elseif pending and grace_exit and emu.framecount()>=grace_exit then end_attempt()
 else release() end
 emu.frameadvance()
end
