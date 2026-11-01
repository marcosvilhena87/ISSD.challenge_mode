-- v0.8.12: observational possession gate; not proof of internal ROM ownership.
local M={}
function M.new()
 return {last_holder=nil,last_distance=nil,streak=0,required=4,
  max_distance=18,max_delta=3}
end
function M.step(t,sample,holder)
 if not holder or not sample or not sample.ball then
  t.last_holder=nil;t.last_distance=nil;t.streak=0
  return false,"missing_observation"
 end
 local p
 for _,player in ipairs(sample.players or {}) do
  if player.id==holder then p=player;break end
 end
 if not p then
  t.last_holder=nil;t.last_distance=nil;t.streak=0
  return false,"missing_player"
 end
 local dx,dy=p.x-sample.ball.x,p.y-sample.ball.y
 local d=math.sqrt(dx*dx+dy*dy)
 if d>t.max_distance then
  t.streak=0
  t.last_holder=holder;t.last_distance=d
  return false,"too_far",d
 end
 if t.last_holder~=holder or not t.last_distance or
     math.abs(d-t.last_distance)>t.max_delta then t.streak=1
 else t.streak=t.streak+1 end
 t.last_holder=holder;t.last_distance=d
 return t.streak>=t.required,t.streak>=t.required and "stable" or "stabilizing",d
end
return M
