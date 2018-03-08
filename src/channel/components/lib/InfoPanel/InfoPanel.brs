Function init()
  m.Title = m.top.findNode("Title")
  m.Episode = m.top.findNode("Episode")
  m.CategoryDetails = m.top.findNode("CategoryDetails")
  m.SeasonDetails = m.top.findNode("SeasonDetails")
  m.TwoLineInfo = m.top.findNode("TwoLineInfo")
  m.ClosedCaptions = m.top.findNode("ClosedCaptionRectangle")
  m.Rating = m.top.findNode("Rating")
  m.Description = m.top.findNode("Description")
  m.DescriptionGroup = m.top.findNode("DescriptionGroup")
  m.DescriptionFocusButton = m.top.findNode("DescriptionFocusButton")
  m.Director = m.top.findNode("Director")
  m.DirectorGroup = m.top.findNode("DirectorGroup")
  m.StarringGroup = m.top.findNode("StarringGroup")
  m.Starring = m.top.findNode("Starring")
  m.Offset = m.top.findNode("Offset")

  m.top.observeField("mode", "onModeChange")
  m.top.observeField("width", "onWidthChange")

  m.top.observeField("releaseDate", "onLine1Change")
  m.top.observeField("length", "onLine1Change")
  m.top.observeField("hasCC", "onHasCC")
  m.top.observeField("rating", "onRatingChange")
  m.top.observeField("genres", "onGenresChange")
  m.top.observeField("description", "onDescriptionChange")
  m.top.observeField("directors", "onDirectorsChange")
  m.top.observeField("starring", "onStarringChange")
  m.top.observeField("seasonEpisodeCount", "onSeasonEpisodeCountChange")
  m.top.observeField("categoryContentCount", "onCategoryContentCountChange")
  m.top.observeField("calculateHeight", "onCalculateHeight")
  m.top.observeField("focusedChild", "onComponentFocus")

  onWidthChange()

  'set the default CC state to be no CC
  firstLineGroup = m.TwoLineInfo.findNode("FirstLineGroup")
  firstLineGroup.removeChild(m.ClosedCaptions)
End Function

Function onComponentFocus()
  tubiLog("InfoPanel.onComponentFocus")
  if m.top.isInFocusChain() and  m.top.description <> invalid and m.top.description <> ""
    m.DescriptionFocusButton.visible = true
  else
    m.DescriptionFocusButton.visible = false
  end if
End Function


' Apply width to all components. Since the outer LayoutGroup has
' horizAlignment set to "custom", each child will have its translation
' field set to adjust it's x offset. We account for the x offset in
' setting each width here so that the children don't go beyond the right edge.
Function onWidthChange()
  tubiLog("InfoPanel.onWidthChange")
  m.Title.width = m.top.width - m.Title.translation[0]
  m.Episode.width = m.top.width - m.Episode.translation[0]
  categoryLine1 = m.CategoryDetails.findNode("CategoryLine1")
  categoryLine1.width = m.top.width - m.CategoryDetails.translation[0]
  seasonLine1 = m.SeasonDetails.findNode("SeasonLine1")
  seasonLine1.width = m.top.width - m.SeasonDetails.translation[0]
  line2 = m.TwoLineInfo.findNode("Line2")
  line2.width = m.top.width - m.TwoLineInfo.translation[0]

  ' The description text needs a right margin which matches its left margin
  m.Description.width = m.top.width - 2 * m.Description.translation[0]
  ' Reduce the director width based on "Direct by..." prefix
  directorPrefixBoundingRect = m.top.findNode("DirectorPrefix").boundingRect()
  m.Director.width = m.top.width - directorPrefixBoundingRect.width + m.DirectorGroup.itemSpacings[0] - m.DirectorGroup.translation[0]
  starringPrefixBoundingRect = m.top.findNode("StarringPrefix").boundingRect()
  m.Starring.width = m.top.width - starringPrefixBoundingRect.width + m.StarringGroup.itemSpacings[0] - m.StarringGroup.translation[0]
  m.DescriptionFocusButton.width = m.top.width + -m.DescriptionGroup.translation[0]
End Function


Function onLine1Change()
  tubiLog("InfoPanel.onLine1Change")
  firstLineGroup = m.TwoLineInfo.findNode("FirstLineGroup")
  line1Label = m.TwoLineInfo.findNode("Line1")
  text = ""
  
  if m.top.releasedate <> invalid and m.top.releasedate <> "" then
    text = m.top.releasedate + " "
  end if
  if m.top.length <> invalid and m.top.length <> 0 then
    ' add 'dot' spacer only if we had a release date
    if text.len() > 0 then 
      text = text + Chr(&hb7) + " "
    end if
    text = text + formatLengthAsEnglish(m.top.length) + " "
  end if
  line1Label.text = text
End Function


Function onHasCC()
  tubiLog("InfoPanel.onHasCC")
  'add closed captions if they are available
  firstLineGroup = m.TwoLineInfo.findNode("FirstLineGroup")
  if m.top.hasCC = true
    firstLineGroup.insertChild(m.ClosedCaptions, 1)
  else
    firstLineGroup.removeChild(m.ClosedCaptions)
  end if
End Function


