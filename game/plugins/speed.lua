do return end
function on_update()
  if ((save_table.is_speedster or 0)>0) and save_table.time_speedster and get_time()>save_table.time_speedster then
    player.set_speed(2)
    save_table.is_speedster=0
  end
end
function on_visit_block(block,pos)
  local i=props.get(pos.x,pos.y)[1]
  if i and (i.image=="mushroom_big1" or i.image=="mushroom_on_crack1") then
    save_table.is_speedster=math.max((i.image=="mushroom_on_crack1" and 2) or 1,save_table.is_speedster or 0)
    player.set_speed((i.image=="mushroom_on_crack1" and 10) or 5)
    save_table.time_speedster=get_time()+5
    player.narration{art="ged",text="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",del=0,weiter=false}
  end
end
