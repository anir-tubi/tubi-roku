Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")
  m.constants = getConstantsFromGlobal()

  m.title = m.top.findNode("title")
  m.subtitle = m.top.findNode("subtitle")
  m.toggleText = m.top.findNode("toggleText")
  m.contentSection = m.top.findNode("contentSection")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.toggleText, typographyConstants.ids.subheaderSmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onItemHasFocus()
  if m.top.itemHasFocus = true
    m.title.color = m.focusedTextColor
    m.subtitle.color = m.focusedTextColor
    m.toggleText.color = m.focusedTextColor
  else
    m.title.color = m.primaryTextColor
    m.subtitle.color = m.secondaryTextColor
    m.toggleText.color = m.primaryTextColor
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  m.focusedTextColor = invalid
  m.tertiaryTextColor = invalid
  m.secondaryTextColor = invalid
  m.primaryTextColor = invalid

  if theme <> invalid
    m.focusedTextColor = theme.focusedTextColor
    m.tertiaryTextColor = theme.tertiaryTextColor
    m.secondaryTextColor = theme.secondaryTextColor
    m.primaryTextColor = theme.primaryTextColor
    m.title.color = m.primaryTextColor
    m.subtitle.color = m.secondaryTextColor
    m.toggleText.color = m.primaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  tubiLog("ConsentPreferenceItem.onItemContentChange")
  item = msg.getData()

  if item <> invalid then
    m.title.text = item.title
    m.subtitle.text = item.subTitle

    subHeaderWidth = item.subHeaderWidth
    m.subtitle.width = subHeaderWidth
    m.toggleText.width = (item.totalWidth - subHeaderWidth - 60)

    if item.isRequired = true
      if m.tertiaryTextColor <> invalid
        m.toggleText.color = m.tertiaryTextColor
      end if
      m.toggleText.text = getTranslation("privacy_preferences_required")
    else
      if m.top.itemHasFocus = true
        if m.focusedTextColor <> invalid
          m.toggleText.color = m.focusedTextColor
        end if
      else
        if m.primaryTextColor <> invalid
          m.toggleText.color = m.primaryTextColor
        end if
      end if

      if item.value = "opted_in"
        m.toggleText.text = getTranslation("privacy_preferences_on")
      else
        m.toggleText.text = getTranslation("privacy_preferences_off")
      end if
    end if
  end if

  ' Vertical center align the content section.
  height = m.top.height
  itemHeight = m.contentSection.boundingRect().height
  if height > 0 AND height <> itemHeight
    m.contentSection.translation = [30, (height - itemHeight) / 2]
  end if
End Function
