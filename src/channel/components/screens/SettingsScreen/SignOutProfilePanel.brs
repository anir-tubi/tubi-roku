Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.avatar = topRef.findNode("Avatar")
  m.name = topRef.findNode("Name")
  m.email = topRef.findNode("Email")
  m.offset = topRef.findNode("Offset")
  m.signOutBtnGroup = topRef.findNode("SignOutButtonLayoutGroup")
  m.nameEmailGroup = topRef.findNode("NameEmailGroup")
  m.tubiKidsLogo = topRef.findNode("TubiKidsLogo")
  m.linkedAccountsGroup = topRef.findNode("LinkedAccountsGroup")
  m.linkedAccountsLabel = topRef.findNode("LinkedAccountsLabel")
  m.linkedAccountsDescription = topRef.findNode("LinkedAccountsDescription")
  m.linkedAccountsGrid = topRef.findNode("LinkedAccountsGrid")
  m.manageTitle = topRef.findNode("ManageTitle")
  m.description = topRef.findNode("Description")
  m.QRCodeUrlString = topRef.findNode("QRCodeUrlString")
  m.signOutButton = topRef.findNode("SignOutButton")
  m.signOutButton.enabled = false

  topRef.observeFieldScoped("linkedAccounts", "onLinkedAccountsChange")
  topRef.observeFieldScoped("removeKidsSignOutBtn", "onRemoveKidsSignOutBtnChange")
  topRef.observeFieldScoped("focusedChild", "onFocusedChildChange")
  topRef.observeFieldScoped("parentalRating", "onParentalRatingChange")

  typographyConstants = getTypographyConstants()

  setTypographyOfLabel(m.name, typographyConstants.ids.bodyLargeStrong, { fontSize: 34 })
  setTypographyOfLabel(m.email, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.manageTitle, typographyConstants.ids.headerSmall, { fontSize: 48 })
  setTypographyOfLabel(m.description, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.QRCodeUrlString, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.linkedAccountsLabel, typographyConstants.ids.headerSmall, { fontSize: 48 })
  setTypographyOfLabel(m.linkedAccountsDescription, typographyConstants.ids.bodyMedium)
  m.avatar.textFont = typographyConstants.ids.displayMedium

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.name.color = theme.primaryTextColor
    m.email.color = theme.secondaryTextColor
    m.manageTitle.color = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    m.QRCodeUrlString.color = theme.primaryTextColor
    m.linkedAccountsLabel.color = theme.primaryTextColor
    m.linkedAccountsDescription.color = theme.primaryTextColor
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
  else
    m.linkedAccountsGroup.removeChild(m.linkedAccountsLabel)
    m.linkedAccountsGroup.removeChild(m.linkedAccountsDescription)
  end if
End Function
