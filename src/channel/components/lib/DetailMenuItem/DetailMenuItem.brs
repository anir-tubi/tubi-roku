Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.Icon = m.top.findNode("Icon")
  if getExperimentResource("roku_update_icons", "roku_update_icons_v1", false).enabled = false
    m.Icon.width = 40
    m.Icon.height = 40
    m.Icon.translation = [22,17]
  end if
  m.DetailsMenuText = m.top.findNode("DetailsMenuText")
  m.top.leftTextPadding = m.DetailsMenuText.translation[0]
  m.Progress = m.top.findNode("ResumeProgressBar")
  m.badgeLabel = m.top.findNode("badgeLabel")

  constants = getConstantsFromGlobal()
  if constants <> invalid
    m.top.color = constants.ui.colors.transparent
    m.Progress.color = constants.ui.colors.focusedText
  end if
End Function

Function onItemContentChange()
  tubiLog("DetailMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then

    if m.top.itemContent.id = "signUpMenuItem"
      'If the button has title and BadgeText, calculated width will be width of both title and badgeText to avoid button crop. To get the
      'calculated width we are assigning the title and badgeText to the m.DetailsMenuText and get the calculated value
      'and after setting the calculatedWidth resetting m.DetailsMenuText.text to title.
      m.DetailsMenuText.text = m.top.itemContent.title + m.top.itemContent.badgeText
      iconWidth = 0
      'adding extra width for focus if icon is present
      if m.top.itemContent.iconUrl <> invalid and m.top.itemContent.iconUrl <> ""
        iconWidth = 36
      end if
      m.top.calculatedTextWidth = m.DetailsMenuText.boundingRect().width + iconWidth
      m.DetailsMenuText.text = m.top.itemContent.title
    else
      m.DetailsMenuText.text = m.top.itemContent.title
      m.top.calculatedTextWidth = m.DetailsMenuText.boundingRect().width
    end if

    m.Icon.uri = m.top.itemContent.iconUrl
    if m.top.itemContent.playstart <> invalid and m.top.itemContent.playstart <> 0.0 and m.top.itemContent.length <> invalid and m.top.itemContent.length <> 0.0 then
      showProgressBar(m.top.itemContent.playstart / m.top.itemContent.length)
    else
      m.Progress.visible = false
    end if
    m.top.calculatedWidth = m.top.calculatedTextWidth + m.DetailsMenuText.translation[0]

    'Move the translation of Button text to left when there is no image
    if m.top.itemContent.id = "signUpMenuItem" and m.top.itemContent.iconUrl = ""
      m.DetailsMenuText.translation = [22, 0]
    else
      m.DetailsMenuText.translation = [72, 0]
    end if
    calculatedWidth = m.DetailsMenuText.boundingRect().width + m.DetailsMenuText.translation[0]
    if m.top.itemContent.badgeText <> ""
      m.badgeLabel.fontColor = "0x10141F"
      m.badgeLabel.fontUri = "pkg:/fonts/Vaud-Bold.ttf"
      m.badgeLabel.fontSize = 21
      m.badgeLabel.text = m.top.itemContent.badgeText
      m.badgeLabel.visible = true
      m.badgeLabel.translation = [calculatedWidth + 20, 20]
    else
      m.badgeLabel.visible = false
    end if
  end if
  
  'Adjusting the DetailsMenuText text to center when there is no icoUrl and badge label text.
  if m.top.itemContent.align = "center"
    xTranslation = (m.top.width - m.top.calculatedTextWidth) / 2
    m.DetailsMenuText.translation = [xTranslation, 0]
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
