-- Experimental PASS LV.1 controller; no automatic input unless explicitly enabled.
-- The only supported inputs are named SNES buttons configured by the operator.
local M={}
local allowed={A=true,B=true,X=true,Y=true,L=true,R=true}
function M.valid_button(v) return allowed[v] == true end
function M.new()
 return {enabled=false,button=nil,phase="idle",start_frame=nil,shot_frame=nil,
  target=nil,origin=nil,cooldown_until=0,last_attempt=nil,tries=0,reason="disabled"}
end
local function find(players,id)
 for _,p in ipairs(players or {}) do if p.id==id then return p end end
end
function M.step(t,frame,sample,holder,visited,plan,bonus_finished)
 local buttons={}
 if not t.enabled or not M.valid_button(t.button) then return buttons,"disabled" end
 if t.start_frame and frame-t.start_frame>3600 then
  t.enabled=false;t.phase="idle";return buttons,"timeout"
 end
 if bonus_finished or (visited and (function()
  local n=0;for _ in pairs(visited) do n=n+1 end;return n>=10
 end)()) then
  t.enabled=false;t.phase="idle";return buttons,"completion_candidate_stop"
 end
 if type(frame)~="number" or not sample or not holder or not find(sample.players,holder) then
  return buttons,"no_stable_holder"
 end
 if frame<t.cooldown_until then return buttons,"cooldown" end
 if t.phase=="await_transfer" then
  if holder~=t.origin then
   t.phase="idle";t.target=nil;t.origin=nil;return buttons,"transfer_observed"
  end
  if frame-(t.shot_frame or frame)<100 then return buttons,"await_transfer" end
  t.phase="idle";t.target=nil;t.origin=nil
  if t.tries>=15 then t.enabled=false;return buttons,"attempt_limit" end
 end
 if t.phase=="idle" then
  if not plan or type(plan.sequence)~="table" or not plan.sequence[1] then
   return buttons,"no_target"
  end
  t.target=plan.sequence[1];t.origin=holder;t.phase="aim"
 end
 local origin=find(sample.players,holder)
 local dest=find(sample.players,t.target)
 if not dest or not origin or dest.id==holder then return buttons,"invalid_target" end
 local dx,dy=dest.x-origin.x,dest.y-origin.y
 -- Input semantics/direction influence have not been validated in PASS LV.1.
 -- Aim for one frame, release for one frame, then pulse the pass button.
 if t.phase=="aim" then
  if math.abs(dx)>12 then buttons[dx>0 and "Right" or "Left"]=true end
  if math.abs(dy)>12 then buttons[dy>0 and "Down" or "Up"]=true end
  t.phase="release";return buttons,"aim"
 elseif t.phase=="release" then
  t.phase="pass";return {},"release"
 elseif t.phase=="pass" then
  buttons[t.button]=true;t.phase="await_transfer"
  t.shot_frame=frame;t.cooldown_until=frame+18;t.tries=t.tries+1
  t.last_attempt={frame=frame,from=holder,to=t.target,button=t.button}
  return buttons,"pass_pulse"
 end
 return buttons,"idle"
end
return M
