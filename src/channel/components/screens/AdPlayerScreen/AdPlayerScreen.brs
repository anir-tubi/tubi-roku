Function init()
  tubiLog("AdPlayerScreen.init")

  ' handle BaseScreen functionality (see BaseScreen.xml)
  m.constants = getConstantsFromGlobal()
  m.top.screenLevel = m.constants.ui.screenLevels.adPlayerScreen
  m.top.id = m.constants.ui.screenIds.adPlayerScreen
  
  m.top.trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }

  m.RAFAdContainer = m.top.findNode("RAFAdContainer")

  m.logo = m.top.findNode("tubiLogo")
  m.Loading = m.top.findNode("Loading")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")

  m.adDescriptionPanel = m.top.findNode("adDescriptionPanel")

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("adState", "onAdStateChange")
  m.top.observeFieldScoped("control", "onControlChange")
  m.top.observeFieldScoped("adProgress", "onAdBufferingProgress")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  'Setting ad task control to "RUN" as the last step in init() because making UI updates, as in onThemeChange(), while the task is starting up causes bright script to throw loop detected error for some reason.
  m.TubiAdsTask = m.top.findNode("TubiAdsTask")
  m.TubiAdsTask.adPlayerNode = m.top
  m.TubiAdsTask.control = "RUN"
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.LoadingProgressBar.focusColor = theme.focusedColor
    m.LoadingProgressBar.unfocusColor = theme.focusedColor
    m.LoadingProgressBar.trackColor = theme.neutralColor2

    if theme.id = m.constants.ui.themeIDs.kidsMode
      m.logo.visible = false
    else
      m.logo.visible = true
    end if
  end if
End Function


Function onContentChange()
  tubiLog("AdPlayer.onContentChange")

  content = m.top.content
  if content <> invalid
    m.top.adState = "init"
    m.adDescriptionPanel.content = content
    
    'set page tracking values for analytics
    m.top.trackingPageInfo = {
      pageType: m.top.trackingPageInfo.pageType
      pageValues: {
        video_id: m.top.content.id.toInt()
      }
    }

    fade(m.adInfoGroup, "in", 0.4, 1)
  end if

 End Function


Function onDisplayAdLoadingMessage()
  if m.top.displayAdLoadingMessage = true
    m.LoadingMessage.text = getTranslation("videoPlayer_adLoadingMessage")
  end if
End Function


Function onScreenFocusChange()

  if m.top.hasFocus() = true then
    if m.top.adState = "adsPlaying" then
      ' If the screensaver screen takes over while an ad is paused when they leave the screensaver they are brought back to the video player screen but the focus is on the screen itself not the RAF renderer. We are manually setting it back so a user can properly resume the ad.
      rafChild = m.RAFAdContainer.getChild(0)
      if rafChild <> invalid then
        rafChild.setFocus(true)
      end if
    end if
  end if
End Function


Function onAdBufferingProgress(msg)
  progress = msg.GetData()
  m.LoadingProgressBar.progress = progress
  if progress = 100
    m.loading.visible = false
  else
    m.loading.visible = true
  end if
End Function


Function onControlChange()
  control = m.top.control
  tubiLog("AdPlayer.onControlChange " + control)

  if control = "play"
    if m.top.content <> invalid
      showAdBreak()
    end if

  else if control = "stop" then
    stopAdsPlayback()
    m.top.adState = "init"

    'in the case where an ad break has started, but RAF does not yet have control, we want to break out of ads on back button pressed
    m.top.adControl = "stop"
  end if  
End Function


' onAdStateChange
'
' adState values are:
'   "ready": the ad shim task is ready and listening for updates to the adControl field (should happen once per user session)
'   "init": no ad request has yet to be made for this video (adState is reset back to init when video is about to be started)
'   "adsPlaying": ads are currently playing - RAF has control
'   "adsClosed": a user has hit the back button while RAF has control, closing the ad experience
'   "noAds": an ad response has been received but there are no ads in it. Or an ad break has played to completion.
'   "adsCompleted": an ad break has played to completion.
Function onAdStateChange(msg)
  adState = msg.getData()

  if (adState = "noAds" OR adState = "adsCompleted" OR adState = "adsClosed")
    m.top.backButtonPressed = true
  else if adState = "ready"
    m.top.adState = "adsReady"
    if m.top.adControl <> ""
      ' There is a race condition that can occur during deeplinks such that m.top.adControl can be set before the preloadedadShim is listening
      ' which results in a ad/video loading screen that never loads. Reset the ad control once the ad state is in init if this is the case
      ' to fix the issue.
      m.top.adControl = m.top.adControl
    end if  
  end if 

End Function


Function showAdBreak()
  m.top.adControl = "play"
End Function


Function stopAdsPlayback()
  tubilog("AdPlayer.stopAdsPlayback")

  renderer = m.RAFAdContainer.getChild(0)
  rendererType = getNodeSubtype(renderer)
  if rendererType = "RAFContentRenderer" then
    ' stitched ads renderer
    renderer.control = "stop"
  else if rendererType = "RAFRenderer" then
    ' nonstitched ads renderer
    renderer.stopAd = true
  end if
End Function