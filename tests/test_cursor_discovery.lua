package.path="lua/?.lua;lua/?/init.lua;"..package.path
local d=require("challenge.cursor_discovery")
local n=0x20000
local s={}
for k=1,4 do s[k]={} for i=1,n do s[k][i]=0 end end
local p=0x1234+1
s[1][p]=9;s[2][p]=10;s[3][p]=11;s[4][p]=9
local q=0x4321+1
s[1][q]=2;s[2][q]=1;s[3][q]=3;s[4][q]=2
local bad=0x3456+1
s[1][bad]=0;s[2][bad]=1;s[3][bad]=2;s[4][bad]=3
local hits=d.analyze(s)
assert(#hits==2)
assert(hits[1].offset==0x1234 and hits[1].adjacent==1)
assert(hits[2].offset==0x4321 and hits[2].adjacent==0)
local path="test_cursor_v1_tmp.csv"
os.remove(path)
d.write_csv(path,"test",{1,2,3,4},hits)
local f=assert(io.open(path,"rb"));local t=f:read("*a");f:close()
assert(t:find("0x01234",1,true) and t:find("candidate_not_validated",1,true))
os.remove(path)
local call=0
local snapshot=d.capture(function(address,domain) assert(domain=="WRAM");call=call+1;return address%256 end)
assert(call==n and #snapshot==n and snapshot[256]==255)
print("test_cursor_discovery.lua: OK (synthetic only)")
