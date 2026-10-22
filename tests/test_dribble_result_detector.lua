package.path="lua/?.lua;lua/?/init.lua;"..package.path
local D=require("challenge.dribble_result_detector")
local function run(positive)
 local st=D.new({enter=2,stable=3,copy_wait=12,max_game=50})
 local events={}
 local function tick(frame,game,remaining,t,b,total,copy)
  local es=D.step(st,{frame=frame,gameplay=game,remaining=remaining,time=t,bonus=b,total=total,copy=copy})
  for _,e in ipairs(es) do events[#events+1]=e.type end
 end
 tick(1,true,5,0,0,0,0);tick(2,true,5,0,0,0,0)
 tick(3,true,0,0,0,0,0);tick(4,false,0,0,0,0,0)
 tick(5,false,0,positive and 10 or 0,positive and 20 or 0,positive and 30 or 0,0)
 tick(6,false,0,positive and 10 or 0,positive and 20 or 0,positive and 30 or 0,0)
 tick(7,false,0,positive and 10 or 0,positive and 20 or 0,positive and 30 or 0,0)
 tick(8,false,0,positive and 10 or 0,positive and 20 or 0,positive and 30 or 0,0)
 tick(9,false,0,positive and 10 or 0,positive and 20 or 0,positive and 30 or 0,positive and 30 or 0)
 local count={};for _,v in ipairs(events) do count[v]=(count[v] or 0)+1 end
 if positive then assert(count.early_result_candidate==1 and count.late_copy_correlated==1 and count.trial_closed==1)
 else assert(not count.early_result_candidate) end
end
run(true);run(false)

-- Regression: previous epoch exited before fifth flag, then new run collected five.
do
 local st=D.new({enter=2,stable=3,copy_wait=30,max_game=50})
 local events={}
 local function tick(f,g,r,t,b,total,copy)
  for _,e in ipairs(D.step(st,{frame=f,gameplay=g,remaining=r,time=t,bonus=b,total=total,copy=copy})) do
   events[#events+1]=e
  end
 end
 tick(1,true,5,0,0,0,0);tick(2,true,5,0,0,0,0)
 tick(3,false,5,0,0,0,0) -- invalidate first epoch at exit
 tick(4,false,5,10,20,30,0)
 tick(5,true,5,10,20,30,0);tick(6,true,5,10,20,30,0)
 tick(7,true,0,10,20,30,0)
 tick(8,false,0,10,20,30,0)
 tick(9,false,0,11,20,31,0)
 tick(10,false,0,11,20,31,0);tick(11,false,0,11,20,31,0)
 tick(12,false,0,11,20,31,0);tick(13,false,0,11,20,31,31)
 local starts,zeros,early=0,0,0
 for _,e in ipairs(events) do
  if e.type=="gameplay_start_candidate" then starts=starts+1 end
  if e.type=="fifth_flag_candidate" then zeros=zeros+1;assert(e.id==2) end
  if e.type=="early_result_candidate" then early=early+1;assert(e.id==2) end
  if e.type=="trial_closed" and e.id==1 then
   assert(e.extra.reason=="exit_before_fifth_flag")
   assert(e.extra.verdict=="five_flags_unobserved")
  end
 end
 assert(starts==2 and zeros==1 and early==1,"epochs must remain isolated")
end

-- Regression: re-entry after fifth flag must not classify old run using the new run's score.
do
 local st=D.new({enter=2,stable=3,copy_wait=30})
 local events={}
 local function tick(f,g,r,t,b,total)
  for _,e in ipairs(D.step(st,{frame=f,gameplay=g,remaining=r,time=t,bonus=b,total=total,copy=0})) do
   events[#events+1]=e
  end
 end
 tick(1,true,5,0,0,0);tick(2,true,5,0,0,0)
 tick(3,true,0,0,0,0);tick(4,false,0,0,0,0)
 tick(5,true,5,0,0,0)
 tick(6,true,0,99,20,119);tick(7,true,0,99,20,119)
 tick(8,false,0,99,20,119)
 for _,e in ipairs(events) do
  assert(e.type~="early_result_candidate","re-entry must never confirm old run")
  if e.type=="trial_closed" then assert(e.extra.reason=="new_game_before_resolution") end
 end
end

print("test_dribble_result_detector OK (v2 regressions)")
