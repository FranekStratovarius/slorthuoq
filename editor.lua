package.path=package.path..";game/?.lua"
local lgi=require"lgi"
local Gtk=lgi.require"Gtk"
local Gdk=lgi.require"Gdk"
local cairo=lgi.require"cairo"

local size=128
local posx=0
local posy=0

local images={}
local mode=Gtk.ComboBoxText{}

local tile=Gtk.ComboBoxText{}
local spin=Gtk.SpinButton.new_with_range(1,10000,1)
tile:append("-","-")
tile:set_active_id("-")
local f=io.popen("ls bilder/data/*.png")
for file in f:lines() do
  local s=cairo.ImageSurface.create_from_png(file)
  local n=file:match("bilder/data/(.*).png")
  images[n]=s
  table.insert(images,{name=n,img=s})
  tile:append(n,n)
end
f:close()

local image={{{"blumenwiese","blumenwiesemossy"}}}
local function load()
  image={}
  local data=assert(loadfile("game/data.lua"))()
  image.items=data.items
  image.enemies=data.enemies
  for k,v in ipairs(data) do
    local n=k
    local img={}
    for y,r in ipairs(v) do
      for x,b in ipairs(r) do
        img[x]=img[x] or {}
if b.dir and b.dir>0 then print(b.dir) end
        img[x][y]={image=b.texture,block=b.block,code=b.code or "",anschluss=b.anschluss,rot=(b.dir and math.floor((b.dir/math.pi/0.5)+0.5)) or 0}
      end
    end
    image[n]=img
  end
  image.spawn={}
  image.spawn.x=(data.spawn and data.spawn.x) or 3
  image.spawn.y=(data.spawn and data.spawn.y) or 3
end
load()


local function draw(cr,x,y,z)
  local l=image[z]
  l=l and l[x+1]
  local img=l and l[y+1]
  local valid=img and (x>=0 and y>=0)
  --if not valid then return end
  cr:translate((x+posx)*size,(y+posy)*size)
  local m=cr:get_matrix()
  if x<0 or y<0 then
    cr:set_source_rgb(1,0,0)
    cr:rectangle(0,0,size,size)
  elseif img and img.image then
    cr:scale(size/32.0,size/32.0)
    if img.rot then
      cr:translate(16,16)
      cr:rotate(math.rad(img.rot*90))
      cr:translate(-16,-16)
    end
    local i=images[img.image]
    cr:set_source_surface(i)
    cr:rectangle(0,0,32,32)
  else
    do return end
    cr:set_source_rgb(0,0,0)
    cr:rectangle(0,0,size,size)
  end
  cr:fill()
  if img and img.block then
    cr:set_matrix(m)
    cr:set_source_rgb(0,1,0)
    for p=0,size,16 do
      cr:move_to(0,p)
      cr:line_to(p,0)
      cr:stroke()
      cr:move_to(size,p)
      cr:line_to(p,size)
      cr:stroke()
    end
  end
  local cnt,cnt2=0,0
  for _,b in ipairs(image.enemies or {}) do
    if b.x==(x+1) and b.y==(y+1) and b.z==z then
      cnt2=cnt2+1
    end
  end
  for _,b in ipairs(image.items or {}) do
    if b.x==(x+1) and b.y==(y+1) and b.z==z then
      cnt=cnt+1
      cr:set_matrix(m)
      cr:set_source_rgb(1,0,0)
      --cr:translate(size*b.off_x,size*b.off_y)
      cr:arc(size*b.off_x,size*b.off_y,3,0,math.pi*2)
      cr:fill()
    end
  end
  if img then
    cr:set_matrix(m)
    cr:set_source_rgb(0,1,0)
    cr:translate(0,10)
    cr:show_text((x+1).."x"..(y+1)..":"..(img.anschluss and "X" or "0")..":"..cnt..":"..cnt2..":"..(img.code and "X" or "0"),0,10)
  end
  local c={}
  if x+1==image.spawn.x and y+1==image.spawn.y then
    cr:set_matrix(m)
    cr:set_source_rgb(0,0,1)
    cr:arc(size/2,size/2,20,0,math.pi*2)
    cr:fill()
  end
