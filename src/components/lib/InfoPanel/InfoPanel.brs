Function init()
  m.Title = m.top.findNode("Title")
  m.Episode = m.top.findNode("Episode")
  m.CategoryDetails = m.top.findNode("CategoryDetails")
  m.SeasonDetails = m.top.findNode("SeasonDetails")
  m.TwoLineInfo = m.top.findNode("TwoLineInfo")
  m.Rating = m.top.findNode("Rating")
  m.Description = m.top.findNode("Description")
  m.Director = m.top.findNode("Director")
  m.DirectorGroup = m.top.findNode("DirectorGroup")
  m.StarringGroup = m.top.findNode("StarringGroup")
  m.Starring = m.top.findNode("Starring")

  m.top.observeField("content", "onContentChange")
  m.top.observeField("mode", "onModeChange")

  onModeChange()  ' kickstart the mode
End Function


'''''''''''''''''''
' onContentChange
'
' Format content for an item or category into the various fields
Function onContentChange()
  print "InfoPanel.onContentChange"
  content = m.top.content
  if content <> invalid then

    ' Title
    m.Title.text = content.title

    ' Episode
    m.Episode.text = content.episode_title

    ' CategoryDetails
    categoryLine1 = m.CategoryDetails.findNode("CategoryLine1")
    if content.totalCount <> invalid and content.totalCount > 0 then
      categoryLine1.text = stri(content.totalCount).trim() + " titles in this category"
    else
      categoryLine1.text = ""
    end if
    categoryLine2 = m.CategoryDetails.findNode("CategoryLine2")
    'TODO(Chris): Where in the API can we get "last updated" information?
    'categoryLine2.text = "Updated on Wednesday"

    ' SeasonDetails
    seasonLabel = m.SeasonDetails.findNode("SeasonLine1")
    if content.totalCount <> invalid and content.totalCount > 0 then
      seasonLabel.text = stri(content.totalCount).trim() + " episodes"
    else
      seasonLabel.text = ""
    end if

    ' TwoLineInfo
    line1Label = m.TwoLineInfo.findNode("Line1")
    line1Label.text = ""
    if content.releasedate <> invalid and content.releasedate <> "" then
      ' line1Label.text = "(" + content.releasedate + ") "
      line1Label.text = content.releasedate + " "
    end if
    if content.length <> invalid and content.length <> 0 then
      ' add 'dot' spacer only if we had a release date
      if line1Label.text.len() > 0 then 
        line1Label.text = line1Label.text + Chr(&hb7) + " "
      end if
      line1Label.text = line1Label.text + formatLengthAsEnglish(content.length) + " "
    end if
    if content.rating <> invalid and content.rating <> "" then
      'line1Label.text = line1Label.text + content.rating
      m.Rating.uri = "pkg:/images/rating-" + Ucase(content.rating) + ".png"
    else
      m.Rating.uri = ""
    end if
    line2Label = m.TwoLineInfo.findNode("Line2")
    line2Label.text = ""
    if content.genres <> invalid and content.genres.count() > 0 then
      capitalGenres = []
      for each c in content.genres
        capitalGenres.push(capitalize(c))
      end for
      line2Label.text = joinStringArray(capitalGenres, ", ")
    end if
  
    ' Description
    m.Description.text = content.description

    ' Directors
    m.DirectorGroup.visible = true
    m.Director.text = content.director
    if content.directors <> invalid and content.directors.count() > 0 then
      m.Director.text = joinStringArray(content.directors, ", ")
    end if
    if m.Director.text = invalid or m.Director.text = "" then
      ' hide the whole group if no directors listed
      m.DirectorGroup.visible = false
    end if

    ' Actors
    m.StarringGroup.visible = true
    m.Starring.text = content.actor
    if content.actors <> invalid and content.actors.count() > 0 then
      m.Starring.text = joinStringArray(content.actors, ", ")
    end if
    if m.Starring.text = invalid or m.Starring.text = "" then
      ' hide the whole group if no directors listed
      m.StarringGroup.visible = false
    end if
  end if

  'vertically center the info panel
  translationY = (m.top.maxHeight - m.top.BoundingRect().height) \ 2
  m.top.translation = [m.top.translation[0], translationY]

End Function


'''''''''''''''''''
' onModeChange
'
' Make various fields visible or invisible by removing them from
' the children for rendering
Function onModeChange()
  print "InfoPanel.onModeChange"
  while m.top.getChildCount() > 0
    m.top.removeChildIndex(0)
  end while

  if m.top.mode= "category" then
    m.top.appendChild(m.Title)
    m.top.appendChild(m.CategoryDetails)
    m.top.appendChild(m.Description)
    m.top.itemSpacings = [52, 31]
  else if m.top.mode = "item" then
    m.top.appendChild(m.Title)
    m.top.appendChild(m.TwoLineInfo)
    m.top.appendChild(m.Description)
    m.top.itemSpacings = [42, 30]
  else if m.top.mode = "movie" then
    m.top.appendChild(m.Title)
    m.top.appendChild(m.TwoLineInfo)
    m.top.appendChild(m.Description)
    m.top.appendChild(m.DirectorGroup)
    m.top.appendChild(m.StarringGroup)
    m.top.itemSpacings = [42, 30, 34, 11]
  else if m.top.mode = "series" then
    m.top.appendChild(m.Title)
    m.top.appendChild(m.Episode)
    m.top.appendChild(m.TwoLineInfo)
    m.top.appendChild(m.Description)
    m.top.appendChild(m.DirectorGroup)
    m.top.appendChild(m.StarringGroup)
    m.top.itemSpacings = [26, 25, 30, 34, 11]
  else if m.top.mode = "season" then
    m.top.appendChild(m.Title)
    m.top.appendChild(m.SeasonDetails)
    m.top.appendChild(m.Description)
    m.top.itemSpacings = [52, 31]
  else if m.top.mode = "episode" then
    m.top.appendChild(m.Title)
    m.top.appendChild(m.Episode)
    m.top.appendChild(m.TwoLineInfo)
    m.top.appendChild(m.Description)
    m.top.itemSpacings = [26, 25, 30]
  end if
End Function
