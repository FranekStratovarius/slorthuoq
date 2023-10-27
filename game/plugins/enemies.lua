do return end
function macro.has_enemies()
  return (#entities.mobs)>0
end
function on_update()
  local c={}
  for _,e1 in ipairs(entities.mobs) do
    local x=0
    local y=0
    for _,e2 in ipairs(entities.mobs) do
      if e1~=e2 then
        local pd=math.sqrt(math.pow(e1.x-e2.x,2)+math.pow(e1.y-e2.y,2))
        if pd<0.1 then
          e1.x=e1.x+(math.random()*2)-1
          e1.y=e1.y+(math.random()*2)-1
          e2.x=e2.x+(math.random()*2)-1
          e2.y=e2.y+(math.random()*2)-1
        end
        local dx=e2.x-e1.x
        local dy=e2.y-e1.y
        local v=(1-math.pow(50,-math.min(pd-1,0)))*0.05
        x=x+dx*v
        y=y+dy*v
      end
    end
    c[e1]={x,y}
  end
  for k,v in pairs(c) do
    k.x=k.x+v[1]
    k.y=k.y+v[2]
  end
end
