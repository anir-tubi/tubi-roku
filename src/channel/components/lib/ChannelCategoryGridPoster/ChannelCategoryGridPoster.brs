Function init()
  m.constants = getConstantsFromGlobal()
  m._ = rodash()
  m.poster = m.top.findNode("Poster")
  m.posterRect = m.top.findNode("PosterRect")
  m.logo = m.top.findNode("Logo")
  m.title = m.top.findNode("Title")
  m.SponsoredBy = m.top.findNode("SponsoredBy")
  m.SponsoredByText = m.top.findNode("SponsoredByText")
  m.SponsoredByPoster = m.top.findNode("SponsoredByPoster")

  if getExperimentResource("roku_rounded_corners", "roku_rounded_corners_v1", true).enabled = true
    m.poster.loadingBitmapUri="pkg:/images/placeholder-featured.webp"
    m.poster.failedBitmapUri="pkg:/images/placeholder-featured.webp"
  end if

  m.top.observeField("itemContent", "onContentChange")
  m.logo.observeField("loadStatus", "onLogoLoad")
  ' used to keep track of if the grid has focus or not, onGridFocusChange fires every time any focus changes including
  ' scrolling between tiles.
  m.gridIsFocused = false

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.SponsoredByText, typographyConstants.ids.bodySmall)

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
    m.PosterRect.color = theme.neutralColor2
    m.Title.color = theme.primaryTextColor
    m.SponsoredByText.color = theme.backgroundColorLight2
  end if
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(data)
  tubiLog("ChannelCategoryGridPoster.onContentChange " + data.getField())

  ' set some defaults
  m.title.visible = false
  m.SponsoredBy.visible = false

  if m.top.itemContent <> invalid then
    thumbnail = invalid
    if m.top.itemContent.sponsorImages <> invalid
      '//If this tile is sponsored, then display the appropriate images
      if m.top.itemContent.sponsorImages.tileBackground <> ""
        thumbnail = m.top.itemContent.sponsorImages.tileBackground
      end if

      if m.top.itemContent.sponsorImages.brandLogo <> ""
        m.SponsoredBy.visible = true
        m.SponsoredByText.text = getTranslation("sponsor_brought_by")
        m.SponsoredByPoster.observeField("loadStatus", "onSponsorPosterLoadStatusChanged")
        m.SponsoredByPoster.uri = m.top.itemContent.sponsorImages.brandLogo
      end if
    end if
    if thumbnail <> invalid
      m.poster.visible = true
      m.posterRect.visible = false
      m.poster.uri = thumbnail
    else
      m.posterRect.width = m.top.width
      m.posterRect.height = m.top.height
      m.posterRect.visible = true
      m.poster.visible = false
    end if

    categoryContent = m.top.itemContent.getParent()
    if categoryContent <> invalid then
        if m.top.itemContent.logouri <> invalid AND m.top.itemContent.logouri <> ""
          m.logo.uri = m.constants.urls.channelLogoBrandedPrefix + m.top.itemContent.id + m.constants.urls.channelLogoBrandedSuffix
        else
          displayTitle()
        end if
    end if
    setTranslations()
  end if
End Function


Function setTranslations()
  nXLogo = (m.top.width - m.logo.width)/2
  nYLogo = (m.top.height - m.logo.height)/2
  m.logo.translation = [nXLogo, nYLogo]

  nTitleWidth = m.top.width * .9
  nXTitle = (m.top.width - nTitleWidth)/2
  nYTitle = (m.top.height - m.title.boundingRect().height)/2
  m.title.width = nTitleWidth
  m.title.translation = [nXTitle, nYTitle]
End Function


' Once the poster loads, then resize it with a static height and a variable width according to the dimensions of the recently loaded image
Function onSponsorPosterLoadStatusChanged(msg)
  loadStatus = msg.GetData()
  if loadStatus = "ready"
    m.SponsoredByPoster.unobserveField("loadStatus")
    nBoundingHeight = m.SponsoredByPoster.boundingRect().height
    nBoundingWidth = m.SponsoredByPoster.boundingRect().width

    nMaxWidth = 150
    nMaxHeight = 30
    nHeight = nMaxHeight
    nWidth = (nBoundingWidth * nHeight)/nBoundingHeight
    if nWidth > nMaxWidth
      '//ensure the image isn't too wide
      nWidth = nMaxWidth
      nHeight = (nBoundingHeight * nWidth)/nBoundingWidth
      m.SponsoredByPoster.height = nHeight
    end if

    m.SponsoredByPoster.height = nHeight
    m.SponsoredByPoster.width = nWidth
    m.SponsoredByPoster.visible = true

    '//center sponsor text and icon
    nSponsorWidth = m.SponsoredByText.boundingRect().width + m.SponsoredBy.itemSpacings[0] + m.SponsoredByPoster.width
    nXSponsor = (m.top.width - nSponsorWidth)/2
    nYSponsor = m.top.height * .79
    m.SponsoredBy.translation = [nXSponsor, nYSponsor]
  end if
End Function


Function onLogoLoad()
  if m.logo.loadStatus = "failed"
    '//If the logo fails to load, then display the title as a failsafe
    displayTitle()
  end if
End Function


Function displayTitle()
  m.title.visible = true
  m.title.text = m.top.itemContent.title
End Function
