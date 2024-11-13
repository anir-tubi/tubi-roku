Function playAdContent(content)
  adPlayer = setupAdPlayer(content)
  currentScreen = getCurrentScreen()

  if currentScreen <> invalid AND currentScreen.id <> m.constants.ui.screenIds.adPlayerScreen
    pushScreen(adPlayer, true, true)
  end if
  sendVideoPlayerCommand(adPlayer, "play")

End Function


Function setupAdPlayer(content)
  adPlayer = getFromScreenCache(m.constants.ui.screenIds.adPlayerScreen)

  if adPlayer = invalid
    adPlayer = CreateObject("roSGNode", "AdPlayerScreen")
    setInScreenCache(adPlayer)
  end if

  stopVideoPreview()

  if isKidsUIOn() = true
    adPlayer.appMode = "KIDS_MODE"
  else if m.uiMode = m.constants.ui.modes.latino
    adPlayer.appMode = "LATINO_MODE"
  else
    adPlayer.appMode = "DEFAULT_MODE"
  end if

  adPlayer.unobserveFieldScoped("state")
  adPlayer.observeFieldScoped("state", "onAdPlayerState")
  adPlayer.unobserveFieldScoped("backButtonPressed")
  adPlayer.observeFieldScoped("backButtonPressed", "onAdPlayerBackPressed")
  adPlayer.content = content
  adPlayer.updateContent = true

  return adPlayer
End Function


Function onAdPlayerBackPressed()
  popScreen(true, true)
End Function

