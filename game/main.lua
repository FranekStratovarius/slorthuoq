local canvas=nil
local dir=1
local debugging=false
local versionsnummerda,version=pcall(require,"versionsnummerSlorthuoq")
local tilesatlas=require"tiles"
local switchindex=require"switchindex"
local narrat=require"narrat"
love.graphics.setDefaultFilter("nearest","nearest",1)

local tiles=nil
local animations={}

local firstload=true
local oldlevel={offsetx=0,offsety=0,targetx=0,targety=0}

local music={music=nil,name=nil}
local fightmusic=nil
local fightmusicactive=false
local musicdump={}

local currentos=love.system.getOS()
local loadedlevel={}
local savegamenexttick=false

local paused=false
local loaded=false
local logodrawn=false
local loadsleep=1
local mouse={}
local respawntimer=3
local musicPlaying=true
local musicPaused=false
local showcredits=false

local narrtext={
  txtquery={},
  accttext=nil
}

local textures={}
local animations={}

local offset={x=0,y=0}
local actualLevel=1
local level={}
local leveloffsets={}
local tmpheight,tmpwidth

local map=require"data"

local camera={
  posx = 1,
  posy = 1,
}

local char={
  health=4,
  posx = (map.spawn and map.spawn.x) or 3,
  posy = (map.spawn and map.spawn.y) or 3,
  dirx = 0,
  diry = -1,
  walking=false,
  speed = 2,
  width = 0.15,
  height = 0.45,
  height2 = 0.2,
  state="wiblex",
  pics = {
    normal={},
    angel={},
    demon={},
    halfling={},
  }
}

local entities={
  mobs={},
  projectiles={},
}

local joystick={
  active=false,
  touchid=nil,
  x=0,
  y=0,
  dx=0,
  dy=0,
  normdx=0,
  normdy=0,
}
local joystick2={
  active=false,
  touchid=nil,
  x=0,
  y=0,
  dx=0,
  dy=0,
  normdx=0,
  normdy=0,
  firedelay=0.7,
}

local hearts={}

local save_table={}--save this to file

local triggers={on_visit_block={},on_update={},on_post_draw={},on_level_change={},on_key_pressed={},on_hit={}}
local timeouts={}
if not save_table.game_time then
  save_table.game_time=0
end
local time_offset=save_table.game_time-love.timer.getTime()
local function game_time()
  if not paused then
    save_table.game_time=love.timer.getTime()+time_offset
    return love.timer.getTime()+time_offset
  else
    return save_table.game_time
  end
end
local plugins={}
local create_plugin_env
local macro={}
local function load_plugin(fn)
  if plugins[fn]==2 then return end
  if plugins[fn]==1 then error("Recursion in "..fn) end
  plugins[fn]=1
  local env=create_plugin_env()
  local f=assert(love.filesystem.load("plugins/"..fn))
  setfenv(f,env)
  f()
  plugins[fn]=2
