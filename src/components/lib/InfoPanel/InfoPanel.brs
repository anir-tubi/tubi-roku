Function init()
  m.Title = m.top.findNode("Title")
  m.Episode = m.top.findNode("Episode")
  m.CategoryDetails = m.top.findNode("CategoryDetails")
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

    ' TwoLineInfo
    line1Label = m.TwoLineInfo.findNode("Line1")
    line1Label.text = ""
    if content.releasedate <> invalid and content.releasedate <> "" then
      line1Label.text = "(" + content.releasedate + ") "
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

End Function


'''''''''''''''''''
' onModeChange
'
' Make various fields visible or invisible by removing them from
' the children for rendering
Function onModeChange()
  print "InfoPanel.onModeChange"
  m.top.removeChildrenIndex(m.top.getChildCount(), 0)

  if m.top.mode= "category" then
    m.top.appendChildren([
      m.Title
      m.CategoryDetails
      m.Description
    ])
    m.top.itemSpacings = [52, 31]
  else if m.top.mode = "item" then
    m.top.appendChildren([
      m.Title
      m.TwoLineInfo
      m.Description
    ])
    m.top.itemSpacings = [44, 30]
  else if m.top.mode = "movie" then
    m.top.appendChildren([
      m.Title
      m.TwoLineInfo
      m.Description
      m.DirectorGroup
      m.StarringGroup
    ])
    m.top.itemSpacings = [44, 30, 34, 11]
  else if m.top.mode = "series" then
    m.top.appendChildren([
      m.Title
      m.Episode
      m.TwoLineInfo
      m.Description
      m.DirectorGroup
      m.StarringGroup
    ])
    m.top.itemSpacings = [26, 27, 30, 34, 11]
  else if m.top.mode = "season" then
    m.top.appendChildren([
      m.Title
    ])
    m.top.itemSpacings = []
  else if m.top.mode = "episode" then
    m.top.appendChildren([
      m.Title
      m.Episode
      m.TwoLineInfo
      m.Description
    ])
    m.top.itemSpacings = [26, 27, 30]
  end if
End Function


'''''''''''''''''''
' formatLengthAsTimestamp
'
' take a float or integer length in seconds, transform to timestamp "HH:MM:SS".
'TODO(Chris): Move this to common library
Function formatLengthAsTimestamp(length As Dynamic) As String
  if type(length) = "Float" or type(length) = "Double" then length = Int(length)
  if type(length) = "Integer" and length > 0 then
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = stri(hours) + ":" + padString(stri(minutes), 2, "0") + ":" + padString(stri(seconds), 2, "0")
    return result
  else
    return ""
  end if
End Function


'''''''''''''''''''
' formatLengthAsEnglish
'
' take an integer length in seconds and give it an English descriptions like "1 h 36 min"
'TODO(Chris): Move this to common library
Function formatLengthAsEnglish(length As Dynamic) As String
  if type(length) = "Float" or type(length) = "Double" then length = Int(length)
  if type(length) = "Integer"
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = ""
    if hours > 0 then result = stri(hours).trim() + " h "
    result  = result + stri(minutes).trim() + " min"    
    return result
  else
    return ""
  end if
End Function


'''''''''''''''''''
' padString
' 
' simple left padding of a string with a given character
' Example: padString('12345', 8, '0') => '00012345'
'
'TODO(Chris): Move this to common library
Function padString(s As String, width As Integer, c as String)
  result = s.trim()
  while result.len() < width
    difference = width - result.len()
    result = right(c, difference) + result
  end while
  return result
End Function


'''''''''''''''''''
' joinStringArray
'
' Join strings together, using 'c' as a separator
' Example: joinStringArray(['a','b','c'],'-') => "a-b-c"
'TODO(Chris): Move this to common library
Function joinStringArray(a As Object, c As String)
  result = ""
  if a.count() > 0 then result = a[0]
  for i=1 to a.count() - 1
    result = result + c + a[i]
  end for
  return result
End Function


''''''''''
' capitalize
'
' Make the first letter uppercase, the reset lowercase
Function capitalize(s As String)
  if s.len() > 0 then
    return Ucase(Left(s, 1)) + LCase(Right(s, s.len() - 1))
  else
    return ""
  end if
End Function
