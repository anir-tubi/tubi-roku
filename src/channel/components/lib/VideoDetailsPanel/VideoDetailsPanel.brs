' VideoDetailsPanel Component
' Displays detailed metadata information for video content in a two-column layout
' Left column: Starring, Director, Languages, Subtitles
' Right column: Rating, Content descriptors, Audio description


' Initializes the component and sets up event observers
Function init()
  topRef = m.top
  m.nodeHelpers = TubiNodeHelpers()

  ' Cache node references
  m.leftColumn = topRef.findNode("leftColumn")
  m.rightColumn = topRef.findNode("rightColumn")

  ' Cache typography IDs for reuse in helper functions
  typographyConstants = getTypographyConstants()
  m.subheaderMediumFont = typographyConstants.ids.subheaderMedium
  m.bodyMediumFont = typographyConstants.ids.bodyMedium
  m.bodyExtraSmallStrongFont = typographyConstants.ids.bodyExtraSmallStrong
  m.bodySmallStrongFont = typographyConstants.ids.bodySmallStrong

  ' Set up theme observer
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  ' Set up content observer
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
End Function


' Handles theme changes and caches color values
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  ' Cache theme colors for use in helper functions
  m.primaryTextColor = ""
  m.neutralColor = ""
  m.secondaryTextColor = ""

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.neutralColor = theme.neutralColor
    m.secondaryTextColor = theme.secondaryTextColor
  end if
End Function


' Handles itemContent changes and populates the detail panel
' Clears existing content and rebuilds both columns based on available metadata
Function onItemContentChange()
  itemContent = m.top.itemContent

  if itemContent <> invalid
    ' Clear existing children from both columns
    m.nodeHelpers.removeAllChildren(m.leftColumn)
    m.nodeHelpers.removeAllChildren(m.rightColumn)

    ' Build and append column items
    leftColumnItems = buildLeftColumnItems(itemContent)
    if isNonEmptyArray(leftColumnItems)
      m.leftColumn.appendChildren(leftColumnItems)
    end if

    rightColumnItems = buildRightColumnItems(itemContent)
    if isNonEmptyArray(rightColumnItems)
      m.rightColumn.appendChildren(rightColumnItems)
    end if
  end if
End Function


' Builds left column items (Starring, Director, Languages, Subtitles)
' @param itemContent - Content node with metadata
' @return Array of layout groups for left column
Function buildLeftColumnItems(itemContent as Object) as Object
  items = []

  if isNonEmptyArray(itemContent.actors)
    starringItem = createDetailItem(getTranslation("metadata_starring"), itemContent.actors.join(", "), "starringItem")
    items.push(starringItem)
  end if

  if isNonEmptyArray(itemContent.directors)
    directorItem = createDetailItem(getTranslation("metadata_directed"), itemContent.directors.join(", "), "directorItem")
    items.push(directorItem)
  end if

  videoResources = itemContent.videoResources
  if isNonEmptyArray(videoResources) AND isAA(videoResources[0][0])
    audioLanguages = videoResources[0][0].audioLanguages
    if isNonEmptyArray(audioLanguages) = true
      audioItem = createDetailItem(getTranslation("metadata_languages"), audioLanguages.join(", "), "audioItem")
      items.push(audioItem)
    end if
  end if

  if isNonEmptyArray(itemContent.subtitleTracks)
    subtitleTracks = itemContent.subtitleTracks
    language = []
    if isNonEmptyArray(subtitleTracks)
      for each track in subtitleTracks
        language.push(track.description)
      end for
    end if
    subtitlesItem = createDetailItem(getTranslation("cc_audio_overlay_subtitles"), language.join(", "), "subtitlesItem")
    items.push(subtitlesItem)
  end if

  return items
End Function


' Builds right column items (Rating, Content descriptors, Audio description)
' @param itemContent - Content node with metadata
' @return Array of layout groups for right column
Function buildRightColumnItems(itemContent as Object) as Object
  items = []

  if isNonEmptyString(itemContent.rating)
    ratingDescription = getRatingDescription(itemContent.rating)
    ratingItem = createRatingItem(itemContent.rating, ratingDescription)
    items.push(ratingItem)
  end if

  ' Content rating descriptors (D, L, S, V, FV)
  if isNonEmptyString(itemContent.descriptorCode) AND isNonEmptyString(itemContent.descriptorDescription)
    descriptorCode = itemContent.descriptorCode.trim().split(" ")
    descriptorDescription = itemContent.descriptorDescription.split(", ")

    for i = 0 to descriptorCode.count() - 1
      code = descriptorCode[i]
      description = descriptorDescription[i]
      ratingDetailItem = createContentRatingItem(code, description)
      items.push(ratingDetailItem)
    end for
  end if

  if itemContent.hasAudioDescription = true
    audioDescItem = createAudioDescriptionItem()
    items.push(audioDescItem)
  end if

  return items
