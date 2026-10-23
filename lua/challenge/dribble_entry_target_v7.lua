-- Adaptive Entry Target v7. Pure state policy, never asserts collision boundaries.
local M={X=744,Y=329,MAX_FRAMES=170}
function M.new() return {started=nil,fallback=false,event=nil} end
function M.choose(st,s)
 if st.fallback then return nil end
 if not st.started then st.started=s.frame end
 local elapsed=s.frame-st.started
 if elapsed>=M.MAX_FRAMES or (math.abs(s.px-M.X)<=6 and math.abs(s.py-M.Y)<=6) then
  st.fallback=true
  st.event={kind="fallback",frame=s.frame,elapsed=elapsed,
   cause=elapsed>=M.MAX_FRAMES and "timeout" or "candidate_reached_without_collection",
   x=s.px,y=s.py}
  return nil
 end
 return {M.X,M.Y}
end
return M
