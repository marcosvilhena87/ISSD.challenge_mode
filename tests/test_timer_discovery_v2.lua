package.path="lua/?.lua;lua/?/init.lua;"..package.path
local M=require("challenge.timer_discovery_v2")
local samples={}
for i=1,9 do
 local bytes={}
 for j=1,M.SIZE do bytes[j]=0 end
 bytes[0x120+1]=i<=5 and i or 5
 bytes[0x130+1]=i<=5 and 0 or i-5
 bytes[0x140+1]=i
 samples[i]={gs=0,ptr=0x0F00,remaining=i<=5 and 6-i or 0,frame=100+i*30,bytes=bytes}
end
local a,an,b,bn=M.rank(samples,20)
local t,z={},{}
for _,v in ipairs(a) do t[v.address]=v end
for _,v in ipairs(b) do z[v.address]=v end
assert(t[0x120] and z[0x130] and an>=2 and bn>=2)
samples[#samples+1]={gs=6,ptr=0,remaining=0,frame=1000,bytes={}}
assert(M.phase(samples[#samples])=="excluded")
print("test_timer_discovery_v2.lua OK synthetic")
