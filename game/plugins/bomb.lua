do return end
function macro.bomb(trigger,z,x,y)
  local bomb
  local function show_bomb()
    if bomb then bomb:delete() end
    bomb=nil
    bomb=props.add("mushroom_on_crack1",z)
    bomb:set_pos(x,y)
  end
  function on_level_change()
    show_bomb()
  end
  function on_update()
    if (save_table["last_bomb"] or 0)<(get_time()-0.01) and macro._all_trigger(trigger) then
      local p=player.get()
      local dist=math.sqrt(math.pow(p.posx-(x),2)+math.pow(p.posy-(y),2))
      if dist<0.5 and current_level()==z then
        local a=get_time()*32
        save_table["last_bomb"]=get_time()
        if bomb then bomb:delete() end
        show_bomb()
        local dirx=math.cos(a)
        local diry=math.sin(a)
        table.insert(entities.projectiles,{type="fireball",life=4,image="fireball_flames1",x=x+offset.x,y=y+offset.y,dirx=dirx,diry=diry,speed=4})
      end
    end
  end
end
function macro.pbomb(trigger,z,x,y)
  local bomb
  local function show_bomb()
    if bomb then bomb:delete() end
    bomb=nil
    bomb=props.add("mushroom_on_crack1",z)
    bomb:set_pos(x,y)
  end
  function on_level_change()
    show_bomb()
  end
  function on_update()
    if true then --(save_table["last_bomb"] or 0)<(get_time()-0.001) then
      local p=player.get()
      local dist=math.sqrt(math.pow(p.posx-(x),2)+math.pow(p.posy-(y),2))
      if dist<0.5 and current_level()==z then
        save_table["bomb"]=get_time()
      end
      if save_table["bomb"] and (save_table["bomb"]+60)>get_time() and macro._all_trigger(trigger) then
        local a=get_time()*100
        save_table["last_bomb"]=get_time()
        if bomb then bomb:delete() end
        show_bomb()
        for b=0,math.pi*2,math.pi/20 do
          local dirx=math.cos(a+b)
          local diry=math.sin(a+b)
          table.insert(entities.projectiles,{type="fireball",life=4,image="fireball_flames1",x=p.posx+offset.x,y=p.posy+offset.y,dirx=dirx,diry=diry,speed=4})
        end
      end
    end
  end
end
