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
assert(type(Ordered.observe)=="function" and type(Ordered.step)=="function",
  "v0.8.23 requires updated challenge.pass_ordered_v0820; restart main.lua")
local Feet=require("challenge.pass_feet_v0815")
Auto=require("challenge.pass_auto_v071")
package.loaded["challenge.goal_evidence_v4"]=nil
package.loaded["challenge.pass_goal_evidence_v0826"]=nil
local GoalEvidence=require("challenge.pass_goal_evidence_v0826")
local Finish=require("challenge.pass_finish_v07")
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
        armed=true;tracker=Tracking.new_tracker(3);possession=Possession.new({minimum=3});spatial=Spatial.new({threshold=24,gap=6,stable=4});timers=Timers.new();bonus=Bonus.new();completion_frame=nil;last_spatial_frame=nil;autopass=Auto.new();finish=Finish.new();goal_monitor=GoalEvidence.new(GoalEvidence.read(memory.read_u8,memory.read_u16_le,emu.framecount()));finish.enabled=auto_finish_queued;auto_finish_queued=false
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
  if armed and autopass.enabled and not auto_finished and sample_for_auto
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
    local reason
    local phase_before=autopass.phase
    if autopass.phase=="idle" and not plan and selector_reason=="approach_required"
        and pass_chain.active and holder then
      local target=bridge_info and bridge_info.target
      local movement=pass_chain.approach_state
      local approach_limit=movement.approach_limit or Ordered.MAX_APPROACH
      if (pass_chain.approach_frames or 0)>=approach_limit then
        local measurement=Feet.measure(sample_for_auto,holder,target)
        local can_extend,why=Ordered.can_extend(movement,pass_chain.approach_frames,measurement)
        if can_extend and approach_limit<Ordered.MAX_APPROACH_ABSOLUTE then
          movement.approach_limit=math.min(approach_limit+Ordered.EXTEND_FRAMES,Ordered.MAX_APPROACH_ABSOLUTE)
          auto_write(emu.framecount(),"approach_extended",holder,target,selected_pass_button,
            "old_limit="..approach_limit.."|new_limit="..movement.approach_limit..
            "|distance="..tostring(measurement and measurement.distance)..
            "|best="..tostring(movement.best_distance).."|reason="..why)
          buttons={};reason="approach_extension_neutral"
          movement.burst_remaining=0;movement.burst_buttons=nil
          pass_chain.approach_neutral=false
        else
          local recovered,dir=Ordered.recover(movement,measurement)
          if recovered and (pass_chain.approach_frames or 0)<Ordered.MAX_APPROACH_ABSOLUTE then
            movement.approach_limit=math.min(approach_limit+16,Ordered.MAX_APPROACH_ABSOLUTE)
            movement.burst_remaining=0;movement.burst_buttons=nil
            pass_chain.approach_neutral=false;buttons={};reason="approach_recovery_neutral"
            auto_write(emu.framecount(),"approach_recovery_started",holder,target,selected_pass_button,
              "direction="..dir.."|limit="..movement.approach_limit.."|cause="..why)
          else
          reason="approach_timeout";buttons={};autopass.enabled=false
          pass_chain.active=false;auto_finished=true
          auto_write(emu.framecount(),"approach_timeout",holder,target,selected_pass_button,
            "limit="..approach_limit.."|absolute="..Ordered.MAX_APPROACH_ABSOLUTE.."|reason="..why)
          end
        end
      elseif pass_chain.approach_neutral then
        buttons={};reason="approach_neutral";pass_chain.approach_neutral=false
        local measurement=Feet.measure(sample_for_auto,holder,target)
        local motion_feedback=Ordered.observe_motion(movement,sample_for_auto,holder,target)
        local motion=movement.last_motion
        if motion then
          auto_write(emu.framecount(),"approach_motion_calibration",holder,target,selected_pass_button,
            "result="..motion_feedback.."|direction="..tostring(motion.direction)..
            "|holder_dx="..tostring(motion.holder_dx).."|holder_dy="..tostring(motion.holder_dy)..
            "|receiver_dx="..tostring(motion.target_dx).."|receiver_dy="..tostring(motion.target_dy)..
            "|projection="..tostring(motion.projection))
        end
        movement.burst_positions=nil
        local feedback=Ordered.observe(pass_chain.approach_state,measurement)
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
          local recovered,dir=Ordered.recover(movement,measurement)
          if recovered and (pass_chain.approach_frames or 0)<Ordered.MAX_APPROACH_ABSOLUTE then
            movement.approach_limit=math.min(math.max(movement.approach_limit or Ordered.MAX_APPROACH,pass_chain.approach_frames+16),Ordered.MAX_APPROACH_ABSOLUTE)
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
            buttons=new_buttons;reason="approach_step"
          else
            buttons={};reason=check;movement.burst_remaining=0
          end
        else
          buttons,reason=Ordered.step(sample_for_auto,holder,target,movement)
          if reason=="approach_step" then
            movement.burst_buttons=buttons
            local initial=Feet.measure(sample_for_auto,holder,target)
            movement.burst_start=initial
            movement.burst_positions=Ordered.capture(sample_for_auto,holder,target)
            for key,pressed in pairs(buttons) do if pressed then movement.burst_direction=key end end
            movement.burst_remaining=math.min(Ordered.BURST_FRAMES,
              (movement.approach_limit or Ordered.MAX_APPROACH)-(pass_chain.approach_frames or 0))
            auto_write(emu.framecount(),"approach_burst_started",holder,target,selected_pass_button,
              "frames="..movement.burst_remaining.."|axis="..tostring(movement.axis))
          end
        end
        if reason=="approach_step" then
          pass_chain.approach_frames=pass_chain.approach_frames+1
          if (movement.recovery_left or 0)>0 then movement.recovery_left=movement.recovery_left-1 end
          movement.burst_remaining=movement.burst_remaining-1
          pass_chain.approach_neutral=movement.burst_remaining==0
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
      if autopass.origin==6 and autopass.target==2 then
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
      auto_write(emu.framecount(),"receiver_selected",holder,receiver.id,selected_pass_button,
       string.format("distance=%s|misalignment=%s|cost=%s|aligned=%s",
        c and string.format("%.2f",c.distance) or "unknown",
        c and string.format("%.2f",c.misalignment) or "unknown",
        c and string.format("%.2f",c.cost) or "unknown",tostring(receiver.aligned)))
    elseif reason=="active_alignment_started" or reason=="active_alignment_ready"
      or (type(reason)=="string" and reason:match("^alignment_adjust_")) then
      auto_write(emu.framecount(),reason,autopass.origin,autopass.target,selected_pass_button,
        "correction_steps="..tostring(autopass.active_alignment and autopass.active_alignment.steps or 0).."|no_B=true")
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
        if holder==autopass.target then
          pass_chain.route_index=pass_chain.route_index+1
          pass_chain.approach_frames=0;pass_chain.approach_neutral=false;pass_chain.approach_state={}
          auto_write(emu.framecount(),"route_advanced",autopass.origin,holder,selected_pass_button,
            "index="..pass_chain.route_index.."/10")
        else
          auto_write(emu.framecount(),"route_deviation",autopass.origin,holder,selected_pass_button,
            "expected="..tostring(autopass.target).."|observed="..tostring(holder).."|recovery=continue")
          pass_chain.approach_frames=0;pass_chain.approach_neutral=false
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
    local shot,reason=Finish.step(finish,emu.framecount(),completion_frame,bonus.first_decrement_frame,sample_for_auto,spatial.holder)
    if reason=="shoot_pulse" or reason=="completion_and_bonus_observed" or reason=="finish_window_expired" then
      finish_write(emu.framecount(),reason)
      auto_write(emu.framecount(),"finish_"..reason,spatial.holder,nil,"X",
        "aim="..tostring(finish.aim_reason).."|direction="..tostring(finish.aim and (finish.aim.Left and "Left" or "Right"))..
        "|vertical="..tostring(finish.aim and (finish.aim.Up and "Up" or finish.aim.Down and "Down" or "neutral")))
    end
    -- Finalization only emits X once; it must never combine with pass B.
    if shot.X then
      buttons=shot;autopass.enabled=false
      if goal_monitor then
        goal_monitor.shot=emu.framecount()
        goal_monitor.complete=completion_frame
        goal_monitor.bonus=bonus.first_decrement_frame
        goal_write(emu.framecount(),"shot_x_issued",GoalEvidence.read(memory.read_u8,memory.read_u16_le,emu.framecount()))
      end
    elseif completion_frame then buttons={} end
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
  if buttons.X then log_input(emu.framecount(),"finish","shoot_pulse",spatial.holder,nil,buttons) end
  joypad.set(buttons,1)
  emu.frameadvance()
end
