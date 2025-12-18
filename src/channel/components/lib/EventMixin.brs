'@playerLogLibInstance: assocarray, playerLogLib library
'@key: String, method name present in the library
'@value: dynamic, param needs to passed to the method
Function updatePlayerLogLib(playerLogLibInstance, method, value = invalid)
  if playerLogLibInstance <> invalid AND isFunction(playerLogLibInstance[method]) = true
    if value = invalid
      playerLogLibInstance[method]()
    else
      playerLogLibInstance[method](value)
    end if
  end if
End Function
