-- Sondas experimentais identificadas em duas sessoes (24 cenarios cada).
-- NAO comprovam por si so a entrada no Challenge Mode.
local M = {}
local ids = {"dribble","pass","shoot","defense","corner_kick","free_kick"}
M.addresses = { challenge_a=0xD708, challenge_b=0xE52C, level_a=0xD70A, level_b=0xE52E }
function M.decode(v)
  if type(v)~="table" then return {status="unknown",reason="no_values"} end
  local a,b,l1,l2=v.challenge_a,v.challenge_b,v.level_a,v.level_b
  if a==nil or b==nil or l1==nil or l2==nil then return {status="unknown",reason="read_failed"} end
  if a~=b or l1~=l2 then return {status="unknown",reason="pair_mismatch"} end
  if type(a)~="number" or type(l1)~="number" or not ids[a+1] or l1<0 or l1>3 or l1%1~=0 then
    return {status="unknown",reason="out_of_range"}
  end
  return {status="candidate",challenge=ids[a+1],level=l1+1,source="candidate_wram",reason="mode_not_validated"}
end
function M.read(reader)
  if type(reader)~="function" then return {status="unknown",reason="no_reader"} end
  local values={}
  for field,address in pairs(M.addresses) do
    local ok,val=pcall(reader,address,"WRAM")
    if not ok or type(val)~="number" then return {status="unknown",reason="read_failed"} end
    values[field]=val
  end
  return M.decode(values)
end
return M