end

local area=Gtk.DrawingArea{hexpand=true,vexpand=true}
function area:on_draw(cr)
  cr:set_source_rgb(1,1,1)
  cr:paint()
  local sx=math.floor(-posx)-2
  local sy=math.floor(-posy)-2
  local ex=math.ceil(-posx+(area:get_allocated_width()/size))+2
  local ey=math.ceil(-posy+(area:get_allocated_height()/size))+2
  local z=spin:get_value()
  local om=cr:get_matrix()
  for x=sx,ex do
    for y=sy,ey do
      cr:set_matrix(om)
      draw(cr,x,y,z)
    end
  end
end
area:add_events(bit.bor(Gdk.EventMask.BUTTON_PRESS_MASK,Gdk.EventMask.POINTER_MOTION_MASK,Gdk.EventMask.SCROLL_MASK))
local lastx,lasty
function area:on_scroll_event(evt)
  if evt.direction=="UP" then
    size=math.min(math.floor(size*2),256)
  else
    size=math.max(math.floor(size/2),16)
  end
  area:queue_draw()
end
function area:on_button_press_event(evt)
  lastx,lasty=evt.x,evt.y
  local x=evt.x/size
  local y=evt.y/size
  x=x-posx
  y=y-posy
  x=math.floor(x)
  y=math.floor(y)
  if evt.button==1 and x>=0 and y>=0 then
    local z=spin:get_value()
    image[z]=image[z] or {}
    image[z][x+1]=image[z][x+1] or {}
    image[z][x+1][y+1]=image[z][x+1][y+1] or {}
    --image[getz()][x+1][y+1]=nil
    if mode:get_active_id()=="K" then
      local set=tile:get_active_id()
      if images[set] then
        image[z][x+1][y+1].image=set
      else
        image[z][x+1][y+1].image=nil
        image[z][x+1][y+1].block=nil
        image[z][x+1][y+1].anschluss=nil
      end
    elseif mode:get_active_id()=="B" then
      image[z][x+1][y+1].block=not image[z][x+1][y+1].block
    elseif mode:get_active_id()=="S" then
      image.spawn.x=x+1
      image.spawn.y=y+1
    elseif mode:get_active_id()=="D" then
      local t=image[z][x+1][y+1]
      t.rot=(t.rot or 0)+1
    elseif false and mode:get_active_id()=="C" then
      local b=image[z][x+1][y+1]
      if not b then return end
      local d=Gtk.Dialog{default_width=500,default_height=500}
      local box=Gtk.Box{orientation="VERTICAL"}
      local text=Gtk.TextView{hexpand=true,vexpand=true}
      text:set_monospace(true)
      local c=b.code or ""
      text:get_buffer():set_text(c,c:len())
      d:get_content_area():add(text)
      d:add_button("OK",1)
      d:add_button("Abbrechen",-1)
      d:show_all()
      local v=d:run()
      if v==1 then
        local buf=text:get_buffer()
        b.code=buf:get_text(buf:get_start_iter(),buf:get_end_iter())
        --b.code=
      end
      d:destroy()
    elseif mode:get_active_id()=="T" then
      local b=image[z][x+1][y+1]
      if not b then return end
      local d=Gtk.Dialog{}
      local box=Gtk.Box{orientation="VERTICAL"}
      local x=Gtk.SpinButton.new_with_range(1,500,1)
      local y=Gtk.SpinButton.new_with_range(1,500,1)
      local level=Gtk.SpinButton.new_with_range(1,500,1)
      local dir=Gtk.ComboBoxText{}
      dir:append("up","Hoch")
      dir:append("down","Runter")
      dir:append("left","Links")
      dir:append("right","Rechts")
      if b.anschluss then
        x:set_value(b.anschluss.x)
        y:set_value(b.anschluss.y)
        level:set_value(b.anschluss.level)
        dir:set_active_id(b.anschluss.dir)
      end
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="level"},level})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="x"},x})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="y"},y})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="dir"},dir})
      d:get_content_area():add(box)
      d:add_button("OK",1)
      d:add_button("Abbrechen",-1)
      d:add_button("Löschen",2)
      d:show_all()
      local v=d:run()
      if v==1 then
        b.anschluss={}
        b.anschluss.x=x:get_value()
        b.anschluss.y=y:get_value()
        b.anschluss.level=level:get_value()
        b.anschluss.dir=dir:get_active_id()
      elseif v==2 then
        b.anschluss=nil
      end
      d:destroy()
    elseif mode:get_active_id()=="I" then
      local items={}
      for ii,i in ipairs(image.items or {}) do
        if i.x==(x+1) and i.y==(y+1) and i.z==z then
          i.i=ii
          table.insert(items,i)
        end
      end
      local b=image[z][x+1][y+1]
      if not b then return end
      local d=Gtk.Dialog{}
      local box=Gtk.Box{orientation="VERTICAL"}
      local num=Gtk.SpinButton.new_with_range(1,(#items)+1,1)
      local off_x=Gtk.SpinButton.new_with_range(0,1,0.01)
      local off_y=Gtk.SpinButton.new_with_range(0,1,0.01)
      local img=Gtk.ComboBoxText{}
      for _,i in ipairs(images) do
        img:append(i.name,i.name)
      end
      img:set_active_id(images[1].name)
      num:set_value((#items)+1)
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="num"},num})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="x"},off_x})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="y"},off_y})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="bild"},img})
      d:get_content_area():add(box)
      d:add_button("Speichern",1)
      d:add_button("Abbrechen",-1)
      d:add_button("Löschen",2)
      function num:on_value_changed()
        local i=items[num:get_value()] or {}
        off_x:set_value(i.off_x or 0)
        off_y:set_value(i.off_y or 0)
        img:set_active_id(i.image)
      end
      d:show_all()
      local v=d:run()
      image.items=image.items or {}
      local i=items[num:get_value()]
