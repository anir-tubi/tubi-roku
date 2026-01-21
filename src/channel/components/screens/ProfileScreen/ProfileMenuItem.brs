Function init()

  m.icon = m.top.findNode("MenuItemIcon")
  m.title = m.top.findNode("MenuItemText")
  m.bottomItemText = m.top.findNode("BottomItemText")
  m.textGroup = m.top.findNode("textGroup")
  m.bottomItemTextGroup = m.top.findNode("BottomItemTextGroup")

  m.top.observeField("itemContent", "onItemContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.displayMedium)
  setTypographyOfLabel(m.bottomItemText, typographyConstants.ids.bodyMediumStrong)
  m.bottomItemText2Font = typographyConstants.ids.bodyMediumStrong
  m.bottomSubTextFont = typographyConstants.ids.bodyExtraSmallStrong
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.bottomItemText.color = theme.primaryTextColor
    m.focusedTextColor = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  item = msg.getData()
  if item <> invalid then

    m.icon.uri = item.HDPosterUrl
    m.bottomItemText.text = item.shortDescriptionLine1
    m.title.text = UCase(item.title)

    width = m.title.boundingRect().width
    translationX = (240 - width) / 2 ' center the initials; 240 is width/height of the item
    height = m.title.boundingRect().height
    translationY = (240 - height) / 2
    m.title.translation = [translationX, translationY]

    if item.isKidsAccount = true
      if m.kidsLogo = invalid
        m.kidsLogo = createObject("roSGNode", "Poster")
        m.kidsLogo.uri = "pkg:/images/profile-kids-logo.png"
        m.kidsLogo.width = 99
        m.kidsLogo.height = 18
        m.textGroup.appendChild(m.kidsLogo)
      end if
    else if m.kidsLogo <> invalid
      m.textGroup.removeChild(m.kidsLogo)
      m.kidsLogo = invalid
    end if

    if item.shortDescriptionLine2 <> invalid AND item.shortDescriptionLine2 <> ""
      if m.bottomSubText = invalid
        m.bottomSubText = createObject("roSGNode", "Label")
        setTypographyOfLabel(m.bottomSubText, m.bottomSubTextFont)
        m.textGroup.appendChild(m.bottomSubText)
        m.bottomSubText.text = item.shortDescriptionLine2
      end if
    else if m.bottomSubText <> invalid
      m.textGroup.removeChild(m.bottomSubText)
      m.bottomSubText = invalid
    end if

    if item.addFreeIcon = true
      if m.freeIcon = invalid
        m.freeIcon = createObject("roSGNode", "TextIcon")
        m.freeIcon.padding = [12, 9]
        m.freeIcon.fontColor = m.focusedTextColor
        m.freeIcon.uri = "pkg:/images/tag-rounded-rectangle-background-pull-$$RES$$.9.png"
        setTypographyOfLabel(m.freeIcon, m.bottomSubTextFont)
        m.freeIcon.text = getTranslation("registration_signup_button_free")
        m.bottomItemTextGroup.appendChild(m.freeIcon)
      end if
    else if m.freeIcon <> invalid
      m.bottomItemTextGroup.removeChild(m.freeIcon)
      m.freeIcon = invalid
    end if
  end if
End Function