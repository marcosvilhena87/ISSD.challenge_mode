-- DRIBBLE LV.1 v0.2 waypoint navigation. Pure stateful policy; experimental coordinates.
local M={}
M.waypoints={{555,261},{772,304},{974,356},{1228,293},{1450,367}}
M.TIME_LIMIT=1800
local function valid(v) return type(v)=="number" and v==v and v%1==0 end
function M.new() return {last_remaining=nil,target=1,started=nil,stable_frame=nil,stable_x=nil,stable_y=nil,stuck=0} end
function M.step(s,st)
 st=st or M.new()
 local fields={"frame","gs","ptr","remaining","px","py","bx","by","poss"}
 for _,k in ipairs(fields) do if not valid(s[k]) then return {},st,"invalid_read" end end
 if s.gs~=0 or s.ptr~=0x0F00 then return {},st,"not_playing" end
 if s.remaining<0 or s.remaining>5 then return {},st,"invalid_count" end
 if not st.started then st.started=s.frame end
 if s.frame-st.started>=M.TIME_LIMIT then return {},st,"time_limit" end
 if st.last_remaining and s.remaining>st.last_remaining then return {},st,"counter_reset" end
 if st.last_remaining and st.last_remaining-s.remaining>1 then return {},st,"counter_jump" end
 st.target=6-s.remaining
 st.last_remaining=s.remaining
 if s.remaining==0 then return {},st,"five_collected" end
 local target=M.waypoints[st.target]
 if not target then return {},st,"no_waypoint" end
 local dx=target[1]-s.px
 local dy=target[2]-s.py
 local ball_dx=s.bx-s.px
 local ball_dy=s.by-s.py
 local has_ball=s.poss==0x0F00
 local buttons={}
 local reason="waypoint"
 local seek_ball=not has_ball and (math.abs(ball_dx)>34 or math.abs(ball_dy)>34)
 if seek_ball then dx=ball_dx;dy=ball_dy;reason="recover_ball" end
 -- Avoid alternating axes every frame; require small deadzone near waypoint.
 if dx>10 then buttons.Right=true elseif dx< -10 then buttons.Left=true end
 if dy>9 then buttons.Down=true elseif dy< -9 then buttons.Up=true end
 -- At a waypoint, do not auto-advance without the counter decreasing.
 if not seek_ball and math.abs(dx)<=10 and math.abs(dy)<=9 then
  reason="await_collection"
  if st.stable_frame==nil then st.stable_frame=s.frame end
  if s.frame-st.stable_frame>90 then return {},st,"waypoint_not_collected" end
 else st.stable_frame=nil end
 if not st.last_motion_frame then st.last_motion_frame=s.frame;st.last_motion_x=s.px;st.last_motion_y=s.py end
 if s.frame-st.last_motion_frame>=45 then
  if math.abs(s.px-st.last_motion_x)<6 and math.abs(s.py-st.last_motion_y)<6 and (buttons.Left or buttons.Right or buttons.Up or buttons.Down) then
   return {},st,"stuck"
  end
  st.last_motion_frame=s.frame;st.last_motion_x=s.px;st.last_motion_y=s.py
 end
 return buttons,st,reason
end
return M
