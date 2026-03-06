Function isValid(value)
  return not (value = invalid OR type(value) = "roInvalid")
End Function

Function isString(value)
  return isStringType(value) AND value.Trim() <> ""
End Function

Function isStringType(value)
  return isValid(value) AND (type(value) = "String" OR type(value) = "roString")
End Function

Function isArray(value) as Boolean
  return isValid(value) AND type(value) = "roArray"
End Function

Function isBoolean(value)
  return isValid(value) AND value
End Function

' Custom function for optional chaining
Function optionalChaining(obj as Object, properties as String) as Dynamic
  error = invalid
  currentObj = invalid
  try
    if obj <> invalid
      propertyList = properties.split(".")
      currentObj = obj

      for each property in propertyList
        if currentObj = invalid
          return invalid
        end if
        currentObj = currentObj[property]
      end for
    end if
  catch e
    error = e
  end try
  if error <> invalid then return invalid
  return currentObj
End Function

Function timeUtil() as Object

  util = {

    _timers: {}

    log: Function(msg)
      print msg
    End Function

    time: Function(eventName as String)
      m._startTimer(eventName.trim())
      m.log(eventName + ": timer started")
    End Function

    timeEnd: Function(eventName)
      ellapsedTime = m._endTimer(eventName.trim())
      if ellapsedTime <> invalid then m.log(eventName + ": " + ellapsedTime + "ms")
    End Function

    _startTimer: Function(event as String)
      m._timers[event] = createObject("roTimespan")
    End Function

    _endTimer: Function(event as String) as Dynamic
      if m._timers[event] = invalid then return invalid
      eventTime = m._timers[event].totalMilliseconds().toStr()
      m._timers.delete(event)
      return eventTime
    End Function
  }

  return util

End Function

Function getDeviceInfo(data)
  error = invalid
  try
    deviceData = CreateObject("roDeviceInfo")
    if data = "osVersion" AND FindMemberFunction(deviceData, "GetOSVersion") <> invalid
      osData = deviceData.GetOSVersion()
      return Val(osData["major"] + "." + osData["minor"])
    end if
  catch e
    error = e
  end try
  if error <> invalid then return invalid
End Function

Function verifyMultistyleLabel()
  osVersion = getDeviceInfo("osVersion")
  multiStyleLabel = true
  if osVersion = invalid OR osVersion < 10.5 then multiStyleLabel = false
  return multiStyleLabel
End Function

Function checkAllPurposeUpdatedSync() as Boolean
  sdkData = m.global._OT_initialize_data
  if sdkData.profile.doesExist("sync") AND sdkData.profile.sync.keys().count() > 0
    m.registry.write("allPurposesUpdatedAfterSync", sdkData.profile.sync.allPurposesUpdatedAfterSync.tostr())
    m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["727"], sdkData.profile.sync.allPurposesUpdatedAfterSync)
    return sdkData.profile.sync.allPurposesUpdatedAfterSync
  else
    allPurposesUpdatedAfterSync = m.registry.read("allPurposesUpdatedAfterSync")
    return allPurposesUpdatedAfterSync = "true"
  end if
  return false
End Function