Function onRatingChange()
  tubiLog("InfoPanel.onRatingChange")
  if m.top.rating <> invalid and m.top.rating <> "" then
    m.Rating.uri = "pkg:/images/rating-" + Ucase(m.top.rating) + ".png"
  else
    m.Rating.uri = ""
  end if
End Function


Function onGenresChange()
  tubiLog("InfoPanel.onGenresChange")
  line2Label = m.TwoLineInfo.findNode("Line2")
  text = ""
  if m.top.genres <> invalid and m.top.genres.count() > 0 then
    capitalGenres = []
    for each c in m.top.genres
      capitalGenres.push(capitalize(c))
    end for
    text = capitalGenres.Join(", ")
  end if
  line2Label.text = text
End Function


Function onDescriptionChange()
  tubiLog("InfoPanel.onDescriptionChange")
  if m.top.description <> invalid and m.top.description <> ""
    m.Description.visible = true
    m.Description.height = 0  ' reset for calculations below
    m.Description.text = m.top.description
  else
    m.Description.visible = false
  end if
End Function


Function onDirectorsChange()
  tubiLog("InfoPanel.onDirectorChange")
  text = ""
  if m.top.directors <> invalid and m.top.directors.count() > 0 then
    text = m.top.directors.Join(", ")
  end if
  if text = "" then
    ' hide the whole group if no directors listed
    m.DirectorGroup.visible = false
  else if m.DirectorGroup.visible = false
    m.DirectorGroup.visible = true
  end if
  m.Director.text = text
End Function


Function onStarringChange()
  tubiLog("InfoPanel.onStarringChange")
  text = ""
  if m.top.starring <> invalid and m.top.starring.count() > 0 then
    text = m.top.starring.Join(", ")
  end if
  if text = invalid or text = "" then
    ' hide the whole group if no actors/starring listed
    m.StarringGroup.visible = false
  else
    m.StarringGroup.visible = true
  end if
  m.Starring.text = text
End Function


Function onSeasonEpisodeCountChange()
  tubiLog("InfoPanel.onSeasonEpisodeCountChange")
  seasonLabel = m.SeasonDetails.findNode("SeasonLine1")
  if m.top.seasonEpisodeCount > 0 then
    seasonLabel.text = stri(m.top.seasonEpisodeCount).trim() + " episodes"
  else
    seasonLabel.text = ""
  end if
End Function


Function onCategoryContentCountChange()
  tubiLog("InfoPanel.onCategoryContentCountChange")
  categoryLine1 = m.CategoryDetails.findNode("CategoryLine1")
  if m.top.categoryContentCount <> invalid and m.top.categoryContentCount > 0 then
    categoryLine1.text = stri(m.top.categoryContentCount).trim() + " titles in this category"
  else
    categoryLine1.text = ""
  end if
End Function


Function onCalculateHeight()
  tubiLog("InfoPanel.onCalculateHeight")
  topMargin = 15
  bottomMargin = 8
  m.DescriptionFocusButton.height = m.Description.boundingRect().height + topMargin + bottomMargin
  ' try to shorten description to fit max height
  if m.top.maxHeight <> 0 and m.top.maxHeight < m.Offset.BoundingRect().height then
    m.Description.height = m.Description.boundingRect().height - (m.offset.BoundingRect().height - m.top.maxHeight)
    if m.Description.height <= 0 then
      m.Description.text = ""
    end if
    m.DescriptionFocusButton.height = m.Description.boundingRect().height + topMargin + bottomMargin
  end if
  'vertically center the info panel
  offsetY = (m.top.maxHeight - m.Offset.BoundingRect().height) \ 2
  if offsetY > 0
    m.Offset.translation = [0, offsetY]
  else
    m.Offset.translation = [0, 0]
  end if
End Function


'''''''''''''''''''
' onModeChange
'
' Make various fields visible or invisible by removing them from
' the children for rendering
Function onModeChange()
  tubiLog("InfoPanel.onModeChange")
  while m.Offset.getChildCount() > 0
    m.Offset.removeChildIndex(0)
  end while

  if m.top.mode= "category" then
    m.Offset.appendChild(m.Title)
    m.Offset.appendChild(m.CategoryDetails)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [52, 15]
  else if m.top.mode = "item" then
    m.Offset.appendChild(m.Title)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [42, 15]
  else if m.top.mode = "movie" then
    m.Offset.appendChild(m.Title)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.appendChild(m.DirectorGroup)
    m.Offset.appendChild(m.StarringGroup)
    m.Offset.itemSpacings = [42, 15, 17, 11]
  else if m.top.mode = "series" then
    m.Offset.appendChild(m.Title)
    m.Offset.appendChild(m.Episode)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.appendChild(m.DirectorGroup)
    m.Offset.appendChild(m.StarringGroup)
    m.Offset.itemSpacings = [26, 25, 15, 17, 11]
  else if m.top.mode = "season" then
    m.Offset.appendChild(m.Title)
    m.Offset.appendChild(m.SeasonDetails)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [52, 15]
  else if m.top.mode = "episode" then
    m.Offset.appendChild(m.Title)
    m.Offset.appendChild(m.Episode)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [26, 25, 15]
  end if
End Function


Function onKeyEvent(key, press)
  if press and key = "OK"
    m.top.descriptionSelected = true
    return true
  end if
  return false
End Function