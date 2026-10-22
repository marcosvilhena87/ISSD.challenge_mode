-- Synthetic tests: no BizHawk or ROM required.
package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local CSV=require("challenge.dribble_csv_v035")
local Commands=require("challenge.dribble_commands_v035")
local path="tests/_dribble_io_test.tmp"
local function write_text(value)
 local f=assert(io.open(path,"wb"));assert(f:write(value));f:close()
end
local function append(value)
 local f=assert(io.open(path,"ab"));assert(f:write(value));f:close()
end
local header="session,value,extra"
write_text(header.."\n20261022T040000Z_1,1,\n")
CSV.setup(path,header)
CSV.write(path,{"20261022T040000Z_2",nil,3},3)
local f=assert(io.open(path,"rb"));local csv=f:read("*a");f:close()
assert(csv:find("20261022T040000Z_2,,3\n",1,true))
write_text("20261022T040000Z_1,1,\n")
CSV.setup(path,header)
local f2=assert(io.open(path,"rb"));assert(f2:read("*l")==header);f2:close()
-- New reader ignores prior commands and accepts only complete appended lines.
write_text("ARM\n")
local messages={}
local reader=Commands.new(path,function(msg) messages[#messages+1]=msg end)
local seen={}
local function capture(msg) seen[#seen+1]=msg end
reader.poll(capture)
assert(#seen==0)
append("PROFILE:CONTROL") -- incomplete
reader.poll(capture)
assert(#seen==0)
append("\r\nARM\n")
reader.poll(capture)
assert(#seen==2 and seen[1]=="PROFILE:CONTROL" and seen[2]=="ARM")
reader.poll(capture)
assert(#seen==2)
os.remove(path)
print("PASS: CSV repair/append and append-only commands")
