local lgi=require"lgi"
local cairo=lgi.require"cairo"
local files={}
local f=io.popen("ls data/*.png")
for file in f:lines() do
  table.insert(files,file)
end
f:close()
local f=io.popen("ls playeranimationen/*.png")
for file in f:lines() do
  table.insert(files,file)
end
f:close()
local images={}
for _,file in ipairs(files) do
  local srf=cairo.ImageSurface.create_from_png(file)
  if srf:get_width()%32==0 then
    if srf:get_height()%32==0 then
      table.insert(images,{name=file,image=srf})
    end
  end
end
local tiles={}
for _,img in ipairs(images) do
  local w,h=img.image:get_width()/32,img.image:get_height()/32
  for y=1,h do
    for x=1,w do
      table.insert(tiles,{image=img,off_x=x-1,off_y=y-1})
    end
  end
end
local x=0
local y=0
local state=2
local img={}
for _,tile in ipairs(tiles) do
  tile.x=x
  tile.y=y
  img[y+1]=img[y+1] or {}
  assert(not img[y+1][x+1],"INVT")
  img[y+1][x+1]=true
  if x==0 and state==2 then
    y=y+1
    x,y=y,0
    state=1
  elseif state==1 and y<x then
    y=y+1
  elseif state==1 and y==x then
    state=2
    x,y=x-1,y
  elseif state==2 and x>0 then
    x=x-1
  else
    print("END")
    return
  end
end
local w,h=#(img[1] or {}),#img
local s=cairo.ImageSurface.create('ARGB32',w*34,h*34)
local cr=cairo.Context.create(s)
cr:set_source_rgba(1,0,0,0)
cr:paint()
for _,t in ipairs(tiles) do
  cr:set_operator("CLEAR")
  cr:set_operator("OVER")
  cr:set_operator("SOURCE")
  local function d(x,y)
    cr:identity_matrix()
    cr:translate((t.x*34)+1+x,(t.y*34)+1+y)
    cr:set_source_surface(t.image.image,-t.off_x*32,-t.off_y*32)
    cr:move_to(0,0)
    cr:line_to(32,0)
    cr:line_to(32,32)
    cr:line_to(0,32)
    cr:close_path()
    cr:fill()
  end
  d(-1,-1)
  d(-1,1)
  d(1,-1)
  d(1,1)
  d(0,1)
  d(0,-1)
  d(1,0)
  d(-1,0)
  d(0,0)
end
s:write_to_png((arg[1] and arg[1]..".png") or "../game/tiles.png")
local file=io.open((arg[1] and arg[1]..".lua") or "../game/tiles.lua","w")
file:write("return {")
for _,tile in ipairs(tiles) do
  local fn=tile.image.name:gsub(".png$",""):gsub("^data/","")
  fn=fn:gsub("^playeranimationen/","")
  local srf=tile.image.image
  if srf:get_width()>32 or srf:get_height()>32 then
    fn=fn.." "..tile.off_x.."x"..tile.off_y
  end
  file:write("['")
  file:write(fn)
  file:write("']={")
  file:write(string.format("x=%d,y=%d",(tile.x*34)+1,(tile.y*34)+1))
  file:write("},")
  --print(tile.image.name,tile.x,tile.y,tile.off_x,tile.off_y)
end
file:write"}"
file:close()
