
' Thin wrapper for Tensor API requests.  Collected here to facilitate easy
' integration tests
Function TensorApi(constants, request, auth)
  return {
    ' dependencies
    constants: constants
    request: request
    auth: auth

    ' public
    getEPGChannelIdsReqInfo: tensorApi_getEPGChannelIdsReqInfo
    getEPGProgramReqInfo: tensorApi_getEPGProgramReqInfo
    getTournamentReqInfo: tensorApi_getTournamentReqInfo

    ' private
    commonOptions: tensorApi_commonOptions
  }
End Function


Function tensorApi_commonOptions()
  headers = {}
  ' appending in this style is necessary to prevent m.constants.headers.commonUapi from being
  ' mutated by potential later appends, since assoc arrays are passed by reference.
  headers.append(m.constants.headers.commonUapi)

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

  if getExperimentResource("roku_tensor_cdn_domain", "roku_tensor_cdn_domain_v1").enabled = true 'bs:disable-line 1001 LINT1001
    url = m.constants.urls.tensor.cdn.epgChannelIds
  else
    url = m.constants.urls.tensor.epgChannelIds
  end if

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


'tournamentPage content request
Function tensorApi_getTournamentReqInfo()

  if getExperimentResource("roku_tensor_cdn_domain", "roku_tensor_cdn_domain_v1").enabled = true 'bs:disable-line 1001 LINT1001
    url = m.constants.urls.tensor.cdn.tournamentscreen
  else
    url = m.constants.urls.tensor.tournamentscreen
  end if

  options = m.commonOptions()
  ' hardcode value 70 to cover all the FIFA matches in the FIFA container instead of using "constants.performance.categoryGridList.finalBlockSize"
  ' which limits the count 50 on lower end devices
  options.params["contents_limit"] = 70
  return {
    url: url
    options: options
  }

End Function
