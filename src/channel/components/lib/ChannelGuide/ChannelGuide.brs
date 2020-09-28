Function init()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings.mode)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.channelsGuide = m.top.findNode("channelsGuide")
  m.channelsGuideSpinner = m.top.findNode("channelsGuideSpinner")
  m.channelsGuide.observeFieldScoped("itemSelected", "onChannelGuideContentSelected")
  m.channelsGuide.observeFieldScoped("itemFocused", "onChannelGuideContentFocused")
  m.top.observeFieldScoped("contentUpdated", "onContentChanged")
  m.top.observeFieldScoped("display", "onDisplayChanged")
End Function

Function onChannelGuideContentFocused(msg)
  tubiLog("ChannelGuide.onChannelGuideContentFocused")
  guide = msg.getRoSGNode()
  item = msg.getData()
  channel = guide.content.getChild(item)

  'Set the navigateWithinPageInfo value which will pass through to ContentController via videoHelpers.brs
  'to fire a navigate_within_page analytics event.
  row = item + 1  '1 based index
  col = 1
  m.top.navigateWithinPageInfo = {
    pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: channel.id.toInt()})
    componentOneof: m.Tracking.getAnalyticsComponent("channel_guide_component", m.lastChannelGuideComponentSelected)
    means_of_navigation: "BUTTON"  'MeansOfNavigation enum
    vertical_location: row
    vertical_location_mode: "INDEX"  'LocationMode enum
    horizontal_location: col
    horizontal_location_mode: "INDEX"  'LocationMode enum
  }
  contentTile = m.Tracking.getAnalyticsTile(channel, col, row)
  m.lastChannelGuideComponentSelected = {content_tile: contentTile}


  '//The trackingComponentInfo has to be set before setting m.top.itemFocused for analytics reasons
  m.top.trackingComponentInfo = {
    componentType: "channel_guide_component"
    componentValues: m.lastChannelGuideComponentSelected
  }

  m.top.itemFocused = channel
End Function


Function onChannelGuideContentSelected(msg)
  tubiLog("ChannelGuide.onChannelGuideContentSelected")
  guide = msg.getRoSGNode()
  item = msg.getData()
  channel = guide.content.getChild(item)

  m.top.itemSelected = channel
End Function


Function onContentChanged()
  tubiLog("ChannelGuide.onContentChanged")
  m.lastChannelGuideComponentSelected = invalid
  if m.top.content <> invalid
    m.channelsGuide.content = m.top.content
  end if
End Function  


Function onDisplayChanged()
  tubiLog("ChannelGuide.onContentChanged")
  if m.top.display = true
    m.channelsGuideSpinner.visible = false
    m.channelsGuide.visible = true

    nJumpToItem = 0
    if m.top.jumpToID <> invalid and m.top.jumpToID <> "" and m.top.content <> invalid
      '//Go thru the content and get the index of the ID referred to in the jumpToID field 
      for i=0 to m.top.content.getChildCount()-1
        channel = m.top.content.getChild(i)
        if channel.id = m.top.jumpToID
          nJumpToItem = i
          exit for
        end if
      end for
    end if
    m.top.jumpToID = ""
    m.channelsGuide.jumpToItem = nJumpToItem
    m.channelsGuide.setFocus(true)
  else 
    '//Display spinner and hide guide
    m.channelsGuideSpinner.visible = true
    m.channelsGuide.visible = false
  end if
End Function