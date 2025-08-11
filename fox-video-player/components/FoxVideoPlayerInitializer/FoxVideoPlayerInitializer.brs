Function init()
  m.top.observeField("config", "onConfigChange")
End Function


Function onConfigChange(msg)
  config = msg.getData()
  m.top.foxRpfInstance = GetFoxRpfInstance(config, m.top.debug)
End Function
