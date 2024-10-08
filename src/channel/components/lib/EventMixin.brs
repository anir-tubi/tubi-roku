'@playerLogLib: assocarray, playerLogLib library
'@key: String, method name present in the library
'@value: dynamic, param needs to passed to the method
Function updatePlayerLogLib(playerLogLib, method, value = invalid)
  if playerLogLib <> invalid AND isFunction(playerLogLib[method]) = true
    if value = invalid
      playerLogLib[method]()
    else
      playerLogLib[method](value)
    end if
  end if
End Function
