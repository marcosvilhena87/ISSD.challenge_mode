-- PASS v0.8: local distance-first receiver choice with alignment tie-break.
-- Geometry is a hypothesis about pass mechanics, not a guaranteed recipient.
local M={}
local function valid(p) return p and type(p.x)=="number" and type(p.y)=="number" end
function M.choose(sample,holder,visited,opts)
 opts=opts or {}
 if not sample or type(sample.players)~="table" then return nil,"missing_sample" end
 local origin
 for _,p in ipairs(sample.players) do if p.id==holder then origin=p;break end end
 if not valid(origin) then return nil,"missing_holder" end
 local tolerance=opts.tolerance or 12
 local alignment_weight=opts.alignment_weight or 0.25
 local best
 for _,p in ipairs(sample.players) do
  if valid(p) and p.id~=holder and p.id>=2 and p.id<=11 and not (visited and visited[p.id]) then
   local dx,dy=p.x-origin.x,p.y-origin.y
   local distance=math.sqrt(dx*dx+dy*dy)
   local misalignment=math.min(math.abs(dx),math.abs(dy))
   local axis_aligned=misalignment<=tolerance
   local cost=distance+alignment_weight*math.max(0,misalignment-tolerance)
   local c={id=p.id,dx=dx,dy=dy,distance=distance,misalignment=misalignment,
    aligned=axis_aligned,cost=cost}
   if not best or c.cost<best.cost or (c.cost==best.cost and c.id<best.id) then best=c end
  end
 end
 return best,best and "selected" or "no_unvisited_receiver"
end
return M
