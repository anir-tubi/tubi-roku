Function init()
  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  topRef = m.top
  topRef.observeField("fullscreenCountdown", "onFullscreenCountdown")

  m.spotlightGroup = topRef.findNode("spotlightGroup")
  m.spotlightInfoPanel = topRef.findNode("InfoPanel")
  m.SpotlightDetailsBtnGroup = topRef.findNode("SpotlightDetailsBtnGroup")
  m.infoPanelGroup = topRef.findNode("infoPanelGroup")
  m.spotlightDetailsBtn = topRef.findNode("SpotlightDetailsBtn")
  m.videoPreviewProgressBar = topRef.findNode("videoPreviewProgressBar")
  m.videoPreviewProgressGroup = topRef.findNode("videoPreviewProgressGroup")
  m.spotlightDetailsBtnFocused = topRef.findNode("spotlightDetailsBtnFocused")
  m.rowList = topRef.findNode("rowList")
  m.rowList.observeFieldScoped("rowItemFocused", "onSpotlightRowItemFocused")
  m.rowList.observeFieldScoped("currFocusColumn", "onSpotlightCurrFocusColumnChange")
  topRef.observeFieldScoped("videoPreviewProgress", "onVideoPreviewProgressChange")
  topRef.observeFieldScoped("contentUpdated", "onSpotlightContentChange")
  topRef.observeField("focusedChild", "onComponentFocusChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.spotlightDetailsBtn, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.spotlightDetailsBtnFocused, typographyConstants.ids.bodyMediumStrong)

  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)

  ' Holds the value of last focused column in spotlight row. This is used to determine if user is scrolling within the spotlight row.
  m.lastSpotlightFocusedColumn = -1
  ' Holds the value of of user scroll direction within the spotlight row. Possible values are "", "right", "left".
  m.spotlightScrollDirection = ""

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.spotlightDetailsBtn.fontColor = theme.neutralColor
    m.spotlightDetailsBtn.iconColor = theme.neutralColor
    m.spotlightDetailsBtnFocused.fontColor = theme.backgroundColor
    m.spotlightDetailsBtnFocused.iconColor = theme.backgroundColor
    m.spotlightDetailsBtn.blendColor = theme.neutralColor
    m.spotlightDetailsBtnFocused.blendColor = theme.focusedColor
    m.videoPreviewProgressBar.focusColor = theme.focusedColor
    m.videoPreviewProgressBar.trackColor = theme.neutralColor
    m.videoPreviewProgressBar.unfocusColor = theme.focusedColor
  end if
End Function


Function onComponentFocusChange()
  if m.top.hasFocus() = true
    m.rowList.setFocus(true)
  end if

  ' This method only gets triggered when we the focus changes within the component and not when user scrolls through the rowlist.
  ' This handles showing unfocused details button when we move focus to menu.
  if m.rowList.hasFocus() = true
    m.infoPanelGroup.opacity = 1
    m.spotlightDetailsBtnFocused.visible = true
  else
    m.spotlightDetailsBtnFocused.visible = false
  end if
End Function


Function onSpotlightContentChange()
  if m.top.content <> invalid then
    spotlightLandscapeSize = m.constants.ui.imageSizes.spotlightLandscape
    posterHeight = spotlightLandscapeSize[1]
    m.rowList.update({
      "itemSize": [1752, posterHeight]
      "rowItemSize": [spotlightLandscapeSize]
      "rowHeights": [posterHeight]
      "showRowLabel": [false]
      "numRows": 1
      "rowItemSpacing": [[15, 0]]
      "focusXOffset" : [267]
    })
    m.rowList.content = m.top.content

    if m.top.hasFocus() = false
      m.top.reloadedItemToBeFocused = getFocusedItemContent()
      ' Below code covers the case where we need to refresh the info panel when the user switches between kids and adults during which focus is on menu.
      ' But all the content in home screen has been updated.
      if m.top.reloadedItemToBeFocused <> invalid
        updateSpotlightInfoPanel(false)
      end if
    end if
  end if
End Function


Function getFocusedItemContent()
  rowItemIndex = m.rowList.rowItemFocused
  content = m.top.content
  itemFocused = invalid
  if content <> invalid AND rowItemIndex[0] <> invalid AND rowItemIndex[1] <> invalid
    category = content.getChild(rowItemIndex[0])
    if category <> invalid
      content = category.getChild(rowItemIndex[1])
      if content <> invalid
        itemFocused = m.metadataTranslate.getContentFromCategoryJson(category, content.id, m.top.signedIn)
        itemFocused.gridItemType = m.constants.ui.gridItemTypes.spotlight
      end if
    end if
  end if

  return itemFocused
