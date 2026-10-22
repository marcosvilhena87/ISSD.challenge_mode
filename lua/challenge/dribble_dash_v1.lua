-- DRIBBLE LV.1 conservative far-field Dash (Y), pure and reversible.
local M={MIN_DISTANCE=100,MAX_BALL_GAP=24}
function M.apply(buttons,s,reason,waypoints)
 if type(buttons)~="table" then return buttons,false end
 buttons.Y=nil -- never carry Y into recovery, shooting, or precision states
 if reason~="waypoint" or s.gs~=0 or s.ptr~=0x0F00 or
  type(s.remaining)~="number" or s.remaining<1 or s.remaining>5 or
  type(s.px)~="number" or type(s.py)~="number" or
  type(s.bx)~="number" or type(s.by)~="number" or
  s.poss~=0x0F00 or buttons.B then return buttons,false end
 if not (buttons.Left or buttons.Right or buttons.Up or buttons.Down) then return buttons,false end
 local wp=waypoints[6-s.remaining]
 if not wp then return buttons,false end
 local dx,dy=wp[1]-s.px,wp[2]-s.py
 if dx*dx+dy*dy<M.MIN_DISTANCE*M.MIN_DISTANCE then return buttons,false end
 local bx,by=s.bx-s.px,s.by-s.py
 if bx*bx+by*by>M.MAX_BALL_GAP*M.MAX_BALL_GAP then return buttons,false end
 buttons.Y=true
 return buttons,true
end
return M
