need("torch")
need("door")
need("shield")
--need("bomb")
local key1=macro.key("key1",5,2,3)
local key2=macro.key("key2",1,6,4)
macro.door({key1,key2},11,12,6,90)
--macro.door({key1},11,12,6)
--macro.bomb({},1,math.random(1,8),math.random(1,8))
macro.trap_door(6,13,5,11,6,6) -- 1:2x4 --> 3:4x2
macro.link_door(11,12,6,1,2,2) -- 1:2x4 --> 3:4x2
--macro.torch(1,3)
--macro.torch(6,5)
macro.shield({},1,7,2)
