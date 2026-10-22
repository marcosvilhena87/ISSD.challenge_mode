-- DRIBBLE Timer Decoder v1. Pure Lua; candidate interpretation, not a canonical memory map.
local M={}
function M.bcd(v)
 if type(v)~="number" or v%1~=0 or v<0 or v>255 then return nil end
 local lo=v%16;local hi=math.floor(v/16)
 if hi>9 or lo>9 then return nil end
 return hi*10+lo
end
function M.decode(row)
 local function n(k) return tonumber(row[k]) end
 local t,b=n("b_014F0"),n("b_014F4")
 local function word(a,b) if not a or not b then return nil end return a+256*b end
 local f_t=word(n("b_014F2"),n("b_014F3"))
 local f_b=word(n("b_014F6"),n("b_014F7"))
 return {time_seconds=M.bcd(t),bonus_seconds=M.bcd(b),time_fraction_u16=f_t,bonus_fraction_u16=f_b,time_fraction_hi=n("b_014F3"),bonus_fraction_hi=n("b_014F7")}
end
function M.summarize(rows)
 local result={}
 for _,phase in ipairs({"time_candidate","bonus_candidate"}) do
  local field=phase=="time_candidate" and "time_seconds" or "bonus_seconds"
  local frac=phase=="time_candidate" and "time_fraction_u16" or "bonus_fraction_u16"
  local count,valid,secchanges,fracchanges,same=0,0,0,0,0
  local first,last,previous=nil,nil,nil
  local changes={}
  for _,r in ipairs(rows) do
   if r.phase==phase then
    local d=M.decode(r);count=count+1
    if d[field]~=nil then valid=valid+1 end
    if previous then
     if previous[field]~=d[field] then
      secchanges=secchanges+1
      if #changes<20 then changes[#changes+1]=tostring(r.frame)..":"..tostring(previous[field])..">"..tostring(d[field]) end
     end
     if previous[frac]~=d[frac] then fracchanges=fracchanges+1 end
     if previous[field]==d[field] then same=same+1 end
    else first=d end
    last=d;previous=d
   end
  end
  result[phase]={samples=count,bcd_valid=valid,seconds_first=first and first[field],seconds_last=last and last[field],seconds_transitions=secchanges,fraction_transitions=fracchanges,stable_seconds_frames=same,transitions=table.concat(changes,";")}
 end
 return result
end
return M
