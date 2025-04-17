Function init()
  m.overlayBackground = m.top.findNode("overlayBackground")
  m.sendFeedbackHeaderLabel = m.top.findNode("sendFeedbackHeaderLabel")
  m.sendFeedbackSubHeaderLabel = m.top.findNode("sendFeedbackSubHeaderLabel")
  m.sendFeedbackHint = m.top.findNode("sendFeedbackHint")
  m.qrCodeHolder = m.top.findNode("qrCodeHolder")

  m.closeButton = m.top.findNode("closeButton")
  m.closeButton.text = getTranslation("dialog_button_close")

  playerControlExperimentType = getExperimentResource("roku_player_ui_refresh", "roku_player_control_ui_refresh_v1", false).type

  if playerControlExperimentType = "variant2" OR playerControlExperimentType = "variant3"
    m.closeButton.uri = "pkg:/images/pill_top_nav_$$RES$$.9.png"
  end if

  m.closeButton.observeFieldScoped("selected", "onCloseSelected")
  m.top.observeField("focusedChild", "onScreenFocusChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.sendFeedbackHeaderLabel, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.sendFeedbackSubHeaderLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.sendFeedbackHint, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.overlayBackground.blendColor = theme.neutralSolidColor
    m.qrCodeHolder.color = theme.backgroundColorLight
    m.closeButton.color = theme.backgroundColorLight2
    m.sendFeedbackHeaderLabel = theme.primaryTextColor
    m.sendFeedbackSubHeaderLabel = theme.primaryTextColor
    m.sendFeedbackHint = theme.primaryTextColor
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.closeButton.setFocus(true)
  end if
End Function


Function onCloseSelected()
  m.top.closeSendFeedbackOverlay = true
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press then
    if key = "back" OR key = "left"
      m.top.closeQRCodeOverlay = true
    end if
  end if

  return true
End Function
