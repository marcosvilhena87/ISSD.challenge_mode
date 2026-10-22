-- Pure evidence classification for DRIBBLE Goal Counter Validation v3.
local M={}
function M.classify(q)
 if q.positive>0 and q.negative then return "conflict_increment_with_negative_control" end
 if q.visual and q.positive==0 then return "visual_goal_without_increment" end
 if q.positive>0 and q.visual and q.plausible>0 and q.inconsistent==0 then return "correlated_goal_candidate" end
 if q.positive>0 then return "increment_unverified" end
 if q.negative and q.positive==0 and q.invalid==0 then return "negative_control_no_increment" end
 return "unverified"
end
function M.quality(q)
 if q.invalid>0 then return "invalid_reads" end
 if q.inconsistent>0 then return "byte_mismatch" end
 if q.resets>0 then return "reset_or_wrap_observed" end
 return "read_consistent"
end
return M
