Function init()
  m.top.functionName = "execGetChannelMetadata"
End Function

Function execGetChannelMetadata() As Void
  tubiLog("ChannelMetadataTask.execGetDetailMetadata")
  if m.top.channelId = invalid or m.top.channelId = ""
    m.top.error = {
      code: -1
      data: ""
      failReason: "Channel id was invalid"
    }
    return
  end if

  tubiLog("ChannelMetadataTask getting content for " + m.top.channelId)

  constants = m.global.constants
  RequestModule = TubiRequest(constants.settings.mode)
  AuthModule = TubiAuth(constants, RequestModule)
  cms = CmsApi(constants, RequestModule, AuthModule)
  translate = TubiMetadataTranslate(constants)
  channelReq = cms.channelReq(m.top.channelId, constants.performance.categoryGridList.finalBlockSize, m.top.kidsMode)
  channel = channelReq.runSynchronous()

  ' Parse results
  if channel <> invalid
    parsed = ParseJSON(channel)
    if parsed = invalid then
      tubiLog("ChannelMetadataTask failed to parse JSON response")
      m.top.error = {
        code: -1
        data: ""
        failReason: "Could not parse json"
      }
    else
      channelNode = translate.translateChannel(parsed)
      container = CreateObject("roSGNode", "ContentNode")
      container.appendChild(channelNode)
      m.top.response = container
    end if
  else
    code = -1
    if channelReq.response <> invalid
      code = channelReq.response.code
    end if
    m.top.error = {
      code: code
      data: ""
      failReason: "Result is invalid"
    }
  end if
End Function
