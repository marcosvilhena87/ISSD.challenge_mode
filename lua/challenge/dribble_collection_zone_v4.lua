-- Collection Zone Discovery v4: bounded observations, not collision geometry.
local M={}
function M.new() return {flags={}} end
local function bag(st,f)
 local q=st.flags[f]
 if not q then q={count=0,negative=0,pre={},post={},near={},min_pre=nil,max_pre=nil};st.flags[f]=q end
 return q
end
local function push(t,p)
 t[#t+1]=p
end
local function bbox(points)
 if #points==0 then return nil end
 local a={minx=points[1].x,maxx=points[1].x,miny=points[1].y,maxy=points[1].y}
 for _,p in ipairs(points) do
  a.minx=math.min(a.minx,p.x);a.maxx=math.max(a.maxx,p.x)
  a.miny=math.min(a.miny,p.y);a.maxy=math.max(a.maxy,p.y)
 end
 return a
end
function M.observe(st,event)
 if event.kind=="collection_transition" then
  local c=event.record
  local q=bag(st,c.flag);q.count=q.count+1
  push(q.pre,{x=c.pre_x,y=c.pre_y,frame=c.pre_frame})
  push(q.post,{x=c.post_x,y=c.post_y,frame=c.frame})
  q.min_pre=math.min(q.min_pre or c.pre_distance,c.pre_distance or math.huge)
  q.max_pre=math.max(q.max_pre or c.pre_distance,c.pre_distance or 0)
 elseif event.kind=="near_without_transition" then
  local q=bag(st,event.flag);q.negative=q.negative+1
  push(q.near,{x=event.x,y=event.y,frame=event.frame})
 end
end
function M.summary(st,flag)
 local q=st.flags[flag] or {count=0,negative=0,pre={},post={},near={}}
 local post=bbox(q.post);local near=bbox(q.near)
 local classification=q.count==0 and "insufficient_collection_evidence" or
   q.count==1 and "single_transition_observed" or "multiple_transitions_observed"
 return {count=q.count,negative=q.negative,post=post,near=near,
  classification=classification,min_pre=q.min_pre,max_pre=q.max_pre}
end
function M.row(st,flag,mode,frame)
 local q=M.summary(st,flag)
 local p,n=q.post,q.near
 return {frame,flag,mode or "OFF","session_summary",q.count,q.negative,
  p and p.minx,p and p.maxx,p and p.miny,p and p.maxy,
  n and n.minx,n and n.maxx,n and n.miny,n and n.maxy,
  q.min_pre,q.max_pre,q.classification}
end
return M
