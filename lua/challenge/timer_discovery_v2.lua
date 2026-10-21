-- Phase-aware DRIBBLE timers v2. Read-only snapshot classification.
local M={SIZE=0x20000}
function M.phase(s)
 if s.gs~=0 or s.ptr~=0x0F00 then return "excluded" end
 if s.remaining>=1 and s.remaining<=5 then return "time" end
 if s.remaining==0 then return "bonus" end
 return "excluded"
end
local function eval(snaps,a,phase)
 local n,changes,up,down,one,stable=0,0,0,0,0,0
 local first,last,prev
 local sequence={}
 for _,s in ipairs(snaps) do
  if M.phase(s)==phase then
   local v=s.bytes[a+1]
   n=n+1
   if first==nil then first=v end
   if prev~=nil then
    if v~=prev then
     changes=changes+1
     if v>prev then up=up+1 else down=down+1 end
     if math.abs(v-prev)==1 then one=one+1 end
     if #sequence<16 then sequence[#sequence+1]=s.frame..":"..prev..">"..v end
    else stable=stable+1 end
   end
   prev=v;last=v
  end
 end
 if n<3 then return nil end
 return {n=n,changes=changes,up=up,down=down,unit=one,stable=stable,first=first,last=last,transitions=table.concat(sequence,";")}
end
function M.rank(snaps,limit)
 assert(#snaps>=3,"need 3 snapshots")
 local time,bonus={},{}
 for a=0,M.SIZE-1 do
  local t=eval(snaps,a,"time");local b=eval(snaps,a,"bonus")
  if t and t.changes>=2 then
   local score=math.floor(100*t.changes/(t.n-1))+t.unit*3
   if b and b.changes<=1 then score=score+30 end
   time[#time+1]={address=a,score=score,primary=t,secondary=b}
  end
  if b and b.changes>=2 then
   local score=math.floor(100*b.changes/(b.n-1))+b.unit*3
   if t and t.changes<=1 then score=score+30 end
   bonus[#bonus+1]={address=a,score=score,primary=b,secondary=t}
  end
 end
 local function sort(rows)
  table.sort(rows,function(x,y) if x.score~=y.score then return x.score>y.score end return x.address<y.address end)
  local trimmed={};for i=1,math.min(limit or 400,#rows) do trimmed[i]=rows[i] end;return trimmed,#rows
 end
 local a,an=sort(time);local b,bn=sort(bonus)
 return a,an,b,bn
end
function M.write(path,session,phase,rows,total)
 local f=assert(io.open(path,"a+"))
 if f:seek("end")==0 then f:write("session,phase,rank,address_hex,score,phase_samples,phase_changes,unit_changes,up,down,first,last,opposite_samples,opposite_changes,transitions,total_candidates,status\n") end
 for i,h in ipairs(rows) do
  local p=h.primary;local q=h.secondary
  local cols={session,phase,i,string.format("0x%05X",h.address),h.score,p.n,p.changes,p.unit,p.up,p.down,p.first,p.last,q and q.n or "",q and q.changes or "",p.transitions,total,"hypothesis_only"}
  for k,v in ipairs(cols) do cols[k]=tostring(v) end
  f:write(table.concat(cols,",").."\n")
 end
 f:close()
end
return M
