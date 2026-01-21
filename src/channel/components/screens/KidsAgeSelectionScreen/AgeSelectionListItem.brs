Function init()
  m.posterBackground = m.top.findNode("PosterBackground")
  m.ageRatingLabel = m.top.findNode("AgeRatingLabel")
  m.ageRange = m.top.findNode("AgeRange")
  m.kidsModePoster = m.top.findNode("KidsModePoster")
  m.includedUpToLabel = m.top.findNode("IncludedUpToLabel")
  m.ratingsBadgeGroup = m.top.findNode("RatingsBadgeGroup")
  m.ratingsBadge1 = m.top.findNode("RatingsBadge1")
  m.ratingsBadge2 = m.top.findNode("RatingsBadge2")

  m.ageRatingLabel.text = getTranslation("kidsAgeSelection_ageRatingLabel")
  m.includedUpToLabel.text = getTranslation("kidsAgeSelection_includedUpToLabel")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.ageRatingLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.ageRange, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.includedUpToLabel, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.ratingsBadge1, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingsBadge2, typographyConstants.ids.bodyExtraSmallStrong)

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.ageRatingLabel.color = theme.primaryTextColor
    m.ageRange.color = theme.primaryTextColor
    m.includedUpToLabel.color = theme.primaryTextColor
    m.posterBackground.blendColor = theme.neutralColor2
    m.ratingsBadge1.backgroundColor = theme.neutralColor2
    m.ratingsBadge2.backgroundColor = theme.neutralColor2
  end if
End Function


Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid then
    m.ageRatingLabel.text = itemContent.title
    m.ageRange.text = itemContent.secondaryTitle
    m.includedUpToLabel.text = itemContent.Description
    m.kidsModePoster.uri = itemContent.HDposterUrl
    m.ratingsBadge1.text = itemContent.shortDescriptionLine1

    if itemContent.shortDescriptionLine2 <> invalid AND itemContent.shortDescriptionLine2 <> ""
      m.ratingsBadge2.text = itemContent.shortDescriptionLine2
    else if m.ratingsBadge2 <> invalid
      m.ratingsBadgeGroup.removeChild(m.ratingsBadge2)
    end if
  end if
End Function