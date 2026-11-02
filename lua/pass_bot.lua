-- PASS LV.1 v0.1: observational runner. No speculative RAM writes or automatic pass inputs.
-- Runtime: BizHawk NLua (SNES). Operator commands: ARM, STOP.
local root=assert(_G.ISSD_PROJECT_ROOT,"Launch from main.lua")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance
  and joypad and joypad.set,"BizHawk APIs missing")
local Probe=require("challenge.probe")
local Tracking=require("challenge.pass_tracking_v02")
local Possession=require("challenge.pass_possession_monitor_v03")
local Spatial=require("challenge.pass_spatial_v04")
local Timers=require("challenge.pass_timers_v05")
local Bonus=require("challenge.pass_bonus_validation_v051")
local Auto=require("challenge.pass_auto_v071")
-- Reload the experimental modules on every main.lua start (BizHawk Lua state may persist).
package.loaded["challenge.pass_alignment_v08"]=nil
package.loaded["challenge.pass_auto_v071"]=nil
package.loaded["challenge.pass_bridge_v083"]=nil
local Alignment=require("challenge.pass_alignment_v08")
local Bridge=require("challenge.pass_bridge_v083")
package.loaded["challenge.pass_possession_gate_v0812"]=nil
package.loaded["challenge.pass_active_alignment_v0818"]=nil
package.loaded["challenge.pass_alignment_ball_v0817"]=nil
package.loaded["challenge.pass_feet_v0815"]=nil
package.loaded["challenge.pass_relay_v0810"]=nil
package.loaded["challenge.pass_priority_v087"]=nil
package.loaded["challenge.pass_ordered_v0820"]=nil
local Priority=require("challenge.pass_priority_v087")
local Ordered=require("challenge.pass_ordered_v0820")
package.loaded["challenge.pass_early_v0865"]=nil
local Early=require("challenge.pass_early_v0865")
assert(Early.VERSION=="0.8.70" and Early.TARGET_DISTANCE==160 and Early.MAX_DISTANCE==180,
  "v0.8.70 requires updated challenge.pass_early_v0865; restart main.lua")
local Reach=require("challenge.pass_reach_v0863")
assert(type(Ordered.observe)=="function" and type(Ordered.step)=="function",
  "v0.8.23 requires updated challenge.pass_ordered_v0820; restart main.lua")
local Feet=require("challenge.pass_feet_v0815")
Auto=require("challenge.pass_auto_v071")
package.loaded["challenge.goal_evidence_v4"]=nil
package.loaded["challenge.pass_goal_evidence_v0826"]=nil
local GoalEvidence=require("challenge.pass_goal_evidence_v0826")
local Finish=require("challenge.pass_finish_v07")
local GoalStadium=require("challenge.pass_goal_stadium_v0866")
local Commands=require("challenge.dribble_commands_v035")
local function mkdir(p) os.execute('mkdir "'..p..'" >nul 2>&1') end
mkdir(root.."/csv"); mkdir(root.."/txt")
local log_path=root.."/csv/pass_lv1_observations_v01.csv"
local command_path=root.."/txt/pass_bot_commands_v01.txt"
local function csv(v,n)
  local out={}
  for i=1,n do out[i]='"'..tostring(v[i]==nil and "" or v[i]):gsub('"','""')..'"' end
  return table.concat(out,",").."\n"
end
local f=assert(io.open(log_path,"ab"))
if f:seek("end")==0 then
  assert(f:write("session,frame,event,armed,challenge_status,challenge,level,challenge_a,challenge_b,selected_level,reason\n"))
end
f:close()
local session=os.date("!%Y%m%dT%H%M%SZ")
local goal_monitor=nil
local map_path=root.."/pass_ram_map_v02.lua"
local map=nil
local map_file=io.open(map_path,"rb")
if map_file then
 map_file:close()
 local ok,loaded=pcall(dofile,map_path)
 if ok then
  local valid,reason=Tracking.validate(loaded)
  if valid then map=loaded else print("[ISSD.pass_lv1] invalid RAM map: "..reason) end
 else print("[ISSD.pass_lv1] RAM map load failed: "..tostring(loaded)) end
