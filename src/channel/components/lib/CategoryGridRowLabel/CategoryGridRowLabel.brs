Function init()
  tubiLog("CategoryGridRowLabel.init")
  m.ItemCount = m.top.findNode("ItemCount")
  m.FocusIndex = m.top.findNode("FocusIndex")
  m.CategoryName = m.top.findNode("CategoryName")
  m.SponsorPoster = m.top.findNode("SponsorPoster")
  m.SponsoredBy = m.top.findNode("SponsoredBy")
  m.SponsoredByText = m.top.findNode("SponsoredByText")
  m.SponsoredByPoster = m.top.findNode("SponsoredByPoster")
  m.CategoryCount = m.top.findNode("CategoryCount")
  m.subText = m.top.findNode("subText")

  m.top.observeFieldScoped("content", "onContentChange")
  m.top.observeFieldScoped("currentIndex", "onIndexChange")
  m.top.observeFieldScoped("isFullyLoaded", "onIsFullyLoaded")

  m.originalTranslation_CategoryName = m.CategoryName.translation
  m.originalTranslation_CategoryCount = m.CategoryCount.translation

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
    m.FocusIndex.color = theme.focusedColor
    m.subText.color = theme.primaryTextColor
    m.CategoryName.color = theme.primaryTextColor
  end if
End Function


' Once the poster loads, then resize it with a static height and a variable width according to the dimensions of the recently loaded image
Function onSponsorPosterLoadStatusChanged(msg)
  loadStatus = msg.GetData()
  if loadStatus = "ready"
    m.SponsoredByPoster.unobserveField("loadStatus")
    nBoundingHeight = m.SponsoredByPoster.boundingRect().height
    nBoundingWidth = m.SponsoredByPoster.boundingRect().width

    m.SponsoredByPoster.height = 32
    nWidth = (nBoundingWidth * m.SponsoredByPoster.height)/nBoundingHeight
    m.SponsoredByPoster.width = nWidth
    m.SponsoredByPoster.visible = true
  end if
End Function



Function onContentChange()
  tubiLog("CategoryGridRowLabel.onContentChange")
  item = m.top.content
  if item <> invalid
    m.CategoryName.text = item.title

    '//reset translations back to the original locations
    m.CategoryName.translation = m.originalTranslation_CategoryName
    m.CategoryCount.translation = m.originalTranslation_CategoryCount

    m.CategoryName.width = 1000
    m.subText.visible = false

    if item.subtext <> invalid AND item.subtext <> ""
      authInfo = getFieldFromGlobal("authInfo")
      if (authInfo = invalid or (authInfo <> invalid AND authInfo.userId = invalid))  'signedOut user or new user
        'recalculate the width of the rowlabel. This is required because Spanish titles might be different width than english.
        m.CategoryName.width = 0
        m.CategoryName.text = item.title
        width = m.CategoryName.boundingRect().width + 25
        m.CategoryName.width = width
        m.subText.text = item.subtext
        m.subText.translation = [width, 5]
        m.subText.visible = true
      end if
    end if

    if item.type = "channel"
      m.CategoryCount.translation = [1630,12]
    end if

    '//Display Sponsor if there is a sponsor
    if item.sponsorImages <> invalid
      '//Move/resize/display elements when there is a sponsor. If no sponsor, then hidden elements will ensure the height of the row label is varied when this component is used as the "rowTitleComponentName" in a rowlist
      '//Set the Sponsor heights here rather than the XML so it does not affect the height of a non-sponsored row label
      images = item.sponsorImages
      m.SponsoredByText.text = getTranslation("sponsor_brought_by")
      SponsoredByTextFont = m.top.findNode("SponsoredByTextFont")
      m.SponsoredByText.height = SponsoredByTextFont.size
      m.SponsoredByPoster.observeField("loadStatus", "onSponsorPosterLoadStatusChanged")
      m.SponsorPoster.uri = images.brandGraphic
      m.SponsorPoster.height = 108
      m.SponsoredByPoster.uri = images.brandLogo
      m.SponsorPoster.opacity = 1
      m.SponsoredBy.opacity = 1
      m.SponsoredBy.visible = true
      m.SponsorPoster.visible = true
      m.CategoryName.translation = [m.SponsoredBy.translation[0], 7]
      m.CategoryCount.translation = [m.CategoryCount.translation[0], 72]
      m.SponsoredBy.translation = [m.SponsoredBy.translation[0], 74]
    else
      '//reset the assets in case the label is reused for other container rows that do not have sponsorships
      m.SponsoredByPoster.unobserveField("loadStatus")
      m.SponsoredByText.height = 0
      m.SponsoredBy.visible = false
      m.SponsorPoster.visible = false
      m.SponsoredByPoster.visible = false
      m.SponsorPoster.height = 0
      m.SponsorPoster.uri = ""
      m.SponsoredByPoster.uri = ""
      m.SponsoredByPoster.height = 0
      m.SponsoredBy.translation = [m.SponsoredBy.translation[0], 0]
    end if

    drawItemCount()

    if (item.gridItemType = "linear" OR item.gridItemType = "continue_watching_signed_out_user" OR item.gridItemType = "emptyContainer") = false
      m.CategoryCount.visible = true
    else
      m.CategoryCount.visible = false
    end if

  end if
End Function


Function drawItemCount()
  cursorIndex = m.top.content.focusIndex
  if cursorIndex = invalid or cursorIndex = -1 then
    cursorIndex = 0
  end if
  if m.top.content.getChildCount() > 0
    m.ItemCount.text = " " + Chr(&hb7) + " " + stri(m.top.content.getChildCount()).trim()
    m.FocusIndex.text = stri(cursorIndex + 1).trim()
  else
    ' It's odd to see '0 of 0' so we hide the counter
    m.ItemCount.text = ""
    m.FocusIndex.text = ""
  end if
End Function


Function onIndexChange(msg)
  tubiLog("CategoryGridRowLabel.onIndexChange")
  focusIndex = msg.GetData()
  if focusIndex >= 0
    m.FocusIndex.text = stri(focusIndex + 1).trim()
  end if
End Function


Function onIsFullyLoaded(msg)
  isFullyLoaded = msg.getData()

  if m.ItemCount.text <> ""

    if isFullyLoaded = false
      m.ItemCount.text = m.ItemCount.text + "+"
    else
      countStr = m.ItemCount.text 'Not sure why directly calling replace does not work
      m.ItemCount.text = countStr.Replace("+", "")
    end if

  end if

End Function
