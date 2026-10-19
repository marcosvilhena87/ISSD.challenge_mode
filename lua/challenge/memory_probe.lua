-- v0.4: identifica selecao candidata; ainda nao detecta presenca do menu.
local M={}
local ids={"dribble","pass","shoot","defense","corner_kick","free_kick"}
M.addresses={challenge_a=0xD708,challenge_b=0xE52C,selected_level=0x1550,
             legacy_level_a=0xD70A,legacy_level_b=0xE52E}
function M.decode(v)
  if type(v)~="table" then return {status="unknown",reason="no_values"} end
  local a,b,level=v.challenge_a,v.challenge_b,v.selected_level
  if type(a)~="number" or type(b)~="number" or type(level)~="number" then
    return {status="unknown",reason="read_failed"}
  end
  if a~=b then return {status="unknown",reason="challenge_pair_mismatch"} end
  if a%1~=0 or a<0 or a>5 or level%1~=0 or level<0 or level>3 then
    return {status="unknown",reason="out_of_range"}
  end
  return {status="candidate",challenge=ids[a+1],level=level+1,
          source="candidate_wram",reason="menu_presence_not_validated",
          legacy_level_a=v.legacy_level_a,legacy_level_b=v.legacy_level_b}
end
function M.read(reader)
  if type(reader)~="function" then return {status="unknown",reason="no_reader"} end
  local values={}
  for field,address in pairs(M.addresses) do
    local ok,val=pcall(reader,address,"WRAM")
    if not ok or type(val)~="number" then return {status="unknown",reason="read_failed"} end
    values[field]=val
  end
  local result=M.decode(values)
  result.raw=values
  return result
end
return M
