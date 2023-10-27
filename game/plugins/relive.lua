do return end
function on_update()
  local last=save_table["last_refresh"] or 0
  if (last+1)<get_time() then
    save_table["last_refresh"]=get_time()
    player.kill(-1)
  end
end
