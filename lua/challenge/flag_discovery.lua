-- Flag Discovery v1: passive WRAM scans + transition candidate ranking.
local M={}
M.SIZE=0x20000
function M.snapshot(read)
 local t={}
 for a=0,M.SIZE-1 do
  local v=read(a,"WRAM")
  assert(type(v)=="number" and v>=0 and v<=255 and v%1==0,"invalid WRAM byte at "..a)
  t[a+1]=v
 end
 return t
end
function M.rank(snaps,limit)
 assert(#snaps>=2,"at least two snapshots required")
 local hits={}
 for addr=0,M.SIZE-1 do
  local prev=snaps[1][addr+1]
  local changes=0;local min,max=prev,prev
  local runs=1
  for j=2,#snaps do
   local v=snaps[j][addr+1]
   if v~=prev then changes=changes+1;runs=runs+1 end
   if v<min then min=v end
   if v>max then max=v end
   prev=v
  end
  -- Step-like candidates; movement/camera fields often change in every sample.
  if changes>=1 and changes<=math.max(2,math.floor((#snaps-1)/2)) and (max-min)<=16 then
   hits[#hits+1]={address=addr,changes=changes,min=min,max=max,first=snaps[1][addr+1],last=snaps[#snaps][addr+1]}
  end
 end
 table.sort(hits,function(a,b)
  if a.changes~=b.changes then return a.changes<b.changes end
  if a.max-a.min~=b.max-b.min then return a.max-a.min<b.max-b.min end
  return a.address<b.address
 end)
 local selected={}
 for i=1,math.min(limit or 200,#hits) do selected[i]=hits[i] end
 return selected,#hits
end
function M.write(path,session,frames,results,total)
 local f=assert(io.open(path,"a+"))
 if f:seek("end")==0 then f:write("session,rank,address_hex,address_dec,changes,min,max,first,last,snapshots,frames,total_candidates,status\n") end
 local sf=table.concat(frames,";")
 for i,h in ipairs(results) do
  f:write(string.format("%s,%d,0x%05X,%d,%d,%d,%d,%d,%d,%d,%s,%d,hypothesis_only\n",session,i,h.address,h.address,h.changes,h.min,h.max,h.first,h.last,#frames,sf,total))
 end
 f:close()
end
return M
