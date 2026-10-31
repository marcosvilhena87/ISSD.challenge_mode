-- PASS LV.1 v0.1: observational runner. No speculative RAM writes or automatic pass inputs.
-- Runtime: BizHawk NLua (SNES). Operator commands: ARM, STOP.
local root=assert(_G.ISSD_PROJECT_ROOT,"Launch from main.lua")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance
  and joypad and joypad.set,"BizHawk APIs missing")
local Probe=require("challenge.probe")
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
  commands.poll(function(line)
    local cmd=line:upper()
    if cmd=="ARM" then
      -- Probe is not proof of gameplay; explicit LV.1 selection is a safety gate.
      if p.status=="candidate" and p.challenge=="PASS" and p.level==1 then
        armed=true;record("armed_candidate_only",p)
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
