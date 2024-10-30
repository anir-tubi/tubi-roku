Function init()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)

  m.relatedContentGroup = m.top.findNode("RelatedContentGroup")
  m.RelatedTitle = m.top.findNode("RelatedTitle")
  m.ymalMovieList = m.top.findNode("YMALMovieList")
  m.ymalMovieList.itemSize = m.constants.ui.imageSizes.largePoster

  ymalMovieRowLabelContent = m.top.findNode("ymalMovieRowLabelContent")
  ymalMovieRowLabelContent.title = getTranslation("screenDetails_relatedTitles")

  m.ymalMovieList.observeFieldScoped("itemSelected", "onRelatedContentSelected")
  m.ymalMovieList.observeFieldScoped("itemFocused", "onRelatedItemFocused")

  m.top.observeFieldScoped("updateContent", "onContentUpdated")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.currentFocusedIndex = 0

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.RelatedTitle, typographyConstants.ids.bodyMedium)

  'Since movie ymal page is overlay over detail page, we still need to send events for video_page
  m.top.trackingPageInfo = {
    pageType: "video_page"
    pageValues: {
      video_id: 0
    }
  }
End function


Function onContentUpdated()
  relatedContent = m.top.content

  if relatedContent <> invalid
    m.ymalMovieList.content = relatedContent

    ' To force a single row in postergrid, set the columns
    m.ymalMovieList.numColumns = relatedContent.getChildCount()
    m.ymalMovieList.jumpToItem = m.ymalMovieList.itemFocused
  end if
End Function


Function onScreenFocusChange()
  if m.top.isInFocusChain() = true
    m.ymalMovieList.setFocus(true)
  end if

End Function


Function onRelatedContentSelected(msg)
  itemSelected = msg.getData()
  selectedContent = m.ymalMovieList.content.getChild(itemSelected)
  handleRelatedContentSelected(selectedContent, itemSelected)
End Function


' @selectedContent: roSGNode, ContentNode that was selected from the ymalMovieList
' @postion: integer, the horizontal position of the content in the ymalMovieList
Function handleRelatedContentSelected(selectedContent, position)

  if selectedContent <> invalid AND position <> invalid AND position > -1
    'set the component info so it can be used in navigate_to_page event
    col = position + 1
    row = 1
    m.top.trackingComponentInfo = {
      componentType: "related_component"
      componentValues: {
        content_tile: m.Tracking.getAnalyticsTile(selectedContent, col, row)
      }
    }

    m.top.relatedContentSelected = position
  end if
End Function


Function onRelatedItemFocused(msg)
  tubiLog("DetailScreen.onRelatedItemFocused")

  itemFocused = msg.getData()

  if m.ymalMovieList.content <> invalid
    focusedContent = m.ymalMovieList.content.getChild(itemFocused)

    if focusedContent <> invalid
      m.RelatedTitle.text = focusedContent.title

      m.top.relatedContentFocused = focusedContent

      sendNavigateWithInPageEvent(focusedContent, itemFocused)
    end if
  end if
End Function


' @focusedContent: roSGNode, ContentNode that is currently focused in the ymalMovieList
' @itemFocused: integer, the horizontal position of the content in the ymalMovieList
Function sendNavigateWithinPageEvent(focusedContent, itemFocused)

  if focusedContent <> invalid AND itemFocused <> invalid AND itemFocused > -1
    col = itemFocused + 1
    row = 1
    contentId = focusedContent.id

    ' trigger navigate_within_page events in ContentController
    if m.currentFocusedIndex <> itemFocused

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage("video_page", {"video_id": contentId })
        componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.oldYmalComponent)
        means_of_navigation: "SCROLL" 'MeansOfNavigation enum
        vertical_location: row '1 based index
        horizontal_location: col
      }

      m.oldYmalComponent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
      }
      m.currentFocusedIndex = itemFocused
    else
      m.oldYmalComponent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
      }
    end if
  end if
End Function
