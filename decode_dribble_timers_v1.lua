-- Offline DRIBBLE timer candidate decoder. Run with Lua in repository root:
-- lua decode_dribble_timers_v1.lua [input.csv] [decoded.csv] [summary.csv]
package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local D=require("challenge.timer_decoder_v1")
local input=arg[1] or "dribble_timer_validation_v1.csv"
local decoded=arg[2] or "dribble_timer_decoded_v1.csv"
local summary=arg[3] or "dribble_timer_decoder_summary_v1.csv"
local f=assert(io.open(input,"r"),"Input CSV missing: "..input)
local header=assert(f:read("*l")):gsub("\r$","")
local keys={};for field in (header..","):gmatch("(.-),") do keys[#keys+1]=field end
local rows={}
for line in f:lines() do
 line=line:gsub("\r$","")
 local cells={};for cell in (line..","):gmatch("(.-),") do cells[#cells+1]=cell end
 if #cells==#keys then
  local row={};for i,k in ipairs(keys) do row[k]=cells[i] end
  if row.phase=="time_candidate" or row.phase=="bonus_candidate" then rows[#rows+1]=row end
 end
end
f:close()
local out=assert(io.open(decoded,"w"))
out:write("session,frame,phase,remaining,time_seconds_bcd,bonus_seconds_bcd,time_fraction_u16,bonus_fraction_u16,time_fraction_hi,bonus_fraction_hi,status\n")
local function s(v) if v==nil then return "" end return tostring(v) end
for _,row in ipairs(rows) do
 local d=D.decode(row)
 out:write(table.concat({s(row.session),s(row.frame),s(row.phase),s(row.remaining),s(d.time_seconds),s(d.bonus_seconds),s(d.time_fraction_u16),s(d.bonus_fraction_u16),s(d.time_fraction_hi),s(d.bonus_fraction_hi),"candidate_only"},",").."\n")
end
out:close()
local stats=D.summarize(rows)
local report=assert(io.open(summary,"w"))
report:write("phase,samples,bcd_valid,seconds_first,seconds_last,seconds_transitions,fraction_transitions,stable_seconds_frames,transitions,status\n")
for _,phase in ipairs({"time_candidate","bonus_candidate"}) do
 local d=stats[phase]
 report:write(table.concat({phase,s(d.samples),s(d.bcd_valid),s(d.seconds_first),s(d.seconds_last),s(d.seconds_transitions),s(d.fraction_transitions),s(d.stable_seconds_frames),s(d.transitions),"hypothesis_only"},",").."\n")
 print(string.format("[ISSD.decoder_v1] %s samples=%d BCD=%d seconds=%s -> %s fraction_changes=%d",phase,d.samples,d.bcd_valid,s(d.seconds_first),s(d.seconds_last),d.fraction_transitions))
end
report:close()
print("[ISSD.decoder_v1] wrote "..decoded.." and "..summary)
