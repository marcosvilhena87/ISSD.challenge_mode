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
print("test_dribble_result_detector OK")
