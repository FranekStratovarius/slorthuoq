local level={}
local torch
local function show_torch()
  if save_table.has_torch then
    torch=props.add("torch1",current_level())
  end
end
function on_level_change()
  show_torch()
end
function on_update()
  if save_table.has_torch and save_table.time_torch and get_time()>(save_table.time_torch+(level[current_level()] or 0)) then
    save_table.has_torch=false
    if torch then torch:delete() torch=nil end
  end
  if torch then
    local x,y=player.get().posx,player.get().posy
    torch:set_pos(x+0.2,y-0.2)
  end
end
function on_visit_block(block,pos)
  local z=current_level()
  for _,item in ipairs(map.items or {}) do
    if pos.x==item.x and pos.y==item.y and z==item.z then
      if item.image=="torch1" then
        goto torch
      end
    end
  end
  do return end
  ::torch::
  save_table.has_torch=true
  if not torch then
    player.narration{art="ged",text="Yay! Licht!",del=0,weiter=false}
    show_torch()
  end
  save_table.time_torch=get_time()
end
function on_post_draw()
  local v=1
  local t=save_table.time_torch and -(get_time()-save_table.time_torch)
  if save_table.has_torch then
    t=t+(level[current_level()] or 0)
    v=math.max(0,1-((t/3)))
  end
  if v>0 then
    local width=love.graphics.getWidth()
    local height=love.graphics.getHeight()
    love.graphics.setColor(0.01,0,0,0.5*v)
    love.graphics.rectangle("fill",0,0,width,height)
  end
end
function macro.torch(l,t)
  assert(type(t)=="number")
  level[l]=t
end
