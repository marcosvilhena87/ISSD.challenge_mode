-- DRIBBLE v0.3.2.5: observational synchronization, no input-policy changes.
local Base=require("challenge.dribble_goal_v0324")
local M={}
function M.new()
 return {base=Base.new(),phase="flags",event="",diag="",flags_frame=nil,shot_frame=nil,
  exit_frame=nil,calibration=nil,calibration_result=nil,sync=nil,sync_result=nil}
end
local function diff(a,b,c,d) return math.abs(a-c)+math.abs(b-d) end
function M.step(s,st)
 st=st or M.new();st.event="";st.diag=""
 if not st.sync and not st.sync_result and s.gs==0 and s.ptr==0x0F00 and s.remaining==5 then
  st.sync={arm=s.frame,px=s.px,py=s.py,bx=s.bx,by=s.by,
   time_initial=s.time,time_previous=s.time,time_change=nil,
   first_ball=nil,first_player=nil,started_on_active_clock=false}
  st.event="start_sync_started"
 end
 local q=st.sync
 if q and type(s.frame)=="number" and type(s.px)=="number" and type(s.py)=="number"
  and type(s.bx)=="number" and type(s.by)=="number" then
  if not q.first_ball and diff(s.bx,s.by,q.bx,q.by)>=3 then q.first_ball=s.frame end
  if not q.first_player and diff(s.px,s.py,q.px,q.py)>=3 then q.first_player=s.frame end
  if not q.time_change and type(s.time)=="number" and type(q.time_previous)=="number"
    and s.time~=q.time_previous then q.time_change=s.frame end
  if type(s.time)=="number" then q.time_previous=s.time end
  st.diag=table.concat({"sync",s.frame-q.arm,q.first_ball or "",q.first_player or "",
   q.time_change or "",s.time or ""},"|")
 end
 local b,base,reason=Base.step(s,st.base)
 st.base=base;st.phase=base.phase
 st.flags_frame=base.flags_frame;st.shot_frame=base.shot_frame;st.exit_frame=base.exit_frame
 st.calibration=base.calibration;st.calibration_result=base.calibration_result
 if q and (s.frame-q.arm>=90 or s.remaining~=5 or s.gs~=0 or s.ptr~=0x0F00) then
  st.sync_result={arm=q.arm,first_ball=q.first_ball,first_player=q.first_player,
    timer_change=q.time_change,initial_time=q.time_initial,
    final_time=s.time,finish=s.frame,
    clock_status=q.time_change and "clock_transition_observed" or "clock_start_unverified"}
  st.sync=nil
  st.event="start_sync_completed"
 end
 if base.event~="" then
  st.event=st.event=="" and base.event or st.event.."|"..base.event
 end
 return b,st,reason
end
return M
