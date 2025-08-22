Function init()
  topRef = m.top
  m.poster = topRef.findNode("poster")
  m.title = topRef.findNode("title")
  m.border = topRef.findNode("border")

  topRef.observeFieldScoped("itemContent", "onContentChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowHasFocus", "onItemHasFocusChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMedium)
  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.focusedColor = theme.focusedColor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    titleText = ""
    category = itemContent.getParent()
    if category <> invalid AND isAA(category.uiCustomization) AND isAA(category.uiCustomization.style)
      style = category.uiCustomization.style
      if isNonEmptyString(style.bannerBackground) = true
        m.poster.uri = style.bannerBackground
      end if

      if itemContent.needsLogin = true AND isNonEmptyString(style.bannerTextGuest) = true
        titleText = style.bannerTextGuest
      else if isNonEmptyString(style.bannerTextRegistered) = true
        titleText = style.bannerTextRegistered
      end if

    end if

    if itemContent.airDateTime <> invalid
      airDatetime = CreateObject("roDateTime")
      airDatetime.FromISO8601String(itemContent.airDateTime)
      airDatetime.toLocalTime()

      if FindMemberFunction(airDatetime, "asDateStringLoc") <> invalid
        titleText = titleText.replace("{date}", airDatetime.asDateStringLoc("MMM d"))
      else
        titleText = titleText.replace("{date}", airDatetime.asDateString("no-weekday"))
      end if
    end if
    m.title.text = titleText
    m.title.translation = [(m.top.width / 2) - (m.title.width / 2), 0]
  end if
End Function


Function onItemHasFocusChange(_msg)
  itemHasFocus = (m.top.itemHasFocus = true AND m.top.rowHasFocus = true)
  if itemHasFocus = true
    m.border.blendColor = m.focusedColor
  else
    m.border.blendColor = "0x00000000"
  end if
End Function