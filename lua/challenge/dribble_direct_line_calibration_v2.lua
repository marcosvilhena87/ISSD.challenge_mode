-- Pure observational DIRECT_LINE calibration: geometry and command corrections.
local M={}
function M.new() return {segments={},last_flag=nil} end
local function point(s)
 return type(s.px)=="number" and type(s.py)=="number"
end
function M.observe(st,s,reason,buttons,line)
 local f=type(s.remaining)=="number" and 6-s.remaining or nil
 if not f or f<1 or f>5 then return nil end
 local q=st.segments[f]
 if not q then q={frames=0,maximum=0,sum=0,corrections=0,diagonal=0,axis=0,off=0,closest=nil,collect_frame=nil};st.segments[f]=q end
 if not point(s) or not line or reason~="waypoint" then return nil end
 local vx,vy=line.tx-line.x,line.ty-line.y
 local len=math.sqrt(vx*vx+vy*vy)
 if len==0 then return nil end
 local cross=(vx*(s.py-line.y)-vy*(s.px-line.x))/len
 local error=math.abs(cross)
 local t=((s.px-line.x)*vx+(s.py-line.y)*vy)/(len*len)
 q.frames=q.frames+1;q.sum=q.sum+error;q.maximum=math.max(q.maximum,error)
 q.closest=q.closest and math.min(q.closest,error) or error
 local horizontal=buttons.Left or buttons.Right
 local vertical=buttons.Up or buttons.Down
 if horizontal and vertical then q.diagonal=q.diagonal+1 elseif horizontal or vertical then q.axis=q.axis+1 end
 if error>3 then q.corrections=q.corrections+1 end
 if t<0 or t>1 then q.off=q.off+1 end
 return {flag=f,error=error,cross=cross,progress=t,diagonal=horizontal and vertical and 1 or 0,correcting=error>3 and 1 or 0}
end
function M.summary(st,flag)
 local q=st.segments[flag] or {}
 return {frames=q.frames or 0,maximum=q.maximum,average=q.frames and q.frames>0 and q.sum/q.frames or nil,
  corrections=q.corrections or 0,diagonal=q.diagonal or 0,axis=q.axis or 0,
  overshoot=q.off or 0,closest=q.closest}
end
return M
