Function init()
  m.Title = m.top.findNode("Title")
  m.Description = m.top.findNode("Description")
  m.OneLineInfo = m.top.findNode("OneLineInfo")
  m.TwoLineInfo = m.top.findNode("TwoLineInfo")
  m.Director = m.top.findNode("Director")
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
    m.Title.text = content.title
    m.Description.text = content.description

    ' OneLineInfo
    info = []
    if content.categories <> invalid and content.categories.count() > 0 then info.push(UCase(content.categories[0]))
    ' TODO(Chris): What format will this come back as? We want only the year
    if content.releasedate <> invalid then info.push(content.releasedate)
    if content.length <> invalid then info.push(formatLengthAsTimestamp(content.length))
    if content.rating <> invalid then info.push(content.rating)
    m.OneLineInfo.text = joinStringArray(info, "   ")
  
    ' TwoLineInfo
    line1Label = m.TwoLineInfo.findNode("Line1")
    line1Label.text = "(" + content.releasedate + ") " + Chr(&hc2) + Chr(&hb7) + " " + formatLengthAsEnglish(content.length) + " " + content.rating
    line2Label = m.TwoLineInfo.findNode("Line2")
    line2Label.text = content.category
    if content.categories <> invalid and content.categories.count() > 0 then
      line2Label.text = joinStringArray(content.categories, ", ")
    end if
  
    m.Director.text = content.director
    if content.directors <> invalid and content.directors.count() > 0 then
      m.Director.text = joinStringArray(content.directors, ", ")
    end if
    m.Starring.text = content.actor
    if content.actors <> invalid and content.actors.count() > 0 then
      m.Starring.text = joinStringArray(content.actors, ", ")
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

  if m.top.mode = "detail" then
    m.top.appendChildren([
      m.Title
      m.TwoLineInfo
      m.Description
      m.Director
      m.Starring
    ])
  else if m.top.mode = "item" then
    m.top.appendChildren([
      m.Title
      m.OneLineInfo
      m.Description
    ])
  else ' category
    m.top.mode = "category" ' in case an invalid value was set
    m.top.appendChildren([
      m.Title
      m.Description
    ])
  end if
  print "InfoPanel has " + stri(m.top.getChildCount()) + " nodes"
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
  if type(length) = "Integer"
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = ""
    if hours > 0 then result = stri(hours) + " h "
    result  = result + stri(minutes) + " min"    
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
