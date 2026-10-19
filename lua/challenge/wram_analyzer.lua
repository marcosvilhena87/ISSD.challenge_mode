-- Analise por padroes de invariancia e distinguibilidade. Sem alegacao de validacao.
local M = {}
local ids = {"dribble","pass","shoot","defense","corner_kick","free_kick"}
local function parse_hex(s)
  s=s:gsub("%s+","")
  assert(#s % 2 == 0, "hex impar")
  assert(s:match("^[0-9a-fA-F]*$"),"hex invalido")
  local parts={}
  for i=1,#s,2 do parts[#parts+1]=string.char(tonumber(s:sub(i,i+1),16)) end
  return table.concat(parts)
end
local function readfile(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local function parse_manifest(path)
  local s=readfile(path); local rows,seen={},{}
  -- Compatibilidade com manifesto antigo: dois caracteres barra e n no cabecalho.
  s=s:gsub("name,challenge,level,round\\\\n", "name,challenge,level,round\\n")
  for line in (s.."\n"):gmatch("(.-)\r?\n") do
    if line~="" and line~="name,challenge,level,round" then
      local name,ch,lv,round=line:match("^([%w_%-]+),([%w_%-]+),(%d+),(%d+)$")
      assert(name and not seen[name],"linha CSV invalida ou duplicada: "..line)
      seen[name]=true
      rows[#rows+1]={name=name,challenge=ch,level=tonumber(lv),round=tonumber(round)}
    end
  end
  return rows
end
local function value(raw,offset,width)
  local a=raw:byte(offset+1)
  if width==1 then return a end
  return a+raw:byte(offset+2)*256 -- word little-endian (hipotese)
end
local function group_score(samples,offset,width,dimension)
  local bygroup,bylabel={},{}
  for _,s in ipairs(samples) do
    local group = dimension=="challenge" and s.challenge or tostring(s.level)
    local v=value(s.raw,offset,width)
    if bygroup[group] and bygroup[group]~=v then return nil end
    bygroup[group]=v
  end
  local n,distinct=0,0
  for _,v in pairs(bygroup) do n=n+1; if not bylabel[v] then distinct=distinct+1;bylabel[v]=true end end
  if n~=(dimension=="challenge" and 6 or 4) then return nil end
  if distinct<2 then return nil end
  return distinct
end
function M.analyze(samples, nbytes)
  assert(#samples==48,"necessarias 2 rodadas completas de 24 cenarios")
  local counts={}
  local expected={}
  for _,id in ipairs(ids) do
    for lv=1,4 do expected[id..":"..lv]=0 end
  end
  for _,s in ipairs(samples) do
    local k=s.challenge..":"..s.level
    assert(expected[k] and (s.round==1 or s.round==2),"amostra invalida: "..k)
    local rk=k..":"..s.round
    assert(not counts[rk],"amostra duplicada "..rk)
    counts[rk]=true
    assert(#s.raw==nbytes,"comprimento divergente")
  end
  for k in pairs(expected) do assert(counts[k..":1"] and counts[k..":2"],"faltando "..k) end
  local out={}
  for width=1,2 do
    for offset=0,nbytes-width do
      for _,dimension in ipairs({"challenge","level"}) do
        local distinct=group_score(samples,offset,width,dimension)
        if distinct then out[#out+1]={offset=offset,width=width,dimension=dimension,distinct=distinct,status="candidate"} end
      end
    end
  end
  table.sort(out,function(a,b)
    if a.distinct~=b.distinct then return a.distinct>b.distinct end
    if a.width~=b.width then return a.width<b.width end
    if a.offset~=b.offset then return a.offset<b.offset end
    return a.dimension<b.dimension
  end)
  return out
end
function M.load(folder)
  local rows=parse_manifest(folder.."/manifest.csv")
  local samples,nbytes={},nil
  for _,r in ipairs(rows) do
    if r.challenge~="outside" then
      r.raw=parse_hex(readfile(folder.."/"..r.name..".hex"))
      nbytes=nbytes or #r.raw
      samples[#samples+1]=r
    end
  end
  return samples,nbytes
end
return M
