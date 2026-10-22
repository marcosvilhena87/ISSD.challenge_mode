-- Route Optimization v2: passive collection-transition evidence, pure Lua.
-- Observations bound candidate entry positions, NOT the actual collision zone.
local M={WINDOW=12,NEAR_RADIUS=30,NEGATIVE_INTERVAL=15}
local function valid(s)
 return type(s)=="table" and type(s.frame)=="number" and type(s.remaining)=="number"
  and type(s.px)=="number" and type(s.py)=="number"
end
local function dist(x,y,wp)
 if not wp then return nil end
 return math.sqrt((x-wp[1])^2+(y-wp[2])^2)
end
function M.new()
 return {history={},previous=nil,collections={},negative_last={}}
end
function M.observe(st,s,waypoints)
 local events={}
 if not valid(s) then st.history={};st.previous=nil;return events end
 local prior=st.previous
 local contiguous=prior and s.frame>prior.frame and s.frame-prior.frame<=3
 local delta=contiguous and prior.remaining-s.remaining or 0
 if delta==1 and prior.remaining>=1 and prior.remaining<=5 then
  local flag=6-prior.remaining
  local wp=waypoints[flag]
  -- Capture pre-transition position, post-transition position and up to WINDOW
  -- earlier samples, without conflating their timestamps with collection frame.
  local c={flag=flag,frame=s.frame,pre_frame=prior.frame,
   pre_x=prior.px,pre_y=prior.py,post_x=s.px,post_y=s.py,
   pre_distance=dist(prior.px,prior.py,wp),
   post_distance=dist(s.px,s.py,wp),window={}}
  for _,p in ipairs(st.history) do
   if p.remaining==prior.remaining and p.frame<=prior.frame and
      prior.frame-p.frame<=M.WINDOW then
    c.window[#c.window+1]={frame=p.frame,x=p.px,y=p.py}
   end
  end
  st.collections[flag]=c
  events[#events+1]={kind="collection_transition",record=c}
 elseif delta~=0 or not contiguous then
  -- Reject counter jumps, resets and discontinuous frame sequences.
  st.history={}
 elseif s.remaining>=1 and s.remaining<=5 then
  local flag=6-s.remaining
  local d=dist(s.px,s.py,waypoints[flag])
  if d and d<=M.NEAR_RADIUS and
     (not st.negative_last[flag] or s.frame-st.negative_last[flag]>=M.NEGATIVE_INTERVAL) then
   st.negative_last[flag]=s.frame
   events[#events+1]={kind="near_without_transition",flag=flag,frame=s.frame,
    x=s.px,y=s.py,distance=d}
  end
 end
 st.history[#st.history+1]={frame=s.frame,remaining=s.remaining,px=s.px,py=s.py}
 while #st.history>M.WINDOW+2 do table.remove(st.history,1) end
 st.previous={frame=s.frame,remaining=s.remaining,px=s.px,py=s.py}
 return events
end
return M
