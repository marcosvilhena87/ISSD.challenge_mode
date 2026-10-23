-- DRIBBLE Bot v0.3.5: two-phase pilot + conservative outcome evidence.
-- Only the operator can CONFIRM_GOAL; post-game state is not proof of success.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root=_G.ISSD_PROJECT_ROOT
if root then
 assert(exists(root.."/lua/challenge/dribble_goal_v0325.lua"),
  "invalid project root provided by main.lua: "..tostring(root))
else
 -- Legacy direct launch remains available for historical workflows.
 for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode","C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode"}) do
  if exists(p.."/lua/challenge/dribble_goal_v0325.lua") then root=p;break end
 end
end
assert(root,"repository root not found: expected lua/challenge/dribble_goal_v0325.lua. Check working directory and git pull.")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
-- Clear cached challenge modules so the controller and optimizer share one waypoint table.
for name,_ in pairs(package.loaded) do
 if type(name)=="string" and name:match("^challenge%.dribble_") then
  package.loaded[name]=nil
 end
end
local P=require("challenge.dribble_goal_v0325")
local Start=require("challenge.dribble_start_detection_v0327")
local Benchmark=require("challenge.dribble_route_benchmark_v0328")
local Goal=require("challenge.dribble_goal_evidence_v4")
local Performance=require("challenge.dribble_performance_v034")
-- Reload mutable route modules on each runner start; BizHawk may retain package.loaded.
local Optimization=require("challenge.dribble_route_optimization_v035")
local function profile_known(name)
 for _,v in ipairs(Optimization.names) do if v==name then return true end end
 return false
end
assert(profile_known("FLAG2_760_325"),
 "outdated route optimization module: expected FLAG2_760_325 at "..root.."/lua/challenge/dribble_route_optimization_v035.lua")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.frameadvance and emu.framecount and joypad and joypad.set,"BizHawk API missing")
local csv_dir=root.."/csv"
os.execute('mkdir "'..csv_dir..'" >nul 2>&1')
local csv_probe,csv_error=io.open(csv_dir.."/.write_probe","wb")
assert(csv_probe,"CSV directory unavailable: "..tostring(csv_error))
csv_probe:close()
os.remove(csv_dir.."/.write_probe")
local session=os.date("!%Y%m%dT%H%M%SZ")
-- Keep operator-created TXT commands under txt/; legacy root commands remain readable.
local txt_dir=root.."/txt"
os.execute('mkdir "'..txt_dir..'" >nul 2>&1')
local command=txt_dir.."/dribble_bot_commands_v035.txt"
local legacy_command=root.."/dribble_bot_commands_v035.txt"
local modern=io.open(command,"rb")
if modern then modern:close() else
 local old=io.open(legacy_command,"rb")
 if old then old:close();command=legacy_command end
end
local trace=csv_dir.."/dribble_bot_trace_v035.csv"
local summary=csv_dir.."/dribble_bot_summary_v035.csv"
local CSV=require("challenge.dribble_csv_v035")
local Commands=require("challenge.dribble_commands_v035")
local ResultDetector=require("challenge.dribble_result_detector")
local Dash=require("challenge.dribble_dash_v3")
local RouteV1=require("challenge.dribble_route_optimization_v1")
local ZoneV2=require("challenge.dribble_collection_zone_v2")
local ZoneV3=require("challenge.dribble_collection_zone_v3")
local ZoneV4=require("challenge.dribble_collection_zone_v4")
local Straight=require("challenge.dribble_direct_line_calibration_v2")
local result_observer=ResultDetector.new()
-- Compact is the default: two canonical files + one multiplexed diagnostics CSV.
-- FULL preserves every historical output for research/compatibility.
-- Set root/dribble_csv_mode.txt to FULL before starting main.lua if required.
local function csv_mode()
 local f=io.open(root.."/dribble_csv_mode.txt","rb")
 if not f then return "COMPACT" end
 local value=(f:read("*a") or ""):match("^%s*(%u+)") or ""
 f:close()
 if value=="FULL" or value=="COMPACT" then return value end
 error("dribble_csv_mode.txt: expected COMPACT or FULL, got "..value)
end
local output_mode=csv_mode()
local native_setup,native_write=CSV.setup,CSV.write
local summary_name="dribble_bot_summary_v035.csv"
local observer_name="dribble_result_observer_v1.csv"
local diagnostics_name="dribble_diagnostics_v2.csv"
local attempt -- shared with diagnostics writer; assigned when bot arms
local schemas={}
local function basename(path) return path:match("([^/\\]+)$") or path end
local function quote(v)
 local x=v==nil and "" or tostring(v)
 return '"'..x:gsub('"','""')..'"'
