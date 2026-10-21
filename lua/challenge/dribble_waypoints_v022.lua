-- DRIBBLE v0.2.2 waypoint transition fix: pure policy, no BizHawk APIs.
local M={}
M.waypoints={{555,261},{772,304},{974,356},{1228,293},{1450,367}}
M.TIME_LIMIT=1800
local function int(x) return type(x)=="number" and x==x and x%1==0 end
function M.new() return {started=nil,last_remaining=nil,target=1,near_since=nil,search_step=0,search_since=nil,motion_frame=nil,motion_x=nil,motion_y=nil,moving_frames=0,grace_until=nil,event=nil} end
local function steer(dx,dy,frame,fine)
 local b={}
 local dead=fine and 2 or 6
 -- Short pulses minimize crossing the target with high velocity.
 local pulse=not fine or frame%4==0
 if pulse then
  if dx>dead then b.Right=true elseif dx< -dead then b.Left=true end
  if dy>dead then b.Down=true elseif dy< -dead then b.Up=true end
 end
 return b
end
function M.step(s,st)
 st=st or M.new()
 for _,k in ipairs({"frame","gs","ptr","remaining","px","py","bx","by","poss"}) do if not int(s[k]) then return {},st,"invalid_read" end end
 if s.gs~=0 or s.ptr~=0x0F00 then return {},st,"not_playing" end
 if s.remaining<0 or s.remaining>5 then return {},st,"invalid_count" end
 if not st.started then st.started=s.frame end
 if s.frame-st.started>=M.TIME_LIMIT then return {},st,"time_limit" end
 if st.last_remaining and (s.remaining>st.last_remaining or st.last_remaining-s.remaining>1) then return {},st,"counter_discontinuity" end
 if st.last_remaining~=nil and s.remaining<st.last_remaining then
  st.near_since=nil;st.search_since=nil;st.search_step=0
  st.motion_frame=s.frame;st.motion_x=s.px;st.motion_y=s.py;st.moving_frames=0;st.grace_until=s.frame+60
  st.event='flag_collected'
 else
  st.event=nil
 end
 st.last_remaining=s.remaining
 st.target=6-s.remaining
 if s.remaining==0 then return {},st,"five_collected" end
 local wp=M.waypoints[st.target]
 if not wp then return {},st,"no_waypoint" end
 local bx,by=s.bx-s.px,s.by-s.py
 local recover=s.poss~=0x0F00 and (math.abs(bx)>34 or math.abs(by)>34)
 local dx,dy=wp[1]-s.px,wp[2]-s.py
 local reason="waypoint"
 if recover then
  dx,dy=bx,by
  reason="recover_ball"
  st.near_since=nil;st.search_since=nil
 else
  if math.abs(dx)<=12 and math.abs(dy)<=12 then
   if not st.near_since then st.near_since=s.frame end
  end
  if st.near_since then
   local age=s.frame-st.near_since
   if age>240 then return {},st,"collection_timeout" end
   -- Search around the observed *player-at-collection* point, not presumed flag coordinates.
   if age>=45 then
    reason="local_search"
    local offsets={{0,0},{8,0},{8,8},{0,8},{-8,8},{-8,0},{-8,-8},{0,-8},{8,-8},{0,0}}
    local index=math.min(math.floor((age-45)/18)+1,#offsets)
    local o=offsets[index]
    dx=wp[1]+o[1]-s.px;dy=wp[2]+o[2]-s.py
   else reason="precision_approach" end
  elseif math.abs(dx)<=24 and math.abs(dy)<=24 then reason="precision_approach" end
 end
 local fine=reason=="precision_approach" or reason=="local_search"
 local buttons=steer(dx,dy,s.frame,fine)
 if not st.motion_frame then st.motion_frame=s.frame;st.motion_x=s.px;st.motion_y=s.py end
 local moving=buttons.Left or buttons.Right or buttons.Up or buttons.Down
 if moving then st.moving_frames=st.moving_frames+1 end
 if s.frame-st.motion_frame>=45 then
  local displacement=math.abs(s.px-st.motion_x)+math.abs(s.py-st.motion_y)
  if (not st.grace_until or s.frame>st.grace_until) and st.moving_frames>=15 and displacement<3 then return {},st,"stuck" end
  st.motion_frame=s.frame;st.motion_x=s.px;st.motion_y=s.py;st.moving_frames=0
 end
 return buttons,st,reason
end
return M
