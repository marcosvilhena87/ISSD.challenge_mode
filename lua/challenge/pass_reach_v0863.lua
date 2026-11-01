-- v0.8.63: passive frame-by-frame pass reach measurements, no input control.
local M={}
local function player(s,id)
 for _,p in ipairs(s and s.players or {}) do if p.id==id then return p end end
end
local function dist(a,b)
 if not a or not b then return nil end
 return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
function M.new() return {pending=nil,flight=nil,serial=0} end
function M.observe(st,frame,s,holder,target,buttons,emit)
 if not s or not s.ball then return end
 if holder and target and holder~=target and not st.flight then
  local a,b=player(s,holder),player(s,target)
  if a and b and (not st.pending or st.pending.from~=holder or st.pending.to~=target) then
   st.pending={from=holder,to=target,started=frame,first={x=a.x,y=a.y},
    previous={x=a.x,y=a.y},walk=0,initial=dist(a,b)}
   emit("plan",frame,st.pending,holder,s,0)
  end
 end
 local p=st.pending
 if p and not st.flight then
  local a=player(s,p.from)
  if a then
   p.walk=p.walk+(dist(p.previous,a) or 0)
   p.previous={x=a.x,y=a.y}
  end
 end
 if buttons and buttons.B and not st.flight and p then
  st.serial=st.serial+1
  st.flight={id=st.serial,from=p.from,to=p.to,start=frame,
    first={x=s.ball.x,y=s.ball.y},previous={x=s.ball.x,y=s.ball.y},
    ball_path=0,ball_max=0,walk=p.walk,initial=p.initial,
    initial_frame=p.started,origin=p.first}
  emit("shot",frame,st.flight,nil,s,0)
  st.pending=nil
 end
 local f=st.flight
 if f and frame>f.start then
  f.ball_path=f.ball_path+(dist(f.previous,s.ball) or 0)
  f.previous={x=s.ball.x,y=s.ball.y}
  f.ball_max=math.max(f.ball_max,dist(f.first,s.ball) or 0)
  if frame-f.start<=180 and (frame-f.start<=12 or (frame-f.start)%5==0) then
   emit("flight",frame,f,nil,s,frame-f.start)
  end
 end
end
function M.finish(st,frame,s,receiver,reason,emit)
 local f=st.flight
 if not f then return end
 emit(reason or "outcome",frame,f,receiver,s,frame-f.start)
 st.flight=nil
end
return M
