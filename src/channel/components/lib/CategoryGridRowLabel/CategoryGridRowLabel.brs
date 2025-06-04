Function init()
  tubiLog("CategoryGridRowLabel.init")
  m.CategoryName = m.top.findNode("CategoryName")
  m.SponsorPoster = m.top.findNode("SponsorPoster")
  m.SponsoredBy = m.top.findNode("SponsoredBy")
  m.SponsoredByText = m.top.findNode("SponsoredByText")
  m.SponsoredByPoster = m.top.findNode("SponsoredByPoster")
  m.subText = m.top.findNode("subText")

  m.top.observeFieldScoped("content", "onContentChange")

  '//Keep a record of what the original transitions are for certain elements in case they need to be adjusted during sponsorships and then returned back to the original transition when the component does not have a sponsorship
  m.originalTranslation_CategoryName = m.CategoryName.translation

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.subText, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.SponsoredByText, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.CategoryName, typographyConstants.ids.subheaderMedium)

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

    m.CategoryName.width = 1000
    m.subText.visible = false

    if item.subtext <> invalid AND item.subtext <> ""
      ' Purposely passing in invalid constants for each row label to avoid having to pull in constants for each row label
      authInfo = TubiAuth(invalid).getAuthInfo()
      if isLoggedInUser(authInfo) = false  'signedOut user or new user
        'recalculate the width of the rowlabel. This is required because Spanish titles might be different width than english.
        m.CategoryName.width = 0
        m.CategoryName.text = item.title
        width = m.CategoryName.boundingRect().width + 25
        m.CategoryName.width = width
        m.subText.text = item.subtext
        m.subText.height = m.CategoryName.boundingRect().height
        m.subText.vertAlign = "center"
        m.subText.translation = [width, 5]
        m.subText.visible = true
      end if
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
  end if
End Function
