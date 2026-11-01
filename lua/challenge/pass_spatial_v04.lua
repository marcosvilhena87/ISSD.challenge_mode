-- PASS LV.1 v0.4: read-only spatial possession candidate inference.
-- Coordinates are signed 16-bit WRAM, verified by operator mapping.
local M={}
M.ball={x=0x042A,y=0x042C}
M.goalkeeper={id=1,x=0x052A,y=0x052C} -- absent during challenge; legacy diagnostics only
M.center_field_y=0x12D8
M.players={}
for id=2,11 do M.players[#M.players+1]={id=id,x=0x042A+id*0x100,y=0x042C+id*0x100} end
local function finite(x) return type(x)=="number" and x==x and x>=-32768 and x<=32767 end
function M.read(read_s16,read_u16)
 local function get(addr)
  local ok,v=pcall(read_s16,addr,"WRAM")
  if ok and finite(v) then return v end
 end
 local bx,by=get(M.ball.x),get(M.ball.y)
 if not bx or not by then return nil,"ball_read_failed" end
 local gx,gy=get(M.goalkeeper.x),get(M.goalkeeper.y)
 local center_y=nil
 if type(read_u16)=="function" then
  local ok,v=pcall(read_u16,M.center_field_y,"WRAM")
  if ok and type(v)=="number" and v>=0 and v<=65535 then center_y=v end
 end
 local players={}
 for _,p in ipairs(M.players) do
  local x,y=get(p.x),get(p.y)
  if not x or not y then return nil,"player_read_failed_"..p.id end
  local dx,dy=x-bx,y-by
  players[#players+1]={id=p.id,x=x,y=y,distance=math.sqrt(dx*dx+dy*dy)}
 end
 local gdx,gdy=gx-bx,gy-by
 return {ball={x=bx,y=by},center_field_y=center_y,goalkeeper={x=gx,y=gy,distance=math.sqrt(gdx*gdx+gdy*gdy)},players=players}
end
function M.new(opts)
 opts=opts or {}
 local threshold=opts.threshold or 24
 local gap=opts.gap or 6
 local stable=opts.stable or 4
 assert(threshold>0 and gap>=0 and stable>=1,"invalid spatial config")
 local t={candidate=nil,streak=0,holder=nil,visited={},events={},threshold=threshold,gap=gap,stable=stable}
 function t:step(sample,frame)
  if not sample then self.candidate=nil;self.streak=0;return nil end
  local nearest,second
  for _,p in ipairs(sample.players) do
   if not nearest or p.distance<nearest.distance then second=nearest;nearest=p
   elseif not second or p.distance<second.distance then second=p end
  end
  local eligible=nearest and nearest.distance<=self.threshold
    and (not second or second.distance-nearest.distance>=self.gap)
    and (not sample.goalkeeper or sample.goalkeeper.distance>nearest.distance)
  local id=eligible and nearest.id or nil
  if id==self.candidate and id~=nil then self.streak=self.streak+1
  else self.candidate=id;self.streak=id and 1 or 0 end
  if not id or self.streak<self.stable or self.holder==id then return nil end
  local from=self.holder;self.holder=id
  local kind=from and "spatial_transfer_candidate" or "spatial_initial_candidate"
  if from then self.visited[id]=true end
  local count=0;for _ in pairs(self.visited) do count=count+1 end
  local e={frame=frame,kind=kind,from=from,to=id,distance=nearest.distance,
   goalkeeper_distance=sample.goalkeeper.distance,visited_count=count,confidence="spatial_proximity_only"}
  self.events[#self.events+1]=e
  return e
 end
 return t
end
return M
