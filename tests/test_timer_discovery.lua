package.path="lua/?.lua;lua/?/init.lua;"..package.path
local M=require("challenge.timer_discovery")
local samples={}
for i=1,8 do
 local a={};for j=1,M.SIZE do a[j]=0 end
 -- Snapshot 5 observes the fifth collection.
 a[0x120+1]=(i<=5) and i or 5
 a[0x130+1]=(i<=5) and 0 or (i-5)
 a[0x140+1]=i
 samples[i]={frame=100+i*30,remaining=i<5 and 5-(i-1) or 0,gameplay=true,bytes=a}
end
local hits,total,fifth=M.rank(samples,20)
assert(fifth==5)
local map={};for _,v in ipairs(hits) do map[v.address]=v end
assert(map[0x120] and map[0x120].kind=="time_pause_candidate")
assert(map[0x130] and map[0x130].kind=="bonus_activation_candidate")
assert(map[0x140] and map[0x140].kind=="continuous_timer_candidate")
local path="test_timer_discovery_tmp.csv";os.remove(path)
M.write(path,"synthetic",hits,total,fifth)
local f=assert(io.open(path));local data=f:read("*a");f:close();os.remove(path)
assert(data:find("bonus_activation_candidate",1,true))
print("test_timer_discovery.lua OK synthetic")
