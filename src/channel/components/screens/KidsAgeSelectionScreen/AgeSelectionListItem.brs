Function init()
  m.posterBackground = m.top.findNode("PosterBackground")
  m.ageRatingLabel = m.top.findNode("AgeRatingLabel")
  m.ageRange = m.top.findNode("AgeRange")
  m.kidsModePoster = m.top.findNode("KidsModePoster")
  m.includedUpToLabel = m.top.findNode("IncludedUpToLabel")
  m.ratingsBadgeGroup = m.top.findNode("RatingsBadgeGroup")
  m.ratingsBadge1 = m.top.findNode("RatingsBadge1")
  m.ratingsBadge2 = m.top.findNode("RatingsBadge2")
  m.ratingsBadge3 = m.top.findNode("RatingsBadge3")
  m.ratingsBadge4 = m.top.findNode("RatingsBadge4")
  m.ratingsBadge5 = m.top.findNode("RatingsBadge5")
  m.ratingsBadgeGroup1 = m.top.findNode("RatingsBadgeGroup1")
  m.ratingsBadgeGroup2 = m.top.findNode("RatingsBadgeGroup2")
  m.ratingsBadgeGroup3 = m.top.findNode("RatingsBadgeGroup3")
  m.includedUpToLabelGroup = m.top.findNode("IncludedUpToLabelGroup")
  m.AgeSelectionListItemGroup = m.top.findNode("AgeSelectionListItemGroup")

  m.ageRatingLabel.text = getTranslation("kidsAgeSelection_ageRatingLabel")
  m.includedUpToLabel.text = getTranslation("kidsAgeSelection_includedUpToLabel")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.ageRatingLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.ageRange, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.includedUpToLabel, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.ratingsBadge1, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingsBadge2, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingsBadge3, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingsBadge4, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingsBadge5, typographyConstants.ids.bodyExtraSmallStrong)

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
    m.ratingsBadge3.backgroundColor = theme.neutralColor2
    m.ratingsBadge4.backgroundColor = theme.neutralColor2
    m.ratingsBadge5.backgroundColor = theme.neutralColor2
  end if
End Function


Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid then
    m.ageRatingLabel.text = itemContent.title
    m.ageRange.text = itemContent.secondaryTitle
    if itemContent.Description <> invalid AND itemContent.Description <> ""
      isUptoParent = (m.includedUpToLabel.getParent() <> invalid)
      if isUptoParent = false
        m.includedUpToLabelGroup.appendChild(m.includedUpToLabel)
      end if
      m.includedUpToLabel.text = itemContent.Description
    else
      m.includedUpToLabelGroup.removeChild(m.includedUpToLabel)
    end if

    m.kidsModePoster.uri = itemContent.HDposterUrl
    if itemContent.shortDescriptionLine1 <> invalid AND itemContent.shortDescriptionLine1 <> ""
      badges = itemContent.shortDescriptionLine1.split(" | ")

      if itemContent.secondaryTitle = "1-3"
        m.ratingsBadge1.text = badges[0]
        m.ratingsBadge2.visible = false
        m.ratingsBadge3.visible = false
        m.ratingsBadge4.visible = false
        m.ratingsBadge5.visible = false
      else if itemContent.secondaryTitle = "4-6"
        m.ratingsBadge1.text = badges[0]
        m.ratingsBadge2.text = badges[1]
        m.ratingsBadge3.text = badges[2]
        m.ratingsBadge4.visible = false
        m.ratingsBadge5.visible = false
      else if itemContent.secondaryTitle = "7-9"
        m.ratingsBadge1.text = badges[0]
        m.ratingsBadge2.text = badges[1]
        m.ratingsBadge3.text = badges[2]
        m.ratingsBadge4.text = badges[3]
        m.ratingsBadge5.text = badges[4]
      else if itemContent.secondaryTitle = "10-12"
        m.AgeSelectionListItemGroup.itemSpacings = [4, 36, 36, 36]

        m.ratingsBadgeGroup1.removeChild(m.ratingsBadge1)
        m.ratingsBadge2.text = badges[0]
        m.ratingsBadge3.text = badges[1]
        m.ratingsBadge4.visible = false
        m.ratingsBadge5.visible = false

      end if
    end if
  end if
End Function