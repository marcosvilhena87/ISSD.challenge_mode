-- v0.8.15: conservative feet-pass geometry. Coordinates do not prove kick trajectory.
local M={VERSION="0.8.15",MAX_RANGE=190,MAX_LATERAL=72,MAX_DRIFT=32}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.measure(sample,from,to)
 local a,b=find(sample,from),find(sample,to)
 if not a or not b then return nil,"missing_player" end
 local dx,dy=b.x-a.x,b.y-a.y
 local distance=math.sqrt(dx*dx+dy*dy)
 local lateral=math.min(math.abs(dx),math.abs(dy))
 return {distance=distance,lateral=lateral,dx=dx,dy=dy,
  valid=distance<=M.MAX_RANGE and lateral<=M.MAX_LATERAL},
  distance>M.MAX_RANGE and "too_far" or (lateral>M.MAX_LATERAL and "diagonal_risk" or "feet_candidate")
end
function M.check(sample,from,to,initial)
 local now,reason=M.measure(sample,from,to)
 if not now then return false,reason end
 if not now.valid then return false,reason,now end
 if initial and (math.abs(now.dx-initial.dx)>M.MAX_DRIFT or
                 math.abs(now.dy-initial.dy)>M.MAX_DRIFT) then
  return false,"target_moved",now
 end
 return true,"feet_candidate",now
end
return M