end
function create_plugin_env()
  local plugin_env={}
  local mt={}
  plugin_env.map=map
  plugin_env.macro=macro
  plugin_env.save_table=save_table
  plugin_env.math=math
  plugin_env.string=string
  plugin_env.love=love--TODO: Protect
  plugin_env.table=table
  plugin_env.print=print
  plugin_env.type=type
  plugin_env.pairs=pairs
  plugin_env.ipairs=ipairs
  plugin_env.tostring=tostring
  plugin_env.error=error
  plugin_env.io=io
  plugin_env.loadfile=loadfile
  plugin_env.assert=assert
  plugin_env.entities=entities
  plugin_env.offset=offset
  function mt:__newindex(name,cb)
    if not triggers[name] then error("Invalid Trigger '"..tostring(name).."'") end
    assert(type(cb)=="function")
    table.insert(triggers[name],cb)
  end
  plugin_env.player={}
  plugin_env.props={}
  function plugin_env.change_level(new_level)
    actualLevel=new_level
    loadLevel()
  end
  function plugin_env.get_time()
    return game_time()
  end
  function plugin_env.reload_level()
    return loadLevel()
  end
  function plugin_env.need(name)
    load_plugin(name..".lua")
  end
  function plugin_env.current_level()
    return actualLevel
  end
  function plugin_env.player.move(x,y,mc)
    char.posx=x+offset.x
    char.posy=y+offset.y
    if mc then
      camera.posx=x+offset.x-0.3
      camera.posy=y+offset.y
    end
  end
  function plugin_env.player.kill(a)
    char.health=math.min(math.max(char.health-a,0),4)
  end
  function plugin_env.reload_time()
    time_offset=save_table.game_time-love.timer.getTime()
  end
  function plugin_env.player.narration(v)
    table.insert(narrtext.txtquery,v)
  end
  function plugin_env.load_tex(name)
    loadTextures({name})
  end
  function plugin_env.props.add(name,z)
    loadTextures({name})
    assert(z)
    local a={}
    local ret={}
    function ret:set_pos(x,y)
      local rnd={}
      if z==actualLevel then
        table.insert(rnd,{x=x,y=y})
      else
        local v=loadedlevel[i]
        for i,v in ipairs(loadedlevel)do
          local x,y=x,y
          if v.name==z then
            if v.dir=="up" then
              x,y=x,y-v.height
            elseif v.dir=="down" then
              x,y=x,y+tmpheight
            elseif v.dir=="left" then
              x,y=x+tmpwidth,y+v.y-1
            elseif v.dir=="right" then
              x,y=x-v.width,y+v.y-1
            end
            table.insert(rnd,{x=x,y=y})
          end
        end
      end
      ::start::
      for j=1,#a do
        local good=false
        for i,item in ipairs(level.props) do
          if a[j]==item then good=true end
        end
        if not good then table.remove(a,j) goto start end
      end
      while (#a)<(#rnd) do
        local t={image=name,x=0,y=0,z=z,off_x=0,off_y=0,off_z=500}
        table.insert(a,t)
        table.insert(level.props or {},t)
      end
      while (#a)>(#rnd) do
        local t=table.remove(a)
        for i,item in ipairs(level.props) do
          if item==t then
            table.remove(level.props,i)
          end
        end
      end
      for i=1,#rnd do
        a[i].x,a[i].y=math.floor(rnd[i].x+offset.x),math.floor(rnd[i].y+offset.y)
        a[i].off_x=x%1
        a[i].off_y=y%1
      end
    end
    function ret:set_rotation(na)
      for _,p in ipairs(a) do p.rot=na end
    end
    function ret:delete()
      ::start::
      while #a>0 do
        local t=table.remove(a,1)
        for i,item in ipairs(level.props) do
          if item==t then
            table.remove(level.props,i)
            goto start
          end
        end
      end
    end
    level.props.sort()
    return ret
  end
  function plugin_env.props.get(x,y)
    x=x+offset.x
    y=y+offset.y
    local ret={}
    for _,prop in ipairs(level.props) do
      if prop.x==x and prop.y==y and prop.z==actualLevel  then
        table.insert(ret,prop)
      end
    end
    return ret
  end
  function plugin_env.player.set_speed(s)
    char.speed=s
  end
  function plugin_env.player.set_state(s)
    char.state=s
  end
  function plugin_env.player.get()
    return {posx=char.posx-offset.x,posy=char.posy-offset.y,dir={x=char.dirx,y=char.diry},state=char.state}
  end
  setmetatable(plugin_env,mt)
  return plugin_env
end
local function load_plugins()
  for _,fn in ipairs(love.filesystem.getDirectoryItems("plugins")) do
    load_plugin(fn)
  end
end
local last_triggerstone


function love.load()
  local tempwidth, tempheight = love.window.getDesktopDimensions(display)
  local scale = love.window.getDPIScale()
  local tempdesktopwidth,_ = love.window.getDesktopDimensions(display)
  local tempwidthoffset,tempheightoffset = tempwidth,tempheight
  width = tempwidth/scale--*0.5
  height = tempheight/scale
  --love.mouse.setRelativeMode(true)
  love.window.setMode(width,height,{fullscreen = true,resizable = false,vsync = false})
  love.window.setFullscreen(true)
	love.keyboard.setKeyRepeat(true)
  love.graphics.setPointSize(10)
  local font = love.graphics.newFont("alagard.ttf", width*0.19)
  love.graphics.setFont(font)
  local dir = love.filesystem.getSaveDirectory()
  local loadedfunc=loadfile(dir.."/saved.lua")
  local loaded
  if loadedfunc then loaded=loadedfunc() end
  if loaded then
    actualLevel=loaded.level
    char.posx=loaded.posx
    char.posy=loaded.posy
  end
  fightmusic=love.audio.newSource(switchindex.music.battle..".mp3","static")
  fightmusic:setLooping(true)
end

function love.resize(w,h)
  local tempwidth, tempheight = love.window.getDesktopDimensions(display)
  local scale = love.window.getDPIScale()
  local tempdesktopwidth,_ = love.window.getDesktopDimensions(display)
  local tempwidthoffset,tempheightoffset = tempwidth,tempheight
  width = tempwidth/scale--*0.5
  height = tempheight/scale
  local font = love.graphics.newFont("alagard.ttf", width*0.19)
  love.graphics.setFont(font)
  if currentos~="Windows"then
    --love.window.setMode(width,height,{fullscreen = true,resizable = false,vsync = false})
  end
  --love.window.setFullscreen(true)
end

function love.update(dt)
  if savegamenexttick then
    if not level[math.floor(char.posy+0.5)][math.floor(char.posx+0.5)].mark then
      savegame()
      savegamenexttick=false
    end
  end
  if logodrawn and not loaded then
    loadsleep=loadsleep-dt
    if loadsleep<0 then
      loadAtStart()
    end
  end
  if not paused and loaded and char.health>0 then
    if map.enemies then
      if #entities.mobs>0 then
        if not fightmusicactive then
          if fightmusic then
            fightmusicactive=true
            fightmusic:play()
            if music.music then music.music:stop()end
          end
        end
      else
        if fightmusicactive then
          fightmusicactive=false
          fightmusic:stop()
          if music.music then music.music:play()end
        end
      end
    end
    animationenAuswechseln(dt)
    if narrtext.txtquery[1] then
      if not narrtext.accttext then
        narrtext.accttext={text="",art=narrtext.txtquery[1].art,dt=0,n=0,weiter=false}
      end
      if narrtext.accttext.weiter and narrtext.accttext.dt>narrtext.txtquery[1].del then
        table.remove(narrtext.txtquery,1)
        narrtext.accttext=nil
      elseif not narrtext.accttext.weiter and narrtext.accttext.dt>0.05 then
        narrtext.accttext.dt=0
        if narrtext.accttext.n==string.len(narrtext.txtquery[1].text) then
          narrtext.accttext.weiter=true
        else
          narrtext.accttext.n=narrtext.accttext.n+1
          narrtext.accttext.text=string.sub(narrtext.txtquery[1].text,1,narrtext.accttext.n)
        end
      else
        narrtext.accttext.dt=narrtext.accttext.dt+dt
      end
    end
    local dirx = 0
    if love.keyboard.isDown("a") then dirx = dirx + 1 end
    if love.keyboard.isDown("d") then dirx = dirx - 1 end
    local diry = 0
    if love.keyboard.isDown("w") then diry = diry + 1 end
    if love.keyboard.isDown("s") then diry = diry - 1 end
    if joystick.active then
      dirx = dirx + joystick.normdx
      diry = diry + joystick.normdy
    end

    local laenge = math.sqrt(dirx*dirx+diry*diry)
    if laenge~=0 then
      char.dirx = dirx/laenge*clamp(laenge,0,0.1)*10
      char.diry = diry/laenge*clamp(laenge,0,0.1)*10
    else
      char.dirx=0
      char.diry=0
    end

    local nposx,nposy=char.posx-(dirx)*dt*char.speed,char.posy-(diry)*dt*char.speed
    char.posx,char.posy=checkLevelKollission(char.posx,char.posy,nposx,nposy,char.width,char.height,char.height2)

    if dirx~=0 or diry~=0 then
      if char.posx-nposx~=0 or char.posy-nposy~=0 then char.walking=false else char.walking=true end
    else
      char.walking=false
    end

    local triggerstone=level[math.floor(char.posy+0.5)] and level[math.floor(char.posy+0.5)][math.floor(char.posx+0.5)]
    if triggerstone and triggerstone.mark then
      actualLevel=triggerstone.level
      oldlevel=triggerstone
      loadLevel()
    end
    if triggerstone and triggerstone~=last_triggerstone then
      for _,f in ipairs(triggers["on_visit_block"] or {}) do
        f(triggerstone,{y=math.floor(char.posy+0.5)-offset.y,x=math.floor(char.posx+0.5)-offset.x})
      end
      last_triggerstone=triggerstone
      --local triggerstone=level[math.floor(char.posy+0.5)][math.floor(char.posx+0.5)]
      --actualLevel=triggerstone.level
      --oldlevel=triggerstone
      --loadLevel()
    end

    local distancex = (char.posx-camera.posx-0.3)
    local distancey = (char.posy-camera.posy)
    camera.posx = camera.posx+distancex*dt*3
    camera.posy = camera.posy+distancey*dt*3

    local dirx = 0
    if love.keyboard.isDown("left") then dirx = dirx - 1 end
    if love.keyboard.isDown("right") then dirx = dirx + 1 end
    local diry = 0
    if love.keyboard.isDown("up") then diry = diry + 1 end
    if love.keyboard.isDown("down") then diry = diry - 1 end

    if mouse.pressed and not joystick2.shot then
      joystick2.shot=true
      local xx=width*0.375+width*0.15*(char.posx-camera.posx+0.5)
      local yy=height*0.375+width*0.15*(char.posy-camera.posy+0.5)
      local dirx=mouse.x-xx
      local diry=mouse.y-yy
      local laenge=math.sqrt(dirx*dirx+diry*diry)
      if laenge~=0 then dirx=dirx/laenge diry=diry/laenge else dirx=0 diry=0 end
      table.insert(entities.projectiles,{type="fireball",life=4,image="fireball_flames1",x=char.posx,y=char.posy,dirx=dirx,diry=diry,speed=4})
    end

    if joystick2.shot and joystick2.firedelay>0 then
      joystick2.firedelay=joystick2.firedelay-dt
      if joystick2.firedelay<0 then
        joystick2.firedelay=0.7
        joystick2.shot=false
      end
    end
    if dirx~=0 or diry~=0 then
      if not joystick2.shot then
        table.insert(entities.projectiles,{type="fireball",life=4,image="fireball_flames1",x=char.posx,y=char.posy,dirx=dirx,diry=diry*-1,speed=4})
        joystick2.shot=true
      end
    end
    if joystick2.active and not joystick2.shot then
      if joystick2.normdx~=0 or joystick2.normdy~=0 then
        local dirx = joystick2.normdx*-1
        local diry = joystick2.normdy*-1
        table.insert(entities.projectiles,{type="fireball",life=4,image="fireball_flames1",x=char.posx,y=char.posy,dirx=dirx,diry=diry,speed=4})
        joystick2.shot=true
      end
    end

    for i,v in ipairs(entities.mobs)do
      if v.z==actualLevel then
        local dirx=v.x-char.posx
        local diry=v.y-char.posy
        local laenge = math.sqrt(dirx*dirx+diry*diry)
        if laenge~=0 then
          v.dirx = clamp(dirx/laenge,-1,1)
          v.diry = clamp(diry/laenge,-1,1)
        else
          v.dirx=0
          v.diry=0
        end

        local nposx,nposy=v.x-(dirx)*dt*v.speed,v.y-(diry)*dt*v.speed

        local move=true
        for j,x in ipairs(entities.mobs)do
          if checkDistance(x.x,x.y,nposx,nposy,0.5) and i~=j then
            move=false
          end
        end
        if move then
          v.x,v.y=checkLevelKollission(v.x,v.y,nposx,nposy,v.width,v.height,v.height2)
        end
        if checkDistance(char.posx,char.posy,v.x,v.y,0.25) then char.health=char.health-1 for _,f in ipairs(triggers["on_hit"] or {}) do f() end table.remove(entities.mobs,i)end
      end
    end
    for i,v in ipairs(entities.projectiles)do
      local nposx=v.x+v.dirx*dt*v.speed
      local nposy=v.y+v.diry*dt*v.speed
      v.life=v.life-dt
      if v.life<0 then table.remove(entities.projectiles,i)end
      v.x,v.y=checkLevelKollission(v.x,v.y,nposx,nposy,0.4,0.4,0.4)
      if v.x-nposx~=0 or v.y-nposy~=0 then table.remove(entities.projectiles,i)end
      for j,x in ipairs(entities.mobs)do
        if checkDistance(x.x,x.y,v.x,v.y,0.25) then table.remove(entities.projectiles,i)table.remove(entities.mobs,j)end
      end
    end
  elseif char.health<=0 then
    respawntimer=respawntimer-dt
    if respawntimer<=0 then
      respawntimer=3
      char.health=4
      local dir = love.filesystem.getSaveDirectory()
      local loadedfunc=loadfile(dir.."/saved.lua")
      local loaded
      if loadedfunc then loaded=loadedfunc() end
      if loaded then
        entities.mobs={}
        actualLevel=loaded.level
        loadLevel()
        char.posx=loaded.posx+offset.x
        char.posy=loaded.posy+offset.y
        camera.posx=char.posx
        camera.posy=char.posy
      end
    end
  end
  for _,f in ipairs(triggers["on_update"] or {}) do
    f()
  end
  for i,f in ipairs(timeouts) do
    if f.finish<love.timer.getTime() then
      table.remove(timeouts,i)
      f.cb()
      return
    end
  end
end

function love.draw()
  if loaded then
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle("fill",0,0,width,height)
    drawLevel()
    love.graphics.setColor(1,1,1)
    if narrtext.accttext and narrtext.accttext.art=="narrat" then
      love.graphics.push()
      love.graphics.scale(0.1,0.1)
      love.graphics.printf(narrtext.accttext.text,
          width*1.5,
          height*0.6,
          width*7,
          "center"
        )
        love.graphics.pop()
    elseif narrtext.accttext and narrtext.accttext.art=="ged" then
      love.graphics.draw(tiles,textures["thoughtbubble"],
          width*0.375+width*0.15*(char.posx-camera.posx+0.5),
          height*0.375+width*0.15*(char.posy-camera.posy-0.7),
          0,
          (width*0.15)/32,
          (width*0.15)/32
        )
      love.graphics.push()
      love.graphics.scale(0.1,0.1)
      love.graphics.printf(narrtext.accttext.text,
          width*0.375+width*0.15*(char.posx-camera.posx+2.84)*10,
          height*0.375+width*0.15*(char.posy-camera.posy+0.78)*10,
          (width*40)/32,
          "center"
        )
        love.graphics.pop()
    elseif narrtext.accttext and narrtext.accttext.art=="sag" then
      love.graphics.draw(tiles,textures["speechbubble"],
          width*0.375+width*0.15*(char.posx-camera.posx+0.5),
          height*0.375+width*0.15*(char.posy-camera.posy-0.7),
          0,
          (width*0.15)/32,
          (width*0.15)/32
        )
      love.graphics.push()
      love.graphics.scale(0.1,0.1)
      love.graphics.printf(narrtext.accttext.text,
          width*0.375+width*0.15*(char.posx-camera.posx+2.83)*10,
          height*0.375+width*0.15*(char.posy-camera.posy+0.82)*10,
          (width*40)/32,
          "center"
        )
        love.graphics.pop()
    end
    if versionsnummerda then
      love.graphics.push()
      love.graphics.scale(0.1,0.1)
        love.graphics.printf(
          "Version: "..version,
          width*8,
          0,
          width*2,
          "right"
        )
      love.graphics.pop()
    end
    love.graphics.setColor(1,1,1)
    for _,f in ipairs(triggers["on_post_draw"] or {}) do f() end
    if char.health>0 then
      if paused then
        if not showcredits then
          love.graphics.setColor(0.5,0.5,0.5,0.5)
          love.graphics.rectangle("fill",0,0,width,height)
          love.graphics.push()
          love.graphics.scale(0.5,0.5)
          love.graphics.setColor(0.2,0.2,0.2,1)
          love.graphics.printf("PAUSIERT",0,height*0.8,width*2,"center")
          love.graphics.pop()
          love.graphics.setColor(1,1,1,1)
          if musicPaused then
            love.graphics.draw(tiles,textures["mute_music"],
                width*0.03,
                height*0.04,
                0,
                (width*0.15)/48,
                (width*0.15)/48
              )
          else
            love.graphics.draw(tiles,textures["music"],
                width*0.03,
                height*0.04,
                0,
                (width*0.15)/48,
                (width*0.15)/48
              )
          end
          love.graphics.draw(tiles,textures["del_save"],
              width*0.03,
              height*0.3,
              0,
              (width*0.15)/48,
              (width*0.15)/48
            )
          love.graphics.draw(tiles,textures["credits"],
              width*0.03,
              height*0.75,
              0,
              (width*0.15)/48,
              (width*0.15)/48
            )
        else
          love.graphics.setColor(0.5,0.5,0.5,0.5)
          love.graphics.rectangle("fill",0,0,width,height)
          love.graphics.push()
          love.graphics.scale(0.4,0.4)
          love.graphics.setColor(0.1,0.1,0.1,1)
          love.graphics.printf(
              "Programmierung:\n    Louis Huss\nGrafik:\n    Aron Zuber\nLeveldesign:\n    Daniel Gutsche"
              ,width*0.4,height*0.1,width*3,"left"
            )
          love.graphics.pop()
          love.graphics.setColor(1,1,1)
          love.graphics.draw(tiles,textures["credits"],
              width*0.03,
              height*0.75,
              0,
              (width*0.15)/48,
              (width*0.15)/48
            )
        end
      else
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(tiles,textures[hearts[char.health+1]],
            width*0.04,
            height*0.04,
            0,
            (width*0.15)/64,
            (width*0.15)/64
          )
      end
    else
      love.graphics.setColor(0.8,0,0,0.5)
      love.graphics.rectangle("fill",0,0,width,height)
      love.graphics.push()
      love.graphics.scale(0.5,0.5)
      love.graphics.setColor(0.3,0,0,1)
      love.graphics.printf("Du bist TOT",0,height*0.8,width*2,"center")
      love.graphics.pop()
    end
    if currentos=="Android"then
      if joystick.active and not paused then
        love.graphics.circle(
          "fill",
          -joystick.dx*width+joystick.x,
          -joystick.dy*height+joystick.y,
          width * 0.01
        )
        love.graphics.setColor(1,1,1,0.2)
        love.graphics.setLineWidth(width*0.003)
        love.graphics.circle(
            "line",
            joystick.x,
            joystick.y,
            width * 0.11
          )
      end
      if joystick2.active and not paused then
        love.graphics.circle(
          "fill",
          -joystick2.dx*width+joystick2.x,
          -joystick2.dy*height+joystick2.y,
          width * 0.01
        )
        love.graphics.setColor(1,1,1,0.2)
        love.graphics.setLineWidth(width*0.003)
        love.graphics.circle(
            "line",
            joystick2.x,
            joystick2.y,
            width * 0.11
          )
      end
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(tiles,textures["pause"],
          width*0.87,
          height*0.04,
          0,
          (width*0.15)/48,
          (width*0.15)/48
        )
    end
    if debugging then
      love.graphics.push()
      love.graphics.scale(0.1,0.1)
      love.graphics.print(
        "TIME: "..tostring(game_time()).."\n"..
        "FPS: "..tostring(love.timer.getFPS()).."\n"..
        "char.posx: "..tostring(round(char.posx,2)).."\n"..
        "char.posy: "..tostring(round(char.posy,2)).."\n"..
        "char.dirx: "..tostring(round(char.dirx,2)).."\n"..
        "char.diry: "..tostring(round(char.diry,2)).."\n"..
        "camera.posx: "..tostring(round(camera.posx,2)).."\n"..
        "camera.posy: "..tostring(round(camera.posy,2)).."\n"..
        "actualLevel: "..tostring(actualLevel).."\n"..
        "touchid: "..tostring(joystick.touchid)
        ,
        0,
        0
      )
      love.graphics.pop()
    end
  else
    love.graphics.setColor(0.8,0.1,0)
    love.graphics.rectangle("fill",0,0,width,height)
    love.graphics.setColor(1,1,1)
    local logo=love.graphics.newImage("logo.png")
    love.graphics.draw(logo,
        width/2-height/2,
        height*0.1,
        0,
        height/192,
        height/192
      )
    love.graphics.setColor(0.2,0.7,0.2)
    love.graphics.printf("Starlight Chaser",0,height*0.6,width*2,"center",0,0.5,0.5)
    logodrawn=true
  end
end

function love.keypressed(key)
  for _,f in ipairs(triggers["on_key_pressed"] or {}) do if f(key) then return end end
  if key=="escape" then
    love.event.quit()
  elseif key=="g" then
    debugging = not debugging
  elseif key=="p"then
    togglePause()
  end
end

function love.touchpressed(id,x,y,dx,dy)
  if x < width*0.5 and not joystick.active then
    joystick.active = true
    joystick.touchid = id
    joystick.x = x
    joystick.y = y
    joystick.dx = 0
    joystick.dy = 0
  end
  if x > width*0.5 and not joystick2.active then
    joystick2.active = true
    joystick2.touchid = id
    joystick2.x = x
    joystick2.y = y
    joystick2.dx = 0
    joystick2.dy = 0
  end
  if x>width*0.87 and x<width*0.97 and y>height*0.04 and y<height*0.04+width*0.1 then togglePause() end
end

function love.touchreleased(id,x,y,dx,dy)
  if joystick.active and id==joystick.touchid then
    joystick.active=false
    joystick.touchid=nil
    joystick.x=-100
    joystick.y=-100
    joystick.dx=0
    joystick.dy=0
  end
  if joystick2.active and id==joystick2.touchid then
    joystick2.active=false
    joystick2.touchid=nil
    joystick2.x=-100
    joystick2.y=-100
    joystick2.dx= 0
    joystick2.dy=0
    joystick2.firedelay=0.7
  end
end

function love.touchmoved(id,x,y,dx,dy)
  if id == joystick.touchid then
    if dx ~= 0 and dy ~= 0 then
      local rel = height/width
      local tempx = joystick.x/width - x/width
      local tempy = joystick.y/height - y/height
      local laenge = math.sqrt(tempx*tempx+tempy*tempy)
      joystick.dx = tempx/laenge*clamp(laenge,0,0.16*rel)
      joystick.normdx = joystick.dx/rel*6.25
      joystick.dy = tempy/laenge*clamp(laenge,0,0.16)
      joystick.normdy = joystick.dy*6.25
    end
  end
  if id == joystick2.touchid then
    if dx ~= 0 and dy ~= 0 then
      local rel = height/width
      local tempx = joystick2.x/width - x/width
      local tempy = joystick2.y/height - y/height
      local laenge = math.sqrt(tempx*tempx+tempy*tempy)
      joystick2.dx = tempx/laenge*clamp(laenge,0,0.16*rel)
      joystick2.normdx = joystick2.dx/rel*6.25
      joystick2.dy = tempy/laenge*clamp(laenge,0,0.16)
      joystick2.normdy = joystick2.dy*6.25
    end
  end
end

function love.mousepressed(x,y,button,isTouch)
  if not isTouch then mouse.pressed=true mouse.x=x mouse.y=y end
  if paused and not showcredits then
    if x>width*0.03 and x<width*0.13 and y>height*0.04 and y<height*0.04+width*0.1 then toggleMusic() end
    if x>width*0.03 and x<width*0.13 and y>height*0.3 and y<height*0.3+width*0.1 then
      love.filesystem.write("saved.lua","")
      actualLevel=1
      loadLevel()
      char.posx=map.spawn.x+offset.x
      char.posy=map.spawn.y+offset.y
      camera.posx,camera.posy=char.posx,char.posy
      paused=false
    end
    if x>width*0.03 and x<width*0.13 and y>height*0.75 and y<height*0.75+width*0.1 then showcredits=true end
  elseif showcredits then
    if x>width*0.03 and x<width*0.13 and y>height*0.75 and y<height*0.75+width*0.1 then showcredits=false end
  end
end

function love.mousemoved(x,y,dx,dy)
  if mouse.pressed then mouse.x=x mouse.y=y end
end

function love.mousereleased(x,y,button,isTouch)
  if not isTouch then mouse.pressed=false end
end

function clamp(val, min, max)
    return math.max(min, math.min(val, max));
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function loadLevel()
  local anschluesse={}
  local tex={}
  for y,a in ipairs(level)do
    for x,b in ipairs(a)do
      if b.mark then b.mark = nil end
      --b={}
    end
  end
  level={}
  for y,a in ipairs(map[actualLevel])do
    for x,b in ipairs(a)do
      local vorhanden=false
      for i,v in ipairs(tex)do
        if b.texture == v then
          vorhanden=true
        end
      end
      if not vorhanden then
        table.insert(tex,b.texture)
      end
      if b.anschluss then
        local tmptable=b.anschluss
        tmptable.oldx=x
        tmptable.oldy=y
        table.insert(anschluesse,tmptable)
      end
    end
  end
  for n,s in ipairs(anschluesse)do
    for y,a in ipairs(map[s.level])do
      for x,b in ipairs(a)do
        local vorhanden=false
        for i,v in ipairs(tex)do
          if b.texture == v then
            vorhanden=true
          end
        end
        if not vorhanden then
          table.insert(tex,b.texture)
        end
      end
    end
  end
  if map.items then
    for i,v in ipairs(map.items)do
      local vorhanden=false
      for j,x in ipairs(tex)do
        if v.image == x then
          vorhanden=true
        end
      end
      if not vorhanden then
        table.insert(tex,v.image)
      end
    end
  end
  if map.enemies then
    for i,v in ipairs(map.enemies)do
      if v.z==actualLevel then
        local image=nil
        for j,x in ipairs(switchindex.mobs)do if x.type==v.type then image=x.image break end end
        local vorhanden=false
        for j,x in ipairs(tex)do
          if image == x then
            vorhanden=true
          end
        end
        if not vorhanden then
          table.insert(tex,image)
        end
      end
    end
  end
  for i,v in ipairs(tex)do
    --print(i,v)
  end
  loadTextures(tex)
  addLevelparttoLevel(actualLevel,anschluesse)
  for y,a in ipairs(level)do
    for x,b in ipairs(a)do
      if b.mark then
        --print(x,y,"anschluss gefunden")
      end
    end
  end
  for i,v in ipairs(switchindex.morph)do
    if v.level==actualLevel then
      char.state=v.morphtarget
    end
  end
  if not music.music and musicdump[actualLevel] then
    music=musicdump[actualLevel]
    music.music:setLooping(true)
    if musicPlaying then
      music.music:play()
    end
  elseif music.music and musicdump[actualLevel] and music.name~=musicdump[actualLevel].name then
    music.music:stop()
    music=musicdump[actualLevel]
    music.music:setLooping(true)
    if musicPlaying then
      music.music:play()
    end
  elseif music.music and not musicdump[actualLevel] then
    music.music:stop()
    music={}
  end
  if narrat[actualLevel] and not narrat[actualLevel].done then
    for i,v in ipairs(narrat[actualLevel])do
      table.insert(narrtext.txtquery,v)
    end
    narrat[actualLevel].done=true
  end
  animations=switchindex.anim
  for i,v in ipairs(animations)do v.actualn=1 v.dt=0 v.newname=v.name end
  for _,f in ipairs(triggers["on_level_change"] or {}) do f() end
  animationenLaden()
  if map.enemies then
    local feinde=false
    for i,v in ipairs(map.enemies)do if v.z==actualLevel then feinde=true end end
    if not feinde then
      savegamenexttick=true
    end
  end
end

function addLevelparttoLevel(actualLevel,anschluss)
  leveltoadd=map[actualLevel]
  loadedlevel={}
  local minx,miny,maxx,maxy=1,1,1,1
  local props={}
  leveloffsets={}
  for i,v in ipairs(anschluss)do
    local tmpheight,tmpwidth=#map[v.level],0
    for y,a in ipairs(map[v.level])do
      if #a>tmpwidth then tmpwidth=#a end
    end
    v.height,v.width=tmpheight,tmpwidth
    if v.dir=="up" then
      table.insert(loadedlevel,{name=v.level,x=v.oldx-v.x+1,y=v.oldy-v.y,height=tmpheight,width=tmpwidth,dir=v.dir})
      table.insert(leveloffsets,{name=v.level,x=v.oldx-v.x+1,y=v.oldy-v.y})
    elseif v.dir=="down" then
      table.insert(loadedlevel,{name=v.level,x=v.oldx-v.x+1,y=v.oldy-v.y+2,height=tmpheight,width=tmpwidth,dir=v.dir})
      table.insert(leveloffsets,{name=v.level,x=v.oldx-v.x+1,y=v.oldy-v.y+2})
    elseif v.dir=="left" then
      table.insert(loadedlevel,{name=v.level,x=v.oldx-v.x,y=v.oldy-v.y+1,height=tmpheight,width=tmpwidth,dir=v.dir})
      table.insert(leveloffsets,{name=v.level,x=v.oldx-v.x,y=v.oldy-v.y+1})
    elseif v.dir=="right" then
      table.insert(loadedlevel,{name=v.level,x=v.oldx-v.x+2,y=v.oldy-v.y+1,height=tmpheight,width=tmpwidth,dir=v.dir})
      table.insert(leveloffsets,{name=v.level,x=v.oldx-v.x+2,y=v.oldy-v.y+1})
    end
  end
  for i,v in ipairs(loadedlevel)do
    if v.x<minx then minx=v.x end
    if v.y<miny then miny=v.y end
    if v.x+v.width-1>maxx then maxx=v.x+v.width-1 end
    if v.y+v.height-1>maxy then maxy=v.y+v.height-1 end
  end
  offset.x=minx*-1+1
  offset.y=miny*-1+1
  for i=1,maxy+offset.y do
    level[i]={}
    for j=1,maxx+offset.x do
      level[i][j]={texture=nil,block=true}
    end
  end
  if map.items then
    tmpheight,tmpwidth=#map[actualLevel],0
    for y,a in ipairs(map[actualLevel])do
      if #a>tmpwidth then tmpwidth=#a end
    end
    for i,v in ipairs(map.items)do if v.z==actualLevel then table.insert(props,{x=v.x+offset.x,y=v.y+offset.y,z=v.z,off_x=v.off_x,off_y=v.off_y,image=v.image})end end
    for i,v in ipairs(loadedlevel)do
      if v.dir=="up" then
        for j,x in ipairs(map.items)do if x.z==v.name then table.insert(props,{x=x.x-offset.x+1,y=x.y+offset.y-v.height,z=x.z,off_x=x.off_x,off_y=x.off_y,image=x.image})end end
      elseif v.dir=="down" then
        for j,x in ipairs(map.items)do if x.z==v.name then table.insert(props,{x=x.x+offset.x-1,y=x.y+offset.y+tmpheight,z=x.z,off_x=x.off_x,off_y=x.off_y,image=x.image})end end
      elseif v.dir=="left" then
        for j,x in ipairs(map.items)do if x.z==v.name then table.insert(props,{x=x.x+offset.x+tmpwidth,y=x.y+offset.y+v.y-1,z=x.z,off_x=x.off_x,off_y=x.off_y,image=x.image})end end
      elseif v.dir=="right" then
        for j,x in ipairs(map.items)do if x.z==v.name then table.insert(props,{x=x.x+offset.x-v.width,y=x.y+offset.y+v.y-1,z=x.z,off_x=x.off_x,off_y=x.off_y,image=x.image})end end
      end
    end
  end
  if map.enemies then
    for i,v in ipairs(map.enemies)do
      if v.z==actualLevel then
        local image=nil
        local speed=nil
        local width = nil
        local height = nil
        local height2 = nil
        for j,x in ipairs(switchindex.mobs)do if x.type==v.type then image=x.image speed=x.speed width=x.width height=x.height height2=x.height2 break end end
        table.insert(entities.mobs,{type=v.type,x=v.x+offset.x,y=v.y+offset.y,z=v.z,image=image,speed=speed,width=width,height=height,height2=height2,dir=0})
      end
    end
  end
  function props.sort()
    table.sort(props,function(a,b) return (a.off_z or a.off_y)<(b.off_z or b.off_y) end)
  end
  props.sort()
  level.props=props
  for y,a in ipairs(leveltoadd)do
    for x,b in ipairs(a)do
      if level[y+offset.y] == nil then
        level[y+offset.y]={}
      end
      level[y+offset.y][x+offset.x] = b
    end
  end
  for i,v in ipairs(loadedlevel)do
    for y,a in ipairs(map[v.name])do
      for x,b in ipairs(a)do
        if level[y+v.y-1+offset.y] == nil then
          level[y+v.y-1+offset.y]={}
        end
        if level[y+v.y-1+offset.y][x+v.x-1+offset.x].texture == nil then
          level[y+v.y-1+offset.y][x+v.x-1+offset.x] = b
        end
      end
    end
  end
  for i,v in ipairs(anschluss)do
    local tmpheight,tmpwidth=#map[v.level],0
    for y,a in ipairs(map[v.level])do
      if #a>tmpwidth then tmpwidth=#a end
    end
    if v.dir=="up" then
      level[v.oldy+offset.y-1][v.oldx+offset.x].mark=true
      level[v.oldy+offset.y-1][v.oldx+offset.x].level=v.level
      level[v.oldy+offset.y-1][v.oldx+offset.x].offsetx=0
      level[v.oldy+offset.y-1][v.oldx+offset.x].offsety=tmpheight
      level[v.oldy+offset.y-1][v.oldx+offset.x].targetx=v.x
      level[v.oldy+offset.y-1][v.oldx+offset.x].targety=v.y
      level[v.oldy+offset.y-1][v.oldx+offset.x].dir=v.dir
    elseif v.dir=="down" then
      level[v.oldy+offset.y+1][v.oldx+offset.x].mark=true
      level[v.oldy+offset.y+1][v.oldx+offset.x].level=v.level
      level[v.oldy+offset.y+1][v.oldx+offset.x].offsetx=0
      level[v.oldy+offset.y+1][v.oldx+offset.x].offsety=tmpheight*-1
      level[v.oldy+offset.y+1][v.oldx+offset.x].targetx=v.x
      level[v.oldy+offset.y+1][v.oldx+offset.x].targety=v.y-1
      level[v.oldy+offset.y+1][v.oldx+offset.x].dir=v.dir
    elseif v.dir=="left" then
      level[v.oldy+offset.y][v.oldx+offset.x-1].mark=true
      level[v.oldy+offset.y][v.oldx+offset.x-1].level=v.level
      level[v.oldy+offset.y][v.oldx+offset.x-1].offsetx=tmpwidth
      level[v.oldy+offset.y][v.oldx+offset.x-1].offsety=0
      level[v.oldy+offset.y][v.oldx+offset.x-1].targetx=v.x
      level[v.oldy+offset.y][v.oldx+offset.x-1].targety=v.y
      level[v.oldy+offset.y][v.oldx+offset.x-1].dir=v.dir
    elseif v.dir=="right" then
      level[v.oldy+offset.y][v.oldx+offset.x+1].mark=true
      level[v.oldy+offset.y][v.oldx+offset.x+1].level=v.level
      level[v.oldy+offset.y][v.oldx+offset.x+1].offsetx=tmpwidth*-1
      level[v.oldy+offset.y][v.oldx+offset.x+1].offsety=0
      level[v.oldy+offset.y][v.oldx+offset.x+1].targetx=v.x-1
      level[v.oldy+offset.y][v.oldx+offset.x+1].targety=v.y
      level[v.oldy+offset.y][v.oldx+offset.x+1].dir=v.dir
    end
  end
  if not firstload then
    if oldlevel.dir=="up" or oldlevel.dir=="down" then
      camera.posx=camera.posx-char.posx
      char.posx=(char.posx+0.5)%1+offset.x+oldlevel.targetx-0.5
      camera.posx=camera.posx+char.posx

      camera.posy=camera.posy-char.posy
      char.posy=char.posy%1+offset.y+oldlevel.targety
      camera.posy=camera.posy+char.posy
    elseif oldlevel.dir=="left" or oldlevel.dir=="right" then
      camera.posx=camera.posx-char.posx
      char.posx=char.posx%1+offset.x+oldlevel.targetx
      camera.posx=camera.posx+char.posx

      camera.posy=camera.posy-char.posy
      char.posy=(char.posy+0.5)%1+offset.y+oldlevel.targety-0.5
      camera.posy=camera.posy+char.posy
    end
  else
    firstload=false
    char.posx=char.posx+offset.x
    char.posy=char.posy+offset.y
    camera.posx=char.posx
    camera.posy=char.posy
  end
end

function drawLevel()
  if char.dirx > 0.383 then
    if char.diry > 0.383 then
      dir = 6
    elseif char.diry < 0.383 and char.diry > -0.383 then
      dir = 7
    else
      dir = 8
    end
  elseif char.dirx < 0.383 and char.dirx > -0.383 then
    if char.diry > 0.383 then
      dir = 5
    elseif char.diry < -0.383 then
      dir = 1
    end
  else
    if char.diry > 0.383 then
      dir = 4
    elseif char.diry < 0.383 and char.diry > -0.383 then
      dir = 3
    else
      dir = 2
    end
  end
  love.graphics.setColor(1,1,1)
  for i,v in ipairs(level)do
    for j,x in ipairs(v)do
      if x.texture then
        local xoffset,yoffset=0,0
        if math.floor(x.rot/math.pi*2) == 1 then xoffset=1 end
        if math.floor(x.rot/math.pi*2) == 2 then yoffset=1 xoffset=1 end
        if math.floor(x.rot/math.pi*2) == 3 then yoffset=1 end
        love.graphics.draw(tiles,textures[x.texture],
          width*0.375+width*0.15*(j-camera.posx+xoffset),
          height*0.375+width*0.15*(i-camera.posy+yoffset),
          x.rot,
          (width*0.15)/32,
          (width*0.15)/32,
          0
        )
      end
    end
  end
  local playerdrawn=false
  for i,v in ipairs(level)do
    for j,x in ipairs(level.props)do
      if i==x.y+1 and i==math.floor(char.posy+1) and char.posy%1-char.height2<x.off_y and not playerdrawn then
        playerdrawn=true
        local anim=0
        if char.walking then anim=1 end
        love.graphics.draw(tiles,textures[char.state..dir..tostring(anim)],
            width*0.375+width*0.15*(char.posx-camera.posx),
            height*0.375+width*0.15*(char.posy-camera.posy),
            0,
            (width*0.15)/32,
            (width*0.15)/32
          )
      end
      if i==x.y+1 then
        local xoffset,yoffset=0,0
        x.rot=x.rot or 0
        for k,y in pairs(leveloffsets)do if y.name==x.z then xoffset,yoffset=y.x,y.y end if x.z~=actualLevel then xoffset,yoffset=xoffset-1,yoffset-1 end end
        local xo,yo=0,0
        if math.floor(x.rot/math.pi*2) == 1 then xo=1 end
        if math.floor(x.rot/math.pi*2) == 2 then yo=1 xo=1 end
        if math.floor(x.rot/math.pi*2) == 3 then yo=1 end
        love.graphics.draw(tiles,textures[x.image],
            width*0.375+width*0.15*(x.x+x.off_x-camera.posx+xo),
            height*0.375+width*0.15*(x.y+x.off_y-camera.posy+yo),
            x.rot,
            (width*0.15)/32,
            (width*0.15)/32
          )
      end
    end
    if not playerdrawn and i==math.floor(char.posy+1) then
      playerdrawn=true
      local anim=0
      if char.walking then anim=1 end
      love.graphics.draw(tiles,textures[char.state..dir..tostring(anim)],
          width*0.375+width*0.15*(char.posx-camera.posx),
          height*0.375+width*0.15*(char.posy-camera.posy),
          0,
          (width*0.15)/32,
          (width*0.15)/32
        )
    end
    for j,x in ipairs(v)do
      if x.block and x.texture then
        love.graphics.draw(tiles,textures[x.texture],
          width*0.375+width*0.15*(j-camera.posx),
          height*0.375+width*0.15*(i-camera.posy),
          0,
          (width*0.15)/32,
          (width*0.15)/32
        )
      end
      if x.mark and #entities.mobs>0 then
        love.graphics.draw(tiles,textures["fog1"],
          width*0.375+width*0.15*(j-camera.posx),
          height*0.375+width*0.15*(i-camera.posy),
          0,
          (width*0.15)/32,
          (width*0.15)/32
        )
      end
      if x.mark and debugging then
        love.graphics.setColor(1,0.1,0.1)
        love.graphics.setLineWidth(10)
          love.graphics.rectangle("line",
            width*0.375+width*0.15*(j-camera.posx),
            height*0.375+width*0.15*(i-camera.posy),
            width*0.15,
            width*0.15
          )
        love.graphics.setColor(1,1,1)
      end
    end
    for j,x in ipairs(entities.mobs)do
      love.graphics.draw(tiles,textures[x.image],
          width*0.375+width*0.15*(x.x-camera.posx),
          height*0.375+width*0.15*(x.y-camera.posy),
          0,
          (width*0.15)/32,
          (width*0.15)/32
        )
    end
    for j,x in ipairs(entities.projectiles)do
      love.graphics.draw(tiles,textures[x.image],
          width*0.375+width*0.15*(x.x-camera.posx+0.25),
          height*0.375+width*0.15*(x.y-camera.posy+0.25),
          0,
          (width*0.15)/32/2,
          (width*0.15)/32/2
        )
    end
  end
end

function loadTextures(tex)
  table.insert(tex,"speechbubble")
  table.insert(tex,"thoughtbubble")
  table.insert(tex,"fireball_flames1")
  table.insert(tex,"pause")
  table.insert(tex,"fog1")
  table.insert(tex,"mute_music")
  table.insert(tex,"music")
  table.insert(tex,"del_save")
  table.insert(tex,"credits")
  table.insert(tex,"emptyheart")
  table.insert(tex,"heart141")
  table.insert(tex,"heart121")
  table.insert(tex,"heart341")
  table.insert(tex,"heart")
  for i=1,8 do
    for j=0,2 do
      table.insert(tex,"wiblex"..i..j)
    end
  end
  for i=1,8 do
    for j=0,2 do
      table.insert(tex,"angel"..i..j)
    end
  end
  for i=1,8 do
    for j=0,2 do
      table.insert(tex,"demon"..i..j)
    end
  end
  for i=1,8 do
    for j=0,2 do
      table.insert(tex,"halfling"..i..j)
    end
  end
  for i,v in ipairs(tex)do
    if not tilesatlas[v] then error("Bild '"..tostring(v).."' nicht gefindet") end
    textures[v] = textures[v] or love.graphics.newQuad(tilesatlas[v].x,tilesatlas[v].y,32,32,tiles:getDimensions())
  end
end

function animationenLaden()
  for i,v in ipairs(animations)do
    --print(i,v)
    for j,x in pairs(textures)do
      --print(j,x)
      local tempname=string.sub(j,1,string.len(j)-string.len(v.actualn))
      if tempname==v.name then
        for k=1,v.n do
          local temptempname=tempname..k
          animations[temptempname] = love.graphics.newQuad(tilesatlas[temptempname].x,tilesatlas[temptempname].y,32,32,tiles:getDimensions())
        end
      end
    end
  end
end

function animationenAuswechseln(dt)
  for i,v in ipairs(animations)do
    for j,x in pairs(textures)do
      local tempname=string.sub(j,1,string.len(j)-string.len(v.actualn))
      if tempname==v.name then
        v.dt=v.dt+dt
        if v.dt>v.speed then
          v.dt=0
          if v.actualn<v.n then v.actualn=v.actualn+1 else v.actualn=1 end
          tempname=tempname..v.actualn
          textures[v.name.."1"] = animations[tempname]
          v.newname=tempname
        end
      end
    end
  end
end

function togglePause()
  if not paused then
    save_table.game_time=love.timer.getTime()+time_offset
  else
    time_offset=save_table.game_time-love.timer.getTime()
  end
  paused=not paused
end

function checkLevelKollission(x,y,nposx,nposy,width,height,height2)
  if nposx>x then
    if not level[math.floor(y+height+0.01)] or not level[math.floor(y+height+0.01)][math.floor(x+1-width)] then
      --error("Fuck You!")
    --end
    else
      if level[math.floor(y+height+0.01)][math.floor(x+1-width)].block
      and (x+1-width)%1<(width)
      or level[math.floor(y+1-height2-0.01)][math.floor(x+1-width)].block
      and (x+1-width)%1<(width)
      or level[math.floor(y+height+0.01)][math.floor(x+1-width)].mark
      --and (x+1-width)%1<(width)
      and #entities.mobs>0
      or level[math.floor(y+1-height2-0.01)][math.floor(x+1-width)].mark
      --and (x+1-width)%1<(width)
      and #entities.mobs>0
      then
      else
          x=nposx
      end
    end
  end
  if nposx<x then
    if not level[math.floor(y+height+0.01)] or not level[math.floor(y+height+0.01)][math.floor(x+width)] then
      --error("Fuck You!")
    --end
    else
      if level[math.floor(y+height+0.01)] and level[math.floor(y+height+0.01)][math.floor(x+width)] and level[math.floor(y+height+0.01)][math.floor(x+width)].block
      and (x+width)%1>(1-width)
      or level[math.floor(y+1-height2-0.01)] and level[math.floor(y+1-height2-0.01)][math.floor(x+width)] and level[math.floor(y+1-height2-0.01)][math.floor(x+width)].block
      and (x+width)%1>(1-width)
      or level[math.floor(y+height+0.01)] and level[math.floor(y+height+0.01)][math.floor(x+width)] and level[math.floor(y+height+0.01)][math.floor(x+width)].mark
      --and (x+width)%1>(1-width)
      and #entities.mobs>0
      or level[math.floor(y+1-height2-0.01)] and level[math.floor(y+1-height2-0.01)][math.floor(x+width)] and level[math.floor(y+1-height2-0.01)][math.floor(x+width)].mark
      --and (x+width)%1>(1-width)
      and #entities.mobs>0
      then
      else
        x=nposx
      end
    end
  end
  if nposy>y then
    if not level[math.floor(y+1-height2)] or not level[math.floor(y+1-height2)][math.floor(x+width+0.01)] then
      --error("Fuck You!")
    --end
    else
      if level[math.floor(y+1-height2)][math.floor(x+width+0.01)].block
      and (y-height2)%1<(height)
      or level[math.floor(y+1-height2)][math.floor(x+1-width-0.01)].block
      and (y-height2)%1<(height)
      or level[math.floor(y+1-height2)][math.floor(x+width+0.01)].mark
      --and (y-height2)%1<(height)
      and #entities.mobs>0
      or level[math.floor(y+1-height2)][math.floor(x+1-width-0.01)].mark
      --and (y-height2)%1<(height)
      and #entities.mobs>0
      then
      else
          y=nposy
      end
    end
  end
  if nposy<y then
    if not level[math.floor(y+height)] or not level[math.floor(y+height)][math.floor(x+width+0.01)] then
      --error("Fuck You!")
    --end
    else
      if level[math.floor(y+height)][math.floor(x+width+0.01)].block
      and (y+height)%1>(1-height2)
      or level[math.floor(y+height)][math.floor(x+1-width-0.01)].block
      and (y+height)%1>(1-height2)
      or level[math.floor(y+height)][math.floor(x+width+0.01)].mark
      --and (y+height)%1>(1-height2)
      and #entities.mobs>0
      or level[math.floor(y+height)][math.floor(x+1-width-0.01)].mark
      --and (y+height)%1>(1-height2)
      and #entities.mobs>0
      then
      else
          y=nposy
      end
    end
  end
  return x,y
end

function checkDistance(x1,y1,x2,y2,mindist)
  local dist=math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
  if dist<mindist then return true else return false end
end

function loadAtStart()
  tiles=love.graphics.newImage("tiles.png")
  table.insert(hearts,"emptyheart")
  table.insert(hearts,"heart141")
  table.insert(hearts,"heart121")
  table.insert(hearts,"heart341")
  table.insert(hearts,"heart")
  if currentos~="Android"then
    canvas = love.graphics.newCanvas()
    local cursor=love.graphics.newQuad(tilesatlas["mouse"].x,tilesatlas["mouse"].y,32,32,tiles:getDimensions())
    local canvas=love.graphics.newCanvas(32,32)
    canvas:renderTo(function()love.graphics.setColor(1,1,1)love.graphics.draw(tiles,cursor)end)
    love.graphics.draw(canvas,0,0)
    local cursorData = canvas:newImageData()
    local mousecursor=love.mouse.newCursor(cursorData,0,0)
    love.mouse.setCursor(mousecursor)
  end
  for i,v in ipairs(switchindex.music)do
    musicdump[v.level]={}
    musicdump[v.level].music=love.audio.newSource(v.music..".mp3","static")
    musicdump[v.level].name=v.music
  end
  load_plugins()
  loadLevel()
  loaded=true
end

function savegame()
  local savetable={level=actualLevel,posx=char.posx-offset.x,posy=char.posy-offset.y}
  love.filesystem.write("saved.lua","return "..tabletostring(savetable))
end

function tabletostring(val)
  local t=type(val)
  if t=="nil" then
    return "nil"
  elseif t=="boolean" then
    return val and "true" or "false"
  elseif t=="number" then
    return val..""
  elseif t=="string" then
    return '"'..val:gsub("[^a-zA-Z0-9 _]",function(a) return string.format("\\x%02X",string.byte(a)) end)..'"'
  elseif t=="table" then
    local t={}
    for k,v in pairs(val) do
      table.insert(t,"["..tabletostring(k).."]="..tabletostring(v))
    end
    return "{"..table.concat(t,",").."}"
  else
    error("Invalid Type: "..tostring(t))
  end
end

function toggleMusic()
  if not musicPaused then
    musicPaused=true
    if musicPlaying and not fightmusicactive then
      if music.music then
        music.music:pause()
      end
    elseif fightmusicactive then
      if fightmusic then
        fightmusic:pause()
      end
    end
  else
    musicPaused=false
    if musicPlaying and not fightmusicactive then
      if music.music then
        music.music:play()
      end
    elseif fightmusicactive then
      musicPlaying=true
      if fightmusic then
        fightmusic:play()
      end
    end
  end
end
