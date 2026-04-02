' HubRowLockup - Lockup component for hub row display
' Shows hub logo, title, synopsis, and an explore button.
' All values are read from a single itemContent node.


' Initializes the HubRowLockup component, caches node references, and sets up observers
Function init() as Void
  topRef = m.top

  m.hubLogo = topRef.findNode("hubLogo")
  m.hubLogoRectangle = topRef.findNode("hubLogoRectangle")
  m.hubTitleLabel = topRef.findNode("hubTitleLabel")
  m.hubSynopsisLabel = topRef.findNode("hubSynopsisLabel")
  m.exploreButton = topRef.findNode("exploreButton")
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.hubTitleLabel, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.hubSynopsisLabel, typographyConstants.ids.bodyMedium)

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "onFocusChange")
  topRef.observeFieldScoped("rowHasFocus", "onFocusChange")
  m.exploreButton.observeFieldScoped("wasSelected", "onButtonSelected")
  m.hubLogo.observeFieldScoped("loadStatus", "onHubLogoLoaded")

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()
End Function


' Handles theme changes and applies colors to labels
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme = invalid then return

  m.hubTitleLabel.color = theme.primaryTextColor
  m.hubSynopsisLabel.color = theme.primaryTextColor
End Function


' Reads hub logo, title, synopsis, button text, and accent color from itemContent
Function onItemContentChange(msg = invalid) as Void
  itemContent = m.top.itemContent
  if itemContent = invalid then return

  container = itemContent.getParent()
  if container <> invalid AND container.hasField("hubLockupAd")
    container.observeFieldScoped("hubLockupAd", "onHubLockupAdChange")
  end if

  if container <> invalid AND container.hubLockupAd <> invalid AND isNonEmptyString(container.hubLockupAd.logoUri)
    m.hubLogo.uri = container.hubLockupAd.logoUri
  else if isNonEmptyString(itemContent.titleArt)
    m.hubLogo.uri = itemContent.titleArt
  end if

  if isNonEmptyString(itemContent.hubTitle)
    m.hubTitleLabel.text = itemContent.hubTitle
  end if

  if isNonEmptyString(itemContent.hubSynopsis)
    m.hubSynopsisLabel.text = itemContent.hubSynopsis
  end if

  if isNonEmptyString(itemContent.buttonText)
    buttonContent = CreateObject("roSGNode", "ContentNode")
    buttonContent.update({
      title: itemContent.buttonText
      isPrimaryButton: true
    }, true)
    m.exploreButton.itemContent = buttonContent
  end if

  if isNonEmptyString(itemContent.accentColor)
    m.exploreButton.backgroundBlendColor = itemContent.accentColor
  end if

  ' This handles the use case where the component re-created.
  onFocusChange()
End Function


' Updates the hub logo when the container's hubLockupAd field changes
Function onHubLockupAdChange(msg) as Void
  hubLockupAd = msg.getData()
  if hubLockupAd <> invalid AND isNonEmptyString(hubLockupAd.logoUri)
    m.hubLogo.uri = hubLockupAd.logoUri
  end if
End Function


' Bottom-aligns the hub logo within its Rectangle after the image loads
Function onHubLogoLoaded(msg) as Void
  if msg.getData() <> "ready" then return

  logoRect = m.hubLogo.boundingRect()
  rectHeight = m.hubLogoRectangle.height
  if logoRect.height > 0 AND logoRect.height < rectHeight
    m.hubLogo.translation = [0, rectHeight - logoRect.height]
  else
    m.hubLogo.translation = [0, 0]
  end if
End Function


' Shows/hides the explore button and updates its focus state
' Button is visible only when this item has focus, or when the row is not focused
Function onFocusChange(msg = invalid) as Void
  focusPercent = m.top.focusPercent
  if focusPercent <> 0 AND focusPercent <> 1 then return

  itemHasFocus = (focusPercent = 1)
  rowHasFocus = m.top.rowHasFocus

  m.exploreButton.itemHasFocus = itemHasFocus
  m.exploreButton.visible = (itemHasFocus = true OR rowHasFocus = false)

End Function


' Forwards button selection event to the parent
Function onButtonSelected(msg) as Void
  m.top.wasSelected = true
End Function
