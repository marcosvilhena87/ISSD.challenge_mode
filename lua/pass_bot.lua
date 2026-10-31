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
local Auto=require("challenge.pass_auto_v06")
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
local selected_pass_button=nil
local pending_auto=false
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
local auto_csv=root.."/csv/pass_auto_v06.csv"
local af=assert(io.open(auto_csv,"ab"))
if af:seek("end")==0 then assert(af:write("session,frame,event,from_player,to_player,button,reason\n")) end
af:close()
local function auto_write(frame,event,from,to,button,reason)
 local h=assert(io.open(auto_csv,"ab"))
 assert(h:write(csv({session,frame,event,from,to,button,reason},7)))
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
print("[ISSD.pass_lv1] OBSERVATION ONLY: no validated PASS targets or success signals")
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
    if cmd=="AUTO:ON" then
      if selected_pass_button then
       pending_auto=true;print("[ISSD.pass_lv1] AUTO queued ON for next ARM")
      else print("[ISSD.pass_lv1] AUTO denied: configure PASSBTN:A/B/X/Y/L/R first") end
    elseif cmd=="AUTO:OFF" then
      pending_auto=false;autopass.enabled=false;release()
      auto_write(emu.framecount(),"auto_off",nil,nil,selected_pass_button,"operator")
    elseif cmd:match("^PASSBTN:[ABXYLR]$") then
      selected_pass_button=cmd:sub(9)
      autopass.enabled=false;pending_auto=false;release()
      print("[ISSD.pass_lv1] experimental pass button="..selected_pass_button.." (requires AUTO:ON and ARM)")
    elseif cmd=="ARM" then
      -- Probe is not proof of gameplay; explicit LV.1 selection is a safety gate.
      if p.status=="candidate" and p.challenge=="PASS" and p.level==1 then
        armed=true;tracker=Tracking.new_tracker(3);possession=Possession.new({minimum=3});spatial=Spatial.new({threshold=24,gap=6,stable=4});timers=Timers.new();bonus=Bonus.new();completion_frame=nil;last_spatial_frame=nil;autopass=Auto.new()
        autopass.enabled=pending_auto and selected_pass_button~=nil;autopass.button=selected_pass_button;autopass.start_frame=emu.framecount()
        pending_auto=false
        auto_write(emu.framecount(),autopass.enabled and "auto_arm" or "observation_arm",nil,nil,selected_pass_button,"opt_in_required")
        record("armed_candidate_only",p)
        print("[ISSD.pass_lv1] armed for observation; PASS LV.1 identity remains unconfirmed")
      else
        armed=false;autopass.enabled=false;record("arm_rejected",p)
        print("[ISSD.pass_lv1] ARM rejected: PASS LV.1 candidate not observed")
      end
    elseif cmd:match("^SNAP:[A-Z0-9_]+$") then
      dump_wram(cmd:sub(6))
    elseif cmd=="STOP" then
      armed=false;autopass.enabled=false;pending_auto=false;record("stopped",p);release()
    else
      print("[ISSD.pass_lv1] unknown command: "..line)
    end
  end)
  -- Experimental control is explicitly opt-in; no RAM writes, no auto shot.
  local buttons={}
  if armed and autopass.enabled and sample_for_auto then
    local holder=spatial.holder
    local plan=holder and Tracking.plan(sample_for_auto.players,holder,spatial.visited) or nil
    local reason
    buttons,reason=Auto.step(autopass,emu.framecount(),sample_for_auto,holder,spatial.visited,plan,completion_frame~=nil)
    if reason=="pass_pulse" and autopass.last_attempt then
      local a=autopass.last_attempt
      auto_write(emu.framecount(),"pass_pulse",a.from,a.to,a.button,"experimental_unverified")
    elseif reason=="timeout" or reason=="attempt_limit" or reason=="completion_candidate_stop" then
      auto_write(emu.framecount(),"auto_stopped",holder,nil,selected_pass_button,reason)
    end
  end
  joypad.set(buttons,1)
  emu.frameadvance()
end
