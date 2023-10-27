do return end
function on_post_draw()
  local hour=((get_time()/300.0)+6)
  local day=math.floor(hour/24)
  hour=hour%24
  local color=(math.cos((hour/24)*math.pi*2)+1)/5
  local minute=(hour*60)%60
  local width=love.graphics.getWidth()
  local height=love.graphics.getHeight()
  love.graphics.push()
  love.graphics.scale(0.1,0.1)
    love.graphics.printf(
      string.format("%02d:%02d",hour,minute),
      width*8,
     500,
       width*2,
      "right"
    )
  love.graphics.pop()
  love.graphics.setColor(0.01,0,0,color)
  love.graphics.rectangle("fill",0,0,width,height)
end

