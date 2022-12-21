Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("width", "onWidthChange")
  m.top.observeFieldScoped("height", "onHeightChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")
  m.buttonBG = m.top.findNode("buttonBG")

  m.Icon = m.top.findNode("Icon")
  m.DetailsMenuText = m.top.findNode("DetailsMenuText")
  m.top.leftTextPadding = m.DetailsMenuText.translation[0]
  m.Progress = m.top.findNode("ResumeProgressBar")
  m.badgeLabel = m.top.findNode("badgeLabel")

  m.constants = getConstantsFromGlobal()
  if m.constants <> invalid
    m.top.color = m.constants.ui.colors.transparent
    m.Progress.color = m.constants.ui.colors.focusedText

    if m.constants.deviceInfo.scaledUi = true
      m.buttonBG.uri = "pkg:/images/menu-focus-hd.9.png"
    end if
  end if
End Function


Function onWidthChange()
  m.buttonBG.width = m.top.width
End Function


Function onHeightChange()
  m.buttonBG.height = m.top.height
End Function


Function onItemContentChange()
  tubiLog("DetailMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then

    item = m.top.itemContent
    'If the button has title and BadgeText, calculated width will be width of both title and badgeText to avoid button crop. To get the
    'calculated width we are assigning the title and badgeText to the m.DetailsMenuText and get the calculated value
    'and after setting the calculatedWidth resetting m.DetailsMenuText.text to title.
    m.DetailsMenuText.text = item.title + item.badgeText
    iconWidth = 0
    'adding extra width for focus if icon is present
    if item.iconUrl <> invalid AND item.iconUrl <> ""
      iconWidth = 36
    end if
    m.top.calculatedTextWidth = m.DetailsMenuText.boundingRect().width + iconWidth
    m.DetailsMenuText.text = item.title

    m.Icon.uri = item.iconUrl

    m.buttonBG.visible = item.isUnfocusedFootprintEnabled

    if item.playstart <> invalid AND item.playstart <> 0.0 AND item.length <> invalid AND item.length <> 0.0 then
      showProgressBar(m.top.itemContent.playstart / item.length)
    else
      m.Progress.visible = false
    end if
    m.top.calculatedWidth = m.top.calculatedTextWidth + m.DetailsMenuText.translation[0]

    'Move the translation of Button text to left when there is no image
    if item.id = "signUpMenuItem" AND item.iconUrl = ""
      m.DetailsMenuText.translation = [22, 0]
    else
      m.DetailsMenuText.translation = [72, 0]
    end if
    calculatedWidth = m.DetailsMenuText.boundingRect().width + m.DetailsMenuText.translation[0]
    if item.badgeText <> ""
      m.badgeLabel.fontColor = m.constants.ui.colors.backgroundColor
      m.badgeLabel.fontUri = "pkg:/fonts/Vaud-Bold.ttf"
      m.badgeLabel.fontSize = 18
      m.badgeLabel.padding = [12, 9]
      m.badgeLabel.text = item.badgeText
      m.badgeLabel.visible = true
      m.badgeLabel.translation = [calculatedWidth + 20, 20]
    else
      m.badgeLabel.visible = false
    end if

    'Adjusting the DetailsMenuText text to center when there is no icoUrl and badge label text.
    if item.align = "center"
      xTranslation = (m.top.width - m.top.calculatedTextWidth) / 2
      m.DetailsMenuText.translation = [xTranslation, 0]
    end if
  end if

End Function

Function showProgressBar(percentage As Double)
  tubiLog("DetailMenuItem.showProgressBar")
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  ' width of menu item is 440, 4 pixel margin for progress bar
  m.Progress.width = (m.top.width - 8.0) * percentage
  m.Progress.visible = true
End Function


Function onItemHasFocus()
  if m.top.itemHasFocus = true
    m.buttonBG.blendcolor = m.constants.ui.colors.focused
  else
    m.buttonBG.blendcolor = m.constants.ui.colors.neutralColor
  end if
End Function
