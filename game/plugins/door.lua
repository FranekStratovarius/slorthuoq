need("enemies")
need("trigger")
function macro.has_enemies()
  return (#entities.mobs)>0
end
function macro.key(name,keyz,keyx,keyy)
  load_tex("key")
  local ret=macro._new_trigger()
  local key
  local function show_key()
    key=nil
    if not save_table["has_key_"..name] then
      key=props.add("key",keyz)
      key:set_pos(keyx,keyy)
    end
  end
  function on_level_change()
    show_key()
  end
  function on_update()
    if not save_table["has_key_"..name] then
      local p=player.get()
      local dist=math.sqrt(math.pow(p.posx-(keyx),2)+math.pow(p.posy-(keyy),2))
      if dist<0.5 and current_level()==keyz then
        save_table["has_key_"..name]=true
        if key then key:delete() end
        show_key()
      end
    end
    ret.set_value(save_table["has_key_"..name])
  end
  return ret
end
function macro.door(trigger,doorz,doorx,doory,rot)
  local door
  local function show_door()
    load_tex("door_open")
    load_tex("door_closed")
    load_tex("door_side_open")
    load_tex("door_side")
    if door then door:delete() door=nil end
    local open=macro._all_trigger(trigger)
    if open then
      if rot%90>0 then door=props.add("door_side_open",doorz) else door=props.add("door_open",doorz) end
      door:set_pos(doorx,doory)
      --player.set_state("angel")
    else
      if rot%90>0 then door=props.add("door_side",doorz) else door=props.add("door_closed",doorz) end
      door:set_pos(doorx,doory)
      --player.set_state("normal")
    end
    door:set_rotation(math.rad(math.floor(rot/90)*90))
    map[doorz][doory][doorx].block=not open
  end
  macro._register_trigger(trigger,show_door)
  function on_level_change()
    show_door()
  end
end
function macro.trap_door(doorz,doorx,doory,destz,destx,desty)
  function on_level_change()
    local door=props.add("trapdoor",doorz)
    door:set_pos(doorx,doory)
  end
  function on_visit_block(block,pos)
    if current_level()==doorz and pos.x==doorx and pos.y==doory then
      if not macro.has_enemies() then
        change_level(destz)
        player.move(destx,desty)
      end
    end
  end
end
function macro.link_door(doorz,doorx,doory,destz,destx,desty)
  function on_visit_block(block,pos)
    if current_level()==doorz and pos.x==doorx and pos.y==doory then
      if not macro.has_enemies() then
        change_level(destz)
        player.move(destx,desty,true)
      end
    end
  end
end
