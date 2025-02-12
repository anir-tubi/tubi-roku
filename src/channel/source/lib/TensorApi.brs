
' Thin wrapper for Tensor API requests.  Collected here to facilitate easy
' integration tests
Function TensorApi(constants, pubServerPersistentData)
  return {
    ' dependencies
    constants: constants
    pubServerPersistentData: pubServerPersistentData

    ' public
    getEPGChannelIdsReqInfo: tensorApi_getEPGChannelIdsReqInfo
    getEPGProgramReqInfo: tensorApi_getEPGProgramReqInfo

    ' private
    commonOptions: tensorApi_commonOptions
  }
End Function


Function tensorApi_commonOptions()
  headers = {}
  ' appending in this style is necessary to prevent m.constants.headers.commonUapi from being
  ' mutated by potential later appends, since assoc arrays are passed by reference.
  headers.append(m.constants.headers.commonUapi)

  if m.pubServerPersistentData <> invalid AND m.pubServerPersistentData.parentalRating <> invalid
    headers["X-TUBI-RATING"] = m.constants.serverValues.parentalControls[m.pubServerPersistentData.parentalRating]
  end if
  headers.append(m.constants.headers.tubiPlatform)

  options = {
    params: {
      "app_id": m.constants.settings.shortAppName
      "platform": m.constants.platform
      "device_id": m.constants.deviceInfo.deviceId
    }
    headers: headers
  }
  return options
End Function


''''''''''''''''''''''
'epgChannelIds request
'
Function tensorApi_getEPGChannelIdsReqInfo(mode = "")
  url = m.constants.urls.tensor.cdn.epgChannelIds
  options = m.commonOptions()

  if mode <> invalid AND mode <> ""
    options.params["mode"] = mode
  end if

  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''

'epgProgram request
'@contentIds: arrays, the list of channelId's
Function tensorApi_getEPGProgramReqInfo(contentIds)
  contentIdsString = contentIds.Join(",")

  url = m.constants.urls.content.epgProgramContent
  options = m.commonOptions()

  capability = formatJson({"program_title_differ_with_episode_title" :true})
  options.headers.append({"x-capability": capability})

  options.params["content_id"] = contentIdsString
  options.params["lookahead"] = 1

  return {
    url: url
    options: options
  }
End Function
