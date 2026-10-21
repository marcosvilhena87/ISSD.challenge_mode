-- DRIBBLE Timer Discovery v1: rank byte changes around the fifth flag.
local M={SIZE=0x20000}
function M.rank(samples,limit)
 assert(#samples>=3,"need >=3 snapshots")
 local fifth
 for i=2,#samples do if samples[i-1].remaining==1 and samples[i].remaining==0 and samples[i].gameplay then fifth=i;break end end
 local out={}
 for a=0,M.SIZE-1 do
  local changes,pre,post,active=0,0,0,0
  local prior=samples[1].bytes[a+1]
  local min,max=prior,prior
  for i=2,#samples do
   local cur=samples[i].bytes[a+1]
   if cur~=prior then
    changes=changes+1
    if fifth and i<=fifth then pre=pre+1 end
    if fifth and i>fifth then post=post+1 end
   end
   if cur<min then min=cur end;if cur>max then max=cur end
   prior=cur
  end
  if changes>=2 then
   local kind,score="moving",0
   if fifth and pre<=1 and post>=2 then kind="bonus_activation_candidate";score=100+math.min(post,20)*2
   elseif pre>=2 and post<=1 then kind="time_pause_candidate";score=75+math.min(pre,20)
   elseif pre>=2 and post>=2 then kind="continuous_timer_candidate";score=40+math.min(changes,20)
   elseif not fifth and changes>=3 then kind="pre_fifth_timer_candidate";score=20+math.min(changes,20) end
   if score>0 then out[#out+1]={address=a,kind=kind,score=score,changes=changes,pre=pre,post=post,first=samples[1].bytes[a+1],last=prior,min=min,max=max} end
  end
 end
 table.sort(out,function(a,b) if a.score~=b.score then return a.score>b.score end return a.address<b.address end)
 local selected={};for i=1,math.min(limit or 400,#out) do selected[i]=out[i] end
 return selected,#out,fifth
end
function M.write(path,session,rows,total,fifth)
 local f=assert(io.open(path,"a+"))
 if f:seek("end")==0 then f:write("session,rank,address_hex,kind,score,changes,before_fifth,after_fifth,first,last,min,max,total_candidates,fifth_snapshot,status\n") end
 for i,x in ipairs(rows) do f:write(string.format("%s,%d,0x%05X,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,hypothesis_only\n",session,i,x.address,x.kind,x.score,x.changes,x.pre,x.post,x.first,x.last,x.min,x.max,total,fifth or "")) end
 f:close()
end
return M
