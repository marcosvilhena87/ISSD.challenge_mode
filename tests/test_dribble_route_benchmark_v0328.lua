package.path="lua/?.lua;lua/?/init.lua;"..package.path
local B=require("challenge.dribble_route_benchmark_v0328")
local function snap(frame) return {frame=frame,px=500,py=300,bx=514,by=300,poss=3840,time=29,remaining=4} end
local q=B.new(1000)
local a={active_frame=1028,valid_start=true}
local frames={1204,1448,1652,1824,2016}
local durations={176,244,204,172,192}
for i,f in ipairs(frames) do
 local row=B.flag(q,i,snap(f),a)
 assert(row.segment_frames==durations[i])
 assert(row.delta_frames==0)
end
local verdict=B.result(q)
assert(verdict.comparable and verdict.delta_total==0 and verdict.status=="reference_time_match")
local p=B.new(1000)
assert(B.flag(p,1,snap(1204),{active_frame=nil,valid_start=true}).start_basis=="arm")
assert(not B.result(p).comparable)
local z=B.new(1000)
assert(B.flag(z,2,snap(1204),a)==nil)
assert(z.discontinuities==1)
print("DRIBBLE v0328 route benchmark OK")
