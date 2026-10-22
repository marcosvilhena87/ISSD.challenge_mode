package.path="lua/?.lua;lua/?/init.lua;"..package.path
local D=require("challenge.dribble_start_detection_v0327")
local function sample(f,frac,time,px,bx,remaining)
 return {frame=f,gs=0,ptr=0x0F00,remaining=remaining or 5,px=px or 376,py=320,bx=bx or 388,by=319,time=time or 30,timefrac=frac or 1000}
end
local q=D.new(sample(100,1000,30))
for f=101,119 do assert(not D.observe(q,sample(f,1000,30))) end
assert(not D.observe(q,sample(120,999,30)))
assert(q.active_frame==120 and q.active_evidence=="timer_fraction_change")
assert(not D.observe(q,sample(123,998,30,376,392)))
local done=D.observe(q,sample(127,997,30,380,392))
assert(done and done.complete and done.final_reason=="all_signals_observed")
assert(done.first_ball==123 and done.first_player==127)
assert(done.first_time_bcd==nil and done.first_time_fraction==120)
local later=D.new(sample(200,1000,30))
for f=201,310 do D.observe(later,sample(f,1000,30)) end
assert(not later.complete)
local stop=D.observe(later,sample(311,1000,30,376,388,4))
assert(stop and stop.final_reason=="first_flag_observed" and not stop.active_frame)
print("start detection v0327 OK")