End Function


' @sTextID: string, id associated with the desired translation string.
Function setSpotlightDetailsBtnText(sTextID)
  sButtonIcon = ""

  if sTextID = "screenHome_button_spotlight_watch_live"
    sButtonIcon = "pkg:/images/live-icon.webp"
  end if

  m.spotlightDetailsBtn.text = getTranslation(sTextID)
  m.spotlightDetailsBtnFocused.text = getTranslation(sTextID)
  m.spotlightDetailsBtn.iconUri = sButtonIcon
  m.spotlightDetailsBtnFocused.iconUri = sButtonIcon
End Function


Function onSpotlightRowItemFocused(msg)
  rowItemFocused = msg.getData()
  focusedItemIndex = rowItemFocused[1]
  if focusedItemIndex <> m.lastSpotlightFocusedColumn
    m.spotlightScrollDirection = "right"
    if focusedItemIndex < m.lastSpotlightFocusedColumn
      m.spotlightScrollDirection = "left"
    end if

    if m.spotlightScrollDirection = "right"
      slideFade(m.infoPanelGroup, "left", "out", 0.2)
    else
      slideFade(m.infoPanelGroup, "right", "out", 0.2)
    end if

    m.infoPanelGroup.unobserveFieldScoped("opacity")
    m.infoPanelGroup.observeFieldScoped("opacity", "onSpotlightInfoPanelOpacityChange")
    m.lastSpotlightFocusedColumn = focusedItemIndex
  else
    updateSpotlightInfoPanel(false)
  end if
End Function


Function onSpotlightInfoPanelOpacityChange(msg)
  if msg.getData() = 0
    updateSpotlightInfoPanel(true)
  end if
End Function


Function updateSpotlightInfoPanel(shouldAnimate)
  rowItemFocused = m.rowList.rowItemFocused
  content = m.top.content

  if content <> invalid
    category = content.getChild(rowItemFocused[0])
    if category <> invalid then
      content = category.getChild(rowItemFocused[1])
      if content <> invalid
        itemFocused = getFocusedItemContent()
        if itemFocused <> invalid
          populateInfoPanel(itemFocused)
          if shouldAnimate = true
            if m.spotlightScrollDirection = "right"
              slideFade(m.infoPanelGroup, "right", "in", 0.2)
            else
              slideFade(m.infoPanelGroup, "left", "in", 0.2)
            end if
          end if
        end if
      end if
    end if
  end if

  m.top.rowItemFocused = rowItemFocused
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(contentNode)
  if contentNode <> invalid
    sType = contentNode.type
    if sType = m.constants.ui.categoryTypes.linear
      populateInfoPanelWithLinearProgramHomescreenMode(contentNode, m.spotlightInfoPanel, true) 'V4 api
      currentProgram = getCurrentLiveProgram(contentNode)
      
      if currentProgram <> invalid AND currentProgram.live = true
        setSpotlightDetailsBtnText("screenHome_button_spotlight_watch_live")
      else
        setSpotlightDetailsBtnText("screenHome_button_spotlight_watch_now")
      end if
    else if sType = m.constants.ui.contentTypes.sportsEvent
      populateInfoPanelWithHomescreenStyleSportsMode(contentNode, m.spotlightInfoPanel, true)
      currentProgram = getCurrentLiveProgram(contentNode)

      if currentProgram <> invalid AND currentProgram.live = true
        setSpotlightDetailsBtnText("screenHome_button_spotlight_watch_live")
      else
        setSpotlightDetailsBtnText("screenHome_button_spotlight_watch_now")
      end if

    else
      populateInfoPanelWithHomescreenStyleItemMode(contentNode, m.spotlightInfoPanel, true)

      setSpotlightDetailsBtnText("screenHome_button_spotlight_details")
    end if    
  end if
End Function


Function onVideoPreviewProgressChange(msg)
  if m.top.videoPreviewProgress > 0
    m.videoPreviewProgressGroup.visible = true
  else
    m.videoPreviewProgressGroup.visible = false
  end if
End Function


Function onSpotlightCurrFocusColumnChange()
  m.videoPreviewProgressGroup.visible = false
  m.videoPreviewProgressBar.progress = 0
End Function


Function onFullscreenCountdown(msg)
  if m.rowList.hasFocus() = true
    m.spotlightInfoPanel.fullscreenCountdown = msg.getData()
  end if
End Function

