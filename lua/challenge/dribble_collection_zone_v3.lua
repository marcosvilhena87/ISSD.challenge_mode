local M={NAMES={LEFT=true,ABOVE=true,BELOW=true}}
local offsets={LEFT={-42,0},ABOVE={-42,-22},BELOW={-42,22}}
function M.target(mode,wp,s,stage)
 local o=offsets[mode];if not o then return nil end
 local x,y=wp[1]+o[1],wp[2]+o[2]
 if stage.done then return wp[1],wp[2],"final" end
 if math.abs(s.px-x)<=9 and math.abs(s.py-y)<=9 then
  stage.done=true;return wp[1],wp[2],"final"
 end
 return x,y,"staging"
end
function M.direction(c)
 local dx,dy=c.post_x-c.pre_x,c.post_y-c.pre_y
 if math.abs(dy)>math.abs(dx) then return dy<0 and "up" or "down" end
 if dx>0 then return "right" elseif dx<0 then return "left" end
 return "stationary"
end
return M
