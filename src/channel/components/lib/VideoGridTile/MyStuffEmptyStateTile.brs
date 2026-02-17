' Initializes the MyStuffEmptyStateTile component
' Displays sign-up prompt with selling points and action button
Function init() as Void
  topRef = m.top
  m.border = topRef.findNode("border")
  m.metadataGroup = topRef.findNode("metadataGroup")
  m.title = topRef.findNode("title")
  m.description = topRef.findNode("description")
  m.sellingPointsGroup = topRef.findNode("sellingPointsGroup")
  m.noSubscriptionLabel = topRef.findNode("noSubscriptionLabel")
  m.noCreditCardLabel = topRef.findNode("noCreditCardLabel")
  m.freeForeverLabel = topRef.findNode("freeForeverLabel")
  m.signUpButton = topRef.findNode("signUpButton")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowListHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("width", "adjustContentAlignment")
  topRef.observeFieldScoped("height", "adjustContentAlignment")

  ' Set text using translations
  m.title.text = getTranslation("metadata_continueWatching_notSignedIn_title")
  m.description.text = getTranslation("metadata_continueWatching_notSignedIn_description")
  m.noSubscriptionLabel.text = getTranslation("guest_tile_no_subscription")
  m.noCreditCardLabel.text = getTranslation("guest_tile_no_credit_card")
  m.freeForeverLabel.text = getTranslation("guest_tile_free_forever")

  ' Set up action button
  buttonContent = CreateObject("roSGNode", "ContentNode")
  buttonContent.update({
    title: getTranslation("metadata_continueWatching_notSignedIn_container_button")
    badgeText: getTranslation("registration_signup_button_free")
    isPrimaryButton: true
  }, true)
  m.signUpButton.itemContent = buttonContent

  ' Set typography
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.headerSmall, { lineSpacing: 1 })
  setTypographyOfLabel(m.description, typographyConstants.ids.bodyMedium, { lineSpacing: 2 })
  setTypographyOfLabel(m.noSubscriptionLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.noCreditCardLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.freeForeverLabel, typographyConstants.ids.bodyMedium)

  ' Set up theme observer
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and applies colors to UI elements
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    ' Selling point labels use reduced opacity white for visual hierarchy
    m.noSubscriptionLabel.color = "0xFFFFFF80"
    m.noCreditCardLabel.color = "0xFFFFFFBF"
    m.freeForeverLabel.color = theme.primaryTextColor
    m.focusedColor = theme.focusedColor
    m.neutralColor2 = theme.neutralColor2
    m.border.blendColor = m.neutralColor2
  end if
End Function


' Handles content updates when itemContent field changes
' Overrides default text with content node data when available
' Hides selling points when showSellingPoints is not true
Function onItemContentChange() as Void
  itemContent = m.top.itemContent
  if itemContent <> invalid
    if isNonEmptyString(itemContent.title) = true
      m.title.text = itemContent.title
    end if
    if isNonEmptyString(itemContent.description) = true
      m.description.text = itemContent.description
    end if
    if isNonEmptyString(itemContent.buttonText) = true
      buttonContent = m.signUpButton.itemContent
      if buttonContent <> invalid
        buttonContent.title = itemContent.buttonText
        ' Hide badge when not provided
        if isNonEmptyString(itemContent.badgeText) = false
          buttonContent.badgeText = ""
        end if
      end if
    end if
    ' Hide selling points for logged-in users
    m.sellingPointsGroup.visible = (itemContent.isSignedIn <> true)
    adjustContentAlignment()
  end if
End Function


' Adjusts content alignment based on tile dimensions
' Positions metadata left, selling points between metadata and button, button right
Function adjustContentAlignment() as Void
  if m.top.width > 0 AND m.top.height > 0
    tileWidth = m.top.width
    tileHeight = m.top.height
    padding = 66
    metadataWidth = m.description.width

    ' Vertically center the metadata group on the left
    metadataHeight = m.metadataGroup.boundingRect().height
    m.metadataGroup.translation = [padding, (tileHeight - metadataHeight) / 2]

    ' Position button on the right side, vertically centered
    boundingRect = m.signUpButton.boundingRect()
    buttonWidth = boundingRect.width
    buttonHeight = boundingRect.height
    buttonX = tileWidth - padding - buttonWidth
    buttonY = (tileHeight - buttonHeight) / 2
    m.signUpButton.translation = [buttonX, buttonY]

    ' Center selling points in the gap between metadata and button (when visible)
    if m.sellingPointsGroup.visible = true
      metadataEndX = padding + metadataWidth + 132 ' gap between metadata and selling points
      boundingRect = m.sellingPointsGroup.boundingRect()
      sellingPointsWidth = boundingRect.width
      sellingPointsHeight = boundingRect.height
      sellingPointsX = metadataEndX + (buttonX - metadataEndX - sellingPointsWidth) / 2
      sellingPointsY = (tileHeight - sellingPointsHeight) / 2
      m.sellingPointsGroup.translation = [sellingPointsX, sellingPointsY]
    end if
  end if
End Function


' Handles focus state changes for the tile
' Updates border color and button focus state
Function onItemHasFocusChange(_msg) as Void
  itemHasFocus = ((m.top.rowHasFocus = true OR m.top.itemHasFocus = true) AND m.top.rowListHasFocus = true)
  m.signUpButton.itemHasFocus = itemHasFocus
  if itemHasFocus = true
    m.border.blendColor = m.focusedColor
  else
    m.border.blendColor = m.neutralColor2
  end if
End Function
