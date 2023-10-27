function macro.shield(trigger,z,x,y)
  local shield
  local function show_shield()
    if shield then shield:delete() end
    shield=nil
    shield=props.add("shield",current_level())
  end
  function on_update()
    if shield then
      if save_table.shield then
        local x,y=player.get().posx,player.get().posy
        shield:set_pos(x+0.2,y-0.2)
      else
        shield:set_pos(x,y)
      end
    end
  end
  function on_level_change()
    show_shield()
  end
  function on_visit_block(block,pos)
    local z=current_level()
    if pos.x==x and pos.y==y and z==current_level() then
      save_table.shield=true
      show_shield()
    end
  end
  function on_hit()
    if save_table.shield then
      player.kill(-1)
      save_table.shield=false
    end
  end
end
