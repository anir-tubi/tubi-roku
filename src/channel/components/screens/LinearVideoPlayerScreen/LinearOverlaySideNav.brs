Function init()
  m.constants = getConstantsFromGlobal()
  m.sideNav = m.top.findNode("sideNav")
  m.sideNav.observeFieldScoped("buttonFocused", "onSideNavFocusChange")
  m.sideNav.observeFieldScoped("buttonSelected", "onSideNavSelectChange")
  m.btnCC = m.sideNav.findNode("btnCC")
  m.btnCC_poster = m.btnCC.findNode("btnCC_poster")
  m.btnCC_label = m.btnCC.findNode("btnCC_label")
  m.btnBack = m.sideNav.findNode("btnBack")
  m.btnBack_poster = m.btnBack.findNode("btnBack_poster")
  m.btnBack_poster_unfocused = m.btnBack.findNode("btnBack_poster_unfocused")
  m.btnBack_label = m.btnBack.findNode("btnBack_label")

  m.btnBack_label.text = getTranslation("linearVideoPlayer_buttonGuide2")
  m.btnCC_label.text = getTranslation("linearVideoPlayer_buttonCaptions2")

  m.top.observeFieldScoped("setOpenState", "onOpenStateChanged")
  m.top.observeFieldScoped("buttonToFocusID", "onSideNavToFocusChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.btnCC_label, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.btnBack_label, typographyConstants.ids.bodySmallStrong)

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
    m.btnBack_label.color = theme.primaryTextColor
    m.btnCC_label.color = theme.primaryTextColor
  end if
End Function


Function onSideNavFocusChange()
  if m.sideNav.buttonFocused = 0
    '//Closed Caption button in focus
    focusSideNavButton(m.btnCC.id)
    unFocusSideNavButton(m.btnBack.id)
    m.top.focusedButtonID = m.constants.ui.linearSideNavIds.subtitles
  else if m.sideNav.buttonFocused = 1
    '//Back to Guide button in focus
    unFocusSideNavButton(m.btnCC.id)
    focusSideNavButton(m.btnBack.id)
    m.top.focusedButtonID = m.constants.ui.linearSideNavIds.epg
  end if
End Function


' The outside tells this component which side nav item to focus
Function onSideNavToFocusChange()
  if m.top.buttonToFocusID = m.constants.ui.linearSideNavIds.subtitles
    m.sideNav.focusButton = 0
  else if m.top.buttonToFocusID = m.constants.ui.linearSideNavIds.epg
    m.sideNav.focusButton = 1
  end if
End Function


Function onSideNavSelectChange()
  if m.sideNav.buttonFocused = 0
    m.top.selectedButtonID = m.constants.ui.linearSideNavIds.subtitles
  else if m.sideNav.buttonFocused = 1
    m.top.selectedButtonID = m.constants.ui.linearSideNavIds.epg
  end if
End Function


'//Set the button to a state where it appears to be focused
Function focusSideNavButton(sButtonID)
  if sButtonID = m.btnCC.id
    poster = m.btnCC_poster
    label = m.btnCC_label
  else if sButtonID = m.btnBack.id
    poster = m.btnBack_poster
    label = m.btnBack_label
  else
    poster = invalid
    label = invalid
  end if

  if poster <> invalid AND label <> invalid then
    theme = getThemeFromGlobal()
    if theme <> invalid
      poster.blendColor = theme.focusedColor
      label.color = theme.highlightedTextColor
    end if

    poster.opacity = 1
    label.opacity = 1
  end if
End Function


'//Set the button to a state where it appears to be unfocused
Function unFocusSideNavButton(sButtonID)
  if sButtonID = m.btnCC.id
    poster = m.btnCC_poster
    label = m.btnCC_label
  else if sButtonID = m.btnBack.id
    poster = m.btnBack_poster
    label = m.btnBack_label
  else
    poster = invalid
    label = invalid
  end if

  if poster <> invalid AND label <> invalid then
    theme = getThemeFromGlobal()
    if theme <> invalid
      poster.blendColor = theme.unfocusedColor
      label.color = theme.primaryTextColor
    end if

    poster.opacity = .5
    label.opacity = .5
  end if
End Function


Function unFocusSideNavButtons()
  unFocusSideNavButton(m.btnCC.id)
  unFocusSideNavButton(m.btnBack.id)
End Function


Function onOpenStateChanged()
  if m.top.setOpenState = "closed"
    '//Make the side nav appear to be closed
    unFocusSideNavButtons()
    m.btnBack_label.visible = false
    m.btnCC_label.visible = false
  else if m.top.setOpenState = "openedAndInFocus"
    '//make the side nav appear opened and in focus. Also set the focus onto the sidenav.
    m.sideNav.setFocus(true)
    m.btnBack_label.visible = true
    m.btnCC_label.visible = true
  else if m.top.setOpenState = "openedAndNotInFocus"
    '//Make the side nav appear to be opened but not in focus
    poster = m.btnCC_poster
    label = m.btnCC_label

    theme = getThemeFromGlobal()
    if theme <> invalid
      poster.blendColor = theme.unfocusedColor
      label.color = theme.primaryTextColor
    end if

    poster.opacity = 1
    label.opacity = 1
    unFocusSideNavButton(m.btnBack.id)
  end if
End Function
