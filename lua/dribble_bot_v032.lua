-- DRIBBLE Bot v0.3.2: two-phase pilot + conservative outcome evidence.
-- Only the operator can CONFIRM_GOAL; post-game state is not proof of success.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode","C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/dribble_goal_v031.lua") then root=p;break end end
assert(root,"repository root not found: expected lua/challenge/dribble_goal_v031.lua. Check working directory and git pull.")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.dribble_goal_v031"]=nil
local P=require("challenge.dribble_goal_v031")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.frameadvance and emu.framecount and joypad and joypad.set,"BizHawk API missing")
local session=os.date("!%Y%m%dT%H%M%SZ")
local command=root.."/dribble_bot_commands_v032.txt"
local trace=root.."/dribble_bot_trace_v032.csv"
local summary=root.."/dribble_bot_summary_v032.csv"
local function setup(path,header)
 local f=assert(io.open(path,"a+"));if f:seek("end")==0 then f:write(header.."\n") end;f:close()
end
setup(trace,"session,frame,armed,phase,event,reason,gs,ptr,remaining,poss,player_x,player_y,ball_x,ball_y,buttons,time_bcd,bonus_bcd,time_frac_u16,bonus_frac_u16")
setup(summary,"session,started_frame,flags_frame,shot_frame,exit_frame,flags_elapsed_frames,goal_elapsed_frames,total_elapsed_frames,flags_remaining,time_start_bcd,time_at_fifth_bcd,bonus_at_fifth_bcd,time_at_exit_bcd,bonus_at_exit_bcd,shot_attempts,exit_reason,outcome,evidence,record_score")
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
local function write(path,columns)
 for i,v in ipairs(columns) do columns[i]=textval(v) end
 local f=assert(io.open(path,"a"));f:write(table.concat(columns,",").."\n");f:close()
end
local function snapshot()
 local s={frame=emu.framecount(),gs=read(memory.read_u16_le,0x00BA),ptr=read(memory.read_u16_le,0x1ACC),remaining=read(memory.read_u8,0x006B4),poss=read(memory.read_u16_le,0x00A6),px=read(memory.read_s16_le,0x0F2A),py=read(memory.read_s16_le,0x0F2C),bx=read(memory.read_s16_le,0x042A),by=read(memory.read_s16_le,0x042C)}
 fields(s);return s
end
local function end_attempt()
 if not attempt or attempt.final then return end
 attempt.final=true;armed=false;pending=false;release()
 local s=attempt.last or snapshot()
 local ff=state.flags_frame;local xf=state.exit_frame
 local n=attempt.started
 write(summary,{attempt.id,n,ff,state.shot_frame,xf,ff and ff-n,nil ~= xf and ff and xf-ff or nil,xf and xf-n,s.remaining,attempt.time_start,attempt.time_fifth,attempt.bonus_fifth,attempt.time_exit,attempt.bonus_exit,state.base.shot_attempts,attempt.exit_reason,attempt.confirmed and "goal_confirmed_operator" or "unverified",attempt.confirmed and "operator_visual_confirmation" or "no_verified_goal_flag",attempt.score})
 print("[ISSD.dribble_bot] v0.3.2 summary saved session="..attempt.id.." outcome=unverified. Confirm with Python.")
end
local function command_handle(cmd)
 local c=cmd:upper()
 if c=="ARM" then
  if attempt and not attempt.final then end_attempt() end
  state=P.new();armed=true;pending=false;grace_exit=nil
  local s=snapshot();attempt={id=session.."_"..tostring(s.frame),started=s.frame,time_start=s.time,last=s,confirmed=false,score=nil,final=false}
  print("[ISSD.dribble_bot] v0.3.2 ARMED session="..attempt.id.." frame="..s.frame)
 elseif c=="STOP" then
  if attempt then attempt.exit_reason=attempt.exit_reason or "operator_stop" end
  end_attempt()
 elseif c=="CONFIRM_GOAL" or c:match("^SCORE:%d+$") then
  print("[ISSD.dribble_bot] v0.3.2 use confirm_dribble_score_v032.py --session "..(attempt and attempt.id or "<session>").." after summary generation")
 elseif c~="" then print("[ISSD.dribble_bot] ignored command: "..cmd) end
end
print("[ISSD.dribble_bot] v0.3.2 DISARMED; commands="..command)
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
  buttons,state,reason=P.step(s,state)
  local names={};for _,k in ipairs({"Left","Right","Up","Down","B"}) do if buttons[k] then names[#names+1]=k end end
  local keys=table.concat(names,"+")
  local allowed={waypoint=true,recover_ball=true,precision_approach=true,local_search=true,goal_approach=true,shot_charge=true,shot_release=true,await_goal_observation=true}
  if allowed[reason] then joypad.set(buttons,1) else release();armed=false;pending=true;grace_exit=s.frame+300;attempt.exit_reason=reason end
  attempt.last=s
  if state.flags_frame==s.frame then attempt.time_fifth=s.time;attempt.bonus_fifth=s.bonus end
  if state.exit_frame==s.frame then attempt.time_exit=s.time;attempt.bonus_exit=s.bonus end
  if s.frame%5==0 or state.event~="" or not allowed[reason] then
   write(trace,{attempt.id,s.frame,armed and 1 or 0,state.phase,state.event,reason,s.gs,s.ptr,s.remaining,s.poss,s.px,s.py,s.bx,s.by,keys,s.time,s.bonus,s.timefrac,s.bonusfrac})
  end
  if state.event~="" then print("[ISSD.dribble_bot] "..state.event.." frame="..s.frame) end
 elseif pending and grace_exit and emu.framecount()>=grace_exit then end_attempt()
 else release() end
 emu.frameadvance()
end