print("V",v)
      if v==1 then
        i={x=x+1,y=y+1,z=z,off_x=off_x:get_value(),off_y=off_y:get_value(),image=img:get_active_id(),i=(i and i.i)}
print(i,i and i.i)
        if i and i.i then
          image.items[i.i]=i
        else
          table.insert(image.items,i)
        end
      elseif v==2 and i and i.i then
        table.remove(image.items,i.i)
      end
print("ITEMS")
for k,v in pairs(image.items) do print(k,v.x,v.y) end
      d:destroy()
    elseif mode:get_active_id()=="E" then
      local enemies={}
      for ii,i in ipairs(image.enemies or {}) do
        if i.x==(x+1) and i.y==(y+1) and i.z==z then
          i.i=ii
          table.insert(enemies,i)
        end
      end
      local b=image[z][x+1][y+1]
      if not b then return end
      local d=Gtk.Dialog{}
      local box=Gtk.Box{orientation="VERTICAL"}
      local num=Gtk.SpinButton.new_with_range(1,(#enemies)+1,1)
      local img=Gtk.ComboBoxText{}
      local si=require"game.switchindex"
      for _,i in ipairs(si.mobs) do
        img:append(i.type,i.type)
      end
      img:set_active_id(si.mobs[1].type)
      num:set_value((#enemies)+1)
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="num"},num})
      box:add(Gtk.Box{orientation="HORIZONTAL",Gtk.Label{label="bild"},img})
      d:get_content_area():add(box)
      d:add_button("Speichern",1)
      d:add_button("Abbrechen",-1)
      d:add_button("Löschen",2)
      function num:on_value_changed()
        local i=enemies[num:get_value()] or {}
        img:set_active_id(i.type)
      end
      d:show_all()
      local v=d:run()
      image.enemies=image.enemies or {}
      local i=enemies[num:get_value()]
print("V",v)
      if v==1 then
        i={x=x+1,y=y+1,z=z,type=img:get_active_id(),i=(i and i.i)}
print(i,i and i.i)
        if i and i.i then
          image.enemies[i.i]=i
        else
          table.insert(image.enemies,i)
        end
      elseif v==2 and i and i.i then
        table.remove(image.enemies,i.i)
      end
for k,v in pairs(image.enemies) do print(k,v.x,v.y) end
      d:destroy()
    end
  end
  area:queue_draw()
end
function area:on_motion_notify_event(evt)
  local hb3=false
  if lastx and lasty and evt.state["BUTTON3_MASK"] then
    local diffx,diffy=lastx-evt.x,lasty-evt.y
    lastx,lasty=evt.x,evt.y
    diffx=diffx/size
    diffy=diffy/size
    posx=posx-diffx
    posy=posy-diffy
  end
  area:queue_draw()
end
local window=Gtk.Window{default_width=500,default_height=500,on_destroy = Gtk.main_quit}
local box=Gtk.Box{orientation="VERTICAL"}
local box2=Gtk.Box{orientation="HORIZONTAL"}
function spin:on_value_changed()
  area:queue_draw()
end
mode:append("K","kacheln")
mode:append("B","blockieren")
mode:append("T","block ändern")
mode:append("S","startposition setzen")
mode:append("D","drehen")
mode:append("I","items")
mode:append("E","Pfeinde")
--mode:append("C","Trigger")
mode:set_active_id("K")
do
  local function f()
    local m=mode:get_active_id()
    tile:set_sensitive(m=="K")
    area:queue_draw()
  end
  function mode:on_changed()
    f()
  end
  f()
end
box2:add(mode)
box2:add(spin)
box2:add(tile)
box2:add(Gtk.Button{label="speichern",on_clicked=function(self)
  os.execute("mv game/data.lua data-old.lua")
  local out={}
  table.insert(out,string.format("spawn={x=%d,y=%d}",image.spawn.x,image.spawn.y))
  local lvl=0
  for _,v in ipairs(image) do
    local cur={}
    local maxx=#v
    local maxy=0
    for i=1,#v do
      maxy=math.max(maxy,#v[i])
    end
    for y=1,maxy do
      local row={}
      for x=1,maxx do
        local c=(v[x] or {})[y] or {}
        if c then
          if c.image then
            local a=(c.anschluss and string.format(",anschluss={x=%d,y=%d,level=%d,dir='%s'}",c.anschluss.x,c.anschluss.y,c.anschluss.level,c.anschluss.dir)) or ""
            local r=((c.rot and math.pi*0.5*(c.rot%4)) or 0)
            table.insert(row,"{texture='"..c.image.."',block="..(c.block and "true" or "false")..a..",rot="..r..",code='"..(c.code or ""):gsub(".",function(a) return string.format("\\x%02x",string.byte(a)) end).."'}")
            if c.code and c.code:len()>0 then print(row[#row]) end
          else
            table.insert(row,"{texture=nil,block=true}")
          end
        else
          table.insert(row,"{texture=nil,block=true}")
        end
      end
      table.insert(cur,"{"..table.concat(row,",").."}")
    end
    lvl=lvl+1
    table.insert(out,"{"..table.concat(cur,",").."}")
  end
  if image.items then
    local t={}
    for _,i in ipairs(image.items) do
      table.insert(t,string.format("{x=%d,y=%d,z=%d,off_x=%f,off_y=%f,image='%s'}",i.x,i.y,i.z,i.off_x,i.off_y,i.image))
    end
    table.insert(out,"items={"..table.concat(t,",").."}")
  end
  if image.enemies then
    local t={}
    for _,i in ipairs(image.enemies) do
      table.insert(t,string.format("{x=%d,y=%d,z=%d,type='%s'}",i.x,i.y,i.z,i.type))
    end
    table.insert(out,"enemies={"..table.concat(t,",").."}")
  end
  out="return {"..table.concat(out,",").."}"
  local file=io.open("game/data.lua","w")
  file:write(out)
  file:close()
  print(out)
end})
box:add(box2)
box:add(area)
window:add(box)
window:show_all()
Gtk.main()
