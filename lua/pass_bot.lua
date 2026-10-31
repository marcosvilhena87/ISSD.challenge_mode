-- PASS LV.1 v0.1: observational runner. No speculative RAM writes or automatic pass inputs.
-- Runtime: BizHawk NLua (SNES). Operator commands: ARM, STOP.
local root=assert(_G.ISSD_PROJECT_ROOT,"Launch from main.lua")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance
  and joypad and joypad.set,"BizHawk APIs missing")
local Probe=require("challenge.probe")
local Tracking=require("challenge.pass_tracking_v02")
local Commands=require("challenge.dribble_commands_v035")
local function mkdir(p) os.execute('mkdir "'..p..'" >nul 2>&1') end
mkdir(root.."/csv"); mkdir(root.."/txt")
local log_path=root.."/csv/pass_lv1_observations_v01.csv"
local command_path=root.."/txt/pass_bot_commands_v01.txt"
local function csv(v)
  local out={}
  for i=1,#v do out[i]='"'..tostring(v[i]==nil and "" or v[i]):gsub('"','""')..'"' end
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
local tracker=Tracking.new_tracker(3)
local tracking_log=root.."/csv/pass_lv1_tracking_v02.csv"
local tf=assert(io.open(tracking_log,"ab"))
if tf:seek("end")==0 then
 assert(tf:write("session,frame,event,from_player,to_player,visited_count,planned_route,estimated_distance,confidence\n"))
end
tf:close()
local function track_write(row)
 local f=assert(io.open(tracking_log,"ab"));assert(f:write(csv(row)));assert(f:close())
end
local armed=false
local previous=nil
local function release() joypad.set({},1) end
local function record(event,p)
  local raw=p.raw or {}
  local row={session,emu.framecount(),event,armed and 1 or 0,p.status,p.challenge,p.level,
    raw.challenge_a,raw.challenge_b,raw.selected_level,p.reason}
  local h=assert(io.open(log_path,"ab"));assert(h:write(csv(row)));assert(h:close())
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
    if cmd=="ARM" then
      -- Probe is not proof of gameplay; explicit LV.1 selection is a safety gate.
      if p.status=="candidate" and p.challenge=="PASS" and p.level==1 then
        armed=true;tracker=Tracking.new_tracker(3);record("armed_candidate_only",p)
        print("[ISSD.pass_lv1] armed for observation; PASS LV.1 identity remains unconfirmed")
      else
        armed=false;record("arm_rejected",p)
        print("[ISSD.pass_lv1] ARM rejected: PASS LV.1 candidate not observed")
      end
    elseif cmd=="STOP" then
      armed=false;record("stopped",p);release()
    else
      print("[ISSD.pass_lv1] unknown command: "..line)
    end
  end)
  -- Never output controller buttons until targets and controls are validated.
  release()
  emu.frameadvance()
end
