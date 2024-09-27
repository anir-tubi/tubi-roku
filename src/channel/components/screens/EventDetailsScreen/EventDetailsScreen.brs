Function init()
  constants = getConstantsFromGlobal()
  topRef = m.top
  m.detailsPurpleCarpetRow = topRef.findNode("detailsPurpleCarpetRow")
  m.detailsPurpleCarpetRow.translation = [constants.ui.translations.marginX, 516]

  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  topRef.observeFieldScoped("content", "onContentChange")
  m.detailsPurpleCarpetRow.observeFieldScoped("rowItemSelected", "onRowItemSelectedChange")

  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  m.metadataTranslate = TubiMetadataTranslate(constants, experiments)

  topRef.trackingPageInfo = {
    pageType: "video_page"
    pageValues: {
      video_id: 0
    }
  }
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.detailsPurpleCarpetRow.setFocus(true)
  end if

  ' force a background update
  primaryEventContent = m.detailsPurpleCarpetRow.primaryEventContent
  if primaryEventContent <> invalid
    m.top.backgroundUriList = primaryEventContent.backgrounds
  end if
End Function


Function onContentChange(msg)
  ' Creating a clone to avoid modifying the original content node.
  content = m.top.content
  if content <> invalid
    clonedContent = m.top.content.clone(true)
    container = clonedContent.getChild(0)
    if container <> invalid
      childrens = []
      for i = 0 to container.getChildCount() - 1
        item = container.getChild(i)
        if item.id = m.top.eventId
          childrens.unshift(item)
        else
          childrens.push(item)
        end if
      end for

      container.update({
        children: childrens
      })
      m.detailsPurpleCarpetRow.content = clonedContent
      m.detailsPurpleCarpetRow.contentUpdated = true
    end if
  end if
End Function


Function onRowItemSelectedChange(msg)
  rowItemSelected = msg.getData()
  content = m.detailsPurpleCarpetRow.listContent
  if content <> invalid
    container = content.getChild(0)
    if container <> invalid AND isNonEmptyArray(rowItemSelected) = true
      itemSelected = container.getChild(rowItemSelected[1])
      if itemSelected <> invalid
        fullContent = m.metadataTranslate.getContentFromCategoryJson(container, itemSelected.id, m.top.signedIn)
        if fullContent <> invalid
          m.top.itemSelected = fullContent
        end if
      end if
    end if
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press = true AND key = "left" then
    m.top.backButtonPressed = true
  end if

  return false
End Function
