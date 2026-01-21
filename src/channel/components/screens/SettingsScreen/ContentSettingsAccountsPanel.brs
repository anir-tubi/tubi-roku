Function init()
  m.top.width = 1034
  m.top.focusable = true
  m.top.hasNextPanel = true
  m.top.selectButtonMovesPanelForward = true
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("signInInfo", "onSignInInfoChange")

  m.title = m.top.findNode("Title")
  m.instructions = m.top.findNode("Instructions")
  m.contentGroup = m.top.findNode("ContentGroup")
  m.accountsList = m.top.findNode("AccountsList")
  m.constants = getConstantsFromGlobal()

  ' Set title and instructions
  m.Title.text = getTranslation("screenSettings_menu_contentSettings")
  m.Instructions.text = getTranslation("screenSettings_contentSettings_instructions")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.Instructions, typographyConstants.ids.bodyMedium)

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Title.color = theme.primaryTextColor
    m.Instructions.color = theme.primaryTextColor
    m.accountsList.focusBitmapBlendColor = theme.focusedColor
    m.accountsList.focusFootprintBlendColor = theme.neutralColor
  end if

  ' Setup MarkupGrid observers
  m.accountsList.observeFieldScoped("itemFocused", "onItemFocusChanged")
End Function


Function onComponentFocus()
  if m.top.isInFocusChain() = true
    m.accountsList.setFocus(true)
  end if
End Function


Function onSignInInfoChange(msg)
  signInInfo = msg.getData()
  if signInInfo <> invalid AND signInInfo.signedIn = true
    ' Create content node for MarkupGrid
    contentNode = CreateObject("roSGNode", "ContentNode")

    ' Add main adult profile first
    mainProfileItem = CreateObject("roSGNode", "SideNavContentNode")
    mainProfileItem.title = signInInfo.name
    if isNonEmptyString(signInInfo.name) = true
      mainProfileItem.secondaryTitle = UCase(signInInfo.name.left(1))
    end if
    if isNonEmptyString(signInInfo.avatarUrl) = true
      mainProfileItem.iconUrl = signInInfo.avatarUrl
    end if
    mainProfileItem.parentalRating = signInInfo.parentalRating
    mainProfileItem.isKidsAccount = false
    contentNode.appendChild(mainProfileItem)

    ' Add linked kids accounts
    if signInInfo.linkedAccounts <> invalid AND signInInfo.linkedAccounts.count() > 0
      for each accountId in signInInfo.linkedAccounts
        profile = signInInfo.linkedAccounts[accountId]
        menuItem = CreateObject("roSGNode", "SideNavContentNode")
        menuItem.title = profile.name
        if isNonEmptyString(profile.name) = true
          menuItem.secondaryTitle = UCase(profile.name.left(1))
        end if
        if isNonEmptyString(profile.avatarUrl) = true
          menuItem.iconUrl = profile.avatarUrl
        end if
        menuItem.isKidsAccount = true
        menuItem.id = accountId
        menuItem.parentalRating = profile.parentalRating
        contentNode.appendChild(menuItem)
      end for
    end if

    ' Set the content on the MarkupGrid
    m.accountsList.content = contentNode
  end if
End Function


Function onItemFocusChanged(msg)
  focusIndex = msg.getData()
  content = m.accountsList.content
  if content <> invalid
    focusedContent = content.getChild(focusIndex)
    if focusedContent <> invalid
      m.top.audioGuideText = focusedContent.title
      m.top.itemFocused = focusedContent
    end if
  end if
End Function

