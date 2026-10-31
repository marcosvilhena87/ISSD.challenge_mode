-- PASS LV.1 v0.3: read-only automatic positional telemetry.
-- Candidate slots only: no claim that these are all outfield players.
local M={}
M.bases={0x062A,0x072A,0x082A,0x092A,0x0A2A,0x0B2A,0x0C2A,0x0D2A,0x0E2A,0x0F2A}
function M.sample(read_s16,read_u8,frame)
 local row={frame}
 for _,addr in ipairs(M.bases) do
  local okx,x=pcall(read_s16,addr,"WRAM")
  local oky,y=pcall(read_s16,addr+2,"WRAM")
  row[#row+1]=okx and x or ""
  row[#row+1]=oky and y or ""
 end
 for _,addr in ipairs({0x00A6,0x00A7,0x00C9,0x014F0}) do
  local ok,v=pcall(read_u8,addr,"WRAM")
  row[#row+1]=ok and v or ""
 end
 return row
end
function M.header()
 local fields={"session","frame"}
 for i=1,10 do
  fields[#fields+1]="slot"..i.."_x_candidate"
  fields[#fields+1]="slot"..i.."_y_candidate"
 end
 for _,a in ipairs({"00A6","00A7","00C9","014F0"}) do fields[#fields+1]="ram_"..a.."_u8" end
 return table.concat(fields,",")
end
return M
