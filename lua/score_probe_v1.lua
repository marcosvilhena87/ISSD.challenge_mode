-- Read-only DRIBBLE LV.1 results-screen score discovery.
-- Controlled operator captures: BOTH, TIME_ONLY, ZERO (in any order).
-- Do not send inputs to the emulated game.
local root=_G.ISSD_PROJECT_ROOT
assert(root,"Run this probe through main.lua using SCORE_PROBE mode")
assert(memory and memory.read_u8 and emu and emu.frameadvance and emu.framecount,
 "BizHawk memory/emu APIs unavailable")
local dir=root.."/csv"
local commands=root.."/score_probe_commands_v1.txt"
local session=os.date("!%Y%m%dT%H%M%SZ")
local labels={BOTH={183,268},TIME_ONLY={213,0},ZERO={0,0}}
local shots={}
local cursor=0
local function readbyte(a)
 local ok,v=pcall(memory.read_u8,a,"WRAM")
 if not ok or type(v)~="number" then error("WRAM read failed at "..string.format("0x%05X",a)) end
 return v
end
local function capture(label)
 if shots[label] then print("[score_probe] duplicate label ignored: "..label);return end
 local data={}
 for a=0,0x1FFFF do data[a+1]=readbyte(a) end
 shots[label]={data=data,frame=emu.framecount()}
 print("[score_probe] captured "..label.." frame="..shots[label].frame)
end
local function value(s,a,width,encoding)
 local b=s[a+1]
 if width==1 then
  if encoding=="bcd8" then
   local hi=math.floor(b/16);local lo=b%16
   if hi>9 or lo>9 then return nil end
   return 10*hi+lo
  end
  return b
 end
 local b2=s[a+2]
 if encoding=="u16le" then return b+256*b2 end
 if encoding=="u16be" then return 256*b+b2 end
 if encoding=="bcd16le" or encoding=="bcd16be" then
  local a1,a2=b,b2
  if encoding=="bcd16be" then a1,a2=b2,b end
  local digits={a1%16,math.floor(a1/16),a2%16,math.floor(a2/16)}
  for _,v in ipairs(digits) do if v>9 then return nil end end
  return digits[1]+10*digits[2]+100*digits[3]+1000*digits[4]
 end
end
local function export()
 local f=assert(io.open(dir.."/score_candidates_v1.csv","wb"))
 f:write("session,address_hex,encoding,target,match_type,both,time_only,zero,capture_frames,status\n")
 local formats={{1,"u8"},{1,"bcd8"},{2,"u16le"},{2,"u16be"},{2,"bcd16le"},{2,"bcd16be"}}
 local found=0
 for a=0,0x1FFFF do
  for _,spec in ipairs(formats) do
   local width,kind=spec[1],spec[2]
   if width==1 or a<0x1FFFF then
    local function val(label)
     return value(shots[label].data,a,width,kind)
    end
    -- u8 uses the raw value, not the BCD decoder.
    local function readval(label)
     if kind=="u8" then return shots[label].data[a+1] end
     return val(label)
    end
    local b,t,z=readval("BOTH"),readval("TIME_ONLY"),readval("ZERO")
    local target,match=nil,nil
    if b==183 and t==213 and z==0 then target="TIME_SCORE";match="exact"
    elseif b==268 and t==0 and z==0 then target="BONUS_SCORE";match="exact"
    elseif b==451 and t==213 and z==0 then target="TOTAL_SCORE";match="exact"
    elseif b and b>0 and t==0 and z==0 then target="BONUS_SCORE";match="positive_vs_zero"
    elseif b and b>0 and t and t>0 and z==0 then target="TIME_SCORE";match="positive_vs_zero" end
    if target then
     local frames=shots.BOTH.frame..";"..shots.TIME_ONLY.frame..";"..shots.ZERO.frame
     f:write(table.concat({session,string.format("0x%05X",a),kind,target,match,b,t,z,'"'..frames..'"',"hypothesis_only"},",").."\n")
     found=found+1
    end
   end
  end
 end
 f:close()
 print("[score_probe] candidate rows="..found.." csv="..dir.."/score_candidates_v1.csv")
 print("[score_probe] These addresses are hypotheses, not validated mappings.")
end
local function handle(line)
 local cmd=line:match("^%s*(.-)%s*$"):upper()
 if labels[cmd] then capture(cmd)
 elseif cmd=="EXPORT" then
  if shots.BOTH and shots.TIME_ONLY and shots.ZERO then export()
  else print("[score_probe] capture BOTH, TIME_ONLY and ZERO before EXPORT") end
 elseif cmd~="" then print("[score_probe] unknown command "..cmd) end
end
-- Start at EOF: old commands cannot accidentally label the current screen.
local function initial_cursor()
 local f=io.open(commands,"rb")
 if f then cursor=f:seek("end") or 0;f:close() end
end
initial_cursor()
print("[score_probe] Ready. commands="..commands.." cursor="..cursor)
while true do
 local f=io.open(commands,"rb")
 if f then
  local size=f:seek("end") or 0
  if size<cursor then cursor=0 end
  f:seek("set",cursor)
  local chunk=f:read("*a") or ""
  f:close()
  local complete=chunk:match("^(.*\n)")
  if complete then
   cursor=cursor+#complete
   for line in complete:gmatch("([^\n]*)\n") do handle(line:gsub("\r$","")) end
  end
 end
 emu.frameadvance()
end
