local M={X=744,Y=329,MAX_FRAMES=170}
function M.new() return {started=nil,fallback=false,events={},activated=false} end
local function event(st,kind,s,cause,elapsed)
 st.events[#st.events+1]={kind=kind,frame=s.frame,x=s.px,y=s.py,cause=cause or "",elapsed=elapsed or 0}
end
function M.choose(st,s)
 if st.fallback then return nil end
 if not st.started then st.started=s.frame end
 local elapsed=s.frame-st.started
 if not st.activated then
  st.activated=true
  event(st,"entry_target_activated",s,"candidate_744_329",elapsed)
 end
 if elapsed>=M.MAX_FRAMES or (math.abs(s.px-M.X)<=6 and math.abs(s.py-M.Y)<=6) then
  st.fallback=true
  local cause=elapsed>=M.MAX_FRAMES and "timeout" or "candidate_reached_without_collection"
  if cause=="candidate_reached_without_collection" then event(st,"candidate_reached",s,cause,elapsed) end
  event(st,"fallback_started",s,cause,elapsed)
  return nil
 end
 return {M.X,M.Y}
end
function M.collected(st,s)
 if not st.activated then return end
 event(st,st.fallback and "collected_after_fallback" or "collected_before_fallback",s,
  st.fallback and "original_waypoint_restored" or "candidate_active",st.started and s.frame-st.started or 0)
end
function M.drain(st)
 local events=st.events
 st.events={}
 return events
end
return M
