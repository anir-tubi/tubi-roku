Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.playerFullscreenCountdownTimer = topRef.findNode("PlayerFullscreenCountdownTimer")
  m.countdownGroup = topRef.findNode("CountdownGroup")
  m.adIndicator = topRef.findNode("AdIndicator")
  m.infoPanel = topRef.findNode("InfoPanel")
  m.infoPanelGroup = topRef.findNode("infoPanelGroup")
  m.rowList = topRef.findNode("rowList")
  m.rowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")
  m.rowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  topRef.observeFieldScoped("contentUpdated", "onContentChange")
  topRef.observeFieldScoped("focusedChild", "onComponentFocusChange")
  m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")
  m.countdownGroup.seconds = m.constants.timers.skinAdTimeout

  typographyConstants = getTypographyConstants()
  m.countdownGroup.typographyLabelId = typographyConstants.ids.bodyExtraSmallStrong
  setTypographyOfLabel(m.adIndicator, typographyConstants.ids.bodyExtraSmallStrong)

  m.adIndicator.text = getTranslation("ad")

  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)

  ' Holds the value of last focused column in the row. This is used to determine if user is scrolling within the row.
  m.lastFocusedColumn = -1
  ' Holds the value of of user scroll direction within the the row. Possible values are "", "right", "left".
  m.scrollDirection = ""

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
    m.RowList.focusBitmapBlendColor = theme.focusedColor
    m.countdownGroup.bgcolor = theme.shadeColor3
    m.adIndicator.fontColor = theme.backgroundColor
  end if
End Function


Function onComponentFocusChange()
  if m.top.hasFocus() = true
    m.rowList.setFocus(true)
  end if

  if m.countdownGroup.seconds > 0
    if m.rowList.hasFocus() = true
      '//reset the timer whenever the row regains focus
      m.countdownGroup.seconds = m.constants.timers.skinAdTimeout

      ' If the countdown is still active and the row is in focus, then continue to countdown
      m.infoPanelGroup.opacity = 1
      m.playerFullscreenCountdownTimer.control = "start"
    else
      m.playerFullscreenCountdownTimer.control = "stop"
    end if
  end if
End Function


Function onContentChange()
  if m.top.content <> invalid then
    thumbnailSize = m.constants.ui.imageSizes.skinAdLandscape
    posterHeight = thumbnailSize[1]
    m.rowList.update({
      "itemSize": [1752, posterHeight]
      "rowItemSize": [thumbnailSize]
      "rowHeights": [posterHeight]
      "showRowLabel": [false]
      "numRows": 1
      "rowItemSpacing": [[15, 0]]
    })
    m.rowList.content = m.top.content

    if m.top.hasFocus() = false
      m.top.reloadedItemToBeFocused = getFocusedItemContent()
      ' Below code covers the case where we need to refresh the info panel when the user switches between kids and adults during which focus is on menu.
      ' But all the content in home screen has been updated.
      if m.top.reloadedItemToBeFocused <> invalid
        updateInfoPanel()
      end if
    end if
  else
    '//if there is no content, then reset the rowlist
    m.rowList.content = invalid
  end if
End Function


Function getFocusedItemContent()
  tubiLog("SkinAdRow.getFocusedItemContent")
  rowItemIndex = m.rowList.rowItemFocused
  content = m.top.content
  itemFocused = invalid
  if content <> invalid AND rowItemIndex[0] <> invalid AND rowItemIndex[1] <> invalid
    category = content.getChild(rowItemIndex[0])
    if category <> invalid
      videoContent = category.getChild(rowItemIndex[1])
      if videoContent <> invalid
        itemFocused = videoContent
      end if
    end if
  end if

  return itemFocused
End Function


Function onRowItemFocused(msg)
  tubiLog("SkinAdRow.onRowItemFocused")
  updateInfoPanel()
End Function


Function onFullscreenCountdown()
  tubiLog("SkinAdRow.onFullscreenCountdown")

  nCurrentCount = m.countdownGroup.seconds
  nNewCount = nCurrentCount - 1
  if nNewCount <= 0
    selectVideoItem()
  else
    m.countdownGroup.seconds = nNewCount
    m.countdownGroup.display = true
  end if
End Function


Function onRowItemSelected(msg)
  tubiLog("SkinAdRow.onRowItemSelected")
  selectVideoItem()
End function


Function selectVideoItem()
  tubiLog("SkinAdRow.selectVideoItem")
  if m.playerFullscreenCountdownTimer.control = "start"
    m.countdownGroup.seconds = 0  'set seconds to 0 so timer does not start again after selection
    m.playerFullscreenCountdownTimer.control = "stop"
    m.countdownGroup.secondsTranslationId = "metadata_watch_again"
    m.countdownGroup.translation = [1425, m.countdownGroup.translation[1]]  '//move the countdown to the right after the text is changed
  end if
  m.top.rowItemSelected = m.rowList.rowItemFocused
End Function


Function updateInfoPanel()
  tubiLog("SkinAdRow.updateInfoPanel")
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
        end if
      end if
    end if
  end if

  m.top.rowItemFocused = rowItemFocused
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(contentNode) 
  tubiLog("SkinAdRow.populateInfoPanel")
  if contentNode <> invalid
    m.infoPanel.content = contentNode 
  end if
End Function