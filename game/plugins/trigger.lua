function macro._new_trigger()
  local ret={}
  local cbs={}
  local val
  function ret.bool()
    return not not val
  end
  function ret.set_value(v)
    local c=val~=v
    val=v
    if c then for _,f in ipairs(cbs) do f() end end
  end
  function ret._on_change(cb)
    table.insert(cbs,cb)
  end
  return ret
end
function macro._all_trigger(trigger)
  local open=true
  for _,t in ipairs(trigger) do
    if not t.bool() then open=false end
  end
  return open
end
function macro._register_trigger(trigger,cb)
  for _,t in ipairs(trigger) do
    t._on_change(cb)
  end
end
