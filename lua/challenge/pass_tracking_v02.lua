-- PASS LV.1 v0.2: pure observation logic and geometry-only route planning.
-- No RAM address is treated as validated until operator-supplied config is verified.
local M={}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<32768 end
local function distance(a,b)
 local dx,dy=a.x-b.x,a.y-b.y
 return math.sqrt(dx*dx+dy*dy)
end
function M.validate(config)
 if type(config)~="table" or type(config.players)~="table" or #config.players~=10 then
  return nil,"expected_exactly_10_outfield_players"
 end
 if type(config.possession_address)~="number" or config.possession_address<0 or config.possession_address>0x1ffff then
  return nil,"possession_address_missing_or_invalid"
 end
 if config.possession_width~=8 and config.possession_width~=16 then return nil,"possession_width_must_be_8_or_16" end
 if type(config.no_possession_values)~="table" then return nil,"missing_no_possession_values" end
 local ids,slots={},{}
 for _,p in ipairs(config.players) do
  if type(p.id)~="number" or ids[p.id] then return nil,"duplicate_or_invalid_player_id" end
  if type(p.possession_value)~="number" or slots[p.possession_value] then return nil,"duplicate_or_invalid_possession_value" end
  if type(p.x_address)~="number" or type(p.y_address)~="number" or p.x_address%1~=0 or p.y_address%1~=0 or p.x_address<0 or p.y_address<0 or p.x_address>0x1ffff or p.y_address>0x1ffff then
   return nil,"invalid_position_address"
  end
  ids[p.id]=true;slots[p.possession_value]=p.id
 end
 for _,v in ipairs(config.no_possession_values) do
  if slots[v] then return nil,"no_possession_collides_with_player" end
 end
 return {by_slot=slots}
end
function M.sample(config,read_u8,read_u16,read_s16)
 local valid,reason=M.validate(config)
 if not valid then return nil,reason end
 local function safe(fn,addr)
  local ok,v=pcall(fn,addr,"WRAM")
  if ok and type(v)=="number" then return v end
 end
 local raw=safe(config.possession_width==8 and read_u8 or read_u16,config.possession_address)
 local holder=raw and valid.by_slot[raw] or nil
 local players={}
 for _,p in ipairs(config.players) do
  local x=safe(read_s16,p.x_address);local y=safe(read_s16,p.y_address)
  if not finite(x) or not finite(y) then return nil,"position_read_failed" end
  players[#players+1]={id=p.id,x=x,y=y}
 end
 return {raw_possession=raw,holder=holder,players=players,known=holder~=nil}
end
function M.new_tracker(stability_frames)
 local t={last=nil,streak=0,stable=nil,visited={},events={},stability=stability_frames or 3}
 function t:step(sample,frame)
  local holder=sample and sample.holder
  if holder==self.last and holder~=nil then self.streak=self.streak+1
  else self.last=holder;self.streak=holder and 1 or 0 end
  if not holder or self.streak<self.stability or self.stable==holder then return nil end
  local old=self.stable
  self.stable=holder
  -- A stable change in possession is evidence of a reception candidate, not proof.
  local event={frame=frame,from=old,to=holder,kind=old and "transfer_candidate" or "initial_possession"}
  if old and not self.visited[holder] then self.visited[holder]=true end
  self.events[#self.events+1]=event
  return event
 end
 return t
end
-- Held-Karp exact shortest Hamiltonian path from a current receiver; straight-line distances only.
-- No claim of optimal in-game time (pass animations, obstacles, possession and input latency unknown).
function M.plan(players,start_id,visited)
 if type(players)~="table" or #players~=10 then return nil,"expected_10_players" end
 local start,remaining,ids={}, {},{}
 for _,p in ipairs(players) do
  if not finite(p.x) or not finite(p.y) or ids[p.id] then return nil,"invalid_players" end
  ids[p.id]=true
  if p.id==start_id then start=p
  elseif not (visited and visited[p.id]) then remaining[#remaining+1]=p end
 end
 if not start then return nil,"invalid_start" end
 local n=#remaining
 if n==0 then return {sequence={},distance=0,method="euclidean_held_karp"} end
 local pow={}
 for i=1,n do pow[i]=2^(i-1) end
 local states={}
 for i=1,n do
  local mask=pow[i];states[mask]=states[mask] or {}
  states[mask][i]={cost=distance(start,remaining[i]),route={remaining[i].id}}
 end
 for mask=1,2^n-1 do
  local row=states[mask]
  if row then for i,node in pairs(row) do
   for j=1,n do
    if math.floor(mask/pow[j])%2==0 then
     local nextmask=mask+pow[j]
     states[nextmask]=states[nextmask] or {}
     local cost=node.cost+distance(remaining[i],remaining[j])
     local prev=states[nextmask][j]
     if not prev or cost<prev.cost then
      local route={}
      for k,v in ipairs(node.route) do route[k]=v end
      route[#route+1]=remaining[j].id
      states[nextmask][j]={cost=cost,route=route}
     end
    end
   end
  end end end
 local best
 for _,node in pairs(states[2^n-1] or {}) do
  if not best or node.cost<best.cost then best=node end
 end
 return {sequence=best.route,distance=best.cost,method="euclidean_held_karp"}
end
return M
