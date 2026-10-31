-- PASS v0.8.2: geometric candidate selection with auditable exclusions.
local M={}
local function valid(p)
 return p and type(p.x)=="number" and type(p.y)=="number"
  and p.x==p.x and p.y==p.y
end
function M.choose(sample,holder,visited,opts)
 opts=opts or {}
 local report={holder=holder,players=0,eligible=0,excluded_holder=0,excluded_visited=0,
  excluded_invalid=0,candidates={}}
 if not sample or type(sample.players)~="table" then return nil,"missing_sample",report end
 local origin
 for _,p in ipairs(sample.players) do
  report.players=report.players+1
  if p.id==holder then origin=p end
 end
 if not valid(origin) then return nil,"missing_holder",report end
 local tolerance=opts.tolerance or 12
 local weight=opts.alignment_weight or 0.25
 local best
 for _,p in ipairs(sample.players) do
  if not valid(p) or type(p.id)~="number" or p.id<2 or p.id>11 then
   report.excluded_invalid=report.excluded_invalid+1
  elseif p.id==holder then report.excluded_holder=report.excluded_holder+1
  elseif visited and visited[p.id] then report.excluded_visited=report.excluded_visited+1
  else
   report.eligible=report.eligible+1
   local dx,dy=p.x-origin.x,p.y-origin.y
   local distance=math.sqrt(dx*dx+dy*dy)
   local misalignment=math.min(math.abs(dx),math.abs(dy))
   local cost=distance+weight*math.max(0,misalignment-tolerance)
   local c={id=p.id,dx=dx,dy=dy,distance=distance,misalignment=misalignment,
    aligned=misalignment<=tolerance,cost=cost}
   report.candidates[#report.candidates+1]=c
   if not best or c.cost<best.cost or (c.cost==best.cost and c.id<best.id) then best=c end
  end
 end
 return best,best and "selected" or "no_unvisited_receiver",report
end
return M
