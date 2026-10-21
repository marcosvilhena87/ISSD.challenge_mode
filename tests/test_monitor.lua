package.path="lua/?.lua;lua/?/init.lua;"..package.path
local monitor=require("challenge.monitor")
local probe=require("challenge.probe")
local path="test_monitor_v03_tmp.csv"
local events="test_monitor_v03_events.txt"
os.remove(path);os.remove(events)
local frame,level=100,0
local function result()
  local r=probe.decode(1,1,level)
  r.raw={challenge_a=1,challenge_b=1,selected_level=level,legacy_level_a=10,legacy_level_b=20}
  return r
end
local m=monitor.new({read=result,frame=function()return frame end,csv=path,events=events,session="test"})
m:step()
local ef=assert(io.open(events,"w"));ef:write("level_select\n");ef:close()
frame=102;m:step()
level=4;frame=103;m:step() -- unknown transition must survive
local f=assert(io.open(path,"r"));local s=f:read("*a");f:close()
assert(s:find("test,100,transition",1,true))
assert(s:find("test,102,operator,level_select",1,true))
assert(s:find("test,103,transition,level_select,,unknown",1,true))
assert(s:find(",4,10,20,1\n",1,true))
os.remove(path);os.remove(events)
print("test_monitor.lua: OK (synthetic only)")
