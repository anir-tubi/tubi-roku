Function init()
  m.top.observeField("controlInput", "onControlInputChange")
End Function


Function onControlInputChange(msg)
  control = msg.getData()

  if control = "stop" AND getExperimentResource("roku_vod_player_alternative_stop_method", "roku_vod_player_alternative_stop_method_v1", true).enabled = true then
    ' If we receive stop command and we are not in the control then use our alternative stop logic instead
    m.top.content = invalid
    m.top.state = "stopped"
  else
    m.top.control = control
  end if
End Function