end
local snapshot_sequence=0
local function dump_wram(label)
  if not label:match("^[A-Z0-9_]+$") or #label>32 then
    print("[ISSD.pass_lv1] invalid SNAP label (A-Z, 0-9, _, max 32)")
    return
  end
  snapshot_sequence=snapshot_sequence+1
  local stamp=string.format("%s_%06d_%s",session,snapshot_sequence,label)
  local path=root.."/csv/pass_wram_"..stamp..".bin"
  local h=assert(io.open(path,"wb"))
  -- SNES WRAM memory domain is 128 KiB; capture is read-only.
  for base=0,0x1ffff,1024 do
    local bytes={}
    for addr=base,base+1023 do
      local ok,v=pcall(memory.read_u8,addr,"WRAM")
      if not ok or type(v)~="number" or v<0 or v>255 then
        h:close();os.remove(path)
        print("[ISSD.pass_lv1] WRAM snapshot failed at "..string.format("0x%05X",addr))
        return
      end
      bytes[#bytes+1]=string.char(v)
    end
    assert(h:write(table.concat(bytes)))
  end
  assert(h:close())
  local meta_path=root.."/csv/pass_wram_snapshots_v02.csv"
  local m=io.open(meta_path,"ab")
  if m then
    if m:seek("end")==0 then m:write("session,frame,label,path,bytes,armed\n") end
    m:write(csv({session,emu.framecount(),label,"pass_wram_"..stamp..".bin",131072,armed and 1 or 0},6))
    m:close()
  end
  print("[ISSD.pass_lv1] captured "..path)
end
local tracker=Tracking.new_tracker(3)
local possession=Possession.new({minimum=3})
local spatial=Spatial.new({threshold=24,gap=6,stable=4})
local autopass=Auto.new()
local finish=Finish.new()
local auto_finish_queued=false
local selected_pass_button=nil
local pending_auto=false
local selected_direction="AUTO"
local trigger_mode="A"
local calibration_mode="A"
local timers=Timers.new()
local bonus=Bonus.new()
local completion_frame=nil
local last_spatial_frame=nil
local bonus_csv=root.."/csv/pass_bonus_validation_v051.csv"
local bf=assert(io.open(bonus_csv,"ab"))
if bf:seek("end")==0 then assert(bf:write("session,frame,event,previous_bonus,current_bonus,time_bcd,bonus_fraction,time_fraction,spatial_count,completion_frame,delta_frames,evidence\n")) end
bf:close()
local function bonus_write(e)
 local h=assert(io.open(bonus_csv,"ab"))
 assert(h:write(csv({session,e.frame,e.kind,e.previous_bonus,e.bonus,e.time,e.bonus_frac,e.time_frac,e.spatial_count,e.completion_frame,e.delta_frames,e.evidence},12)))
 assert(h:close())
end
local timer_csv=root.."/csv/pass_timers_v05.csv"
local timer_file=assert(io.open(timer_csv,"ab"))
if timer_file:seek("end")==0 then
 assert(timer_file:write("session,frame,event,time_bcd,time_fraction,bonus_bcd,bonus_fraction,spatial_candidate_count,last_spatial_frame,delta_from_last_spatial,bonus_activation_frame,evidence\n"))
end
timer_file:close()
local function timer_write(e)
 local count=0
 for _ in pairs(spatial.visited) do count=count+1 end
 local delta=last_spatial_frame and e.frame-last_spatial_frame or nil
 local h=assert(io.open(timer_csv,"ab"))
 assert(h:write(csv({session,e.frame,e.kind,e.time,e.time_frac,e.bonus,e.bonus_frac,
 count,last_spatial_frame,delta,timers.bonus_activation_frame,"timer_transition_unverified"},12)))
 assert(h:close())
end
local spatial_path=root.."/csv/pass_spatial_v04.csv"
local sf=assert(io.open(spatial_path,"ab"))
if sf:seek("end")==0 then
 assert(sf:write("session,frame,event,from_player,to_player,ball_x,ball_y,nearest_distance,goalkeeper_distance,visited_count,route,distance_estimate,confidence\n"))
end
sf:close()
local finish_csv=root.."/csv/pass_finish_v07.csv"
local ff=assert(io.open(finish_csv,"ab"))
if ff:seek("end")==0 then assert(ff:write("session,frame,event,completion_frame,first_bonus_decrement,shot_frame,evidence\n")) end
ff:close()
local function finish_write(frame,event)
 local h=assert(io.open(finish_csv,"ab"))
 assert(h:write(csv({session,frame,event,completion_frame,bonus.first_decrement_frame,finish.shot_frame,"operator_confirmed_button_unverified_goal"},7)))
 assert(h:close())
end
local goal_evidence_csv=root.."/csv/pass_goal_evidence_v0826.csv"
local gfh=assert(io.open(goal_evidence_csv,"ab"))
if gfh:seek("end")==0 then
 assert(gfh:write("session,frame,event,goal_u16,baseline,delta,gs,ptr,remaining,completion_frame,bonus_frame,shot_frame,classification,evidence\n"))
end
gfh:close()
local function goal_write(frame,event,sample)
 local m=goal_monitor
 if not m then return end
 local h=assert(io.open(goal_evidence_csv,"ab"))
 assert(h:write(csv({session,frame,event,sample and sample.goal,m.baseline,
  sample and sample.goal and sample.goal-m.baseline,
  sample and sample.gs,sample and sample.ptr,sample and sample.remaining,
  m.complete,m.bonus,m.shot,GoalEvidence.classify(m),"passive_counter_unverified_goal"},14)))
 assert(h:close())
end
local trajectory_csv=root.."/csv/pass_shot_trajectory_v0859.csv"
local tf=assert(io.open(trajectory_csv,"ab"))
if tf:seek("end")==0 then
 assert(tf:write("session,frame,elapsed,ball_x,ball_y,goalkeeper_x,goalkeeper_y,goalkeeper_x_gap,goal_counter,phase\\n"))
end
tf:close()
local function trajectory_write(frame,elapsed,sample,phase)
 local b=sample and sample.ball
 local gk=sample and sample.goalkeeper
 local c=GoalEvidence.read(memory.read_u8,memory.read_u16_le,frame)
 local h=assert(io.open(trajectory_csv,"ab"))
 assert(h:write(csv({session,frame,elapsed,b and b.x,b and b.y,gk and gk.x,gk and gk.y,
  b and gk and math.abs(gk.x-b.x),c and c.goal,phase},10)))
 assert(h:close())
end
local calibration_csv=root.."/csv/pass_direction_v072.csv"
local cf=assert(io.open(calibration_csv,"ab"))
if cf:seek("end")==0 then assert(cf:write("session,frame,result,from_player,planned_player,observed_player,direction,ball_displacement,pass_frame,transfer_frame,latency_frames\n")) end
cf:close()
local function calibration_write(frame,result,a,observed,transfer_frame)
 local h=assert(io.open(calibration_csv,"ab"))
 local pf=a and a.frame or nil
 assert(h:write(csv({session,frame,result,a and a.from,a and a.to,observed,autopass.direction,
 string.format("%.2f",autopass.ball_max_displacement),pf,transfer_frame,pf and transfer_frame and transfer_frame-pf},11)))
 assert(h:close())
end
local input_csv=root.."/csv/pass_inputs_v081.csv"
local ih=assert(io.open(input_csv,"ab"))
if ih:seek("end")==0 then assert(ih:write("session,frame,phase,reason,holder,target,up,down,left,right,B,X\n")) end
ih:close()
local function log_input(frame,phase,reason,holder,target,b)
 local h=assert(io.open(input_csv,"ab"))
 assert(h:write(csv({session,frame,phase,reason,holder,target,b.Up and 1 or 0,b.Down and 1 or 0,
 b.Left and 1 or 0,b.Right and 1 or 0,b.B and 1 or 0,b.X and 1 or 0},12)))
 assert(h:close())
end
local candidate_csv=root.."/csv/pass_candidates_v082.csv"
local candidate_file=assert(io.open(candidate_csv,"ab"))
if candidate_file:seek("end")==0 then
 assert(candidate_file:write("session,frame,holder,selector_reason,players,eligible,excluded_holder,excluded_visited,excluded_invalid,candidate_id,dx,dy,distance,misalignment,cost,selected\n"))
end
candidate_file:close()
local function candidate_write(frame,holder,reason,report,selected)
 local h=assert(io.open(candidate_csv,"ab"))
 if report and #report.candidates>0 then
  for _,c in ipairs(report.candidates) do
   assert(h:write(csv({session,frame,holder,reason,report.players,report.eligible,
    report.excluded_holder,report.excluded_visited,report.excluded_invalid,
    c.id,c.dx,c.dy,string.format("%.2f",c.distance),
    string.format("%.2f",c.misalignment),string.format("%.2f",c.cost),
    selected and c.id==selected.id and 1 or 0},16)))
  end
 else
  assert(h:write(csv({session,frame,holder,reason,
   report and report.players,report and report.eligible,
   report and report.excluded_holder,report and report.excluded_visited,
   report and report.excluded_invalid},16)))
 end
 assert(h:close())
end
local gates_csv=root.."/csv/pass_runtime_gates_v084.csv"
local gh=assert(io.open(gates_csv,"ab"))
if gh:seek("end")==0 then assert(gh:write("session,frame,gate,armed,enabled,finished,has_sample,holder,phase,probe_status,reason\n")) end
gh:close()
local auto_csv=root.."/csv/pass_auto_v06.csv"
local af=assert(io.open(auto_csv,"ab"))
if af:seek("end")==0 then assert(af:write("session,frame,event,from_player,to_player,button,reason\n")) end
af:close()
local function auto_write(frame,event,from,to,button,reason)
 local h=assert(io.open(auto_csv,"ab"))
 assert(h:write(csv({session,frame,event,from,to,button,reason},7)))
 assert(h:close())
end
local trigger_csv=root.."/csv/pass_trigger_v0811.csv"
local trigger_header=assert(io.open(trigger_csv,"ab"))
if trigger_header:seek("end")==0 then
 assert(trigger_header:write("session,frame,mode,phase,reason,holder,target,ball_x,ball_y,holder_x,holder_y,distance,up,down,left,right,B\n"))
end
trigger_header:close()
local function trigger_write(frame,mode,phase,reason,holder,target,sample,buttons)
 local hp
 if sample then
  for _,p in ipairs(sample.players or {}) do if p.id==holder then hp=p;break end end
 end
 local ball=sample and sample.ball
 local d=ball and hp and math.sqrt((ball.x-hp.x)^2+(ball.y-hp.y)^2) or nil
 local h=assert(io.open(trigger_csv,"ab"))
 assert(h:write(csv({session,frame,mode,phase,reason,holder,target,
  ball and ball.x,ball and ball.y,hp and hp.x,hp and hp.y,
  d and string.format("%.3f",d),buttons.Up and 1 or 0,
  buttons.Down and 1 or 0,buttons.Left and 1 or 0,
  buttons.Right and 1 or 0,buttons.B and 1 or 0},17)))
 assert(h:close())
end
local function spatial_write(e,sample)
 local planned=Tracking.plan(sample.players,e.to,spatial.visited)
 local h=assert(io.open(spatial_path,"ab"))
 assert(h:write(csv({session,e.frame,e.kind,e.from,e.to,sample.ball.x,sample.ball.y,
 string.format("%.2f",e.distance),string.format("%.2f",e.goalkeeper_distance),
 e.visited_count,planned and table.concat(planned.sequence,">") or "",
 planned and string.format("%.2f",planned.distance) or "",e.confidence},13)))
 assert(h:close())
end
local possession_path=root.."/csv/pass_possession_v03.csv"
local ph=assert(io.open(possession_path,"ab"))
if ph:seek("end")==0 then
 assert(ph:write("session,frame,event,previous_raw,current_raw,player_id,source,confidence\n"))
end
ph:close()
local function possession_write(e,source)
 local h=assert(io.open(possession_path,"ab"))
 assert(h:write(csv({session,e.frame,e.kind,e.previous,e.current,e.player_id,
  source,e.evidence},8)))
 assert(h:close())
end
-- Legacy DRIBBLE possession word 0x00A6 is ONLY A CANDIDATE in PASS.
-- Observe without allowing it to mark a player or a successful pass.
local candidate_addr=0x00A6
local candidate_width=16
local function sample_candidate()
 local address=(map and map.possession_address) or candidate_addr
 local width=(map and map.possession_width) or candidate_width
 local fn=width==8 and memory.read_u8 or memory.read_u16_le
 if type(fn)~="function" then return nil end
 local ok,v=pcall(fn,address,"WRAM")
 if ok and type(v)=="number" then return v end
 return nil
end
local tracking_log=root.."/csv/pass_lv1_tracking_v02.csv"
local tf=assert(io.open(tracking_log,"ab"))
if tf:seek("end")==0 then
 assert(tf:write("session,frame,event,from_player,to_player,visited_count,planned_route,estimated_distance,confidence\n"))
end
tf:close()
local function track_write(row)
 local f=assert(io.open(tracking_log,"ab"));assert(f:write(csv(row,9)));assert(f:close())
end
local armed=false
local previous=nil
local auto_finished=false
local pass_chain={active=false,passes=0,next_frame=0,limit=18,started=false,previous=nil,consecutive_relays=0,route_index=1,approach_frames=0,approach_neutral=false,approach_state={}}
-- v0.8.84 long-range pass trial integrated in the normal relay sequence.
local long_710={phase="ready",start=nil,initial=nil,direction=nil,shot_frame=nil,
 target=nil,origin=nil,trial_kind=nil,returns=0,missing_attempts=0,
 last_holder=nil,return_due=false,walk_ticks=0,walk_start=nil,walk_dir=nil,
 advance_start=nil,advance_origin=nil,advance_target=nil,
 attempts={},cooldown_until=0,receiver_start=nil,carrier_start=nil,
 sidestep_97_count=0,sidestep_97_initial=nil,sidestep_97_blocker=nil,
 sidestep_97_last_cross=nil,sidestep_97_exhausted=false,
 support_attempts={},support_target=nil,original_target=nil,fast_pass=false,
 final_target=nil,final_retries=0,final_next_retry=0,final_last_holder=nil,
 universal_previous_holder=nil,universal_support_cooldown={},queue_target=nil,queue_last_holder=nil,
 watchdog_key=nil,watchdog_start=0,watchdog_last_action=0,watchdog_release_until=0,
 align_start=0,align_origin=nil,align_initial_gap=nil,align_no_progress=0,align_mode=0}
-- Last missing outfield player: player IDs 2..11 (10 players), spatial evidence only.
local function last_missing_710(visited,holder)
 if not visited then return nil end
 local absent,count=nil,0
 for id=2,11 do if not visited[id] then absent=id;count=count+1 end end
 if count==1 and holder~=absent then return absent end
 return nil
end
-- Strict queue: first not-yet-observed outfielder in ascending ID order.
local function first_unvisited(visited,holder)
 if not visited then return nil end
 for id=2,11 do
  if not visited[id] and id~=holder then return id end
 end
 return nil
end
local function lane_blocker(sample,from,to)
 if not sample then return nil end
 local a,b
 for _,p in ipairs(sample.players or {}) do
  if p.id==from then a=p elseif p.id==to then b=p end
 end
 if not a or not b then return nil end
 local dx,dy=b.x-a.x,b.y-a.y
 local denom=dx*dx+dy*dy
 if denom<1 then return nil end
 for _,p in ipairs(sample.players or {}) do
  if p.id~=from and p.id~=to then
   local projection=((p.x-a.x)*dx+(p.y-a.y)*dy)/denom
   if projection>0.10 and projection<0.90 then
    local px,py=a.x+projection*dx,a.y+projection*dy
    local cross=math.sqrt((p.x-px)^2+(p.y-py)^2)
    if cross<=24 then return p.id,cross end
   end
  end
 end
 return nil
end
-- v0.8.90: WRAM coordinates: X grows rightward, Y grows downward.
local function pair_geometry(sample,from,to)
 local xy=Ordered.capture(sample,from,to)
 if not xy then return nil end
 local dx,dy=xy.tx-xy.hx,xy.ty-xy.hy
 local direction=(math.abs(dx)>=math.abs(dy))
   and (dx>=0 and "Right" or "Left")
   or (dy>=0 and "Down" or "Up")
 return {xy=xy,dx=dx,dy=dy,distance=math.sqrt(dx*dx+dy*dy),
         direction=direction}
end
-- Diagonal travel is allowed as movement only, never with B.
local function approach_buttons(g)
 local b={}
 if not g then return b end
 if math.abs(g.dx)>24 then b[g.dx>0 and "Right" or "Left"]=true end
 if math.abs(g.dy)>24 then b[g.dy>0 and "Down" or "Up"]=true end
 return b
end
-- A blocker can become a legal support receiver even if already visited.
local function support_receiver(sample,from,to,blocker)
 if not blocker or blocker==from or blocker==to then return nil end
 if blocker<2 or blocker>11 then return nil end
 local g=pair_geometry(sample,from,blocker)
 if not g or g.distance<28 or g.distance>410 then return nil end
 local second=lane_blocker(sample,from,blocker)
 if second then return nil end
 return g
end
local function carrier_gap(sample,id)
 if not sample or not sample.ball then return nil end
 for _,p in ipairs(sample.players or {}) do
  if p.id==id then
   local dx=sample.ball.x-p.x
   local dy=sample.ball.y-p.y
   return math.sqrt(dx*dx+dy*dy)
  end
 end
 return nil
end
-- Try four neighboring cardinal directions; prefer the one that clears the
-- known blocker without increasing the holder-to-receiver separation much.
local function lane_escape(sample,from,to)
 local g=pair_geometry(sample,from,to)
 if not g then return nil end
 local options={{"Up",0,-12},{"Down",0,12},{"Left",-12,0},{"Right",12,0},
                {"UpRight",12,-12},{"DownRight",12,12},
                {"UpLeft",-12,-12},{"DownLeft",-12,12}}
 local best,best_score=nil,-math.huge
 for _,a in ipairs(options) do
  local shifted={players={},ball=sample.ball}
  for _,p in ipairs(sample.players or {}) do
   local np={id=p.id,x=p.x,y=p.y}
   if p.id==from then np.x=np.x+a[2];np.y=np.y+a[3] end
   shifted.players[#shifted.players+1]=np
  end
  local blocker,cross=lane_blocker(shifted,from,to)
  local ng=pair_geometry(shifted,from,to)
  if ng then
   local score=(not blocker and 1000 or (cross or 0)*3)
       -(ng.distance-g.distance)*2
   if score>best_score then best_score=score;best=a[1] end
  end
 end
 return best
end
local reach=Reach.new()
local reach_path=root.."/csv/pass_reach_v0864.csv"
local rf=assert(io.open(reach_path,"ab"))
if rf:seek("end")==0 then assert(rf:write("session,frame,event,attempt,from_player,planned_player,observed_player,initial_gap,carrier_walk,receiver_walk,combined_walk,ball_path,ball_max_displacement,closest_ball_receiver_gap,final_ball_receiver_gap,reception_class,elapsed,ball_x,ball_y\n")) end
rf:close()
local function reach_emit(event,frame,attempt,receiver,sample,elapsed)
 local h=assert(io.open(reach_path,"ab"))
 assert(h:write(csv({session,frame,event,attempt.id,attempt.from,attempt.to,receiver,
  attempt.initial,attempt.walk,attempt.receiver_walk,attempt.combined_walk,
  attempt.ball_path,attempt.ball_max,attempt.closest_gap,attempt.receiver_final_gap,
  attempt.reception_class,elapsed,
  sample and sample.ball and sample.ball.x,sample and sample.ball and sample.ball.y},19)))
 assert(h:close())
end
local previous_gate=nil
local function gate_write(frame,gate,reason,p,sample)
 local signature=table.concat({gate,tostring(armed),tostring(autopass.enabled),
  tostring(auto_finished),tostring(sample~=nil),tostring(spatial.holder),
  tostring(autopass.phase),tostring(reason)},"|")
 if signature==previous_gate then return end
 previous_gate=signature
 local h=assert(io.open(gates_csv,"ab"))
 assert(h:write(csv({session,frame,gate,armed and 1 or 0,autopass.enabled and 1 or 0,
  auto_finished and 1 or 0,sample and 1 or 0,spatial.holder,autopass.phase,p.status,reason},11)))
 assert(h:close())
end
-- v0.8.74: ball-to-carrier telemetry. The existing Ordered.step
-- possession guard remains authoritative.
local function ball_gap_710(sample)
 if not sample or not sample.ball then return nil end
 for _,p in ipairs(sample.players or {}) do
  if p.id==7 then
   local dx=sample.ball.x-p.x;local dy=sample.ball.y-p.y
   return math.sqrt(dx*dx+dy*dy)
  end
 end
 return nil
end
local function release() joypad.set({},1) end
local function record(event,p)
  local raw=p.raw or {}
  local row={session,emu.framecount(),event,armed and 1 or 0,p.status,p.challenge,p.level,
    raw.challenge_a,raw.challenge_b,raw.selected_level,p.reason}
  local h=assert(io.open(log_path,"ab"));assert(h:write(csv(row,11)));assert(h:close())
end
local function observe()
  local p=Probe.read(memory.read_u8)
  local key=table.concat({p.status or "",p.challenge or "",p.level or "",p.reason or ""},"|")
  if key~=previous then record("state_change",p);previous=key end
  return p
end
local commands=Commands.new(command_path,function(message)
  print("[ISSD.pass_lv1] "..message)
end)
print("[ISSD.pass_lv1] observation default; experimental input is opt-in; PASS success signals unverified")
print("[ISSD.pass_lv1] selector_version="..tostring(Alignment.VERSION).." selector_api="..tostring(Alignment.API).." bridge="..Bridge.VERSION)
local integration_ok,integration_result=pcall(Bridge.selftest,Alignment,Auto)
if integration_ok then
 print("[ISSD.pass_lv1] integration_selftest=PASS holder=6 eligible="..tostring(integration_result.eligible).." target="..tostring(integration_result.target))
else
 print("[ISSD.pass_lv1] integration_selftest=FAIL "..tostring(integration_result))
end
print("[ISSD.pass_lv1] commands="..command_path.." log="..log_path)
release()
while true do
  local p=observe()
  local sample_for_auto=nil
  if armed then
   local ss,err=Spatial.read(memory.read_s16_le)
   sample_for_auto=ss
   if ss then
    local event=spatial:step(ss,emu.framecount())
    if event then
     last_spatial_frame=event.frame
     if not completion_frame and event.visited_count==10 then completion_frame=event.frame end
     spatial_write(event,ss)
    end
   elseif not spatial.read_error_logged then
    print("[ISSD.pass_lv1] spatial read error: "..tostring(err))
    spatial.read_error_logged=true
   end
   local ts=Timers.read(memory.read_u8,memory.read_u16_le)
   local te=timers:step(ts,emu.framecount())
   if te then timer_write(te) end
   local count=0;for _ in pairs(spatial.visited) do count=count+1 end
   local be=bonus:step(emu.framecount(),ts,count,completion_frame)
   if be then bonus_write(be) end
   local raw=sample_candidate()
   local player_id=nil
   if map and raw~=nil then
    for _,entity in ipairs(map.players) do
     if entity.possession_value==raw then player_id=entity.id;break end
    end
   end
   local e=possession:step(emu.framecount(),raw,player_id)
   if e then possession_write(e,map and "operator_ram_map" or "legacy_dribble_00A6_hypothesis") end
  end
  if map and armed and p.status=="candidate" and p.challenge=="PASS" and p.level==1 then
   local sample,reason=Tracking.sample(map,memory.read_u8,memory.read_u16_le,memory.read_s16_le)
   if sample then
    local event=tracker:step(sample,emu.framecount())
    if event then
     local count=0
     for _ in pairs(tracker.visited) do count=count+1 end
     local planned=Tracking.plan(sample.players,event.to,tracker.visited)
     local route=planned and table.concat(planned.sequence,">") or ""
     track_write({session,event.frame,event.kind,event.from,event.to,count,route,
       planned and string.format("%.3f",planned.distance) or "","unverified_ram_candidate"})
    end
   elseif not tracker.read_error_logged then
    print("[ISSD.pass_lv1] tracking read error: "..tostring(reason))
    tracker.read_error_logged=true
   end
  end
  commands.poll(function(line)
    local cmd=line:upper()
    if cmd=="TRIGGER:A" or cmd=="TRIGGER:B" then
      if armed then print("[ISSD.pass_lv1] TRIGGER mode requires a new ARM")
      else trigger_mode=cmd:sub(9);print("[ISSD.pass_lv1] trigger experiment="..trigger_mode) end
    elseif cmd=="FINISH:ON" then
      if armed then print("[ISSD.pass_lv1] FINISH:ON requires next ARM")
      else
        auto_finish_queued=true
        print("[ISSD.pass_lv1] FINISH queued for next ARM; one X shot only after 10/10 and bonus countdown")
      end
    elseif cmd=="FINISH:OFF" then
      auto_finish_queued=false;finish.enabled=false;release()
    elseif cmd=="CALIB:A" or cmd=="CALIB:B" then
      if armed and not auto_finished then
        print("[ISSD.pass_lv1] CALIB requires a new ARM")
      else
        calibration_mode=cmd:sub(7)
        print("[ISSD.pass_lv1] pass calibration="..calibration_mode..
          (calibration_mode=="A" and " cardinal" or " diagonal"))
      end
    elseif cmd:match("^DIRECTION:") then
      local direction=cmd:sub(11)
      local valid={AUTO=true,NEUTRAL=true,Up=true,Down=true,Left=true,Right=true,
       Up_Left=true,Up_Right=true,Down_Left=true,Down_Right=true}
      local normalized=direction:gsub("^UP","Up"):gsub("^DOWN","Down"):gsub("^LEFT","Left"):gsub("^RIGHT","Right")
      normalized=normalized:gsub("_UP","_Up"):gsub("_DOWN","_Down"):gsub("_LEFT","_Left"):gsub("_RIGHT","_Right")
      if valid[normalized] then
        selected_direction=normalized;autopass.enabled=false;pending_auto=false
        print("[ISSD.pass_lv1] selected pass direction: "..selected_direction)
      else print("[ISSD.pass_lv1] invalid DIRECTION: "..direction) end
    elseif cmd=="AUTO:ON" then
      if selected_pass_button then
       pending_auto=true;print("[ISSD.pass_lv1] AUTO queued ON for next ARM")
      else print("[ISSD.pass_lv1] AUTO denied: configure PASSBTN:A/B/X/Y/L/R first") end
    elseif cmd=="AUTO:OFF" then
      pending_auto=false;autopass.enabled=false;finish.enabled=false;pass_chain.active=false;release()
      auto_write(emu.framecount(),"auto_off",nil,nil,selected_pass_button,"operator")
    elseif cmd:match("^PASSBTN:[ABXYLR]$") then
      selected_pass_button=cmd:sub(9)
      autopass.enabled=false;pending_auto=false;release()
      print("[ISSD.pass_lv1] experimental pass button="..selected_pass_button.." (requires AUTO:ON and ARM)")
    elseif cmd=="ARM" or cmd=="REARM" then
      if cmd=="REARM" and not (armed and auto_finished and selected_pass_button=="B") then
        print("[ISSD.pass_lv1] REARM rejected: requires completed attempt and PASSBTN:B")
      else
      if cmd=="REARM" then pending_auto=true;print("[ISSD.pass_lv1] REARM accepted: fresh single chain") end
      -- Probe is not proof of gameplay; explicit LV.1 selection is a safety gate.
      if p.status=="candidate" and p.challenge=="PASS" and p.level==1 then
        armed=true;reach=Reach.new();tracker=Tracking.new_tracker(3);possession=Possession.new({minimum=3});spatial=Spatial.new({threshold=24,gap=6,stable=4});timers=Timers.new();bonus=Bonus.new();completion_frame=nil;last_spatial_frame=nil;autopass=Auto.new();finish=Finish.new();goal_monitor=GoalEvidence.new(GoalEvidence.read(memory.read_u8,memory.read_u16_le,emu.framecount()));finish.enabled=auto_finish_queued;auto_finish_queued=false
        autopass.enabled=pending_auto and selected_pass_button=="B";autopass.button=selected_pass_button;autopass.start_frame=emu.framecount();autopass.direction=selected_direction;autopass.trigger_delay=trigger_mode=="B" and 12 or 0;autopass.calibration_mode=calibration_mode
        pending_auto=false;auto_finished=false;previous_gate=nil
        pass_chain={active=autopass.enabled,passes=0,next_frame=0,limit=18,started=false,previous=nil,consecutive_relays=0,route_index=1,approach_frames=0,approach_neutral=false,approach_state={}}
        auto_write(emu.framecount(),autopass.enabled and "auto_arm" or "observation_arm",nil,nil,selected_pass_button,"opt_in_required")
        record("armed_candidate_only",p)
        print("[ISSD.pass_lv1] armed for observation; PASS LV.1 identity remains unconfirmed")
      else
        armed=false;autopass.enabled=false;finish.enabled=false;record("arm_rejected",p)
        print("[ISSD.pass_lv1] ARM rejected: PASS LV.1 candidate not observed")
      end
      end
    elseif cmd:match("^SNAP:[A-Z0-9_]+$") then
      dump_wram(cmd:sub(6))
    elseif cmd=="STOP" then
      armed=false;autopass.enabled=false;finish.enabled=false;pending_auto=false;auto_finish_queued=false;pass_chain.active=false;record("stopped",p);release()
    else
      print("[ISSD.pass_lv1] unknown command: "..line)
    end
  end)
  -- Experimental control is explicitly opt-in; no RAM writes, no auto shot.
  local buttons={}
  local gate="ready"
  local gate_reason="ready"
  if not armed then gate="blocked";gate_reason="not_armed"
  elseif not autopass.enabled then gate="blocked";gate_reason="auto_disabled"
  elseif auto_finished then gate="blocked";gate_reason="already_finished"
  elseif not sample_for_auto then gate="blocked";gate_reason="missing_spatial_sample"
  elseif not integration_ok then gate="blocked";gate_reason="integration_selftest_failed"
  elseif not spatial.holder then gate="waiting";gate_reason="no_stable_holder" end
  gate_write(emu.framecount(),gate,gate_reason,p,sample_for_auto)
  -- Continuous mode: the first stable carrier also counts toward ten outfield players.
  if pass_chain.active and not pass_chain.started and spatial.holder
      and spatial.holder>=2 and spatial.holder<=11 then
    pass_chain.started=true
    spatial.visited[spatial.holder]=true
    auto_write(emu.framecount(),"chain_initial_player",nil,spatial.holder,selected_pass_button,"visited=1/10")
  end
  local chain_visits=0
  for id in pairs(spatial.visited) do if type(id)=="number" and id>=2 and id<=11 then chain_visits=chain_visits+1 end end
  if pass_chain.active and chain_visits>=10 then
    pass_chain.active=false;autopass.enabled=false;auto_finished=true
    auto_write(emu.framecount(),"chain_complete_candidate",nil,spatial.holder,selected_pass_button,
      "visited=10/10|spatial_only|no_auto_shot")
    print("[ISSD.pass_lv1] chain candidate complete: 10/10 outfield players; FINISH="..tostring(finish.enabled))
  end
  -- v0.8.5: lack of a stable holder is a transient wait, not a terminal failure.
  -- Timeout is measured from ARM and never emits controller input.
  local holder_pending=armed and autopass.enabled and not auto_finished
    and autopass.phase=="idle" and not spatial.holder
  if holder_pending and autopass.start_frame
      and emu.framecount()-autopass.start_frame>=180 then
    autopass.enabled=false;auto_finished=true
    auto_write(emu.framecount(),"single_pass_result",nil,nil,selected_pass_button,"holder_detection_timeout")
    calibration_write(emu.framecount(),"holder_detection_timeout",nil,nil,nil)
    print("[ISSD.pass_lv1] single-pass result: holder_detection_timeout")
  end
  -- Priority lock: normal approach/repeat must not compete with recovery.
  -- v0.8.99: active diagonal alignment for any holder/first-unvisited pair.
  local align_target=first_unvisited(spatial.visited,spatial.holder)
  local align_g=align_target and pair_geometry(sample_for_auto,spatial.holder,align_target)
  local align_gap=spatial.holder and carrier_gap(sample_for_auto,spatial.holder)
  if armed and pass_chain.active and autopass.enabled and not auto_finished and
      long_710.phase=="ready" and align_g and align_gap and align_gap<=18 and
      math.abs(align_g.dy)>100 and
      long_710.align_no_progress<3 then
    long_710.phase="align"
    long_710.origin=spatial.holder
    long_710.target=align_target
    long_710.align_start=emu.framecount()
    long_710.align_origin={x=align_g.xy.hx,y=align_g.xy.hy}
    long_710.align_initial_gap=align_g.distance
    long_710.watchdog_last_action=emu.framecount()
    auto_write(emu.framecount(),"queue_alignment_started",long_710.origin,align_target,"B",
      "dx="..align_g.dx.."|dy="..align_g.dy..
      "|direction="..align_g.direction.."|distance="..string.format("%.2f",align_g.distance))
  end
  -- v0.8.98: do not let an idle special-route priority lock the ordinary controller.
  local wd_frame=emu.framecount()
  local wd_target=first_unvisited(spatial.visited,spatial.holder)
  local wd_key=tostring(spatial.holder)..":"..tostring(wd_target)
  if wd_key~=long_710.watchdog_key then
    long_710.align_no_progress=0;long_710.align_mode=0
    long_710.watchdog_key=wd_key
    long_710.watchdog_start=wd_frame
    long_710.watchdog_last_action=wd_frame
    long_710.watchdog_release_until=0
  end
  if long_710.phase=="ready" and wd_target and
     wd_frame-long_710.watchdog_last_action>=90 then
    long_710.watchdog_release_until=wd_frame+48
    long_710.watchdog_last_action=wd_frame
    long_710.attempts={}
    long_710.cooldown_until=0
    auto_write(wd_frame,"queue_watchdog_release",spatial.holder,wd_target,"B",
      "reason=special_route_idle|release_frames=48")
  end
  local wd_released=wd_frame<long_710.watchdog_release_until
  local priority_missing=last_missing_710(spatial.visited,spatial.holder)
  local relay_97=pass_chain.active and spatial.holder==9 and not spatial.visited[7]
      and not long_710.sidestep_97_exhausted
  local priority_lock=pass_chain.active and not wd_released and
      (priority_missing~=nil or relay_97 or long_710.return_due or
       long_710.phase=="align" or long_710.phase=="sidestep" or long_710.phase=="advance" or long_710.phase=="face" or
       long_710.phase=="observe")
  if armed and autopass.enabled and not auto_finished and sample_for_auto
      and not priority_lock
      and (spatial.holder or autopass.phase~="idle")
      and (not pass_chain.active or emu.framecount()>=pass_chain.next_frame) then
    local holder=spatial.holder
    local plan,selector_reason,bridge_info,priority_stage
    if holder and integration_ok then
      -- Start at strict geometry on each fresh attempt, relax only if no route.
      Feet.set_level(autopass.relax_level or 0)
      plan,selector_reason,bridge_info,priority_stage=Priority.resolve(Bridge,Alignment,sample_for_auto,holder,spatial.visited,pass_chain.previous,pass_chain.consecutive_relays,autopass.retargets>0 and {[autopass.rejected_target]=true} or nil,pass_chain.route_index)
      -- Adaptive thresholds remain defined, but ordered mode approaches the exact
      -- requested player rather than broadening the search to another target.
      if false then
        while not plan and (autopass.relax_level or 0)<Feet.MAX_LEVEL do
          autopass.relax_level=(autopass.relax_level or 0)+1
          local range,lateral=Feet.set_level(autopass.relax_level)
          auto_write(emu.framecount(),"limits_expanded",holder,nil,selected_pass_button,
            "level="..autopass.relax_level.."|range="..range.."|lateral="..lateral)
          plan,selector_reason,bridge_info,priority_stage=Priority.resolve(Bridge,Alignment,sample_for_auto,holder,spatial.visited,pass_chain.previous,pass_chain.consecutive_relays,autopass.retargets>0 and {[autopass.rejected_target]=true} or nil)
        end
        if not plan then
          auto_write(emu.framecount(),"limits_exhausted",holder,nil,selected_pass_button,
            "level="..tostring(autopass.relax_level).."|range="..Feet.MAX_RANGE.."|lateral="..Feet.MAX_LATERAL)
        end
      end
    elseif not integration_ok then selector_reason="integration_selftest_failed"
    else selector_reason="no_stable_holder" end
    -- v0.8.70: do not dispatch a 7->10 pass just because the general
    -- passing radius (190 WRAM) has been reached. Approach to <=180 instead.
    -- This applies to normal plans as well as the earlier experimental path.
    -- 160 is the desired proximity; 180 is the bounded release threshold.
    if pass_chain.active and autopass.phase=="idle" and holder==7
       and plan and plan.target==10 then
      local close=Feet.measure(sample_for_auto,7,10)
      if not close or close.distance>Early.MAX_DISTANCE
         or close.lateral>Early.MAX_LATERAL then
        plan=nil
        selector_reason="approach_required"
        bridge_info=bridge_info or {}
        bridge_info.target=10
      end
    end
    local report=bridge_info and bridge_info.report
    local receiver=plan and {id=plan.target,aligned=plan.aligned}
    if autopass.phase=="idle" and holder then
      candidate_write(emu.framecount(),holder,selector_reason,report,receiver)
      auto_write(emu.framecount(),"handoff_diagnostic",holder,
       bridge_info and bridge_info.receiver_id,selected_pass_button,
       "module="..tostring(Alignment.VERSION).."|selector="..tostring(bridge_info and bridge_info.reason or selector_reason)..
       "|receiver="..tostring(bridge_info and bridge_info.receiver_id).."|plan="..tostring(plan and plan.target).."|priority_stage="..tostring(priority_stage).."|route_score="..tostring(bridge_info and bridge_info.route_score).."|route_version=0.8.10|relay_mode="..tostring(bridge_info and bridge_info.relay_mode))
    end
    if autopass.phase=="idle" and bridge_info and bridge_info.route_evaluated then
      for rank,c in ipairs(bridge_info.route_evaluated) do
        auto_write(emu.framecount(),"route_candidate",holder,c.id,selected_pass_button,
          "rank="..rank.."|immediate="..string.format("%.2f",c.immediate)..
          "|onward="..string.format("%.2f",c.onward)..
          "|total="..string.format("%.2f",c.total)..
          "|stage="..tostring(priority_stage))
      end
    end
    -- v0.8.76: one optional repeat 7->10, only when 10 was already
    -- actually observed and 11 remains unvisited. Does NOT count a new visit.
    -- The normal 7->11 route is restored when the repeat is consumed.
    if pass_chain.active and holder==7 and autopass.phase=="idle"
       and spatial.visited[10] and not spatial.visited[11]
       and not pass_chain.repeat_710_used then
      if not pass_chain.repeat_710_started then
        pass_chain.repeat_710_started=true
        pass_chain.approach_frames=0
        pass_chain.approach_neutral=false
        pass_chain.approach_state={}
        auto_write(emu.framecount(),"repeat_710_started",7,10,selected_pass_button,
          "already_visited_10=true|count_additional_visit=false")
      end
      local m=Feet.measure(sample_for_auto,7,10)
      plan=nil
      selector_reason="approach_required"
      bridge_info=bridge_info or {}
      bridge_info.target=10
      if m and m.distance<=Early.MAX_DISTANCE and m.lateral<=Early.MAX_LATERAL
         and pass_chain.approach_frames>=Early.MIN_APPROACH then
        local eligible=Early.evaluate(sample_for_auto,7,10,pass_chain.approach_frames,false)
        if eligible then
          plan={sequence={10},target=10,aligned=true,early_710_trial=true}
          pass_chain.repeat_710_used=true
          auto_write(emu.framecount(),"repeat_710_pass_authorized",7,10,selected_pass_button,
            "distance="..tostring(m.distance).."|lateral="..tostring(m.lateral))
        end
      end
    end
    -- 7→10: a single bounded, explicit early trial. Other pairs untouched.
    local early_candidate=false
    local early_distance=nil
    if autopass.phase=="idle" and not plan and selector_reason=="approach_required"
       and pass_chain.active and holder==7 and bridge_info and bridge_info.target==10 then
      local eligible,early_why,m=Early.evaluate(sample_for_auto,holder,10,
        pass_chain.approach_frames or 0,pass_chain.early_710_used)
      if not eligible and m and (pass_chain.approach_frames or 0)%12==0 then
        auto_write(emu.framecount(),"approach_710_close_gate",7,10,selected_pass_button,
          "distance="..string.format("%.2f",m.distance)..
          "|lateral="..string.format("%.2f",m.lateral)..
          "|target="..Early.TARGET_DISTANCE.."|release_max="..Early.MAX_DISTANCE..
          "|reason="..tostring(early_why))
      end
      if eligible then
        plan={sequence={10},target=10,aligned=true,early_710_trial=true}
        early_candidate=true
        early_distance=m.distance
        pass_chain.early_710_used=true
        -- Release continuous RIGHT; Auto.step aims, releases, then presses B.
        pass_chain.approach_neutral=false
        pass_chain.approach_state.burst_remaining=0
        pass_chain.approach_state.burst_buttons=nil
        auto_write(emu.framecount(),"early_710_trial",7,10,selected_pass_button,
          "distance="..string.format("%.2f",m.distance)..
          "|lateral="..string.format("%.2f",m.lateral)..
          "|approach_frames="..tostring(pass_chain.approach_frames)..
          "|max_distance="..Early.MAX_DISTANCE.."|target_distance="..Early.TARGET_DISTANCE..
          "|confidence=experimental_unverified")
      end
    end
    local reason
    local phase_before=autopass.phase
    if autopass.phase=="idle" and not plan and selector_reason=="approach_required"
        and pass_chain.active and holder then
      local target=bridge_info and bridge_info.target
      local movement=pass_chain.approach_state
      movement.current_frame=emu.framecount()
      -- Watchdog for neutral/settle states that never resume an approach.
      if holder==7 and target==10 then
        local coords=Ordered.capture(sample_for_auto,7,10)
        if not coords then
          movement.pair_710_invalid_frames=(movement.pair_710_invalid_frames or 0)+1
          if movement.pair_710_invalid_frames>=3 then
            buttons={};reason="approach_710_invalid_coordinates"
            pass_chain.active=false;autopass.enabled=false;auto_finished=true
            auto_write(emu.framecount(),"approach_710_invalid_coordinates",7,10,selected_pass_button,
              "invalid_frames="..tostring(movement.pair_710_invalid_frames))
          end
        else
          movement.pair_710_invalid_frames=0
        end
        if pass_chain.approach_neutral and (movement.burst_remaining or 0)<=0 then
          movement.pair_710_neutral_frames=(movement.pair_710_neutral_frames or 0)+1
          if movement.pair_710_neutral_frames>=5 then
            pass_chain.approach_neutral=false
            movement.right_followup_left=0
            movement.right_settle_remaining=0
            movement.burst_remaining=0
            movement.burst_buttons=nil
            movement.pair_710_neutral_frames=0
            auto_write(emu.framecount(),"approach_710_neutral_watchdog",7,10,selected_pass_button,
              "action=recalculate_direction|distance="..
                tostring((Feet.measure(sample_for_auto,7,10) or {}).distance))
          end
        else
          movement.pair_710_neutral_frames=0
        end
      end
      local approach_absolute=(holder==7 and target==10) and Ordered.MAX_APPROACH_710_ABSOLUTE or Ordered.MAX_APPROACH_ABSOLUTE
      -- Detect the same X coordinate persisting across Dash observations.
      -- Switch to plain directional running rather than repeating Y in place.
      if holder==7 and target==10 then
        local pos=Ordered.capture(sample_for_auto,7,10)
        if pos then
          local prior=movement.stall_710_last_position
          if prior and math.abs(pos.hx-prior.hx)<0.5 and math.abs(pos.hy-prior.hy)<0.5 then
            movement.stall_710_frames=(movement.stall_710_frames or 0)+1
          else
            movement.stall_710_frames=0
          end
          movement.stall_710_last_position=pos
          if not movement.dash_710_disabled and (movement.stall_710_frames or 0)>=6 then
            movement.dash_710_disabled=true
            movement.burst_remaining=0
            movement.burst_buttons=nil
            pass_chain.approach_neutral=false
            auto_write(emu.framecount(),"approach_710_dash_stall_fallback",7,10,selected_pass_button,
              "holder_x="..tostring(pos.hx).."|holder_y="..tostring(pos.hy)..
              "|receiver_x="..tostring(pos.tx).."|receiver_y="..tostring(pos.ty)..
              "|next=direction_only")
          end
        end
      end
      if holder==7 and target==10 then
        local pos=Ordered.capture(sample_for_auto,7,10)
        if pos and (pass_chain.approach_frames or 0)%4==0 then
          auto_write(emu.framecount(),"approach_710_ab_probe",7,10,selected_pass_button,
            "phase=DIRECTION_ONLY_V0877"..
            "|holder_x="..tostring(pos.hx).."|holder_y="..tostring(pos.hy)..
            "|receiver_x="..tostring(pos.tx).."|receiver_y="..tostring(pos.ty)..
            "|gap="..tostring(ball_gap_710(sample_for_auto)))
        end
        -- Measure relative closing by comparing actual WRAM X positions,
        -- not requested directional input or predicted receiver velocity.
        local current=Ordered.capture(sample_for_auto,7,10)
        local previous=movement.pair_710_relative_sample
        if current then
          if previous and emu.framecount()>previous.frame then
            local dt=emu.framecount()-previous.frame
            local holder_vx=(current.hx-previous.hx)/dt
            local receiver_vx=(current.tx-previous.tx)/dt
            local closing=holder_vx-receiver_vx
            movement.pair_710_closure_samples=movement.pair_710_closure_samples or {}
            table.insert(movement.pair_710_closure_samples,{frame=emu.framecount(),closing=closing})
            while #movement.pair_710_closure_samples>24 do table.remove(movement.pair_710_closure_samples,1) end
            local near_stop=math.abs(receiver_vx)<=0.4
            if near_stop then
              movement.pair_710_slow_frames=(movement.pair_710_slow_frames or 0)+dt
            else
              movement.pair_710_slow_frames=0
            end
            if emu.framecount()%4==0 then
              auto_write(emu.framecount(),"approach_710_relative_closure",7,10,selected_pass_button,
                "holder_vx="..string.format("%.3f",holder_vx)..
                "|receiver_vx="..string.format("%.3f",receiver_vx)..
                "|closing_vx="..string.format("%.3f",closing)..
                "|receiver_slow_frames="..tostring(movement.pair_710_slow_frames)..
                "|holder_x="..tostring(current.hx)..
                "|receiver_x="..tostring(current.tx)..
                "|gap="..tostring(ball_gap_710(sample_for_auto)))
              if movement.pair_710_slow_frames>=8 then
                auto_write(emu.framecount(),"approach_710_receiver_slow_window",7,10,selected_pass_button,
                  "frames="..tostring(movement.pair_710_slow_frames)..
                  "|receiver_x="..tostring(current.tx)..
                  "|closing_vx="..string.format("%.3f",closing))
              end
            end
          end
          movement.pair_710_relative_sample={hx=current.hx,tx=current.tx,frame=emu.framecount()}
        end
        local gap=ball_gap_710(sample_for_auto)
        if gap then
          auto_write(emu.framecount(),"approach_710_ball_gap",7,10,selected_pass_button,
            "gap="..string.format("%.2f",gap)..
            "|dash="..tostring(movement.burst_buttons and movement.burst_buttons.Y==true)..
            "|approach_frames="..tostring(pass_chain.approach_frames or 0))
        end
      end
      if holder==7 and target==10 then
        local v=Ordered.observe_710(movement,sample_for_auto,emu.framecount())
        if v and emu.framecount()%12==0 then
          local measured=Feet.measure(sample_for_auto,7,10)
          auto_write(emu.framecount(),"approach_710_receiver_velocity",7,10,selected_pass_button,
            "vx="..tostring(v.vx).."|vy="..tostring(v.vy)..
            "|distance="..tostring(measured and measured.distance))
        end
      end
      movement.approach_frames=pass_chain.approach_frames or 0
      local approach_limit=movement.approach_limit or Ordered.MAX_APPROACH
      if holder==8 and target==9 and not movement.receiver_last then
        Ordered.observe_receiver(movement,sample_for_auto,emu.framecount(),holder,target)
      end
      if holder==5 and target==8 and movement.right_settle_remaining==nil then
        movement.right_settle_remaining=4
        movement.right_settle_previous=Ordered.capture(sample_for_auto,holder,target)
      end
      if holder==5 and target==8 and (movement.right_settle_remaining or 0)>0 then
        local now=Ordered.capture(sample_for_auto,holder,target)
        local prev=movement.right_settle_previous
        if now and prev then
          auto_write(emu.framecount(),"approach_right_settle",holder,target,selected_pass_button,
            "remaining="..movement.right_settle_remaining..
            "|holder_x="..now.hx.."|holder_y="..now.hy..
            "|target_x="..now.tx.."|target_y="..now.ty..
            "|holder_dx="..(now.hx-prev.hx).."|holder_dy="..(now.hy-prev.hy))
        end
        movement.right_settle_previous=now
        movement.right_settle_remaining=movement.right_settle_remaining-1
        buttons={};reason="approach_right_settle"
      elseif movement.recovery_phase=="awaiting_sample" then
        pass_chain.approach_neutral=true
      end
      -- A dash-separated ball gets three neutral observations, not a forced B.
      -- If the existing 18-WRAM foot guard stays invalid, fail closed.
      if holder==7 and target==10 and (movement.dash_ball_pause or 0)>0 then
        local gap=ball_gap_710(sample_for_auto)
        movement.dash_ball_pause=movement.dash_ball_pause-1
        buttons={};reason="approach_710_dash_ball_neutral"
        if gap and gap<=18 then
          movement.dash_ball_pause=0
          movement.burst_remaining=0;movement.burst_buttons=nil
          pass_chain.approach_neutral=false
          auto_write(emu.framecount(),"approach_710_dash_ball_recovered",7,10,selected_pass_button,
            "gap="..tostring(gap))
        elseif movement.dash_ball_pause==0 then
          buttons={};pass_chain.active=false;autopass.enabled=false;auto_finished=true
          reason="approach_710_dash_ball_unrecovered"
          auto_write(emu.framecount(),"approach_aborted",7,10,selected_pass_button,reason)
        end
      elseif holder==7 and target==10 and
             (movement.burst_buttons and movement.burst_buttons.Y) and
             (ball_gap_710(sample_for_auto) or math.huge)>18 then
        movement.dash_ball_pause=3
        movement.burst_remaining=0;movement.burst_buttons=nil
        buttons={};reason="approach_710_dash_ball_neutral"
        pass_chain.approach_neutral=false
        auto_write(emu.framecount(),"approach_710_dash_ball_pause",7,10,selected_pass_button,
          "gap="..tostring(ball_gap_710(sample_for_auto)).."|neutral_frames=3")
      elseif reason=="approach_right_settle" then
        -- Four neutral frames establish the residual motion baseline.
      elseif (pass_chain.approach_frames or 0)>=approach_limit and not pass_chain.approach_neutral then
        local measurement=Feet.measure(sample_for_auto,holder,target)
        local checkpoint,checkpoint_reason=false,nil
        if holder==7 and target==10 then
          checkpoint,checkpoint_reason=Ordered.goalward_checkpoint(movement,pass_chain.approach_frames,measurement)
        end
        local can_extend,why
        if checkpoint then
          can_extend,why=true,checkpoint_reason
        else
          can_extend,why=Ordered.can_extend(movement,pass_chain.approach_frames,measurement)
        end
        -- Progressive 7->10 budget: extra time only if recent distance or
        -- measured X progress indicates meaningful movement, never unbounded.
        if not can_extend and holder==7 and target==10
           and (pass_chain.approach_frames or 0)<approach_absolute
           and (movement.pair_710_progressive_extensions or 0)<8 then
          local positions=Ordered.capture(sample_for_auto,7,10)
          local last=movement.pair_710_progressive_checkpoint
          if not last and positions then
            movement.pair_710_progressive_checkpoint={
              hx=positions.hx, distance=measurement and measurement.distance}
          elseif last and positions and measurement and
             (positions.hx-last.hx>=12 or last.distance-measurement.distance>=8) then
            can_extend=true;why="pair_710_progressive_distance"
            movement.pair_710_progressive_checkpoint={
              hx=positions.hx,distance=measurement.distance}
            auto_write(emu.framecount(),"approach_710_progressive_extension",7,10,selected_pass_button,
              "holder_x="..tostring(positions.hx)..
              "|distance="..tostring(measurement.distance)..
              "|frames="..tostring(pass_chain.approach_frames))
          end
        end
        if not can_extend and holder==7 and target==10 then
          local recent,recent_reason=Ordered.recent_closure_710(movement,pass_chain.approach_frames,measurement)
          if recent then
            can_extend,why=true,recent_reason
            auto_write(emu.framecount(),"approach_710_recent_closure_extension",7,10,selected_pass_button,
              "frames="..tostring(pass_chain.approach_frames)..
              "|distance="..tostring(measurement and measurement.distance)..
              "|best="..tostring(movement.best_distance)..
              "|limit="..tostring(approach_limit))
          end
        end
        if can_extend and approach_limit<approach_absolute then
          if why=="pair_710_progressive_distance" then
            movement.pair_710_progressive_extensions=(movement.pair_710_progressive_extensions or 0)+1
          end
          if why=="pair_710_recent_measured_closure" then
            movement.pair_710_recent_extensions=(movement.pair_710_recent_extensions or 0)+1
          end
          if why=="goalward_receiver_stage_progress" then
            movement.pair_710_checkpoints=(movement.pair_710_checkpoints or 0)+1
            movement.pair_710_checkpoint_distance=measurement.distance
            auto_write(emu.framecount(),"approach_710_goalward_checkpoint",holder,target,selected_pass_button,
              "stage="..tostring(movement.pair_710_checkpoints)..
              "|distance="..tostring(measurement.distance)..
              "|absolute="..tostring(approach_absolute))
          end
          if why=="pair_89_receiver_escape_progress" then
            movement.pair_89_extension_count=(movement.pair_89_extension_count or 0)+1
          end
          if why=="pair_710_recent_right_progress" then
            movement.pair_710_extension_count=(movement.pair_710_extension_count or 0)+1
          end
          if why=="pair_67_recent_up_progress" then
            movement.pair_67_extension_count=(movement.pair_67_extension_count or 0)+1
          end
          if why=="recent_progress_verified" then
            movement.recent_extension_count=(movement.recent_extension_count or 0)+1
          end
          movement.approach_limit=math.min(approach_limit+Ordered.EXTEND_FRAMES,approach_absolute)
          auto_write(emu.framecount(),"approach_extended",holder,target,selected_pass_button,
            "old_limit="..approach_limit.."|new_limit="..movement.approach_limit..
            "|distance="..tostring(measurement and measurement.distance)..
            "|best="..tostring(movement.best_distance).."|reason="..why)
          buttons={};reason="approach_extension_neutral"
          movement.burst_remaining=0;movement.burst_buttons=nil
          pass_chain.approach_neutral=false
        else
          local recovered,dir=Ordered.recover(movement,measurement,holder,target)
          if recovered and not movement.pair_89_stopped and (pass_chain.approach_frames or 0)<approach_absolute then
            movement.approach_limit=math.min(approach_limit+(movement.recovery_left or 16),approach_absolute)
            movement.burst_remaining=0;movement.burst_buttons=nil
            pass_chain.approach_neutral=false;buttons={};reason="approach_recovery_neutral"
            auto_write(emu.framecount(),"approach_recovery_started",holder,target,selected_pass_button,
              "direction="..dir.."|limit="..movement.approach_limit.."|cause="..why)
          else
          reason="approach_timeout";buttons={};autopass.enabled=false
          pass_chain.active=false;auto_finished=true
          auto_write(emu.framecount(),"approach_timeout",holder,target,selected_pass_button,
            "limit="..approach_limit.."|absolute="..approach_absolute.."|reason="..why)
          end
        end
      elseif pass_chain.approach_neutral and (movement.right_followup_left or 0)>0 then
        buttons={};reason="approach_right_followup"
        local coords=Ordered.capture(sample_for_auto,holder,target)
        if coords then
          auto_write(emu.framecount(),"approach_right_followup",holder,target,selected_pass_button,
            "remaining="..movement.right_followup_left..
            "|holder_x="..coords.hx.."|holder_y="..coords.hy..
            "|target_x="..coords.tx.."|target_y="..coords.ty)
        end
        movement.right_followup_left=movement.right_followup_left-1
      elseif pass_chain.approach_neutral and holder==6 and target==7 and
          movement.pair_67_settle_left==nil and movement.burst_positions then
        local now=Ordered.capture(sample_for_auto,holder,target)
        local before=movement.burst_positions
        if now and math.abs(now.hx-before.hx)+math.abs(now.hy-before.hy)<0.5 then
          movement.pair_67_settle_left=2
          buttons={};reason="approach_67_settle"
          auto_write(emu.framecount(),"approach_67_delayed_motion",holder,target,selected_pass_button,
            "neutral_frames=2|direction="..tostring(movement.burst_direction))
        else
          movement.pair_67_settle_left=0
        end
      elseif pass_chain.approach_neutral and holder==6 and target==7 and
          (movement.pair_67_settle_left or 0)>0 then
        -- Do not assess a temporarily still carrier until two neutral samples.
        buttons={};reason="approach_67_settle"
        movement.pair_67_settle_left=movement.pair_67_settle_left-1
        auto_write(emu.framecount(),"approach_67_neutral_wait",holder,target,selected_pass_button,
          "remaining="..tostring(movement.pair_67_settle_left))
      elseif pass_chain.approach_neutral then
        buttons={};reason="approach_neutral";pass_chain.approach_neutral=false
        local measurement=Feet.measure(sample_for_auto,holder,target)
        if holder==8 and target==9 then
          local obs=Ordered.observe_receiver(movement,sample_for_auto,emu.framecount(),holder,target)
          local forecast=Ordered.receiver_prediction(movement,sample_for_auto,holder,target,emu.framecount())
          if obs then
            auto_write(emu.framecount(),"approach_89_neutral_velocity",holder,target,selected_pass_button,
              "valid="..tostring(obs.valid).."|vx="..tostring(obs.vx).."|vy="..tostring(obs.vy)..
              "|reason="..tostring(obs.reason))
          end
          if forecast then
            auto_write(emu.framecount(),"approach_89_predicted_target",holder,target,selected_pass_button,
              "predicted_x="..tostring(forecast.predicted_x)..
              "|predicted_y="..tostring(forecast.predicted_y)..
              "|dx="..tostring(forecast.dx).."|dy="..tostring(forecast.dy)..
              "|horizon="..tostring(forecast.horizon))
          end
        end
        local motion_feedback=Ordered.observe_motion(movement,sample_for_auto,holder,target)
        local motion=movement.last_motion
        if motion_feedback=="motion_delayed_or_still" then
          movement.still_counts=movement.still_counts or {}
          local k=movement.burst_direction
          if k then
            movement.still_counts[k]=(movement.still_counts[k] or 0)+1
            if movement.still_counts[k]>=3 then
              movement.last_still_direction=k
              movement.penalties=movement.penalties or {}
              movement.penalties[k]=(movement.penalties[k] or 0)+18
              auto_write(emu.framecount(),"approach_direction_still",holder,target,selected_pass_button,
                "direction="..k)
            end
          end
        elseif motion_feedback=="motion_calibrated" then
          movement.still_counts={}
        end
        if motion then
          auto_write(emu.framecount(),"approach_motion_calibration",holder,target,selected_pass_button,
            "result="..motion_feedback.."|direction="..tostring(motion.direction)..
            "|holder_dx="..tostring(motion.holder_dx).."|holder_dy="..tostring(motion.holder_dy)..
            "|receiver_dx="..tostring(motion.target_dx).."|receiver_dy="..tostring(motion.target_dy)..
            "|projection="..tostring(motion.projection))
        end
        movement.burst_positions=nil
        movement.pair_67_settle_left=nil
        if holder==5 and target==8 then
          local right_status,right_delta=Ordered.guard_right(movement,measurement,motion_feedback=="motion_unavailable" and nil or motion)
          if right_status then
            auto_write(emu.framecount(),"approach_right_feedback",holder,target,selected_pass_button,
              "result="..right_status.."|distance_change="..tostring(right_delta)..
              "|projection="..tostring(motion and motion.projection)..
              "|suspended="..tostring(movement.right_suspended))
          end
          if movement.right_suspended then
            -- Controlled retry uses actual target vector and retains the
            -- absolute 210-frame cap; do not kill the chain on one bad burst.
            local used=movement.controlled_58_retries or 0
            local remaining=approach_absolute-(pass_chain.approach_frames or 0)
            local m=Feet.measure(sample_for_auto,5,8)
            if used<2 and remaining>12 and m then
              movement.controlled_58_retries=used+1
              movement.right_suspended=false
              movement.right_58_regressions=0
              movement.right_still=0
              movement.right_small_negative=0
              movement.right_cumulative_regression=0
              movement.burst_remaining=0
              movement.burst_buttons=nil
              pass_chain.approach_neutral=false
              movement.approach_limit=math.min(approach_absolute,
                math.max(movement.approach_limit or Ordered.MAX_APPROACH,
                  (pass_chain.approach_frames or 0)+16))
              buttons={}
              auto_write(emu.framecount(),"approach_58_controlled_retry",5,8,selected_pass_button,
                "retry="..tostring(used+1)..
                "|dx="..tostring(m.dx).."|dy="..tostring(m.dy)..
                "|distance="..tostring(m.distance)..
                "|remaining="..tostring(remaining))
            else
              buttons={};autopass.enabled=false;pass_chain.active=false;auto_finished=true
              auto_write(emu.framecount(),"approach_right_blocked",holder,target,selected_pass_button,
                "reason="..tostring(movement.right_block_reason)..
                "|distance_change="..tostring(right_delta)..
                "|controlled_retries="..tostring(used))
            end
          end
        end
        local diagonal_result,growth,lateral_growth=Ordered.guard_diagonal(movement,measurement)
        if diagonal_result then
          auto_write(emu.framecount(),"approach_diagonal_feedback",holder,target,selected_pass_button,
            "result="..diagonal_result.."|distance_growth="..tostring(growth)..
            "|lateral_growth="..tostring(lateral_growth)..
            "|disabled="..tostring(movement.diagonal_disabled))
        end
        -- 8→9: separate movement of the carrier from movement of the receiver.
        -- Receiver escape is not automatically blamed on the commanded input.
        if holder==8 and target==9 and measurement and movement.burst_start then
          local delta=measurement.distance-movement.burst_start.distance
          local lateral_delta=measurement.lateral-movement.burst_start.lateral
          local m=movement.last_motion
          local carrier=m and m.holder_toward or 0
          local escape=m and m.receiver_away or 0
          local closing=m and m.relative_closing or 0
          if carrier>0.5 then
            movement.pair_89_last_carrier=carrier
            movement.pair_89_carrier_progress_streak=math.min(4,(movement.pair_89_carrier_progress_streak or 0)+1)
            movement.pair_89_carrier_stall=0
            movement.pair_89_last_bad_direction=nil
          elseif delta>1.5 then
            movement.pair_89_carrier_progress_streak=0
            movement.pair_89_carrier_stall=(movement.pair_89_carrier_stall or 0)+1
            movement.pair_89_last_bad_direction=movement.burst_direction
          end
          local receiver_caused=carrier>0.5 and escape>carrier and delta>1.5
          if receiver_caused then
            movement.pair_89_escape_growth=(movement.pair_89_escape_growth or 0)+delta
          elseif delta>1.5 then
            movement.pair_89_total_growth=(movement.pair_89_total_growth or 0)+delta
          elseif delta< -0.5 then
            movement.pair_89_total_growth=math.max(0,(movement.pair_89_total_growth or 0)+delta)
          end
          auto_write(emu.framecount(),"approach_89_relative_feedback",holder,target,selected_pass_button,
            "direction="..tostring(movement.burst_direction)..
            "|holder_toward="..tostring(carrier)..
            "|receiver_away="..tostring(escape)..
            "|closing="..tostring(closing)..
            "|distance_delta="..tostring(delta)..
            "|lateral_delta="..tostring(lateral_delta)..
            "|carrier_stall="..tostring(movement.pair_89_carrier_stall or 0)..
            "|receiver_caused="..tostring(receiver_caused)..
            "|escape_growth="..tostring(movement.pair_89_escape_growth or 0)..
            "|carrier_progress_streak="..tostring(movement.pair_89_carrier_progress_streak or 0))
          -- Receiver-driven separation is logged but does not consume the
          -- carrier-failure growth budget. The global approach cap remains.
          if (movement.pair_89_carrier_stall or 0)>=2 or
             (movement.pair_89_total_growth or 0)>65 then
            buttons={};autopass.enabled=false;pass_chain.active=false;auto_finished=true
            movement.pair_89_stopped=true
            auto_write(emu.framecount(),"approach_89_regression_stop",holder,target,selected_pass_button,
              "carrier_stall="..tostring(movement.pair_89_carrier_stall or 0)..
              "|cumulative_growth="..tostring(movement.pair_89_total_growth))
          end
        end
        if holder==6 and target==7 and measurement and movement.burst_start
          and movement.burst_direction=="Up_Right" then
          local d=measurement.distance-movement.burst_start.distance
          local l=measurement.lateral-movement.burst_start.lateral
          local motion=movement.last_motion
          local moved=motion and (math.abs(motion.holder_dx)+math.abs(motion.holder_dy)) or 0
          movement.pair_67_diagonal_trials=(movement.pair_67_diagonal_trials or 0)+1
          -- A single diagonal can appear to regress because receiver 7
          -- moves concurrently. Keep UP+RIGHT as preferred solution until
          -- persistent regression is measured over at least three bursts.
          if d>2 and l>2 then
            movement.pair_67_diagonal_regressions=(movement.pair_67_diagonal_regressions or 0)+1
          else
            movement.pair_67_diagonal_regressions=0
          end
          if moved<0.5 then
            movement.pair_67_diagonal_stalls=(movement.pair_67_diagonal_stalls or 0)+1
          else
            movement.pair_67_diagonal_stalls=0
          end
          if (movement.pair_67_diagonal_regressions or 0)>=3
             or (movement.pair_67_diagonal_stalls or 0)>=3 then
            movement.pair_67_diagonal_disabled=true
          end
          auto_write(emu.framecount(),"approach_67_diagonal_feedback",holder,target,selected_pass_button,
            "distance_growth="..tostring(d).."|lateral_growth="..tostring(l)..
            "|holder_motion="..tostring(moved)..
            "|trials="..tostring(movement.pair_67_diagonal_trials)..
            "|regressions="..tostring(movement.pair_67_diagonal_regressions or 0)..
            "|stalls="..tostring(movement.pair_67_diagonal_stalls or 0)..
            "|disabled="..tostring(movement.pair_67_diagonal_disabled or false))
        end
        if holder==6 and target==7 and measurement and movement.burst_start then
          local gain=movement.burst_start.distance-measurement.distance
          local lateral_gain=movement.burst_start.lateral-measurement.lateral
          if movement.burst_direction=="Up" and (gain>0.5 or lateral_gain>0.5) then
            movement.pair_67_up_streak=(movement.pair_67_up_streak or 0)+1
            movement.pair_67_last_gain=math.max(gain,lateral_gain)
            movement.pair_67_last_distance=measurement.distance
          elseif movement.burst_direction=="Up" then
            movement.pair_67_up_streak=0
            movement.pair_67_last_gain=0
          end
          auto_write(emu.framecount(),"approach_67_up_feedback",holder,target,selected_pass_button,
            "direction="..tostring(movement.burst_direction)..
            "|distance_gain="..tostring(gain).."|lateral_gain="..tostring(lateral_gain)..
            "|up_streak="..tostring(movement.pair_67_up_streak or 0))
        end
        -- 6→7: distinguish carrier movement from receiver escape, and
        -- prevent consecutive bursts that worsen both distance and lateral.
        if holder==6 and target==7 and measurement and movement.burst_start then
          local motion=movement.last_motion
          local dd=measurement.distance-movement.burst_start.distance
          local dl=measurement.lateral-movement.burst_start.lateral
          local carrier=motion and motion.holder_toward or 0
          local escape=motion and motion.receiver_away or 0
          local closing=motion and motion.relative_closing or 0
          local direction=movement.burst_direction
          if dd>1.5 and dl>1.5 then
            if movement.pair_67_last_regressing_direction==direction then
              movement.pair_67_double_regression=(movement.pair_67_double_regression or 0)+1
            else
              movement.pair_67_double_regression=1
              movement.pair_67_last_regressing_direction=direction
            end
          elseif dd< -0.5 or dl< -0.5 then
            movement.pair_67_double_regression=0
            movement.pair_67_last_regressing_direction=nil
            if direction==movement.pair_67_avoid_direction then
              movement.pair_67_avoid_direction=nil;movement.pair_67_avoid_left=0
            end
          end
          if (movement.pair_67_double_regression or 0)>=2 and direction then
            movement.pair_67_avoid_direction=direction
            movement.pair_67_avoid_left=3
            movement.pair_67_up_streak=0
            movement.good_direction_lock=0
            movement.pair_67_double_regression=0
            auto_write(emu.framecount(),"approach_67_direction_guard",holder,target,selected_pass_button,
              "blocked="..tostring(direction).."|next_decisions=3")
          end
          auto_write(emu.framecount(),"approach_67_relative_feedback",holder,target,selected_pass_button,
            "direction="..tostring(direction).."|holder_toward="..tostring(carrier)..
            "|receiver_away="..tostring(escape).."|closing="..tostring(closing)..
            "|distance_growth="..tostring(dd).."|lateral_growth="..tostring(dl)..
            "|both_regressing="..tostring(dd>1.5 and dl>1.5))
        end
        if holder==7 and target==10 and measurement and movement.burst_start then
          local m=movement.last_motion
          local carrier=m and m.holder_toward or 0
          local escape=m and m.receiver_away or 0
          local closing=m and m.relative_closing or 0
          local gain=movement.burst_start.distance-measurement.distance
          -- Recent geometric progress is separate from the carrier's own motion.
          movement.pair_710_net_samples=movement.pair_710_net_samples or {}
          local net=movement.pair_710_net_samples
          net[#net+1]=gain
          if #net>4 then table.remove(net,1) end
          local recent_net=0
          for _,v in ipairs(net) do recent_net=recent_net+v end
          movement.pair_710_recent_net_gain=recent_net
          auto_write(emu.framecount(),"approach_710_net_progress",holder,target,selected_pass_button,
            "carrier_toward="..tostring(carrier)..
            "|receiver_away="..tostring(escape)..
            "|net_gain_burst="..tostring(gain)..
            "|net_gain_recent="..tostring(recent_net)..
            "|distance="..tostring(measurement.distance))
          if movement.burst_direction=="Right" and carrier>0.5 then
            movement.pair_710_right_streak=math.min(4,(movement.pair_710_right_streak or 0)+1)
            movement.pair_710_last_carrier=carrier
            movement.pair_710_last_distance=measurement.distance
          elseif movement.burst_direction=="Right" then
            movement.pair_710_right_streak=0
            movement.pair_710_last_carrier=carrier
          end
          if movement.burst_direction=="Right" then
            if carrier>0.5 then
              movement.pair_710_right_stalls=0
            else
              movement.pair_710_right_stalls=(movement.pair_710_right_stalls or 0)+1
            end
          end
          auto_write(emu.framecount(),"approach_710_steering_feedback",holder,target,selected_pass_button,
            "direction="..tostring(movement.burst_direction)..
            "|holder_toward="..tostring(carrier)..
            "|receiver_away="..tostring(escape)..
            "|right_stalls="..tostring(movement.pair_710_right_stalls or 0)..
            "|vertical_count="..tostring(movement.pair_710_vertical_count or 0))
          local receiver_goalward=(m and m.target_dx or 0)>0
          if receiver_goalward then
            movement.pair_710_goalward_observations=(movement.pair_710_goalward_observations or 0)+1
          end
          auto_write(emu.framecount(),"approach_710_goalward_feedback",holder,target,selected_pass_button,
            "receiver_dx="..tostring(m and m.target_dx)..
            "|receiver_goalward_candidate="..tostring(receiver_goalward)..
            "|holder_toward="..tostring(carrier)..
            "|receiver_away="..tostring(escape)..
            "|distance="..tostring(measurement.distance)..
            "|checkpoint_count="..tostring(movement.pair_710_checkpoints or 0))
          auto_write(emu.framecount(),"approach_710_relative_feedback",holder,target,selected_pass_button,
            "direction="..tostring(movement.burst_direction)..
            "|holder_toward="..tostring(carrier)..
            "|receiver_away="..tostring(escape)..
            "|closing="..tostring(closing)..
            "|distance_gain="..tostring(gain)..
            "|right_streak="..tostring(movement.pair_710_right_streak or 0))
        end
        local feedback=Ordered.observe(pass_chain.approach_state,measurement)
        if movement.recovery_phase=="awaiting_sample" then
          movement.recovery_phase="evaluated"
        end
        if movement.recovery_probe_failed then
          auto_write(emu.framecount(),"approach_probe_failed",holder,target,selected_pass_button,
            "gain="..tostring(movement.recovery_probe_gain))
          if holder==6 and target==7 and movement.pair_67_diagonal_disabled
              and (movement.pair_67_cardinal_flip or 0)==0
              and (pass_chain.approach_frames or 0)+16<approach_absolute then
            movement.pair_67_cardinal_flip=1
            movement.recovery_probe_failed=false
            movement.recovery_exploratory=false
            movement.recovery_phase=nil
            movement.recovery_probe_gain=nil
            movement.approach_limit=math.min(
              math.max(movement.approach_limit or Ordered.MAX_APPROACH,
                (pass_chain.approach_frames or 0)+16),approach_absolute)
            movement.burst_remaining=0;movement.burst_buttons=nil
            buttons={}
            auto_write(emu.framecount(),"approach_67_cardinal_retry",holder,target,selected_pass_button,
              "flip=1|budget=16|limit="..tostring(movement.approach_limit))
          else
            buttons={};autopass.enabled=false;pass_chain.active=false;auto_finished=true
          end
        elseif movement.recovery_exploratory and movement.recovery_left==0 and movement.recovery_probe_gain then
          auto_write(emu.framecount(),"approach_probe_result",holder,target,selected_pass_button,
            "gain="..tostring(movement.recovery_probe_gain))
          movement.recovery_exploratory=false
          movement.approach_limit=math.min(math.max(movement.approach_limit or Ordered.MAX_APPROACH,pass_chain.approach_frames+16),approach_absolute)
        end
        if holder==5 and target==8 and (movement.recent_progress or 0)>=2 then
          auto_write(emu.framecount(),"approach_recent_progress",holder,target,selected_pass_button,
            "distance="..tostring(measurement and measurement.distance)..
            "|streak="..tostring(movement.recent_progress)..
            "|direction="..tostring(movement.burst_direction))
        end
        if feedback=="direction_worsened" or feedback=="direction_no_progress" or feedback=="direction_improved" or feedback=="direction_partial_progress" or feedback=="direction_pending_feedback" then
          auto_write(emu.framecount(),"approach_direction_feedback",holder,target,selected_pass_button,
            "result="..feedback.."|gain="..tostring(movement.last_gain)..
            "|bad_bursts="..tostring(movement.bad_bursts or 0)..
            "|distance="..tostring(measurement and measurement.distance)..
            "|lateral="..tostring(measurement and measurement.lateral)..
            "|distance_gain="..tostring(movement.last_distance_gain).."|lateral_gain="..tostring(movement.last_lateral_gain))
        elseif feedback=="no_direction_improves" then
          auto_write(emu.framecount(),"approach_no_improvement",holder,target,selected_pass_button,
            "bad_bursts="..tostring(movement.bad_bursts))
          local recovered,dir=Ordered.recover(movement,measurement,holder,target)
          if recovered and (pass_chain.approach_frames or 0)<approach_absolute then
            movement.approach_limit=math.min(math.max(movement.approach_limit or Ordered.MAX_APPROACH,pass_chain.approach_frames+(movement.recovery_left or 16)),approach_absolute)
            auto_write(emu.framecount(),"approach_recovery_started",holder,target,selected_pass_button,
              "direction="..dir.."|cause=no_improvement")
          else
            buttons={};autopass.enabled=false;pass_chain.active=false;auto_finished=true
          end
        end
        if feedback=="axis_switched" then
          auto_write(emu.framecount(),"approach_axis_switched",holder,target,selected_pass_button,
            "axis="..tostring(pass_chain.approach_state.axis).."|switches="..tostring(pass_chain.approach_state.switches)..
            "|distance="..tostring(measurement and measurement.distance))
          if (pass_chain.approach_state.switches or 0)%2==0 and (autopass.relax_level or 0)<Feet.MAX_LEVEL then
            autopass.relax_level=(autopass.relax_level or 0)+1
            local range,lateral=Feet.set_level(autopass.relax_level)
            auto_write(emu.framecount(),"limits_expanded",holder,target,selected_pass_button,
              "level="..autopass.relax_level.."|range="..range.."|lateral="..lateral.."|cause=approach_stall")
          end
        end
        -- Relax limits incrementally if geometry remains invalid despite movement.
        if (pass_chain.approach_frames or 0)>0
            and pass_chain.approach_frames%20==0
            and movement.last_expansion_step~=pass_chain.approach_frames
            and (autopass.relax_level or 0)<Feet.MAX_LEVEL then
          movement.last_expansion_step=pass_chain.approach_frames
          autopass.relax_level=autopass.relax_level+1
          local range,lateral=Feet.set_level(autopass.relax_level)
          auto_write(emu.framecount(),"limits_expanded",holder,target,selected_pass_button,
            "level="..autopass.relax_level.."|range="..range.."|lateral="..lateral.."|cause=approach_duration")
        end
        auto_write(emu.framecount(),"approach_progress",holder,target,selected_pass_button,
          "distance="..tostring(measurement and measurement.distance)..
          "|initial="..tostring(pass_chain.approach_state.initial_distance)..
          "|best="..tostring(pass_chain.approach_state.best_distance)..
          "|lateral="..tostring(measurement and measurement.lateral)..
          "|best_lateral="..tostring(pass_chain.approach_state.best_lateral)..
          "|stalled="..tostring(pass_chain.approach_state.stalled or 0))
      else
        -- Keep a direction continuously for up to four frames; check safety on
        -- every frame and sample progress once per burst on the neutral frame.
        if (movement.burst_remaining or 0)>0 and movement.burst_buttons then
          local new_buttons,check=Ordered.step(sample_for_auto,holder,target,movement)
          if check=="approach_step" then
            -- Preserve the SAME physical input for the entire calibrated burst.
            -- Ordered.step is still called to revalidate possession/geometry.
            buttons=movement.burst_buttons
            reason="approach_step"
          else
            buttons={};reason=check;movement.burst_remaining=0
          end
        else
          buttons,reason=Ordered.step(sample_for_auto,holder,target,movement)
          if reason=="approach_step" then
            -- Dash applies ONLY to movement during 7->10, never a pass.
            -- Keep burst_direction cardinal; Y is not a steering axis.
            if movement.experimental_dash_710_enabled==true and holder==7 and target==10 and not buttons.B and
                (buttons.Right or buttons.Left or buttons.Up or buttons.Down) then
              buttons.Y=true
              auto_write(emu.framecount(),"approach_710_dash_start",7,10,selected_pass_button,
                "dash=Y|direction="..tostring(movement.direction)..
                "|distance="..tostring((Feet.measure(sample_for_auto,7,10) or {}).distance))
            end
            movement.burst_buttons=buttons
            movement.target=target
            if holder==7 and target==10 and movement.dash_710_disabled then
              auto_write(emu.framecount(),"approach_710_direction_only",7,10,selected_pass_button,
                "direction="..tostring(movement.direction)..
                "|ball_gap="..tostring(ball_gap_710(sample_for_auto)))
            end
            local initial=Feet.measure(sample_for_auto,holder,target)
            movement.burst_start=initial
            movement.burst_positions=Ordered.capture(sample_for_auto,holder,target)
            if (holder==8 and target==9 or holder==6 and target==7) and buttons.Up and buttons.Right then
              movement.burst_direction="Up_Right"
              movement.diagonal_start=initial
              auto_write(emu.framecount(),"approach_diagonal_started",holder,target,selected_pass_button,
                "buttons=Up+Right|distance="..tostring(initial and initial.distance)..
                "|lateral="..tostring(initial and initial.lateral))
            else
              movement.burst_direction=nil
              for _,key in ipairs({"Right","Left","Up","Down"}) do if buttons[key] then movement.burst_direction=key;break end end
            end
            local desired_burst=(holder==5 and target==8 and not movement.right_suspended and buttons.Right) and 8 or Ordered.BURST_FRAMES
            if holder==7 and target==10 and buttons.Right and not buttons.Left and not buttons.B then
              desired_burst=8
            elseif holder==6 and target==7 and buttons.Up and buttons.Right and not buttons.B then
              desired_burst=Ordered.CONTINUOUS_HOLD_67
            end
            local recovery_cap=(movement.recovery_exploratory and (movement.recovery_left or 0)>0)
                and movement.recovery_left or desired_burst
            movement.burst_remaining=math.min(desired_burst,
              (movement.approach_limit or Ordered.MAX_APPROACH)-(pass_chain.approach_frames or 0),
              recovery_cap)
            auto_write(emu.framecount(),"approach_coordinate_decision",holder,target,selected_pass_button,
              "dx="..tostring(initial and initial.dx).."|dy="..tostring(initial and initial.dy)..
              "|direction="..tostring(movement.burst_direction)..
              "|frames="..tostring(movement.burst_remaining)..
              "|geometry_reason="..tostring(movement.geometry_reason)..
              "|up="..tostring(buttons.Up==true)..
              "|right="..tostring(buttons.Right==true))
            if desired_burst>Ordered.BURST_FRAMES and movement.burst_remaining>0 then
              auto_write(emu.framecount(),"approach_continuous_hold_started",holder,target,selected_pass_button,
                "frames="..tostring(movement.burst_remaining)..
                "|direction="..tostring(movement.burst_direction)..
                "|approach_frames="..tostring(pass_chain.approach_frames))
            end
            auto_write(emu.framecount(),"approach_burst_started",holder,target,selected_pass_button,
              "frames="..movement.burst_remaining.."|axis="..tostring(movement.axis))
          end
        end
        if reason=="approach_step" and holder==5 and target==8 then
          local coords=Ordered.capture(sample_for_auto,holder,target)
          if coords then
            auto_write(emu.framecount(),"approach_right_frame",holder,target,selected_pass_button,
              "right="..tostring(buttons.Right and true or false)..
              "|up="..tostring(buttons.Up and true or false)..
              "|left="..tostring(buttons.Left and true or false)..
              "|holder_x="..coords.hx.."|holder_y="..coords.hy..
              "|target_x="..coords.tx.."|target_y="..coords.ty)
          end
        end
        if reason=="approach_step" then
          pass_chain.approach_frames=pass_chain.approach_frames+1
          if (movement.recovery_left or 0)>0 then
            movement.recovery_left=movement.recovery_left-1
            if movement.recovery_exploratory and movement.recovery_left==0 then
              movement.recovery_phase="awaiting_sample"
            end
          end
          movement.burst_remaining=movement.burst_remaining-1
          if movement.burst_remaining==0 and
             ((holder==7 and target==10 and movement.burst_direction=="Right")
               or (holder==6 and target==7 and movement.burst_direction=="Up_Right")) then
            auto_write(emu.framecount(),"approach_continuous_hold_ended",holder,target,selected_pass_button,
              "direction="..tostring(movement.burst_direction)..
              "|approach_frames="..tostring(pass_chain.approach_frames))
          end
          pass_chain.approach_neutral=movement.burst_remaining==0
          if pass_chain.approach_neutral and holder==5 and target==8 and movement.burst_direction=="Right" then
            movement.right_followup_left=3
          end
          auto_write(emu.framecount(),"approach_step",holder,target,selected_pass_button,
            "step="..pass_chain.approach_frames.."|range_limit="..Feet.MAX_RANGE.."|axis="..tostring(movement.axis))
        elseif reason=="target_in_range" then
          buttons={};reason="approach_neutral";pass_chain.approach_neutral=false
        else
          buttons={};pass_chain.active=false;autopass.enabled=false;auto_finished=true
          auto_write(emu.framecount(),"approach_aborted",holder,target,selected_pass_button,reason)
        end
      end
    elseif integration_ok and (autopass.phase~="idle" or plan) then
      buttons,reason=Auto.step(autopass,emu.framecount(),sample_for_auto,holder,spatial.visited,plan,completion_frame~=nil)
    else
      buttons={};reason=selector_reason or "invalid_handoff";autopass.enabled=false
      pass_chain.active=false;auto_finished=true
      auto_write(emu.framecount(),"feet_route_blocked",holder,nil,selected_pass_button,reason)
    end
    -- Fail closed: release Dash whenever not actively approaching 7->10,
    -- and never allow Dash to accompany B or X.
    if buttons.Y and (buttons.B or buttons.X or reason~="approach_step"
       or holder~=7 or not pass_chain.active) then
      buttons.Y=nil
    end
    if holder==7 and pass_chain.active and pass_chain.approach_state and
       pass_chain.approach_state.target==10 and emu.framecount()%4==0 then
      auto_write(emu.framecount(),"approach_710_actual_input",7,10,selected_pass_button,
        "right="..tostring(buttons.Right==true)..
        "|left="..tostring(buttons.Left==true)..
        "|up="..tostring(buttons.Up==true)..
        "|down="..tostring(buttons.Down==true)..
        "|actual_Y="..tostring(buttons.Y==true)..
        "|reason="..tostring(reason))
    end
    if autopass.early_710_trial and holder==7 and autopass.target==10 then
      if reason=="target_selected" or reason=="possession_gate_ready"
         or reason=="facing_directional" or reason=="facing_release"
         or reason=="direction_and_B_hold" or reason=="pass_pulse"
         or reason=="early_710_guard_out_of_band"
         or reason=="early_710_guard_lateral_risk" then
        auto_write(emu.framecount(),"early_710_execution",7,10,selected_pass_button,
          "phase="..tostring(autopass.phase).."|reason="..tostring(reason)..
          "|B="..tostring(buttons.B==true)..
          "|direction="..tostring(autopass.facing_direction)..
          "|distance="..tostring((Feet.measure(sample_for_auto,7,10) or {}).distance))
      end
    end
    if holder==4 and autopass.target==5 and reason=="pass_pulse" then
      local player4
      for _,v in ipairs(sample_for_auto and sample_for_auto.players or {}) do
        if v.id==4 then player4=v;break end
      end
      local ball=sample_for_auto and sample_for_auto.ball
      if ball and player4 then
        auto_write(emu.framecount(),"pass_45_ball_relative_at_b",4,5,selected_pass_button,
          "dx="..tostring(ball.x-player4.x)..
          "|dy="..tostring(ball.y-player4.y)..
          "|facing_command="..tostring(autopass.facing_direction))
      end
    end
    if holder==4 and autopass.target==5 and reason=="pre_down_step" then
      local src,dst=nil,nil
      for _,v in ipairs(sample_for_auto and sample_for_auto.players or {}) do
        if v.id==4 then src=v elseif v.id==5 then dst=v end
      end
      if src and dst then
        auto_write(emu.framecount(),"facing_45_target_step",4,5,selected_pass_button,
          "dx="..tostring(dst.x-src.x).."|dy="..tostring(dst.y-src.y)..
          "|direction="..tostring(autopass.facing_direction)..
          "|frame="..tostring(autopass.pre_down_frames or 0)..
          "|button_B=false")
      end
    elseif holder==4 and autopass.target==5 and reason=="pre_down_release" then
      auto_write(emu.framecount(),"facing_45_release",4,5,selected_pass_button,
        "neutral=true|next=hold")
    end
    if armed and holder==6 and buttons.Right and not buttons.B and
        ((bridge_info and bridge_info.target==3) or autopass.target==3) then
      buttons.Right=nil
      auto_write(emu.framecount(),"first_pass_right_suppressed",6,3,selected_pass_button,
        "pre_pass_right_blocked")
    end
    if buttons.B or buttons.Up or buttons.Down or buttons.Left or buttons.Right or
       reason=="target_selected" or reason=="no_valid_target" or reason=="no_direction_for_pass" or reason=="selector_api_mismatch" or reason=="selector_report_missing" or reason=="integration_selftest_failed" or reason=="selected_without_receiver" or reason=="invalid_handoff" or reason=="no_unvisited_receiver" then
      log_input(emu.framecount(),phase_before,reason,holder,autopass.target,buttons)
    end
    if type(reason)=="string" and reason:match("^retarget_requested_") then
      buttons={}
      auto_write(emu.framecount(),"retarget_requested",autopass.origin,autopass.rejected_target,selected_pass_button,
        "cause="..tostring(autopass.rejected_reason).."|count="..tostring(autopass.retargets).."|max="..tostring(autopass.max_retargets))
    elseif reason=="retarget_ready" then
      auto_write(emu.framecount(),"retarget_ready",autopass.origin,nil,selected_pass_button,"neutral_cooldown_complete")
    elseif reason=="retarget_limit_reached" then
      buttons={};pass_chain.active=false;autopass.enabled=false;auto_finished=true
      auto_write(emu.framecount(),"retarget_limit_stop",autopass.origin,autopass.rejected_target,selected_pass_button,"max_retargets")
    end
    if type(reason)=="string" and reason:match("^feet_pass_rejected_") then
      auto_write(emu.framecount(),"feet_pass_rejected",autopass.origin,autopass.target,selected_pass_button,reason)
      pass_chain.active=false;autopass.enabled=false;auto_finished=true
    end
    if reason=="no_valid_target" then
      local diagnostic=string.format("selector=%s|players=%d|eligible=%d|excluded_visited=%d|excluded_invalid=%d",
       tostring(selector_reason),report and report.players or 0,report and report.eligible or 0,
       report and report.excluded_visited or 0,report and report.excluded_invalid or 0)
      auto_write(emu.framecount(),"target_rejected",holder,nil,selected_pass_button,diagnostic)
    end
    if reason=="target_selected" and receiver then
      -- Per-pass experiment: apply UP+B only to 6 -> 2.
      -- Do not change selected_direction or subsequent pass settings.
      if autopass.origin==6 and autopass.target==3 then
        auto_write(emu.framecount(),"pass_direction_override",6,3,selected_pass_button,
          "policy=pair_6_3_only|pre_up=2|release=1|pass=B_only")
      elseif autopass.origin==6 and autopass.target==2 then
        autopass.direction="Up"
        auto_write(emu.framecount(),"pass_direction_override",6,2,selected_pass_button,
          "direction=Up|button=B|policy=pair_6_2_only")
      elseif autopass.origin==4 and autopass.target==5 then
        autopass.direction="Down"
        auto_write(emu.framecount(),"pass_direction_override",4,5,selected_pass_button,
          "direction=Down|button=B|policy=pair_4_5_only")
      end
      autopass.visited_before_pass={}
      for id,seen in pairs(spatial.visited) do autopass.visited_before_pass[id]=seen end
      local c
      for _,candidate in ipairs(report and report.candidates or {}) do
       if candidate.id==receiver.id then c=candidate;break end
      end
      local gap=Feet.measure(sample_for_auto,holder,receiver.id)
      if gap then
        auto_write(emu.framecount(),"pass_min_gap_check",holder,receiver.id,selected_pass_button,
          "distance="..tostring(gap.distance)..
          "|minimum="..tostring(Feet.MIN_PASS_DISTANCE)..
          "|valid="..tostring(gap.distance>=Feet.MIN_PASS_DISTANCE))
      end
      auto_write(emu.framecount(),"receiver_selected",holder,receiver.id,selected_pass_button,
       string.format("distance=%s|misalignment=%s|cost=%s|aligned=%s",
        c and string.format("%.2f",c.distance) or "unknown",
        c and string.format("%.2f",c.misalignment) or "unknown",
        c and string.format("%.2f",c.cost) or "unknown",tostring(receiver.aligned)))
    elseif reason=="active_alignment_started" or reason=="active_alignment_ready"
      or (type(reason)=="string" and reason:match("^alignment_adjust_")) then
      auto_write(emu.framecount(),reason,autopass.origin,autopass.target,selected_pass_button,
        "correction_steps="..tostring(autopass.active_alignment and autopass.active_alignment.steps or 0).."|no_B=true")
    elseif reason=="pre_up_step" or reason=="pre_up_release" then
      auto_write(emu.framecount(),reason,autopass.origin,autopass.target,selected_pass_button,
        "steps="..tostring(autopass.pre_up_frames or 0).."|next=B_only")
    elseif reason=="pre_down_step" or reason=="pre_down_release" then
      auto_write(emu.framecount(),reason,autopass.origin,autopass.target,selected_pass_button,
        "steps="..tostring(autopass.pre_down_frames or 0).."|next=Down+B")
    elseif reason=="facing_directional" then
      auto_write(emu.framecount(),"facing_directional",autopass.origin,autopass.target,selected_pass_button,
        "direction="..tostring(autopass.facing_direction)..
        "|frame="..tostring(autopass.facing_count)..
        "|no_B=true")
    elseif reason=="facing_release" then
      auto_write(emu.framecount(),"facing_release",autopass.origin,autopass.target,selected_pass_button,"neutral_frame")
    elseif reason=="alignment_correction" then
      auto_write(emu.framecount(),"alignment_correction",holder,autopass.target,selected_pass_button,"bounded_directional_pre_align")
    elseif reason=="possession_gate_ready" then
      auto_write(emu.framecount(),reason,autopass.origin,autopass.target,selected_pass_button,
        "distance="..tostring(autopass.gate_distance)..
        "|streak="..tostring(autopass.gate_tracker and autopass.gate_tracker.streak))
    elseif reason=="flight_wait_extended" then
      auto_write(emu.framecount(),"flight_wait_extended",autopass.origin,autopass.target,
        selected_pass_button,"wait_frames="..tostring(autopass.wait_frames)..
        "|first_motion_frame="..tostring(autopass.first_motion_frame)..
        "|displacement="..string.format("%.2f",autopass.ball_max_displacement))
    elseif reason=="pass_pulse" and autopass.last_attempt then
      local a=autopass.last_attempt
      auto_write(emu.framecount(),"pass_pulse",a.from,a.to,a.button,"experimental_unverified|wait_frames="..tostring(autopass.wait_frames).."|calib="..tostring(autopass.calibration_mode))
    elseif reason=="transfer_candidate_observed" or reason=="ball_moved_without_transfer" or reason=="no_ball_motion_detected" or reason=="timeout" or reason=="completion_candidate_stop" or reason=="coordinates_lost" or reason=="no_valid_target" or reason=="no_direction_for_pass" or reason=="selector_api_mismatch" or reason=="selector_report_missing" or reason=="integration_selftest_failed" or reason=="selected_without_receiver" or reason=="invalid_handoff" or reason=="no_unvisited_receiver" or reason=="possession_gate_timeout" or reason=="retarget_limit_reached" then
      if reach.flight then
        Reach.finish(reach,emu.framecount(),sample_for_auto,
          reason=="transfer_candidate_observed" and spatial.holder or nil,reason,reach_emit)
      end
      if reason=="possession_gate_timeout" then
        auto_write(emu.framecount(),"possession_gate_timeout",autopass.origin,autopass.target,selected_pass_button,
          "streak="..tostring(autopass.gate_tracker and autopass.gate_tracker.streak))
      end
      auto_write(emu.framecount(),"single_pass_result",autopass.origin,autopass.target,selected_pass_button,reason.."|direction="..selected_direction.."|max_ball_displacement="..string.format("%.2f",autopass.ball_max_displacement))
      calibration_write(emu.framecount(),reason,autopass.last_attempt,reason=="transfer_candidate_observed" and holder or nil,reason=="transfer_candidate_observed" and emu.framecount() or nil)
      for _,point in ipairs(autopass.early_flight or {}) do
        auto_write(point.frame,"early_flight",autopass.origin,autopass.target,selected_pass_button,
          "calib="..tostring(autopass.calibration_mode).."|dx="..tostring(point.dx).."|dy="..tostring(point.dy).."|x="..tostring(point.x).."|y="..tostring(point.y))
      end
      local flight=autopass.flight_samples or {}
      for _,point in ipairs(flight) do
        auto_write(point.frame,"flight_sample",autopass.origin,autopass.target,selected_pass_button,
          "x="..tostring(point.x).."|y="..tostring(point.y)..
          "|displacement="..string.format("%.2f",point.displacement)..
          "|target_distance="..(point.target_distance and string.format("%.2f",point.target_distance) or "unknown"))
      end
      auto_write(emu.framecount(),"flight_summary",autopass.origin,autopass.target,
        selected_pass_button,"first_motion_frame="..tostring(autopass.first_motion_frame)..
        "|observed_receiver="..tostring(reason=="transfer_candidate_observed" and holder or "none")..
        "|wait_frames="..tostring(autopass.wait_frames).."|extended="..tostring(autopass.extended))
      if reason=="transfer_candidate_observed" and holder~=autopass.target then
        auto_write(emu.framecount(),"receiver_mismatch",autopass.origin,holder,selected_pass_button,
          "planned="..tostring(autopass.target).."|observed="..tostring(holder)..
          "|reserved_early="..tostring((holder==10 or holder==11) and not spatial.visited[2]))
      end
      local completed_displacement=autopass.ball_max_displacement
      if reason=="transfer_candidate_observed" and pass_chain.active then
        pass_chain.passes=pass_chain.passes+1
        local repeated=autopass.visited_before_pass and autopass.visited_before_pass[holder]
        if repeated then pass_chain.consecutive_relays=pass_chain.consecutive_relays+1
        else pass_chain.consecutive_relays=0 end
        auto_write(emu.framecount(),"relay_outcome",autopass.origin,holder,selected_pass_button,
          "repeat="..tostring(repeated and true or false).."|consecutive="..pass_chain.consecutive_relays)
        pass_chain.previous=autopass.origin
        if holder~=autopass.target then
          local next_target,next_reason=Ordered.next(pass_chain.route_index,holder,spatial.visited)
          auto_write(emu.framecount(),"route_unexpected_receiver_reconcile",autopass.origin,holder,selected_pass_button,
            "planned="..tostring(autopass.target)..
            "|actual="..tostring(holder)..
            "|visited_actual="..tostring(spatial.visited[holder] and true or false)..
            "|next_unvisited="..tostring(next_target)..
            "|route_reason="..tostring(next_reason))
        end
        if holder==7 and autopass.target==10 and pass_chain.repeat_710_started then
          pass_chain.repeat_710_used=true
          auto_write(emu.framecount(),"repeat_710_result",autopass.origin,holder,selected_pass_button,
            "actual_receiver="..tostring(holder)..
            "|count_additional_visit=false")
        end
        if holder==autopass.target then
          pass_chain.route_index=pass_chain.route_index+1
          pass_chain.approach_frames=0;pass_chain.approach_neutral=false;pass_chain.approach_state={}
          auto_write(emu.framecount(),"route_advanced",autopass.origin,holder,selected_pass_button,
            "index="..pass_chain.route_index.."/10")
        else
          auto_write(emu.framecount(),"route_deviation",autopass.origin,holder,selected_pass_button,
            "expected="..tostring(autopass.target).."|observed="..tostring(holder).."|recovery=continue")
          pass_chain.approach_frames=0;pass_chain.approach_neutral=false
          pass_chain.approach_state={}
          if Ordered.can_relay_six_seven(holder,spatial.visited) then
            auto_write(emu.framecount(),"route_67_continuity",holder,7,selected_pass_button,
              "player_6_previously_visited="..tostring(spatial.visited[6] and true or false)..
              "|player_2_visited="..tostring(spatial.visited[2] and true or false)..
              "|player_7_visited=false|eligible=true")
          end
          auto_write(emu.framecount(),"route_recovered",autopass.origin,holder,selected_pass_button,
            "next="..tostring(Ordered.next(pass_chain.route_index,holder,spatial.visited)))
        end
        local visits=0;for id in pairs(spatial.visited) do if type(id)=="number" and id>=2 and id<=11 then visits=visits+1 end end
        auto_write(emu.framecount(),"chain_transfer_candidate",autopass.origin,holder,selected_pass_button,
          "observed="..tostring(holder).."|planned="..tostring(autopass.target).."|visited="..visits.."/10|passes="..pass_chain.passes)
        if not pass_chain.active or visits>=10 or pass_chain.passes>=pass_chain.limit then
          pass_chain.active=false;autopass.enabled=false;auto_finished=true
          auto_write(emu.framecount(),not pass_chain.active and "route_stop" or (visits>=10 and "chain_complete_candidate" or "chain_limit_stop"),
            nil,holder,selected_pass_button,"visited="..visits.."/10|passes="..pass_chain.passes.."|no_auto_shot")
        else
          -- Retain the spatial visitor set, reset only the one-pass actuator.
          local next_auto=Auto.new()
          next_auto.enabled=true;next_auto.button="B";next_auto.direction=selected_direction
          next_auto.start_frame=emu.framecount();next_auto.trigger_delay=trigger_mode=="B" and 12 or 0;next_auto.calibration_mode=calibration_mode
          autopass=next_auto;pass_chain.next_frame=emu.framecount()+8
          auto_write(emu.framecount(),"chain_next_pending",holder,nil,selected_pass_button,"cooldown_frames=8")
        end
      else
        pass_chain.active=false;autopass.enabled=false;auto_finished=true
      end
      print("[ISSD.pass_lv1] single-pass result: "..reason.." max_ball_displacement="..string.format("%.2f",completed_displacement))
    end
  end
  if armed and finish.enabled then
    -- The challenge has no opposing goalkeeper: read the field reference instead.
    local goal,goal_error=GoalStadium.read(memory.read_s16_le,memory.read_u16_le)
    if sample_for_auto then sample_for_auto.goal_reference=goal end
    if completion_frame and not finish.stadium_audited then
      finish.stadium_audited=true
      auto_write(emu.framecount(),"finish_stadium_goal_audit",spatial.holder,nil,"OBSERVE",
        "stadium="..tostring(goal and goal.stadium)..
        "|length="..tostring(goal and goal.field_length)..
        "|width="..tostring(goal and goal.field_width)..
        "|center_x="..tostring(goal and goal.center_x)..
        "|center_y="..tostring(goal and goal.center_y)..
        "|goal_right_x="..tostring(goal and goal.right_x)..
        "|goal_left_x="..tostring(goal and goal.left_x)..
        "|attack_side=right_unverified|calibrated=false"..
        "|read_error="..tostring(goal_error))
    end
    local shot,reason=Finish.step(finish,emu.framecount(),completion_frame,bonus.first_decrement_frame,sample_for_auto,spatial.holder)
    if reason=="shoot_pulse" or reason=="completion_and_bonus_observed" or reason=="finish_window_expired" or reason=="shot_blocked_too_far" or reason=="goalkeeper_coordinate_mismatch" or reason=="invalid_coordinate_domain" then
      finish_write(emu.framecount(),reason)
      auto_write(emu.framecount(),"finish_"..reason,spatial.holder,nil,"X",
        "aim="..tostring(finish.aim_reason).."|direction="..tostring(finish.aim and (finish.aim.Left and "Left" or "Right"))..
        "|vertical="..tostring(finish.aim and (finish.aim.Up and "Up" or finish.aim.Down and "Down" or "neutral")))
    end
    if reason=="finish_goal_approach" then
      buttons=shot;autopass.enabled=false
      if finish.approach_frames%10==1 then
        auto_write(emu.framecount(),"finish_goal_approach",spatial.holder,nil,"MOVE",
          "frames="..tostring(finish.approach_frames)..
          "|best_gap="..tostring(finish.approach_best)..
          "|start_gap="..tostring(finish.approach_x_start))
      end
    end
    -- Finalization only emits X once; it must never combine with pass B.
    if shot.X then
      buttons=shot;autopass.enabled=false
      trajectory_write(emu.framecount(),0,sample_for_auto,"shot_x")
      if goal_monitor then
        goal_monitor.complete=completion_frame
        goal_monitor.bonus=bonus.first_decrement_frame
        local shot_sample=GoalEvidence.read(memory.read_u8,memory.read_u16_le,emu.framecount())
        if GoalEvidence.mark_shot(goal_monitor,shot_sample) then
          goal_write(emu.framecount(),"shot_x_issued",shot_sample)
          auto_write(emu.framecount(),"goal_post_shot_started",spatial.holder,nil,"X",
            "window="..tostring(GoalEvidence.WINDOW).."|baseline="..tostring(shot_sample.goal))
        end
      end
    elseif completion_frame and reason~="finish_goal_approach" then buttons={} end
  end
  -- DRIBBLE-derived passive counter observation after the X pulse.
  -- This continues even when the pass automation has been disabled.
  if armed and goal_monitor and goal_monitor.shot and not goal_monitor.closed
     and emu.framecount()>goal_monitor.shot then
    local g=GoalEvidence.read(memory.read_u8,memory.read_u16_le,emu.framecount())
    local elapsed=emu.framecount()-goal_monitor.shot
    if sample_for_auto and (elapsed<=60 or elapsed%10==0) then
      trajectory_write(emu.framecount(),elapsed,sample_for_auto,"post_x")
    end
    local event=GoalEvidence.step(goal_monitor,g)
    if event or goal_monitor.closed or
       (emu.framecount()-goal_monitor.shot)%GoalEvidence.SAMPLE_EVERY==0 then
      local kind=event or (goal_monitor.closed and "post_shot_window_closed" or "post_shot_sample")
      goal_write(emu.framecount(),kind,g)
      if event or goal_monitor.closed then
        auto_write(emu.framecount(),"goal_post_shot_"..kind,spatial.holder,nil,"X",
          "classification="..GoalEvidence.classify(goal_monitor)..
          "|goal="..tostring(g.goal).."|baseline="..tostring(goal_monitor.baseline))
      end
    end
  end
  -- Frame-level WRAM evidence surrounding every pass and trigger delay.
  if armed and sample_for_auto and
      (autopass.phase=="active_align" or autopass.phase=="retarget_wait" or autopass.phase=="possession_gate" or autopass.phase=="prewait" or autopass.phase=="face" or autopass.phase=="face_release" or autopass.phase=="align" or
       autopass.phase=="hold" or autopass.phase=="wait") then
    local pf=autopass.pass_frame
    if autopass.phase~="wait" or (pf and emu.framecount()-pf<=30) then
      trigger_write(emu.framecount(),trigger_mode,autopass.phase,"frame_sample",
        spatial.holder,autopass.target,sample_for_auto,buttons)
    end
  end
  if armed and buttons.Right and not buttons.B and ((holder==6 and autopass.target==2) or (holder==6 and bridge_info and bridge_info.target==2)) then
    buttons.Right=nil
    auto_write(emu.framecount(),"interposition_right_suppressed",6,2,selected_pass_button,"avoid_rightward_step_before_up_b")
  end
  if armed and holder==6 and bridge_info and bridge_info.target==2 and emu.framecount()%10==0 then
    local blocker=Ordered.interposition(sample_for_auto)
    if blocker then auto_write(emu.framecount(),"interposition_6_3_2",6,2,selected_pass_button,
      "between="..tostring(blocker.between).."|offset="..tostring(blocker.offset).."|blocked="..tostring(blocker.blocked)) end
  end
  if armed and sample_for_auto then
    local tracked_target=autopass.target
    if not tracked_target and pass_chain.approach_state then tracked_target=pass_chain.approach_state.target end
    Reach.observe(reach,emu.framecount(),sample_for_auto,spatial.holder,tracked_target,buttons,reach_emit)
    if reach.flight and emu.framecount()-reach.flight.start>=180 then
      Reach.finish(reach,emu.framecount(),sample_for_auto,nil,"flight_timeout",reach_emit)
    end
  end
  if buttons.X then log_input(emu.framecount(),"finish","shoot_pulse",spatial.holder,nil,buttons) end
  if armed and pass_chain.active and (holder==9 or holder==6) and
      (pass_chain.approach_state and (pass_chain.approach_state.direction or
       pass_chain.approach_state.burst_direction)) then
    local trace=pass_chain.approach_state
    local target=pass_chain and pass_chain.approach_target or nil
    if not target and trace then target=trace.target end
    if not target and autopass then target=autopass.target end
    if not target and holder==7 and (buttons.Right or buttons.Up or buttons.Down or buttons.Left) then target=10 end
    if target and (target==7 or target==10) and (buttons.Up or buttons.Right or buttons.Left or buttons.Down) then
      auto_write(emu.framecount(),"approach_target_joypad_commit",holder,target,selected_pass_button,
        "selected="..tostring(trace.burst_direction or trace.direction)..
        "|reason="..tostring(trace.geometry_reason)..
        "|up="..tostring(buttons.Up==true).."|right="..tostring(buttons.Right==true)..
        "|down="..tostring(buttons.Down==true).."|left="..tostring(buttons.Left==true)..
        "|pass_b="..tostring(buttons.B==true))
    end
  end
  -- v0.8.80 final frame guard: no controls on impossible 7/10 geometry.
  if armed and holder==7 and sample_for_auto and pass_chain.approach_state
     and (pass_chain.approach_state.target==10 or
          (bridge_info and bridge_info.target==10)) then
    local v=Ordered.capture(sample_for_auto,7,10)
    if not v then
      buttons={}
      local st=pass_chain.approach_state
      st.pair_710_output_invalid=(st.pair_710_output_invalid or 0)+1
      if st.pair_710_output_invalid>=3 then
        pass_chain.active=false;autopass.enabled=false;auto_finished=true
        auto_write(emu.framecount(),"approach_710_invalid_coordinates",7,10,selected_pass_button,
          "reason=output_guard|invalid_frames="..tostring(st.pair_710_output_invalid))
      end
    else
      local st=pass_chain.approach_state
      st.pair_710_output_invalid=0
      local empty=not (buttons.Right or buttons.Left or buttons.Up or buttons.Down
                      or buttons.B or buttons.X or buttons.Y)
      if empty and reason=="approach_neutral" then
        st.pair_710_output_neutral=(st.pair_710_output_neutral or 0)+1
        if st.pair_710_output_neutral>=5 then
          pass_chain.approach_neutral=false
          st.right_followup_left=0;st.right_settle_remaining=0
          st.burst_remaining=0;st.burst_buttons=nil
          st.pair_710_output_neutral=0
          auto_write(emu.framecount(),"approach_710_neutral_watchdog",7,10,selected_pass_button,
            "action=clear_neutral_at_output")
        end
      else
        st.pair_710_output_neutral=0
      end
    end
  end
  -- Observe a genuine holder change 10->7; perform one 7->10 return
  -- before resuming the outstanding last-player recovery.
  if armed and pass_chain.active and spatial.holder then
    if long_710.last_holder==10 and spatial.holder==7 and
       long_710.returns<1 then
      long_710.return_due=true
      if long_710.phase=="done" then long_710.phase="ready" end
      auto_write(emu.framecount(),"return_710_queued",7,10,"B",
        "reason=observed_holder_transition_10_to_7")
    end
    long_710.last_holder=spatial.holder
  end
  -- Rearm the directional controller for a NEW relay only after completion.
  -- Bound retries by carrier/receiver pair and a cooldown in real frames.
  if long_710.phase=="done" and emu.framecount()>=(long_710.cooldown_until or 0) then
    long_710.phase="ready"
    auto_write(emu.framecount(),"long_pass_rearmed",spatial.holder,nil,"B",
      "reason=finished_previous_trial")
  end
  -- v0.8.94: the sole unvisited outfielder always owns the destination.
  local final_target=last_missing_710(spatial.visited,spatial.holder)
  if final_target~=long_710.final_target then
    auto_write(emu.framecount(),"final_target_changed",spatial.holder,final_target,"B",
      "previous="..tostring(long_710.final_target).."|reason=visited_set_update")
    long_710.final_target=final_target
    long_710.final_retries=0
    long_710.final_next_retry=0
    long_710.attempts={}
    long_710.sidestep_97_exhausted=false
  end
  if final_target and long_710.support_target and
      spatial.holder==long_710.support_target then
    auto_write(emu.framecount(),"final_support_received",spatial.holder,final_target,"B",
      "support_target="..tostring(long_710.support_target)..
      "|next_target="..tostring(final_target))
    long_710.support_target=nil
    long_710.original_target=nil
    long_710.attempts={}
    long_710.phase="ready"
    long_710.cooldown_until=emu.framecount()+8
  end
  if final_target and spatial.holder and spatial.holder~=long_710.final_last_holder then
    auto_write(emu.framecount(),"final_holder_changed",spatial.holder,final_target,"B",
      "previous_holder="..tostring(long_710.final_last_holder))
    long_710.final_last_holder=spatial.holder
    long_710.attempts={}
    long_710.final_retries=0
    long_710.final_next_retry=0
    if long_710.phase=="done" then long_710.phase="ready" end
  end
  if final_target and long_710.phase=="done" and
     emu.framecount()>=(long_710.final_next_retry or 0) and
     emu.framecount()>=(long_710.cooldown_until or 0) then
    long_710.phase="ready"
    long_710.final_retries=long_710.final_retries+1
    long_710.attempts={}
    auto_write(emu.framecount(),"final_retry_rearmed",spatial.holder,final_target,"B",
      "retry="..long_710.final_retries.."|reason=resume_after_trial")
  end
  if final_target and long_710.phase=="ready" and
      long_710.target and long_710.target~=final_target and
      long_710.original_target~=final_target then
    auto_write(emu.framecount(),"final_stale_target_cleared",spatial.holder,final_target,"B",
      "stale="..tostring(long_710.target))
    long_710.target=nil
    long_710.support_target=nil
  end
  -- v0.8.96: remember the previous holder, preventing immediate support ping-pong.
  if spatial.holder and spatial.holder~=long_710.last_holder then
    long_710.universal_previous_holder=long_710.last_holder
  end
  -- v0.8.85: first protect the final missing receiver, even after a detour.
  -- Never count a speculative pass as a verified visit.
  local missing=last_missing_710(spatial.visited,spatial.holder)
  local queue_target=first_unvisited(spatial.visited,spatial.holder)
  if queue_target~=long_710.queue_target then
    auto_write(emu.framecount(),"queue_target_changed",spatial.holder,queue_target,"B",
      "previous="..tostring(long_710.queue_target).."|order=ascending_unvisited")
    long_710.queue_target=queue_target
    long_710.attempts={}
  end
  if queue_target and spatial.holder~=long_710.queue_last_holder then
    long_710.queue_last_holder=spatial.holder
    auto_write(emu.framecount(),"queue_holder_changed",spatial.holder,queue_target,"B",
      "priority=unvisited_first")
  end
  if armed and pass_chain.active and sample_for_auto and
     not wd_released and long_710.phase=="ready" and spatial.holder and
     (missing or long_710.return_due or
      (spatial.holder==9 and not spatial.visited[7]) or (spatial.holder==7 and
        (Ordered.next(nil,7,spatial.visited)==10 or
         (pass_chain.repeat_710_started and not pass_chain.repeat_710_used))) or
      queue_target~=nil or Ordered.next(nil,spatial.holder,spatial.visited)~=nil) then
    local from=spatial.holder
    local target=queue_target or missing or (long_710.return_due and from==7 and 10)
       or (from==9 and not spatial.visited[7] and 7)
       or ((from==7) and 10 or nil) or Ordered.next(nil,from,spatial.visited)
    if target and target~=from then
      local xy=Ordered.capture(sample_for_auto,from,target)
      local gap=ball_gap_710(sample_for_auto)
      if from~=7 then
        local bp=sample_for_auto.ball
        if bp then for _,p in ipairs(sample_for_auto.players or {}) do
          if p.id==from then gap=math.sqrt((bp.x-p.x)^2+(bp.y-p.y)^2) end
        end end
      end
      local routing_g=pair_geometry(sample_for_auto,from,target)
      if routing_g and (emu.framecount()-long_710.watchdog_last_action>=24) then
        local why=(not gap and "missing_ball" or
          (gap>18 and "ball_not_with_holder" or
          (routing_g.distance>410 and "distance" or
          (math.abs(routing_g.dy)>100 and "lateral_alignment" or
          (emu.framecount()<long_710.cooldown_until and "cooldown" or "evaluate_lane")))))
        auto_write(emu.framecount(),"queue_route_diagnostic",from,target,"B",
          "reason="..why.."|dx="..routing_g.dx.."|dy="..routing_g.dy..
          "|direction="..routing_g.direction..
          "|distance="..string.format("%.2f",routing_g.distance))
      end
      local attempt_key=tostring(from)..":"..tostring(target)
      if xy and gap and gap<=18 and
         (long_710.attempts[attempt_key] or 0)<2 and
         emu.framecount()>=(long_710.cooldown_until or 0) then
        local dx,dy=xy.tx-xy.hx,xy.ty-xy.hy
        local distance=math.sqrt(dx*dx+dy*dy)
        local blocker,cross=lane_blocker(sample_for_auto,from,target)
        -- Universal support BEFORE sidestep, for every intended pass.
        local support_g=blocker and support_receiver(sample_for_auto,from,target,blocker) or nil
        local support_key=blocker and (tostring(from)..":"..tostring(blocker)) or nil
        local support_count=support_key and (long_710.support_attempts[support_key] or 0) or 0
        local loop_back=blocker and blocker==long_710.universal_previous_holder
        local cooldown=blocker and (long_710.universal_support_cooldown[support_key] or 0) or 0
        -- An already-visited relay is allowed only if it shortens the
        -- remaining route to the SAME first-unvisited queue target.
        local remaining=support_g and pair_geometry(sample_for_auto,blocker,target)
        local improves=support_g and remaining and
          remaining.distance+12<distance and
          remaining.distance<distance and
          (not lane_blocker(sample_for_auto,blocker,target))
        if blocker and support_g and improves and support_count<2 and not loop_back and
           emu.framecount()>=cooldown then
          long_710.support_attempts[support_key]=support_count+1
          long_710.universal_support_cooldown[support_key]=emu.framecount()+90
          long_710.original_target=target
          long_710.support_target=blocker
          long_710.origin=from;long_710.target=blocker
          long_710.initial=support_g.distance
          long_710.direction=support_g.direction
          long_710.receiver_start={x=support_g.xy.tx,y=support_g.xy.ty}
          long_710.carrier_start={x=support_g.xy.hx,y=support_g.xy.hy}
          long_710.start=emu.framecount()
          long_710.watchdog_last_action=emu.framecount()
          long_710.shot_frame=nil
          long_710.fast_pass=true
          long_710.phase="face"
          long_710.watchdog_last_action=emu.framecount()
          auto_write(emu.framecount(),"universal_support_planned",from,blocker,"B",
            "primary_target="..tostring(target)..
            "|already_visited="..tostring(spatial.visited[blocker]==true)..
            "|attempt="..(support_count+1)..
            "|direction="..support_g.direction..
            "|primary_distance="..string.format("%.2f",distance)..
            "|remaining_distance="..string.format("%.2f",remaining.distance)..
            "|queue_target="..tostring(queue_target))
        elseif blocker and from==9 and target==7 and
           not long_710.sidestep_97_exhausted and
           long_710.sidestep_97_count<4 then
          long_710.phase="sidestep"
          long_710.watchdog_last_action=emu.framecount()
          long_710.walk_start=emu.framecount()
          long_710.sidestep_97_count=long_710.sidestep_97_count+1
          long_710.origin=9;long_710.target=7
          long_710.sidestep_97_initial={x=xy.hx,y=xy.hy}
          long_710.sidestep_97_blocker=blocker
          long_710.sidestep_97_last_cross=cross
          long_710.walk_dir=lane_escape(sample_for_auto,from,target) or "Up"
          auto_write(emu.framecount(),"relay_97_sidestep_started",9,7,"B",
            "attempt="..long_710.sidestep_97_count..
            "|blocker="..blocker.."|cross="..string.format("%.2f",cross)..
            "|direction="..long_710.walk_dir..
            "|holder_x="..xy.hx.."|holder_y="..xy.hy..
            "|target_x="..xy.tx.."|target_y="..xy.ty..
            "|dx="..dx.."|dy="..dy)
        elseif blocker and from==9 and target==7 and
           long_710.sidestep_97_count>=4 then
          if not long_710.sidestep_97_exhausted then
            long_710.sidestep_97_exhausted=true
            auto_write(emu.framecount(),"relay_97_sidestep_exhausted",9,7,"B",
              "attempts="..long_710.sidestep_97_count..
              "|blocker="..blocker.."|cross="..string.format("%.2f",cross))
          end
        elseif blocker and (loop_back or support_count>=2 or not support_g or
             emu.framecount()<cooldown) and
             (not long_710.last_universal_reject_frame or
              emu.framecount()-long_710.last_universal_reject_frame>=24) then
          long_710.last_universal_reject_frame=emu.framecount()
          auto_write(emu.framecount(),"universal_support_rejected",from,blocker,"B",
            "primary_target="..tostring(target)..
            "|reason="..(loop_back and "immediate_return" or
              (support_count>=2 and "attempt_limit" or
              (not support_g and "invalid_geometry" or
              (not improves and "no_queue_progress" or "cooldown")))))
        elseif blocker and missing and not long_710.return_due and
           long_710.walk_ticks<4 then
          long_710.phase="sidestep"
          long_710.walk_start=emu.framecount()
          long_710.walk_ticks=long_710.walk_ticks+1
          long_710.origin=from;long_710.target=target
          long_710.walk_dir=lane_escape(sample_for_auto,from,target) or "Up"
          auto_write(emu.framecount(),"last_missing_sidestep_started",from,target,"B",
            "blocker="..tostring(blocker).."|direction="..long_710.walk_dir)
        elseif blocker then
          -- v0.8.95: choose a previously visited teammate as support during
          -- PLANNING, not only after entering the face phase.
          local support_key=tostring(from)..":"..tostring(blocker)
          local support_count=long_710.support_attempts[support_key] or 0
          local support_g=support_receiver(sample_for_auto,from,target,blocker)
          local next_leg=support_g and pair_geometry(sample_for_auto,blocker,target)
          local good_support=next_leg and next_leg.distance+12<distance
            and not lane_blocker(sample_for_auto,blocker,target)
          if support_g and good_support and support_count<2 and
             blocker~=long_710.universal_previous_holder then
            long_710.support_attempts[support_key]=support_count+1
            long_710.original_target=queue_target or target
            long_710.support_target=blocker
            long_710.origin=from
            long_710.target=blocker
            long_710.initial=support_g.distance
            long_710.direction=support_g.direction
            long_710.receiver_start={x=support_g.xy.tx,y=support_g.xy.ty}
            long_710.carrier_start={x=support_g.xy.hx,y=support_g.xy.hy}
            long_710.start=emu.framecount()
            long_710.shot_frame=nil
            long_710.fast_pass=true
            long_710.phase="face"
            long_710.cooldown_until=0
            auto_write(emu.framecount(),"final_support_planned",from,blocker,"B",
              "final_target="..tostring(missing or target)..
              "|support_target="..tostring(blocker)..
              "|already_visited="..tostring(spatial.visited[blocker]==true)..
              "|direction="..support_g.direction..
              "|distance="..string.format("%.2f",support_g.distance)..
              "|attempt="..(support_count+1))
          else
            if not long_710.last_support_reject_frame or
                emu.framecount()-long_710.last_support_reject_frame>=24 then
              long_710.last_support_reject_frame=emu.framecount()
              auto_write(emu.framecount(),"final_support_rejected",from,blocker,"B",
                "final_target="..tostring(missing or target)..
                "|reason="..(support_count>=2 and "attempt_limit" or "invalid_support_geometry"))
            end
          end
          if not long_710.last_blocker_frame or
             emu.framecount()-long_710.last_blocker_frame>=24 then
            long_710.last_blocker_frame=emu.framecount()
            auto_write(emu.framecount(),"long_pass_lane_blocked",from,target,"B",
              "blocker="..tostring(blocker).."|cross="..string.format("%.2f",cross)..
              "|distance="..string.format("%.2f",distance))
          end
        elseif distance>=35 and distance<=410 and math.abs(dy)<=100 then
          long_710.start=emu.framecount()
          long_710.shot_frame=nil
          long_710.attempts[attempt_key]=(long_710.attempts[attempt_key] or 0)+1
          long_710.phase=(from==7 and target==10) and "advance" or "face"
          long_710.advance_start=emu.framecount()
          long_710.advance_origin={x=xy.hx,y=xy.hy}
          long_710.advance_target={x=xy.tx,y=xy.ty}
          long_710.receiver_start={x=xy.tx,y=xy.ty}
          long_710.carrier_start={x=xy.hx,y=xy.hy}
          if from==9 and target==7 then
            auto_write(emu.framecount(),"relay_97_started",9,7,"B",
              "distance="..string.format("%.2f",distance)..
              "|dx="..dx.."|dy="..dy.."|gap="..string.format("%.2f",gap))
          end
          long_710.initial=distance;long_710.target=target
          long_710.origin=from
          long_710.trial_kind=long_710.return_due and "return_7_to_10"
             or (missing and "last_missing" or
                (from==9 and target==7 and "relay_9_to_7" or "relay_710"))
          if long_710.return_due then
            long_710.return_due=false;long_710.returns=long_710.returns+1
          end
          long_710.direction=pair_geometry(sample_for_auto,from,target).direction
          -- Suspend normal approach immediately for this bounded experiment.
          pass_chain.next_frame=emu.framecount()+150
          auto_write(emu.framecount(),"long_710_started",from,target,"B",
            "distance="..string.format("%.2f",distance)..
            "|dx="..dx.."|dy="..dy.."|direction="..long_710.direction..
            "|kind="..long_710.trial_kind.."|ball_gap="..string.format("%.2f",gap))
        end
      end
    end
  end
  -- Shift part of the receiving burden to player 7, using observed motion
  -- rather than assuming the receiver will run to meet the ball.
  if long_710.phase=="align" then
    local frame=emu.framecount()
    local g=pair_geometry(sample_for_auto,long_710.origin,long_710.target)
    local gap=carrier_gap(sample_for_auto,long_710.origin)
    buttons={}
    pass_chain.next_frame=frame+2
    if spatial.holder~=long_710.origin or not g or not gap or gap>18 then
      auto_write(frame,"queue_alignment_stopped",long_710.origin,long_710.target,"B",
        "reason=possession_or_geometry")
      long_710.phase="ready";long_710.cooldown_until=frame+18
    else
      local elapsed=frame-long_710.align_start
      local walked=math.sqrt((g.xy.hx-long_710.align_origin.x)^2+
                             (g.xy.hy-long_710.align_origin.y)^2)
      local gain=long_710.align_initial_gap-g.distance
      if math.abs(g.dy)<=100 or elapsed>=18 or walked>=42 then
        local progress=gain>=5 or walked>=5
        if progress then
          long_710.align_no_progress=0
        else
          long_710.align_no_progress=long_710.align_no_progress+1
          long_710.align_mode=(long_710.align_mode+1)%3
        end
        long_710.phase="ready"
        long_710.cooldown_until=frame+8
        long_710.watchdog_last_action=frame
        auto_write(frame,"queue_alignment_result",long_710.origin,long_710.target,"B",
          "reason="..(math.abs(g.dy)<=100 and "aligned" or
                       (progress and "bounded_progress" or "insufficient_progress"))..
          "|walk="..string.format("%.2f",walked)..
          "|gain="..string.format("%.2f",gain)..
          "|dy="..g.dy.."|no_progress="..long_710.align_no_progress)
        if long_710.align_no_progress>=3 then
          long_710.watchdog_release_until=frame+48
          auto_write(frame,"queue_alignment_fallback",long_710.origin,long_710.target,"B",
            "reason=repeated_no_progress|release_frames=48")
        end
      else
        buttons=approach_buttons(g)
        if long_710.align_mode==1 then
          buttons={ [g.dy>0 and "Down" or "Up"]=true }
        elseif long_710.align_mode==2 then
          buttons={ [g.dx>0 and "Right" or "Left"]=true }
        end
      end
    end
  end
  if long_710.phase=="advance" then
    local frame=emu.framecount()
    local xy=Ordered.capture(sample_for_auto,7,10)
    local gap=ball_gap_710(sample_for_auto)
    buttons={}
    if not xy or not gap or gap>18 or spatial.holder~=7 then
      long_710.phase="done";long_710.cooldown_until=frame+36
      auto_write(frame,"long_710_advance_aborted",7,10,"B",
        "reason=geometry_or_possession")
    else
      local dx=xy.hx-long_710.advance_origin.x
      local dy=xy.hy-long_710.advance_origin.y
      local progress=math.sqrt(dx*dx+dy*dy)
      local elapsed=frame-long_710.advance_start
      if elapsed>=18 or progress>=40 then
        long_710.phase="face";long_710.start=frame;long_710.fast_pass=true
        auto_write(frame,"long_710_advance_finished",7,10,"B",
          "carrier_dx="..dx.."|carrier_dy="..dy..
          "|carrier_walk="..string.format("%.2f",progress)..
          "|receiver_dx="..(xy.tx-long_710.advance_target.x)..
          "|receiver_dy="..(xy.ty-long_710.advance_target.y)..
          "|distance_after="..string.format("%.2f",math.sqrt(
            (xy.tx-xy.hx)^2+(xy.ty-xy.hy)^2)))
      else
        buttons=approach_buttons(pair_geometry(sample_for_auto,7,10))
      end
    end
  end
  if long_710.phase=="sidestep" then
    local frame=emu.framecount()
    local xy=Ordered.capture(sample_for_auto,long_710.origin,long_710.target)
    local gap=ball_gap_710(sample_for_auto)
    if long_710.origin~=7 and sample_for_auto and sample_for_auto.ball then
      for _,p in ipairs(sample_for_auto.players or {}) do
        if p.id==long_710.origin then
          gap=math.sqrt((sample_for_auto.ball.x-p.x)^2+
                        (sample_for_auto.ball.y-p.y)^2)
        end
      end
    end
    buttons={}
    if not xy or not gap or gap>18 or spatial.holder~=long_710.origin then
      long_710.phase="ready"
      auto_write(frame,long_710.origin==9 and long_710.target==7
        and "relay_97_sidestep_aborted" or "last_missing_sidestep_aborted",
        long_710.origin,long_710.target,"B","reason=loss_of_possession")
    elseif frame-long_710.walk_start<6 then
      if long_710.walk_dir=="UpRight" then buttons={Up=true,Right=true}
      elseif long_710.walk_dir=="DownRight" then buttons={Down=true,Right=true}
      elseif long_710.walk_dir=="UpLeft" then buttons={Up=true,Left=true}
      elseif long_710.walk_dir=="DownLeft" then buttons={Down=true,Left=true}
      else buttons={[long_710.walk_dir]=true} end
    else
      long_710.phase="ready"
      local is97=long_710.origin==9 and long_710.target==7
      local blocker,cross=lane_blocker(sample_for_auto,long_710.origin,long_710.target)
      if not blocker and long_710.origin and long_710.target then
        long_710.phase="face";long_710.start=frame
        local g=pair_geometry(sample_for_auto,long_710.origin,long_710.target)
        if g then long_710.direction=g.direction end
        auto_write(frame,"relay_lane_open_pass_queued",long_710.origin,long_710.target,"B",
          "direction="..tostring(long_710.direction))
      end
      local origin=long_710.sidestep_97_initial
      local delta_x=origin and xy.hx-origin.x or 0
      local delta_y=origin and xy.hy-origin.y or 0
      auto_write(frame,is97 and "relay_97_sidestep_finished"
        or "last_missing_sidestep_finished",long_710.origin,long_710.target,"B",
        "direction="..long_710.walk_dir..
        "|holder_x="..xy.hx.."|holder_y="..xy.hy..
        "|dx="..delta_x.."|dy="..delta_y..
        "|blocker="..tostring(blocker).."|cross="..tostring(cross)..
        "|previous_cross="..tostring(long_710.sidestep_97_last_cross))
    end
  end
  if long_710.phase=="face" or long_710.phase=="observe" then
    local frame=emu.framecount()
    -- Preserve normal route state; delay the ordinary controller until
    -- the trial completes, then resume with actual receiver observations.
    pass_chain.next_frame=frame+2
    buttons={}
    if long_710.phase=="face" then
      -- Possession must be measured against the ACTUAL origin, not player 7.
      local gap=carrier_gap(sample_for_auto,long_710.origin)
      local coords=Ordered.capture(sample_for_auto,long_710.origin,long_710.target)
      local failure=nil
      if spatial.holder~=long_710.origin then
        failure="holder_changed"
      elseif not coords then
        failure="invalid_coordinates"
      elseif not gap then
        failure="missing_ball_or_origin"
      elseif gap>18 then
        failure="ball_out_of_range"
      end
      if failure then
        long_710.phase="done";long_710.cooldown_until=frame+36
        long_710.final_next_retry=frame+36
        auto_write(frame,"long_710_aborted",long_710.origin,long_710.target,selected_pass_button,
          "reason="..failure.."|actual_holder="..tostring(spatial.holder)..
          "|ball_gap="..tostring(gap).."|origin="..tostring(long_710.origin)..
          "|target="..tostring(long_710.target))
      else
        local elapsed=frame-long_710.start
        local g=pair_geometry(sample_for_auto,long_710.origin,long_710.target)
        if g then long_710.direction=g.direction end
        local blocker=lane_blocker(sample_for_auto,long_710.origin,long_710.target)
        if blocker then
          local key=tostring(long_710.origin)..":"..tostring(blocker)
          local count=long_710.support_attempts[key] or 0
          local sg=support_receiver(sample_for_auto,long_710.origin,long_710.target,blocker)
          if sg and count<2 and long_710.origin~=blocker then
            long_710.support_attempts[key]=count+1
            long_710.original_target=long_710.original_target or long_710.target
            long_710.target=blocker
            long_710.direction=sg.direction
            long_710.fast_pass=true
            long_710.start=frame
            long_710.shot_frame=nil
            buttons={}
            auto_write(frame,"relay_support_blocker_selected",long_710.origin,blocker,"B",
              "original_target="..tostring(long_710.original_target)..
              "|already_visited="..tostring(spatial.visited[blocker]==true)..
              "|direction="..sg.direction.."|attempt="..(count+1))
          else
            buttons={};long_710.phase="ready"
            long_710.cooldown_until=frame+12
            auto_write(frame,"relay_support_unavailable",long_710.origin,long_710.target,"B",
              "blocker="..tostring(blocker).."|attempts="..count)
          end
          auto_write(frame,"relay_pass_cancelled_blocker",long_710.origin,long_710.target,"B",
            "blocker="..tostring(blocker))
        elseif long_710.fast_pass and elapsed<2 then
          buttons={[long_710.direction]=true,B=true}
          if not long_710.shot_frame then
            long_710.shot_frame=frame
            auto_write(frame,"relay_fast_directional_b",long_710.origin,long_710.target,"B",
              "direction="..long_710.direction.."|distance="..string.format("%.2f",g.distance))
          end
        elseif long_710.fast_pass then
          long_710.fast_pass=false
          long_710.phase="observe"
        elseif elapsed<3 then
          buttons=approach_buttons(g)
        elseif elapsed<5 then
          buttons={}
        elseif elapsed<7 then
          buttons={[long_710.direction]=true,B=true}
          if not long_710.shot_frame then
            long_710.shot_frame=frame
            auto_write(frame,"long_710_directional_b",long_710.origin,long_710.target,"B",
              "distance="..tostring(long_710.initial)..
              "|holder_x="..tostring(g and g.xy.hx)..
              "|holder_y="..tostring(g and g.xy.hy)..
              "|target_x="..tostring(g and g.xy.tx)..
              "|target_y="..tostring(g and g.xy.ty)..
              "|dx="..tostring(g and g.dx)..
              "|dy="..tostring(g and g.dy)..
              "|direction="..long_710.direction.."|simultaneous=true")
          end
        else
          long_710.phase="observe"
        end
      end
    else
      if spatial.holder==long_710.target then
        long_710.fast_pass=false;long_710.original_target=nil
        long_710.phase="done";long_710.cooldown_until=frame+36
        local xy=Ordered.capture(sample_for_auto,long_710.origin,long_710.target)
        if xy and long_710.receiver_start and long_710.carrier_start then
          auto_write(frame,"long_710_motion_result",long_710.origin,long_710.target,"B",
            "carrier_dx="..(xy.hx-long_710.carrier_start.x)..
            "|carrier_dy="..(xy.hy-long_710.carrier_start.y)..
            "|receiver_dx="..(xy.tx-long_710.receiver_start.x)..
            "|receiver_dy="..(xy.ty-long_710.receiver_start.y))
        end
        auto_write(frame,"long_710_receiver_observed",long_710.origin,long_710.target,"B",
          "holder="..tostring(long_710.target).."|confidence=spatial_only")
      elseif frame-(long_710.shot_frame or frame)>=120 then
        long_710.phase="done";long_710.cooldown_until=frame+36
        auto_write(frame,"long_710_observation_timeout",long_710.origin,long_710.target,"B",
          "holder="..tostring(spatial.holder).."|success_unverified")
      end
    end
    if long_710.phase=="done" then pass_chain.next_frame=frame+1 end
  end
  if pass_chain.active and
      (last_missing_710(spatial.visited,spatial.holder) or
       (spatial.holder==9 and not spatial.visited[7]
        and not long_710.sidestep_97_exhausted))
      and long_710.phase=="ready" then
    -- Do not allow stale ordinary approach commands to move toward player 10.
    buttons={}
  end
  -- Audit actual input and paired coordinates for ANY selected relay.
  if armed and sample_for_auto and spatial.holder then
    local target=first_unvisited(spatial.visited,spatial.holder) or long_710.target
    if not target and long_710.phase=="ready" then
      target=last_missing_710(spatial.visited,spatial.holder)
        or Ordered.next(nil,spatial.holder,spatial.visited)
    end
    if target and target~=spatial.holder and emu.framecount()%6==0 then
      local g=pair_geometry(sample_for_auto,spatial.holder,target)
      if g then
        auto_write(emu.framecount(),"relay_coordinates",spatial.holder,target,"B",
          "hx="..g.xy.hx.."|hy="..g.xy.hy..
          "|tx="..g.xy.tx.."|ty="..g.xy.ty..
          "|dx="..g.dx.."|dy="..g.dy..
          "|distance="..string.format("%.2f",g.distance)..
          "|direction="..g.direction..
          "|up="..tostring(buttons.Up==true)..
          "|down="..tostring(buttons.Down==true)..
          "|left="..tostring(buttons.Left==true)..
          "|right="..tostring(buttons.Right==true)..
          "|B="..tostring(buttons.B==true))
      end
    end
  end
  joypad.set(buttons,1)
  emu.frameadvance()
end
