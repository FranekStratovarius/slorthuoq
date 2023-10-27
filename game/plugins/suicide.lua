do return end
function on_update()
  for i,p in ipairs(entities.projectiles or {}) do
    local pl=player.get()
    local x=p.x-offset.x
    local y=p.y-offset.y
    local dist=math.sqrt(math.pow(x-pl.posx,2)+math.pow(y-pl.posy,2))
    if p.enemy and dist<0.25 then
      player.kill(1)
      table.remove(entities.projectiles,i)
    end
  end
  ::start::
  for i,p in ipairs(entities.projectiles or {}) do
    for _,p2 in ipairs(entities.projectiles or {}) do
      if p~=p2 then
        local dist=math.sqrt(math.pow(p.x-p2.x,2)+math.pow(p.y-p2.y,2))
        if dist<0.25 then
          table.remove(entities.projectiles,i)
          goto start
        end
      end
    end
  end
end
function on_update()
  for i,p in ipairs(entities.projectiles or {}) do
    if p.guided then
      local pl=player.get()
      local x=(pl.posx+offset.x)
      local y=(pl.posy+offset.y)
      local x=p.x-x
      local y=p.y-y
      local c=0.99
      x=(p.dirx*c)-(x*(1-c))
      y=(p.diry*c)-(y*(1-c))
      local l=math.sqrt(math.pow(x,2)+math.pow(y,2))
      p.dirx=x/l
      p.diry=y/l
    end
  end
end
local boring=true
function on_update()
  local last=save_table["last_enemy_shot"] or 1
  if (last+1)<get_time() then
    save_table["last_enemy_shot"]=get_time()
    for _,p in ipairs(entities.mobs) do
      local x,y=p.x,p.y
      if not boring then
        x=math.floor(player.get().posx)+offset.x+math.random(-5,5)
        y=math.floor(player.get().posy)+offset.y+math.random(-5,5)
      end
      x=x-(p.dirx*0.5)
      y=y-(p.diry*0.5)
      table.insert(entities.projectiles,{type="fireball",life=60,image="fireball_flames1",
      guided=true,enemy=true,x=x,y=y,dirx=(boring and 0 or -p.dirx),diry=(boring and 0 or -p.diry),speed=(boring and 4 or 0.5)})
    end
  end
end

