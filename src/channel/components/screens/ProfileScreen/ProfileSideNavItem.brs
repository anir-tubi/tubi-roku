Function init()
  m.label = m.top.findNode("Label")
  m.focusedLabel = m.top.findNode("focusedLabel")
  m.labelParent = m.top.findNode("LabelParent")
  m.subTxtParent = m.top.findNode("subTxtParent")
  m.icon = m.top.findNode("Icon")
  m.focusedIcon = m.top.findNode("focusedIcon")
  m.menuItemText = m.top.findNode("menuItemText")
  m.kidsLogo = m.top.findNode("kidsLogo")
  m.kidsLogoFocused = m.top.findNode("kidsLogoFocused")
  m.kidsLogoGroup = m.top.findNode("kidsLogoGroup")

  m.subTxt = m.top.findNode("subTxt")
  m.subTxtFocused = m.top.findNode("subTxtFocused")
  m.sideIcon = m.top.findNode("sideIcon")
  m.sideIconFocused = m.top.findNode("sideIconFocused")

  m.focusedLabel.opacity = 0
  m.focusedIcon.opacity = 0
  m.subTxtFocused.opacity = 0

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.subTxt, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.subTxtFocused, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.focusedLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.menuItemText, typographyConstants.ids.bodyMediumStrong)
  onThemeChange()

End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.label.color = theme.primaryTextColor
    m.focusedLabel.color = theme.focusedTextColor
    m.subTxt.color = theme.primaryTextColor
    m.subTxtFocused.color = theme.focusedTextColor
    m.menuItemText.color = theme.primaryTextColor
    m.icon.blendcolor = theme.primaryTextColor
    m.focusedIcon.blendcolor = theme.focusedTextColor
    m.sideIcon.blendcolor = theme.primaryTextColor
    m.sideIconFocused.blendcolor = theme.focusedTextColor
    m.kidsLogoFocused.blendcolor = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  item = msg.getData()
  if item <> invalid then
    if item.setFocus <> invalid AND item.setFocus = false
      m.top.unObserveFieldScoped("focusPercent")
    end if

    m.icon.uri = item.iconUrl
    m.focusedIcon.uri = item.filledIconUrl
    m.menuItemText.text = item.secondaryTitle
    menuTransX = m.icon.translation[0] + ((m.icon.width - m.menuItemText.boundingRect().width) / 2)
    menuTransY = m.icon.translation[1] + ((m.icon.height - m.menuItemText.boundingRect().height) / 2)
    m.menuItemText.translation = [menuTransX, menuTransY]
    m.sideIcon.uri = item.sideIconUrl
    m.sideIconFocused.uri = item.sideIconUrl
    if item.shortDescriptionLine1 <> invalid AND item.shortDescriptionLine1 <> ""
      subTxtPresent = (m.subTxtParent.getParent() <> invalid)
      if subTxtPresent = false

        m.labelParent.appendChild(m.subTxtParent)
      end if

      m.subTxt.text = item.shortDescriptionLine1
      m.subTxtFocused.text = item.shortDescriptionLine1
      m.labelParent.removeChild(m.kidsLogoGroup)

    else
      m.labelParent.removeChild(m.subTxtParent)
      if item.isKidsAccount = true
        kidsLogoGroupPresent = (m.kidsLogoGroup.getParent() <> invalid)
        if kidsLogoGroupPresent = false
          m.labelParent.appendChild(m.kidsLogoGroup)
        end if
      else
        m.labelParent.removeChild(m.kidsLogoGroup)
      end if
    end if

    m.label.text = item.title
    m.focusedLabel.text = item.title
    transY = (m.top.height - m.labelParent.boundingRect().height) / 2
    m.labelParent.translation = [88, transY]

    if m.top.index = 0
      m.sideIcon.visible = true
      m.sideIconFocused.visible = true
    else
      m.sideIcon.visible = false
      m.sideIconFocused.visible = false
    end if
  end if
End Function


Function onFocusPercentChange()

  focusPercent = m.top.focusPercent

  if m.focusedIcon.uri <> ""
    m.focusedIcon.opacity = focusPercent
    m.icon.opacity = 1 - focusPercent
  else
    m.icon.opacity = 1
  end if

  m.focusedLabel.opacity = focusPercent
  m.label.opacity = 1 - focusPercent

  subTxtPresent = (m.subTxtParent.getParent() <> invalid)
  if subTxtPresent = true
    m.subTxtFocused.opacity = focusPercent
    m.subTxt.opacity = 1 - focusPercent
  end if
  if m.sideIcon.visible = true
    m.sideIconFocused.opacity = focusPercent
    m.sideIcon.opacity = 1 - focusPercent
  end if

  kidsLogoGroupPresent = (m.kidsLogoGroup.getParent() <> invalid)
  if kidsLogoGroupPresent = true
    m.kidsLogo.opacity = 1 - focusPercent
    m.kidsLogoFocused.opacity = focusPercent
  end if

End Function