end
local function split_header(header)
 local names={}
 for value in (header..","):gmatch("(.-),") do names[#names+1]=value end
 return names
end
local function setup(path,header)
 local name=basename(path)
 schemas[name]={header=header,fields=split_header(header)}
 if output_mode=="FULL" or name==summary_name or name==observer_name then
  native_setup(path,header)
 end
end
local function write(path,values,n)
 local name=basename(path)
 if output_mode=="FULL" or name==summary_name or name==observer_name then
  return native_write(path,values,n)
 end
 if name=="dribble_bot_trace_v035.csv" then return end
 local schema=assert(schemas[name],"Unregistered compact CSV source: "..name)
 assert(#schema.fields==n,"Invalid field count for "..name)
 local serialized={}
 local index={}
 for i=1,n do
  local field=schema.fields[i]
  serialized[i]=values[i]==nil and "" or tostring(values[i])
  index[field]=values[i]
 end
 -- Normalize session and frame independently of the source's column order.
 -- Profile audit begins with frame, not session.
 local session_id=index.session or (attempt and attempt.id) or ""
 local frame=index.frame or index.arm_frame or index.start_frame or
  index.flag_frame or index.shot_frame or index.fifth_flag_frame or ""
 if frame=="" then frame=emu.framecount() end
 local record_type=index.event or index.classification or index.verdict or
  index.status or name:gsub("%.csv$","")
 local line={session_id,frame,name,record_type,schema.header,table.concat(serialized,",")}
 for i,v in ipairs(line) do line[i]=quote(v) end
 local f=assert(io.open(csv_dir.."/"..diagnostics_name,"a"))
 assert(f:write(table.concat(line,",").."\n"))
 assert(f:close())
end
if output_mode=="COMPACT" then
 native_setup(csv_dir.."/"..diagnostics_name,
  "session,frame,source_csv,record_type,source_columns,source_values")
end
print("[ISSD.dribble_bot] CSV mode="..output_mode..
 (output_mode=="COMPACT" and " (summary, observer, diagnostics v2; trace disabled)" or " (legacy full reports)"))

setup(csv_dir.."/dribble_entry_target_v7.csv","session,frame,mode,event,cause,x,y,elapsed_frames")
setup(csv_dir.."/dribble_collection_zone_v4.csv","session,frame,flag,mode,event,transitions,near_without_transition,post_min_x,post_max_x,post_min_y,post_max_y,near_min_x,near_max_x,near_min_y,near_max_y,min_pre_distance,max_pre_distance,classification")
setup(csv_dir.."/dribble_collection_zone_v3.csv","session,frame,flag,mode,event,pre_x,pre_y,post_x,post_y,pre_distance,post_distance,entry_direction,travel_distance,elapsed_frames")
setup(csv_dir.."/dribble_collection_zone_v2.csv","session,frame,flag,event,pre_frame,pre_x,pre_y,post_x,post_y,pre_distance,post_distance,sample_frame,sample_x,sample_y,classification")
setup(csv_dir.."/dribble_route_optimization_v1.csv","session,flag,event,mode,frame,travel_distance,elapsed_frames,samples,collection_x,collection_y")
setup(csv_dir.."/dribble_direct_line_calibration_v2.csv","session,frame,flag,event,cross_track_error,signed_error,progress,diagonal,correcting,frames,max_error,avg_error,corrections,diagonal_frames,axis_frames,outside_segment_frames,closest_error")
setup(csv_dir.."/dribble_dash_calibration_v3.csv","session,frame,flag,event,distance_to_waypoint,brake_distance,closing_speed,reason,dash_frames,starts,stops,off_cause,ball_gap,minimum_distance,frames_since_last_off")
setup(csv_dir.."/dribble_result_observer_v1.csv","session,detector_trial,frame,event,gameplay,remaining,time_score,bonus_score,total_score,copy_total,start_frame,exit_frame,early_frame,early_verdict,copy_match_frame,final_verdict,finish_reason,status")
setup(trace,"session,frame,armed,phase,event,reason,gs,ptr,remaining,poss,player_x,player_y,ball_x,ball_y,buttons,time_bcd,bonus_bcd,time_frac_u16,bonus_frac_u16,recovery_diagnostics")
setup(summary,"session,started_frame,flags_frame,shot_frame,exit_frame,flags_elapsed_frames,goal_elapsed_frames,total_elapsed_frames,flags_remaining,time_start_bcd,time_at_fifth_bcd,bonus_at_fifth_bcd,time_at_exit_bcd,bonus_at_exit_bcd,shot_attempts,exit_reason,outcome,evidence,record_score")
setup(csv_dir.."/dribble_initial_calibration_v035.csv","session,start_frame,end_frame,first_player_frame,first_ball_frame,first_possession_change_frame,classification,finish_reason")
setup(csv_dir.."/dribble_flag_timing_v035.csv","session,flag_number,frame,remaining_before,remaining_after,elapsed_since_arm,frames_since_previous,player_x,player_y,ball_x,ball_y,time_bcd,bonus_bcd")
setup(csv_dir.."/dribble_start_state_v035.csv","session,arm_frame,gs,ptr,remaining,poss,player_x,player_y,ball_x,ball_y,time_bcd,time_frac_u16,bonus_bcd,bonus_frac_u16")
setup(csv_dir.."/dribble_start_sync_v035.csv","session,arm_frame,first_ball_frame,first_player_frame,first_timer_transition_frame,initial_time_bcd,last_time_bcd,end_frame,clock_status")
setup(csv_dir.."/dribble_active_start_v035.csv","session,arm_frame,first_timer_fraction_frame,first_timer_second_frame,first_ball_frame,first_player_frame,active_candidate_frame,active_candidate_evidence,wait_frames,finish_frame,finish_reason,valid_start_state")
setup(csv_dir.."/dribble_active_flag_timing_v035.csv","session,flag_number,flag_frame,active_candidate_frame,frames_since_active_candidate,frames_since_previous_flag")
setup(csv_dir.."/dribble_route_segments_v035.csv","session,flag_number,frame,segment_frames,baseline_frames,delta_frames,start_basis,player_x,player_y,ball_x,ball_y,poss,time_bcd,remaining,active_candidate_frame,valid_start_state")
setup(csv_dir.."/dribble_goal_evidence_v035.csv","session,arm_frame,initial_goal,fifth_flag_frame,shot_frame,increment_frame,increment_delta,gs_at_increment,remaining_at_increment,increment_count,reset_count,byte_mismatch,final_goal,classification,record_score")
setup(csv_dir.."/dribble_goal_events_v035.csv","session,frame,event,goal_u16,remaining,gs,shot_frame,classification")
setup(csv_dir.."/dribble_performance_v035.csv","session,arm_frame,active_frame,fifth_flag_frame,shot_frame,increment_frame,arm_to_active_frames,active_to_fifth_frames,arm_to_fifth_frames,fifth_to_shot_frames,shot_to_increment_frames,fifth_to_increment_frames,arm_to_increment_frames,route_comparable,route_delta_frames,goal_classification,record_score")
setup(csv_dir.."/dribble_summary_integrated_v035.csv","session,arm_frame,fifth_flag_frame,shot_frame,increment_frame,goal_initial,goal_final,goal_classification,goal_evidence,visual_confirmation,record_score,flags_elapsed_frames,preparation_frames,shot_to_increment_frames,total_to_increment_frames,route_comparable,route_delta_frames")
setup(csv_dir.."/dribble_route_benchmark_v035.csv","session,observed_flags,comparable,delta_total_frames,status,arm_frame,active_candidate_frame,fifth_flag_frame,exit_frame")
setup(csv_dir.."/dribble_route_optimization_v035.csv","session,profile,active_route_frames,baseline_delta_frames,complete,goal_classification,eligible,verdict")
setup(csv_dir.."/dribble_profile_audit_v035.csv","frame,event,requested_profile,applied_profile,session,wp1_x,wp1_y")
setup(csv_dir.."/dribble_route_experiments_v035.csv","session,profile,flag_number,segment_frames,baseline_frames,delta_frames,valid_start,player_x,player_y")
setup(csv_dir.."/dribble_travel_profile_v035.csv","session,route_profile,approach_profile,travel_profile,arm_frame,complete,eligible,active_route_frames,goal_classification")
setup(csv_dir.."/dribble_approach_proximity_v035.csv","session,route_profile,approach_profile,flag_number,observed_frames,near24_frames,near12_frames,precision_frames,local_search_frames,recover_ball_frames,precision_idle_frames,complete")
local W=require("challenge.dribble_waypoints_v022")
local approach_names={CONTROL=true,CONTINUOUS_PRECISION=true}
local selected_travel="DIRECT_LINE"
local route_mode="DIRECT_LINE"
local requested_route=nil
local route_flag=2
local zone_mode=nil
local entry_v7=false
local requested_entry_v7=nil
local requested_zone=nil
local requested_travel=nil
local selected_approach="CONTINUOUS_PRECISION"
local requested_approach=nil
local selected_profile=Optimization.DEFAULT_PROFILE
local requested_profile=nil
assert(Optimization.apply(selected_profile))
W.approach_profile=selected_approach
W.travel_profile=selected_travel
local command_reader=Commands.new(command,function(msg)
 print("[ISSD.dribble_bot] "..msg.." frame="..emu.framecount())
end)
local armed=false;attempt=nil;local state=P.new();local pending=false;local grace_exit=nil
-- Independent read-only observer. Never changes buttons, armed, attempt or outcome.
local function release() joypad.set({},1) end
local function read(fn,a) local ok,v=pcall(fn,a,"WRAM");if ok then return v end end
local function bcd(b) if type(b)~="number" then return nil end;local lo=b%16;local hi=math.floor(b/16);if lo>9 or hi>9 then return nil end;return hi*10+lo end
local function fields(s)
 s.time=bcd(read(memory.read_u8,0x014F0));s.bonus=bcd(read(memory.read_u8,0x014F4))
 s.timefrac=read(memory.read_u16_le,0x014F2);s.bonusfrac=read(memory.read_u16_le,0x014F6)
end
local function snapshot()
 local s={frame=emu.framecount(),gs=read(memory.read_u16_le,0x00BA),ptr=read(memory.read_u16_le,0x1ACC),remaining=read(memory.read_u8,0x006B4),poss=read(memory.read_u16_le,0x00A6),px=read(memory.read_s16_le,0x0F2A),py=read(memory.read_s16_le,0x0F2C),bx=read(memory.read_s16_le,0x042A),by=read(memory.read_s16_le,0x042C)}
 fields(s);s.goal=read(memory.read_u16_le,0x0DA2);s.lo=read(memory.read_u8,0x0DA2);s.hi=read(memory.read_u8,0x0DA3);return s
end
local function result_snapshot(s)
 s=s or snapshot()
 local function rbyte(a) return read(memory.read_u8,a) end
 local function rword(a) return read(memory.read_u16_le,a) end
 return {frame=s.frame,gameplay=s.gs==0 and s.ptr==0x0F00,remaining=s.remaining,
  time=rbyte(0x01CF3),bonus=rword(0x01CF8),total=rword(0x01CFA),copy=rword(0x0DC06)}
end
local function observe_result(s)
 local ok,events=pcall(function()
  return ResultDetector.step(result_observer,result_snapshot(s))
 end)
 if not ok then
  print("[ISSD.dribble_bot] result observer error: "..tostring(events))
  return
 end
 for _,e in ipairs(events) do
  local a=e.trial
  local p=a and a.preliminary
  write(csv_dir.."/dribble_result_observer_v1.csv",
   {session,e.id or "",e.frame,e.type,e.sample.gameplay and 1 or 0,
    e.sample.remaining,e.sample.time,e.sample.bonus,e.sample.total,e.sample.copy,
    a and a.start,a and a.exited,p and p.frame,p and p.verdict,
    a and a.copy_confirmed_frame,e.extra and e.extra.verdict,
    e.extra and e.extra.reason,"hypothesis_only"},18)
 end
end
local function flush_start(a,frame,reason)
 if not a or a.active_written then return end
 local q=a.active
 if not q.complete then Start.finish(q,frame,reason) end
 write(csv_dir.."/dribble_active_start_v035.csv",{a.id,q.arm_frame,q.first_time_fraction,
  q.first_time_bcd,q.first_ball,q.first_player,q.active_frame,q.active_evidence,
  q.active_frame and q.active_frame-q.arm_frame or nil,q.finish_frame,q.final_reason,
  q.valid_start and 1 or 0},12)
 a.active_written=true
end
local function log_goal(a,ss,event)
 write(csv_dir.."/dribble_goal_events_v035.csv",{a.id,ss.frame,event,ss.goal,ss.remaining,ss.gs,a.goal.shot_frame,Goal.classify(a.goal)},8)
end
local function flush_proximity(a)
 if not a or a.proximity_written then return end
 a.proximity_written=true
 for i=1,5 do
  local q=a.proximity[i]
  local fs=Dash.flag_summary(a.dash,i,(a.last and a.last.frame) or a.started)
  write(csv_dir.."/dribble_dash_calibration_v3.csv",
   {a.id,(a.last and a.last.frame) or a.started,i,"flag_summary",nil,nil,nil,
    "end_attempt",a.dash.frames[i] or 0,a.dash.starts[i] or 0,a.dash.stops[i] or 0,
    fs.off_cause,nil,fs.minimum,fs.frames_since_off},15)
  write(csv_dir.."/dribble_approach_proximity_v035.csv",
   {a.id,a.profile,a.approach_profile,i,q.observed,q.near24,q.near12,
    q.precision,q.search,q.recover,q.precision_idle,q.collected and 1 or 0},12)
 end
end
local function end_attempt()
 if not attempt or attempt.final then return end
 attempt.final=true;armed=false;pending=false;release()
 flush_proximity(attempt)
 for i=1,5 do
  local row=ZoneV4.row(attempt.zone_v4,i,i==2 and (attempt.zone_mode or "OFF") or "OFF",
    (attempt.last and attempt.last.frame) or attempt.started)
  write(csv_dir.."/dribble_collection_zone_v4.csv",
    {attempt.id,row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8],
     row[9],row[10],row[11],row[12],row[13],row[14],row[15],row[16],row[17]},18)
 end
 local gs=attempt.last or snapshot()
 write(csv_dir.."/dribble_goal_evidence_v035.csv",{attempt.id,attempt.started,attempt.goal.base,
  attempt.goal.flags_frame,attempt.goal.shot_frame,attempt.goal.increment_frame,attempt.goal.delta,
  attempt.goal.increment_gs,attempt.goal.increment_remaining,attempt.goal.increment_count,
  attempt.goal.reset_count,attempt.goal.byte_mismatch,gs.goal,Goal.classify(attempt.goal),attempt.score},15)
 local verdict=Benchmark.result(attempt.route)
 local opt=Optimization.result(attempt.route,attempt.profile,{classification=Goal.classify(attempt.goal)})
 write(csv_dir.."/dribble_route_optimization_v035.csv",{attempt.id,attempt.profile,opt.active_frames,opt.baseline_delta,
  opt.complete,opt.goal_classification,opt.eligible,opt.verdict},8)
 write(csv_dir.."/dribble_travel_profile_v035.csv",{attempt.id,attempt.profile,attempt.approach_profile,attempt.travel_profile,attempt.started,opt.complete,opt.eligible,opt.active_frames,opt.goal_classification},9)
 for _,seg in ipairs(Optimization.rows(attempt.route,attempt.profile)) do
  write(csv_dir.."/dribble_route_experiments_v035.csv",{attempt.id,seg.profile,seg.flag,seg.frames,
   seg.reference,seg.delta,seg.valid and 1 or 0,seg.px,seg.py},9)
 end
 local perf=Performance.calculate(attempt,attempt.goal,attempt.active,verdict)
 local cls=Goal.classify(attempt.goal)
 write(csv_dir.."/dribble_performance_v035.csv",{attempt.id,attempt.started,attempt.active.active_frame,
  attempt.goal.flags_frame,attempt.goal.shot_frame,attempt.goal.increment_frame,
  perf.arm_to_active,perf.active_to_fifth,perf.arm_to_fifth,perf.fifth_to_shot,
  perf.shot_to_increment,perf.fifth_to_increment,perf.arm_to_increment,
  perf.route_comparable,perf.route_delta,cls,attempt.score},17)
 write(csv_dir.."/dribble_summary_integrated_v035.csv",{attempt.id,attempt.started,
  attempt.goal.flags_frame,attempt.goal.shot_frame,attempt.goal.increment_frame,
  attempt.goal.base,gs.goal,cls,
  cls=="contextual_goal_candidate" and "memory_context_only" or "not_contextually_supported",
  attempt.confirmed and 1 or 0,attempt.score,
  perf.arm_to_fifth,perf.fifth_to_shot,perf.shot_to_increment,
  perf.arm_to_increment,perf.route_comparable,perf.route_delta},17)
 write(csv_dir.."/dribble_route_benchmark_v035.csv",{attempt.id,verdict.observed,verdict.comparable and 1 or 0,verdict.delta_total,verdict.status,attempt.started,attempt.active.active_frame,state.flags_frame,state.exit_frame},9)
 flush_start(attempt,(attempt.last and attempt.last.frame) or emu.framecount(),"attempt_finalized")
 local s=attempt.last or snapshot()
 local ff=state.flags_frame;local xf=state.exit_frame
 local n=attempt.started
 write(summary,{attempt.id,n,ff,state.shot_frame,xf,ff and ff-n,nil ~= xf and ff and xf-ff or nil,xf and xf-n,s.remaining,attempt.time_start,attempt.time_fifth,attempt.bonus_fifth,attempt.time_exit,attempt.bonus_exit,state.base.base.base.base.base.shot_attempts,attempt.exit_reason,attempt.confirmed and "goal_confirmed_operator" or "unverified",attempt.confirmed and "operator_visual_confirmation" or "no_verified_goal_flag",attempt.score},19)
 print("[ISSD.dribble_bot] v0.3.5 summary saved session="..attempt.id.." outcome=unverified. Confirm with Python.")
end
local function command_handle(cmd)
 local c=cmd:upper()
 if c:match("^ENTRY:") then
  local mode=c:match("^ENTRY:(.+)$")
  if mode=="ON" or mode=="OFF" then requested_entry_v7=mode;print("[ISSD.dribble_bot] entry v7 queued="..mode.." next ARM")
  else print("[ISSD.dribble_bot] invalid entry v7 mode="..tostring(mode)) end
 elseif c:match("^ZONE:") then
  local mode=c:match("^ZONE:(.+)$")
  if mode=="OFF" or ZoneV3.NAMES[mode] then requested_zone=mode;print("[ISSD.dribble_bot] zone queued="..mode.." next ARM")
  else print("[ISSD.dribble_bot] invalid zone mode="..tostring(mode)) end
 elseif c:match("^ROUTE:") then
  local mode=c:match("^ROUTE:(.+)$")
  if RouteV1.NAMES[mode] then requested_route=mode;print("[ISSD.dribble_bot] route queued="..mode.." next ARM")
  else print("[ISSD.dribble_bot] invalid route="..tostring(mode)) end
 elseif c:match("^TRAVEL:") then
  local name=c:match("^TRAVEL:(.+)$")
  if name=="AXIS" or name=="DIRECT_LINE" then
   requested_travel=name
   print("[ISSD.dribble_bot] travel queued="..name.." next ARM")
  else print("[ISSD.dribble_bot] invalid travel="..tostring(name)) end
 elseif c:match("^APPROACH:") then
  local name=c:match("^APPROACH:(.+)$")
  if approach_names[name] then
   requested_approach=name
   print("[ISSD.dribble_bot] approach queued="..name.." next ARM")
  else print("[ISSD.dribble_bot] invalid approach="..tostring(name)) end
 elseif c:match("^PROFILE:") then
  local candidate=c:match("^PROFILE:(.+)$")
  local known=false
  for _,name in ipairs(Optimization.names) do if name==candidate then known=true;break end end
  if known then
   requested_profile=candidate
   print("[ISSD.dribble_bot] profile queued="..candidate.." next ARM")
   write(csv_dir.."/dribble_profile_audit_v035.csv",{emu.framecount(),"profile_queued",candidate,selected_profile,attempt and attempt.id or "",nil,nil},7)
  else print("[ISSD.dribble_bot] invalid profile="..tostring(candidate)) end
 elseif c=="ARM" then
  if attempt and not attempt.final then end_attempt() end
  if requested_profile then selected_profile=requested_profile;requested_profile=nil end
  if requested_approach then selected_approach=requested_approach;requested_approach=nil end
  if requested_travel then selected_travel=requested_travel;requested_travel=nil end
  if requested_route then route_mode=requested_route;requested_route=nil end
  W.set_segment_modes({[route_flag]=route_mode})
  if requested_zone then zone_mode=requested_zone=="OFF" and nil or requested_zone;requested_zone=nil end
  W.set_zone_approach(zone_mode)
  assert(Optimization.apply(selected_profile))
  W.approach_profile=selected_approach
  W.travel_profile=selected_travel
  state=P.new();armed=true;pending=false;grace_exit=nil
  local s=snapshot();attempt={dash=Dash.new(),straight=Straight.new(),route_v1=RouteV1.new(),zone_v2=ZoneV2.new(),zone_v4=ZoneV4.new(),zone_mode=zone_mode,entry_v7=entry_v7,route_mode=route_mode,id=session.."_"..tostring(s.frame),started=s.frame,profile=selected_profile,time_start=s.time,last=s,last_remaining=s.remaining,last_flag_frame=s.frame,flags_seen=0,active=Start.new(s),route=Benchmark.new(s.frame),goal=Goal.new(s),confirmed=false,score=nil,final=false,approach_profile=selected_approach,travel_profile=selected_travel,
   proximity={{},{},{},{},{}},proximity_written=false}
  for i=1,5 do attempt.proximity[i]={observed=0,near24=0,near12=0,
   precision=0,search=0,recover=0,precision_idle=0,collected=false} end
  write(csv_dir.."/dribble_start_state_v035.csv",{attempt.id,s.frame,s.gs,s.ptr,s.remaining,s.poss,s.px,s.py,s.bx,s.by,s.time,s.timefrac,s.bonus,s.bonusfrac},14)
  local W=require("challenge.dribble_waypoints_v022")
  write(csv_dir.."/dribble_profile_audit_v035.csv",{s.frame,"arm_applied",selected_profile,selected_profile,attempt.id,W.waypoints[1][1],W.waypoints[1][2]},7)
  print("[ISSD.dribble_bot] approach applied="..selected_approach.." travel applied="..selected_travel.." route flag2="..route_mode.." zone="..(entry_v7 and "ENTRY_V7" or (zone_mode or "OFF")).." entry_v7="..(entry_v7 and "ON" or "OFF"))
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
 command_reader.poll(function(line)
  print("[ISSD.dribble_bot] command received="..line.." frame="..emu.framecount())
  command_handle(line)
 end)
 if armed then
  local s=snapshot();observe_result(s);local buttons;local reason
  Start.observe(attempt.active,s)
  if attempt.active.complete then flush_start(attempt,s.frame,attempt.active.final_reason) end
  buttons,state,reason=P.step(s,state)
  RouteV1.observe(attempt.route_v1,s)
  -- Passive collection-zone discovery: no button-policy or waypoint changes.
  local zone_events=ZoneV2.observe(attempt.zone_v2,s,W.waypoints)
  for _,ze in ipairs(zone_events) do
   ZoneV4.observe(attempt.zone_v4,ze)
   if ze.kind=="collection_transition" then
    local c=ze.record
    if c.flag==2 then
     local metric=attempt.route_v1.segments[2]
     write(csv_dir.."/dribble_collection_zone_v3.csv",
      {attempt.id,c.frame,2,attempt.zone_mode or "OFF","collection_transition",
       c.pre_x,c.pre_y,c.post_x,c.post_y,c.pre_distance,c.post_distance,
       ZoneV3.direction(c),metric and metric.distance,metric and metric.frames},14)
    end
    write(csv_dir.."/dribble_collection_zone_v2.csv",
     {attempt.id,c.frame,c.flag,"collection_transition",c.pre_frame,c.pre_x,c.pre_y,
      c.post_x,c.post_y,c.pre_distance,c.post_distance,nil,nil,nil,"observed_transition"},15)
    for _,p in ipairs(c.window) do
     write(csv_dir.."/dribble_collection_zone_v2.csv",
      {attempt.id,c.frame,c.flag,"pre_window",c.pre_frame,c.pre_x,c.pre_y,
       c.post_x,c.post_y,c.pre_distance,c.post_distance,p.frame,p.x,p.y,
       "historical_position_not_collection_boundary"},15)
    end
   elseif ze.kind=="near_without_transition" then
    write(csv_dir.."/dribble_collection_zone_v2.csv",
     {attempt.id,ze.frame,ze.flag,"near_without_transition",nil,ze.x,ze.y,
      nil,nil,ze.distance,nil,nil,nil,nil,"negative_observation"},15)
   end
  end
  if s.remaining and s.remaining>=1 and s.remaining<=5 then
   local i=6-s.remaining
   local q=attempt.proximity[i]
   local wp=W.waypoints[i]
   if wp and type(s.px)=="number" and type(s.py)=="number" then
    local dx,dy=math.abs(wp[1]-s.px),math.abs(wp[2]-s.py)
    q.observed=q.observed+1
    if dx<=24 and dy<=24 then q.near24=q.near24+1 end
    if dx<=12 and dy<=12 then q.near12=q.near12+1 end
    if reason=="precision_approach" then
     q.precision=q.precision+1
     if not(buttons.Left or buttons.Right or buttons.Up or buttons.Down) then q.precision_idle=q.precision_idle+1 end
    elseif reason=="local_search" then q.search=q.search+1
    elseif reason=="recover_ball" then q.recover=q.recover+1 end
   end
  end
  if state.shot_frame and not attempt.goal_shot_marked then
   Goal.marker(attempt.goal,"SHOT_STARTED",state.shot_frame)
   attempt.goal_shot_marked=true
   log_goal(attempt,s,"shot_started_from_controller")
  end
  local ge=Goal.step(attempt.goal,s)
  if ge then log_goal(attempt,s,ge) end
  -- Dash only during safe far-field waypoint travel; never in shot/recovery.
  local dash_events
  -- Dash temporarily disabled during DIRECT_LINE calibration.
  -- Keep Y explicitly absent regardless of previous output.
  buttons.Y=nil
  dash_events={}
  local line_state=state
  -- The waypoint controller's state contains .line; a deeper .base belongs
  -- to another controller. Stop at the first valid active segment.
  local actual_line=nil
  while type(line_state)=="table" do
   if type(line_state.line)=="table" and line_state.line.tx and line_state.line.ty then
    actual_line=line_state.line
    break
   end
   -- dribble_goal_v03 keeps the waypoint state in .flag, not .base.
   if type(line_state.flag)=="table" then
    line_state=line_state.flag
   else
    line_state=line_state.base
   end
  end
  local sl=Straight.observe(attempt.straight,s,reason,buttons,actual_line)
  if sl and s.frame%15==0 then
   write(csv_dir.."/dribble_direct_line_calibration_v2.csv",
    {attempt.id,s.frame,sl.flag,"sample",sl.error,sl.cross,sl.progress,
     sl.diagonal,sl.correcting,nil,nil,nil,nil,nil,nil,nil,nil},17)
  end
  for _,de in ipairs(dash_events) do
   local flag=de.flag
   write(csv_dir.."/dribble_dash_calibration_v3.csv",
    {attempt.id,de.frame,flag,de.kind,de.distance,de.brake,de.closing,de.reason,
     attempt.dash.frames[flag] or 0,attempt.dash.starts[flag] or 0,
     attempt.dash.stops[flag] or 0,de.cause,de.gap,attempt.dash.minimum[flag],nil},15)
  end
  local names={};for _,k in ipairs({"Left","Right","Up","Down","B","Y"}) do if buttons[k] then names[#names+1]=k end end
  local keys=table.concat(names,"+")
  local allowed={waypoint=true,recover_ball=true,precision_approach=true,local_search=true,goal_approach=true,shot_charge=true,shot_release=true,await_goal_observation=true,stuck_recovery=true,recovery_completed=true,recovery_retry=true,delayed_observation=true,movement_detected=true,movement_observed_ball_only=true}
  if allowed[reason] then joypad.set(buttons,1) else release();armed=false;pending=true;grace_exit=s.frame+300;attempt.exit_reason=reason end
  if attempt.last_remaining and s.remaining and s.remaining<attempt.last_remaining and s.remaining>=0 and s.remaining<=5 then
   local drop=attempt.last_remaining-s.remaining
   if drop==1 then
    attempt.flags_seen=attempt.flags_seen+1
    if attempt.proximity[attempt.flags_seen] then attempt.proximity[attempt.flags_seen].collected=true end
    write(csv_dir.."/dribble_flag_timing_v035.csv",{attempt.id,attempt.flags_seen,s.frame,attempt.last_remaining,s.remaining,
      s.frame-attempt.started,s.frame-attempt.last_flag_frame,s.px,s.py,s.bx,s.by,s.time,s.bonus},13)
    write(csv_dir.."/dribble_active_flag_timing_v035.csv",{attempt.id,attempt.flags_seen,s.frame,
      attempt.active.active_frame,
      attempt.active.active_frame and s.frame-attempt.active.active_frame or nil,
      s.frame-attempt.last_flag_frame},6)
    local segment=Benchmark.flag(attempt.route,attempt.flags_seen,s,attempt.active)
    if segment then
     write(csv_dir.."/dribble_route_segments_v035.csv",{attempt.id,segment.number,segment.frame,
      segment.segment_frames,segment.baseline_frames,segment.delta_frames,segment.start_basis,
      segment.px,segment.py,segment.bx,segment.by,segment.poss,segment.time,
      segment.remaining,segment.active_frame,segment.valid_start and 1 or 0},16)
    end
    local travel,elapsed,samples=RouteV1.summary(attempt.route_v1,attempt.flags_seen)
    local segment_mode=attempt.flags_seen==route_flag and attempt.route_mode or "DIRECT_LINE"
    write(csv_dir.."/dribble_route_optimization_v1.csv",
     {attempt.id,attempt.flags_seen,"flag_collected",segment_mode,s.frame,travel,elapsed,samples,s.px,s.py},10)
    attempt.last_flag_frame=s.frame
    local sm=Straight.summary(attempt.straight,attempt.flags_seen)
    write(csv_dir.."/dribble_direct_line_calibration_v2.csv",
     {attempt.id,s.frame,attempt.flags_seen,"flag_collected",nil,nil,nil,nil,nil,
      sm.frames,sm.maximum,sm.average,sm.corrections,sm.diagonal,sm.axis,sm.overshoot,sm.closest},17)
    local metrics=Dash.flag_summary(attempt.dash,attempt.flags_seen,s.frame)
    write(csv_dir.."/dribble_dash_calibration_v3.csv",
     {attempt.id,s.frame,attempt.flags_seen,"flag_collected",nil,nil,nil,
      "flag_counter",attempt.dash.frames[attempt.flags_seen] or 0,
      attempt.dash.starts[attempt.flags_seen] or 0,attempt.dash.stops[attempt.flags_seen] or 0,
      metrics.off_cause,nil,metrics.minimum,metrics.frames_since_off},15)
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
   write(csv_dir.."/dribble_initial_calibration_v035.csv",{attempt.id,c.start,c.finish,
     c.first_player,c.first_ball,c.first_possession_change,c.classification,c.outcome},8)
   attempt.calibration_written=true
  end
  if state.sync_result and not attempt.sync_written then
   local q=state.sync_result
   write(csv_dir.."/dribble_start_sync_v035.csv",{attempt.id,q.arm,q.first_ball,
    q.first_player,q.timer_change,q.initial_time,q.final_time,q.finish,q.clock_status},9)
   attempt.sync_written=true
  end
  if state.event~="" then print("[ISSD.dribble_bot] "..state.event.." frame="..s.frame) end
 elseif pending and grace_exit and emu.framecount()>=grace_exit then
  observe_result()
  end_attempt()
 else
  observe_result()
  release()
 end
 emu.frameadvance()
end