End Function


' Creates a detail item with label and value in vertical layout
' Used for displaying metadata like "Starring", "Director", "Languages", etc.
' @param labelText - The label text (e.g., "Starring")
' @param valueText - The value text (e.g., "Actor Name")
' @param itemId - ID for the item group for testing purposes
' @return LayoutGroup containing label and value
Function createDetailItem(labelText as String, valueText as String, itemId as String) as Object
  ' Create label
  label = createLabel(labelText, {
    color: m.primaryTextColor
    typographyFont: m.subheaderMediumFont
  })

  ' Create value with wrapping enabled
  value = createLabel(valueText, {
    width: 675
    wrap: true
    color: m.primaryTextColor
    typographyFont: m.bodyMediumFont
  })

  return createLayoutGroup("vert", {
    id: itemId
    itemSpacings: [8]
    children: [label, value]
  })
End Function


' Creates a rating item with badge and description
' Badge dynamically sizes based on text length (e.g., "G" vs "TV-MA")
' @param ratingText - The rating text (e.g., "TV-14", "PG-13")
' @param descriptionText - The rating description
' @return LayoutGroup containing badge and description
Function createRatingItem(ratingText as String, descriptionText as String) as Object
  ratingHeight = 42

  ' Rating badge with 9-patch background
  ratingBadge = CreateObject("roSGNode", "Group")

  badgeBackground = createPoster("pkg:/images/vod-details-rating-background-$$RES$$.9.png", {
    height: ratingHeight
    loadDisplayMode: "scaleToFit"
  })

  ratingLabel = createLabel(UCase(ratingText), {
    width: 0
    height: ratingHeight
    color: m.secondaryTextColor
    typographyFont: m.bodySmallStrongFont
    horizAlign: "center"
    vertAlign: "center"
    lineSpacing: 2
  })

  ' Calculate dynamic width based on text length
  nRatingBoundingBoxIncrease = ratingLabel.boundingRect().width + 24
  nRatingBoundingBoxIncrease = ensureDivisibleBy3(nRatingBoundingBoxIncrease)
  badgeBackground.width = nRatingBoundingBoxIncrease
  ratingLabel.width = nRatingBoundingBoxIncrease

  ratingBadge.appendChildren([badgeBackground, ratingLabel])

  ' Build children array
  children = [ratingBadge]

  ' Add description if provided
  if descriptionText <> invalid AND descriptionText <> ""
    description = createLabel(descriptionText, {
      width: 600
      wrap: true
      color: m.primaryTextColor
      typographyFont: m.bodyMediumFont
      lineSpacing: 2
    })
    children.push(description)
  end if

  return createLayoutGroup("vert", {
    itemSpacings: [12]
    children: children
  })
End Function


' Creates a content rating descriptor item with code badge and description
' Used for displaying content descriptors like D (Sexual dialogue), L (Language), etc.
' @param code - The descriptor code (e.g., "D", "L", "S", "V", "FV")
' @param descriptionText - The descriptor description
' @return LayoutGroup containing badge and description in horizontal layout
Function createContentRatingItem(code as String, descriptionText as String) as Object
  ' Create rating code badge using mixin helper
  ratingSize = 42
  codeBadge = createRatingDescriptorBadge(code, {
    ratingSize: ratingSize
    labelFont: m.bodyExtraSmallStrongFont
    labelColor: m.secondaryTextColor
  })

  ' Add description aligned to badge
  description = createLabel(descriptionText, {
    height: ratingSize
    vertAlign: "center"
    color: m.primaryTextColor
    typographyFont: m.bodyMediumFont
  })

  return createLayoutGroup("horiz", {
    itemSpacings: [20]
    children: [codeBadge, description]
  })
End Function


' Creates an audio description availability item
' Displays icon and text indicating audio description is available
' @return LayoutGroup containing icon and description text
Function createAudioDescriptionItem() as Object
  ' Audio Description icon
  icon = createPoster("pkg:/images/icon-audio-description.webp", {
    width: 96
    height: 42
  })

  ' Description text aligned to icon
  description = createLabel(getTranslation("metadata_audio_description"), {
    height: 42
    vertAlign: "center"
    color: m.primaryTextColor
    typographyFont: m.bodyMediumFont
  })

  return createLayoutGroup("horiz", {
    itemSpacings: [20]
    children: [icon, description]
  })
End Function


' Converts a rating string to its corresponding translation key and returns the description
' Dynamically generates translation keys based on rating format
' @param rating - The rating string (e.g., "TV-14", "PG-13", "R")
' @return The translated rating description
Function getRatingDescription(rating as String) as String
  ' Convert rating to translation key format
  ' Example: "TV-14" -> "rating_tv_14_description"
  ' Example: "PG-13" -> "rating_pg_13_description"
  translationKey = "rating_" + LCase(rating).replace("-", "_") + "_description"
  return getTranslation(translationKey)
End Function


