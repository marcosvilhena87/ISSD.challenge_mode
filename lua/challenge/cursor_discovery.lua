-- WRAM Cursor Discovery v1: leitura sob demanda, sem inputs ou dumps brutos.
local M={}
local labels={"A","B","C","A"}
local function valid(v) return type(v)=="number" and v>=0 and v<=255 and v%1==0 end
local function check(s)
  assert(type(s)=="table" and #s==0x20000,"snapshot precisa conter 128 KiB")
end
function M.analyze(snaps)
  assert(#snaps==4,"sao exigidas quatro capturas A B C A")
  for i=1,4 do check(snaps[i]) end
  local hits={}
  for i=1,0x20000 do
    local a,b,c,d=snaps[1][i],snaps[2][i],snaps[3][i],snaps[4][i]
    if valid(a) and valid(b) and valid(c) and valid(d) and
       a==d and a~=b and a~=c and b~=c then
      local offset=i-1
      hits[#hits+1]={offset=offset,a=a,b=b,c=c,returned=d,
        adjacent=(b==a+1 and c==b+1) and 1 or 0}
    end
  end
  table.sort(hits,function(x,y)
    if x.adjacent~=y.adjacent then return x.adjacent>y.adjacent end
    return x.offset<y.offset
  end)
  return hits
end
function M.capture(read)
  local values={}
  for address=0,0x1FFFF do
    local ok,val=pcall(read,address,"WRAM")
    if not ok or not valid(val) then
      error(string.format("WRAM read failed at 0x%05X: %s",address,tostring(val)))
    end
    values[address+1]=val
  end
  return values
end
function M.write_csv(path,session,frames,hits)
  local f=assert(io.open(path,"a+"))
  if f:seek("end")==0 then
    f:write("session,frame_a1,frame_b,frame_c,frame_a2,rank,address_hex,address_dec,value_a,value_b,value_c,value_return,ascending_012,evidence\n")
  end
  for i,h in ipairs(hits) do
    f:write(string.format("%s,%d,%d,%d,%d,%d,0x%05X,%d,%d,%d,%d,%d,%d,candidate_not_validated\n",
      session,frames[1],frames[2],frames[3],frames[4],
      i,h.offset,h.offset,h.a,h.b,h.c,h.returned,h.adjacent))
  end
  f:flush();f:close()
end
M.labels=labels
return M
