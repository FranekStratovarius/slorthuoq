do return end
local function save(val)
  local t=type(val)
  if t=="nil" then
    return "nil"
  elseif t=="boolean" then
    return val and "true" or "false"
  elseif t=="number" then
    return val..""
  elseif t=="string" then
    return '"'..val:gsub("[^a-zA-Z0-9 _]",function(a) return string.format("\\x%02X",string.byte(a)) end)..'"'
  elseif t=="table" then
    local t={}
    for k,v in pairs(val) do
      table.insert(t,"["..save(k).."]="..save(v))
    end
    return "{"..table.concat(t,",").."}"
  else
    error("Invalid Type: "..tostring(t))
  end
end
local last
function on_update()
  local t=get_time()
  if not last then
    local f=assert(loadfile("saved.lua"))()
    for k,v in pairs(f) do
      save_table[k]=v
    end
    reload_time()
    last=get_time()
    change_level(save_table.level)
    player.move(save_table.player.posx,save_table.player.posy)
  elseif (t-last)>2 then
    save_table.player=player.get()
    save_table.level=current_level()
    local f=assert(io.open("saved.lua","w"))
    f:write("return "..save(save_table))
    f:close()
    last=t
  end
end
