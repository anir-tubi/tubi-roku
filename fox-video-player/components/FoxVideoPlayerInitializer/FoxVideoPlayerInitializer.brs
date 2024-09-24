function init()
  m.top.observeField("config", "onConfigChange")
end function


sub onConfigChange(msg)
  config = msg.getData()
  m.top.foxRpfInstance = GetFoxRpfInstance(config, m.top.debug)
end sub
