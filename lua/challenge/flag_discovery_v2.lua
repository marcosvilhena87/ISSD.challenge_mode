-- Flag Discovery v2: pure ranking for in-game snapshots, candidate only.
local M={SIZE=0x20000}
local function popcount(v) local n=0;while v>0 do n=n+v%2;v=math.floor(v/2) end;return n end
function M.analyze(snaps,frames,limit)
 assert(#snaps>=3 and #frames==#snaps,"at least three paired gameplay snapshots")
 local hits={}
 for a=0,M.SIZE-1 do
  local first=snaps[1][a+1];local last=first
  local changes,inc,dec,bitset,bitclear=0,0,0,0,0
  local seq={}
  for i=2,#snaps do
   local v=snaps[i][a+1]
   if v~=last then
    changes=changes+1
    if v==last+1 then inc=inc+1 end
    if v==last-1 then dec=dec+1 end
    local xor=0;local x,y=last,v
    for _=1,8 do if x%2~=y%2 then xor=xor+1 end;x=math.floor(x/2);y=math.floor(y/2) end
    if xor==1 then if v>last then bitset=bitset+1 else bitclear=bitclear+1 end end
    seq[#seq+1]=frames[i]..":"..last..">"..v
   end
   last=v
  end
  if changes>=1 and changes<=12 then
   local kind,score="discrete",0
   if inc>=2 and dec==0 and inc==changes and changes<=5 then kind="counter_up";score=100+inc*15
   elseif dec>=2 and inc==0 and dec==changes and changes<=5 then kind="counter_down";score=90+dec*15
   elseif bitset>=2 and bitclear==0 and bitset==changes and changes<=5 then kind="bitmask_set";score=85+bitset*15
   elseif bitclear>=2 and bitset==0 and bitclear==changes and changes<=5 then kind="bitmask_clear";score=80+bitclear*15
   elseif changes==1 and (bitset==1 or bitclear==1) then kind="single_flag";score=40
   elseif changes>=2 and changes<=5 then kind="stepped_other";score=20+changes end
   if score>0 then hits[#hits+1]={address=a,kind=kind,score=score,changes=changes,first=first,last=last,events=table.concat(seq,";")} end
  end
 end
 table.sort(hits,function(a,b) if a.score~=b.score then return a.score>b.score end return a.address<b.address end)
 local selected={};for i=1,math.min(limit or 300,#hits) do selected[i]=hits[i] end
 return selected,#hits
end
function M.write(path,session,hits,total)
 local f=assert(io.open(path,"a+"));if f:seek("end")==0 then f:write("session,rank,address_hex,kind,score,changes,first,last,transitions,total_candidates,status\n") end
 for i,h in ipairs(hits) do f:write(string.format("%s,%d,0x%05X,%s,%d,%d,%d,%d,%s,%d,hypothesis_only\n",session,i,h.address,h.kind,h.score,h.changes,h.first,h.last,h.events,total)) end
 f:close()
end
return M
