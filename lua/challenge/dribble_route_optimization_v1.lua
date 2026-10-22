-- Route Optimization v1: pure travel policy and observed path length.
local M={DEFAULT="DIRECT_LINE",NAMES={DIRECT_LINE=true,DIAGONAL_FIRST=true,COLLECTION_ENTRY=true}}
M.entry_offsets={{0,0},{-8,0},{-8,0},{0,0},{-8,0}} -- experimental, not verified collection centers
function M.new() return {last=nil,segments={}} end
function M.observe(st,s)
 local f=type(s.remaining)=="number" and 6-s.remaining or nil
 if not f or f<1 or f>5 or type(s.px)~="number" or type(s.py)~="number" or type(s.frame)~="number" then st.last=nil;return end
 local prev=st.last
 local q=st.segments[f] or {distance=0,frames=0,samples=0};st.segments[f]=q
 if prev and prev.flag==f and s.frame>prev.frame and s.frame-prev.frame<=3 then
  local dt=s.frame-prev.frame
  q.distance=q.distance+math.sqrt((s.px-prev.x)^2+(s.py-prev.y)^2)
  q.frames=q.frames+dt;q.samples=q.samples+1
 end
 st.last={flag=f,frame=s.frame,x=s.px,y=s.py}
end
function M.summary(st,f)
 local q=st.segments[f] or {}
 return q.distance or 0,q.frames or 0,q.samples or 0
end
-- Only called in far-field waypoint movement; precision/recovery/shoot are untouched.
function M.steer(mode,s,wp,origin)
 local tx,ty=wp[1],wp[2]
 if mode=="COLLECTION_ENTRY" then
  local f=6-s.remaining
  local o=M.entry_offsets[f] or {0,0}
  tx,ty=tx+o[1],ty+o[2]
 end
 local dx,dy=tx-s.px,ty-s.py
 local b={}
 local function axis(x,positive,negative) if x>6 then b[positive]=true elseif x< -6 then b[negative]=true end end
 if mode=="DIAGONAL_FIRST" then
  -- Simultaneous direction until one component is within tolerance.
  axis(dx,"Right","Left");axis(dy,"Down","Up")
 elseif mode=="COLLECTION_ENTRY" then
  -- Similar diagonal control, aiming for a conservative experimental entry point.
  axis(dx,"Right","Left");axis(dy,"Down","Up")
 end
 return b
end
return M
