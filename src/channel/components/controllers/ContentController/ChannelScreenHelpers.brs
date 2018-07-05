Function showChannelScreen(content, sourceTrackingUri)
  channelScreen = CreateObject("roSGNode", "ChannelDetailScreen")
  channelScreen.observeFieldScoped("contentSelected", "onChannelContentSelected")
  channelScreen.observeFieldScoped("backgroundUriList", "onChannelBackgroundChange")
  channelScreen.isLoading = true
  pushScreen(channelScreen, false)  ' don't send tracking until we resolve series episode
  getChannelFromServer(channelScreen, content, sourceTrackingUri)
End Function

Function onChannelContentSelected(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentSelected")
  channelScreen = msg.getRoSGNode()
  showDetailScreen(channelScreen.contentSelected, channelScreen.trackingUri)
End Function

Function getChannelFromServer(screen, content, sourceTrackingUri)
  tubiLog("ChannelScreenHelpers.getSingleContentFromServer")
  channelTask = CreateObject("roSGNode", "ChannelMetadataTask")
  channelTask.channelId = content.id
  screen.addField("task", "node", false)
  screen.task = channelTask
  screen.addField("sourceTrackingUri", "string", false)
  screen.sourceTrackingUri = sourceTrackingUri
  channelTask.addField("target", "node", false)
  channelTask.target = screen
  channelTask.observeField("response", "onChannelContentResponse")
  channelTask.observeField("error", "onChannelContentError")
  channelTask.control = "RUN"
End Function

Function onChannelContentResponse(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentResponse")
  task = msg.getRoSGNode()
  screen = task.target
  screen.isLoading = false
  screen.content = task.response
  task.unobserveField("response")
  task.unobserveField("error")

  if screen.sourceTrackingUri <> invalid
    screenTrackingNavigate(screen.sourceTrackingUri, screen.trackingUri)
  end if
  screenTrackingLoad(screen.trackingUri)
End Function

Function onChannelContentError(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentError")
  ' TODO(Chris): show some error
  task = msg.getRoSGNode()
  screen = task.target
  task.unobserveField("response")
  task.unobserveField("error")
End Function
