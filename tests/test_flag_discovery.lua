package.path="lua/?.lua;lua/?/init.lua;"..package.path
local D=require("challenge.flag_discovery")
local a,b,c={},{},{}
for i=1,D.SIZE do a[i]=0;b[i]=0;c[i]=0 end
a[0x1235]=0;b[0x1235]=1;c[0x1235]=1
a[0x2001]=3;b[0x2001]=3;c[0x2001]=4
a[0x3001]=0;b[0x3001]=100;c[0x3001]=200
local results,n=D.rank({a,b,c},10)
assert(n==2 and #results==2)
assert(results[1].address==0x1234 and results[2].address==0x2000)
local temp="test_flag_candidates_tmp.csv";os.remove(temp)
D.write(temp,"synthetic",{1,2,3},results,n)
local f=assert(io.open(temp,"r"));local s=f:read("*a");f:close()
assert(s:find("0x01234",1,true) and s:find("hypothesis_only",1,true))
os.remove(temp)
print("test_flag_discovery.lua OK synthetic")
