Function init()
  m.constants = getConstantsFromGlobal()

  m.title = m.top.findNode("Title")
  m.avatar = m.top.findNode("Avatar")
  m.name = m.top.findNode("Name")
  m.email = m.top.findNode("Email")
  m.offset = m.top.findNode("Offset")
  m.signOutBtnGroup = m.top.findNode("SignOutButtonLayoutGroup")
  m.nameEmailGroup = m.top.findNode("NameEmailGroup")
  m.tubiKidsLogo = m.top.findNode("TubiKidsLogo")
  m.linkedAccountsGroup = m.top.findNode("LinkedAccountsGroup")
  m.linkedAccountsLabel = m.top.findNode("LinkedAccountsLabel")
  m.linkedAccountsDescription = m.top.findNode("LinkedAccountsDescription")
  m.linkedAccountsGrid = m.top.findNode("LinkedAccountsGrid")
  m.top.observeFieldScoped("linkedAccounts", "onLinkedAccountsChange")
  m.top.observeFieldScoped("removeKidsSignOutBtn", "onRemoveKidsSignOutBtnChange")
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")
  m.parentalRating = m.top.findNode("ParentalRating")
  m.top.observeFieldScoped("parentalRating", "onParentalRatingChange")
  m.manageTitle = m.top.findNode("ManageTitle")
  m.description = m.top.findNode("Description")
  m.qrCodePoster = m.top.findNode("QrCodePoster")
  m.QRCodeUrlString = m.top.findNode("QRCodeUrlString")
  m.offset = m.top.findNode("Offset")
  m.signOutButton = m.top.findNode("SignOutButton")
  m.signOutButton.enabled = false
  m.kidsLinked = false
  m.originalOffsetX = m.offset.translation[0]
  m.originalOffsetY = m.offset.translation[1]

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, m.typographyConstants.ids.headerSmall, { fontSize: 48 })
  setTypographyOfLabel(m.name, m.typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.email, m.typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.manageTitle, m.typographyConstants.ids.headerSmall, { fontSize: 48 })
  setTypographyOfLabel(m.description, m.typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.QRCodeUrlString, m.typographyConstants.ids.subheaderLarge)
  setTypographyOfLabel(m.linkedAccountsLabel, m.typographyConstants.ids.headerSmall, { fontSize: 48 })
  setTypographyOfLabel(m.linkedAccountsDescription, m.typographyConstants.ids.bodyMedium)
  m.avatar.textFont = m.typographyConstants.ids.displayMedium

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
    m.name.color = theme.primaryTextColor
    m.email.color = theme.primaryTextColor
    m.manageTitle.color = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    m.QRCodeUrlString.color = theme.primaryTextColor
  end if
End Function


Function onFocusedChildChange(msg)
  if m.top.hasFocus() = true AND isSignOutButtonShown() = true
    m.signOutButton.setFocus(true)
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean

  if press then
    if key = "OK" AND isSignOutButtonShown() = true AND m.signOutButton.hasFocus() = true
      m.top.signOutSelected = true
      return true
    else if key = "down" AND m.kidsLinked = true
      if isSignOutButtonShown() = true AND m.signOutButton.hasFocus() = true
        m.qrCodePoster.setFocus(true)
        m.offset.translation = [m.originalOffsetX, -1000]
        return true
      end if
    else if key = "up" AND m.kidsLinked = true
      if m.qrCodePoster.hasFocus() = true AND isSignOutButtonShown() = true
        m.signOutButton.setFocus(true)
        m.offset.translation = [m.originalOffsetX, -147]
        return true
      end if
    end if
  end if

  return false
End Function


Function onParentalRatingChange(msg)
  parentalRating = msg.getData()

  'TODO: write a mixin 'isKidProfile'
  if parentalRating = 0 OR parentalRating = 1 OR parentalRating = 4 OR parentalRating = 5
    hideSignOutButton()
    m.nameEmailGroup.removeChild(m.email)
    if m.tubiKidsLogo.getParent() = invalid
      m.nameEmailGroup.appendChild(m.tubiKidsLogo)
    end if
    m.tubiKidsLogo.visible = true
  else
    showSignOutButton()
    if m.email.getParent() = invalid
      m.nameEmailGroup.appendChild(m.email)
    end if
    m.nameEmailGroup.removeChild(m.tubiKidsLogo)
  end if

End Function


Function showSignOutButton()
  if isSignOutButtonShown() = false
    m.signOutBtnGroup.appendChild(m.signOutButton)
  end if
End Function


Function hideSignOutButton()
  m.signOutBtnGroup.removeChild(m.signOutButton)
End Function


Function isSignOutButtonShown()
  return m.signOutButton.getParent() <> invalid
End Function


Function onRemoveKidsSignOutBtnChange(msg)
  removeSignOutButton = msg.getData()
  if removeSignOutButton = true
    hideSignOutButton()
  else
    showSignOutButton()
  end if
End Function


Function onLinkedAccountsChange(msg)
  linkedAccounts = msg.getData()
  if linkedAccounts <> invalid AND linkedAccounts.count() > 0 then
    linkedKids = CreateObject("roSGNode", "ContentNode")
    for each accountId in linkedAccounts
      profile = linkedAccounts[accountId]
      menuItem = CreateObject("roSGNode", "ContentNode")
      if isNonEmptyString(profile.name) = true
        menuItem.title = profile.name
      else if isNonEmptyString(profile.firstName) = true
        menuItem.title = profile.firstName
      end if

      menuItem.HDPosterUrl = profile.avatarUrl
      linkedKids.appendChild(menuItem)
    end for

    m.linkedAccountsGrid.content = linkedKids

    if m.linkedAccountsLabel.getParent() = invalid
      m.linkedAccountsGroup.appendChild(m.linkedAccountsLabel)
    end if

    if m.linkedAccountsDescription.getParent() = invalid
      m.linkedAccountsGroup.appendChild(m.linkedAccountsDescription)
    end if
    m.kidsLinked = true
  else
    m.linkedAccountsGroup.removeChild(m.linkedAccountsLabel)
    m.linkedAccountsGroup.removeChild(m.linkedAccountsDescription)
    m.kidsLinked = false
  end if
End Function