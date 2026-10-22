-- Pure reusable passive DRIBBLE result detector. No BizHawk, file, joypad or globals.
local M={}
local function key(s)
 if type(s.time)~="number" or type(s.bonus)~="number" or type(s.total)~="number" then return "unreadable" end
 return s.time..":"..s.bonus..":"..s.total
end
function M.new(opts)
 opts=opts or {}
 return {opts={enter=opts.enter or 10,stable=opts.stable or 90,copy_wait=opts.copy_wait or 1200,
  max_game=opts.max_game or 7200},active=nil,consecutive=0,next_id=0,blocked=false}
end
function M.step(st,s)
 assert(type(s.frame)=="number" and type(s.gameplay)=="boolean","frame/gameplay required")
 local events={}
 local function emit(name,a,extra)
  events[#events+1]={type=name,id=a and a.id or nil,frame=s.frame,sample=s,trial=a,extra=extra}
 end
 st.consecutive=s.gameplay and st.consecutive+1 or 0
 if not st.active and not st.blocked and st.consecutive==st.opts.enter and s.remaining==5 then
  st.next_id=st.next_id+1
  st.active={id=st.next_id,start=s.frame,first_zero=nil,exited=nil,latest_key=key(s),
   stable_since=s.frame,changes=0,first_change=nil,last_change=nil,main_changed_post_exit=false,
   preliminary=nil,copy_confirmed_frame=nil}
  emit("gameplay_start_candidate",st.active)
 end
 local a=st.active
 if a then
  local k=key(s)
  if k~=a.latest_key then
   local previous=a.latest_key
   a.latest_key=k;a.stable_since=s.frame;a.changes=a.changes+1
   a.first_change=a.first_change or s.frame;a.last_change=s.frame
   if a.exited then a.main_changed_post_exit=true end
   emit("primary_change",a,{previous=previous,current=k,phase=a.exited and "POST_EXIT" or "GAMEPLAY"})
   if a.preliminary then
    emit("early_candidate_superseded",a)
    a.preliminary=nil;a.copy_confirmed_frame=nil
   end
  end
  if s.gameplay and s.remaining==0 and not a.first_zero then a.first_zero=s.frame;emit("fifth_flag_candidate",a) end
  if not s.gameplay and not a.exited then a.exited=s.frame;emit("gameplay_exit_candidate",a) end
  local coherent=s.time~=nil and s.bonus~=nil and s.total~=nil and s.total==s.time+s.bonus
  if a.exited and not a.preliminary and a.first_zero and a.main_changed_post_exit and coherent and
    s.frame-a.stable_since>=st.opts.stable then
   local verdict=s.bonus>0 and "positive_bonus_candidate" or
     (s.time>0 and "time_only_candidate" or "zero_score_candidate")
   a.preliminary={frame=s.frame,time=s.time,bonus=s.bonus,total=s.total,verdict=verdict}
   emit("early_result_candidate",a)
  end
  if a.preliminary and not a.copy_confirmed_frame and s.copy~=nil and s.copy==a.preliminary.total then
   a.copy_confirmed_frame=s.frame;emit("late_copy_correlated",a)
  end
  local reason
  if not a.exited then
   if s.frame-a.start>st.opts.max_game then reason="gameplay_timeout" end
  elseif a.preliminary and a.copy_confirmed_frame then reason="copy_correlation_observed"
  elseif s.frame-a.exited>=st.opts.copy_wait then reason="post_exit_timeout"
  elseif s.gameplay and st.consecutive>=st.opts.enter then reason="new_game_before_resolution" end
  if reason then
   local verdict=not a.exited and "gameplay_interrupted" or
    (not a.first_zero and "five_flags_unobserved" or
    (not a.preliminary and "no_stable_fresh_primary_result" or
    (a.copy_confirmed_frame and "copy_correlated_candidate" or "copy_unverified")))
   emit("trial_closed",a,{reason=reason,verdict=verdict})
   st.active=nil;st.blocked=true
  end
 end
 if st.blocked and not s.gameplay then st.blocked=false end
 return events
end
return M
