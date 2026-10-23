-- DRIBBLE v0.2.2 waypoint transition fix: pure policy, no BizHawk APIs.
local M={}
local Route=require("challenge.dribble_route_optimization_v1")
local Zone3=require("challenge.dribble_collection_zone_v3")
local Entry7=require("challenge.dribble_entry_target_v7")
M.segment_modes={}
M.zone_approach=nil
M.entry_v7=false
M.entry_v7_event=nil
function M.set_entry_v7(enabled) M.entry_v7=enabled==true;M.entry_v7_event=nil end
function M.set_zone_approach(mode) M.zone_approach=mode end
function M.set_segment_modes(modes) M.segment_modes=modes or {} end
M.waypoints={{555,261},{760,330},{974,356},{1228,293},{1460,360}}
M.TIME_LIMIT=1800
M.travel_profile="DIRECT_LINE" -- experimental straight path; AXIS remains available
M.approach_profile="CONTINUOUS_PRECISION" -- default; reversible via APPROACH:CONTROL
local function int(x) return type(x)=="number" and x==x and x%1==0 end
function M.new() return {started=nil,last_remaining=nil,target=1,near_since=nil,search_step=0,search_since=nil,motion_frame=nil,motion_x=nil,motion_y=nil,moving_frames=0,grace_until=nil,event=nil,line=nil,zone_stage={done=false},entry_v7=Entry7.new()} end
local function steer(dx,dy,frame,fine,continuous)
 local b={}
 local dead=fine and 2 or 6
 -- Short pulses minimize crossing the target with high velocity.
 local pulse=not fine or continuous or frame%4==0
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
  st.line=nil
  st.zone_stage={done=false}
  st.entry_v7=Entry7.new()
  st.event='flag_collected'
 else
  st.event=nil
 end
 st.last_remaining=s.remaining
 local target=6-s.remaining
 if st.target~=target then st.line=nil;st.zone_stage={done=false};st.entry_v7=Entry7.new() end
 st.target=target
 if s.remaining==0 then return {},st,"five_collected" end
 local wp=M.waypoints[st.target]
 if not wp then return {},st,"no_waypoint" end
 if st.target==2 and M.entry_v7 then
  local selected=Entry7.choose(st.entry_v7,s)
  if st.entry_v7.event then
   M.entry_v7_event=st.entry_v7.event
   st.entry_v7.event=nil
  end
  if selected then wp=selected end
 end
 local bx,by=s.bx-s.px,s.by-s.py
 local recover=s.poss~=0x0F00 and (math.abs(bx)>34 or math.abs(by)>34)
 local dx,dy=wp[1]-s.px,wp[2]-s.py
 local reason="waypoint"
 if recover then
  dx,dy=bx,by
  reason="recover_ball"
  st.near_since=nil;st.search_since=nil
  st.line=nil
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
 local zone_x,zone_y,zone_phase
 if reason=="waypoint" and st.target==2 and M.zone_approach then
  zone_x,zone_y,zone_phase=Zone3.target(M.zone_approach,wp,s,st.zone_stage)
 end
 local buttons
 if reason=="waypoint" and zone_phase=="staging" then
  buttons=steer(zone_x-s.px,zone_y-s.py,s.frame,false,false)
 elseif reason=="waypoint" and (M.segment_modes[st.target]=="DIAGONAL_FIRST" or M.segment_modes[st.target]=="COLLECTION_ENTRY") then
  buttons=Route.steer(M.segment_modes[st.target],s,wp,st.line)
 elseif reason=="waypoint" and M.travel_profile=="DIRECT_LINE" then
  -- Stay near the straight segment from the initial position to the waypoint.
  -- Drive the major axis continuously; correct the minor axis only if the
  -- perpendicular error exceeds a bounded tolerance. Precision and recovery
  -- remain delegated to the established controller.
  if not st.line then st.line={x=s.px,y=s.py,tx=wp[1],ty=wp[2]} end
  local line=st.line
  local vx,vy=line.tx-line.x,line.ty-line.y
  -- Follow the segment with simultaneous directional inputs (diagonal allowed).
  -- Correct toward the nearest point on the line, with bounded lookahead.
  local len2=vx*vx+vy*vy
  local aimx,aimy=wp[1],wp[2]
  if len2>0 then
   local t=((s.px-line.x)*vx+(s.py-line.y)*vy)/len2
   local look=math.min(1,math.max(0,t)+35/math.sqrt(len2))
   local cx,cy=line.x+vx*look,line.y+vy*look
   local cross=math.abs(vx*(s.py-line.y)-vy*(s.px-line.x))/math.sqrt(len2)
   if cross>3 then aimx,aimy=cx,cy end
  end
  buttons=steer(aimx-s.px,aimy-s.py,s.frame,false,false)
 else
  buttons=steer(dx,dy,s.frame,fine,reason=="precision_approach" and M.approach_profile=="CONTINUOUS_PRECISION")
 end
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
