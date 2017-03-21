Function init()
  tubiLog("EPGChannelItem.init")
  m.top.observeField("content", "onContentChange")
  m.ChannelName = m.top.findNode("ChannelName")
  m.Marker = m.top.findNode("CurrentMarker")
  m.episodeSpacing = 2
End Function

Function onContentChange()
  tubiLog("EPGChannelItem.onContentChange")

  if m.top.content <> invalid then

    ' set the title
    if m.top.content.title <> invalid and m.top.content.title <> "" then
      m.ChannelName.text = Left(m.top.content.title, 5)
    end if

    ' set the current marker
    parent = m.top.content.getParent()
    if parent <> invalid and parent.liveTVCursor <> invalid then
      currentIndex = parent.liveTVCursor[0]
      m.Marker.visible = false
      currentChannel = parent.getChild(currentIndex)
      if currentChannel <> invalid and currentChannel.isSameNode(m.top.content) then
        minWidth = m.ChannelName.width + m.episodeSpacing
        maxWidth = ((1750 - minWidth) / 3.5) + minWidth    ' 3.5 hours total width but we only allow 1 hour wide
        datetime = CreateObject("roDateTime")
        m.Marker.width = Int(minWidth + (maxWidth - minWidth) * (datetime.GetMinutes() / 60))
        m.Marker.visible = true
      end if
    end if

    ' now create timeslots
    maxWidth = 1750 - (m.ChannelName.width + m.episodeSpacing)
    timeslots = m.top.findNode("Timeslots")


    '                            marker 
    ' | fixed width  | 0:00         |               | 1:00                 | 2:00        |
    ' | ------------ | ------------ | -------------------------------------------------- |
    ' | Channel Name | n-1 episode  |        | current episode    |  next episode | n+2  |

    if m.top.content.getChildCount() = 0 or m.top.content.liveTvChannelType = "short_form" then
      ' empty channel or short-form content
      empty = timeslots.createChild("Rectangle")
      empty.width = maxWidth
      empty.height = 80
      addLabel(empty, m.top.content.description, maxWidth)
    else
      p = m.top.content.getParent()
      channelList = m.top.content.getParent()
      if channelList <> invalid then
        cursor = channelList.liveTVCursor

        ' Relate the channel position to the current channel position so they're in time-sync
        otherPlaylist = channelList.getChild(cursor[0])
        thisPlaylist = m.top.content
        otherCursor = [cursor[1], cursor[2]]
        otherPosition = playlistPositionFromEpisodicPosition(otherPlaylist, otherCursor)
        cursor = episodicPositionFromPlaylistPosition(thisPlaylist, otherPosition)
        cursor.unshift(0)  ' does not factor in below

      else
        ' use unix epoch as start
        cursor = calculateCurrentLiveTVEpisode(m.top.content)
        cursor.unshift(0)  ' just to normalize to 3 elements like liveTVCursor
      end if

      cursor = offsetCursorForHourMarker(m.top.content, cursor)

      i = cursor[1]         ' index of the episode we are filling in the grid with
      position = cursor[2]  ' position into the episode.  For the current playing selection
      totalWidth = 0                ' accumulated total width in pixels
                                    ' this is non-zero, but zero for all others
      while totalWidth <= maxWidth
        episode = m.top.content.getChild(i)
        if episode = invalid then
          i = 0
          episode = m.top.content.getChild(i)
        end if
        ' maxWidth represents 3.5 hrs (12,600 seconds)
        width = Int((episode.length - position) * (maxWidth / (3.5 * 60 * 60)))
        ' clamp it at the max
        if (totalWidth + width) > maxWidth then width = (maxWidth - totalWidth)
        rect = timeslots.createChild("Rectangle")
        rect.width = width
        rect.height = 80
        rect.translation = [totalWidth, 0]
        addLabel(rect, episode.title, width)
        totalWidth = totalWidth + width + m.episodeSpacing
        i = i + 1
        position = 0
      end while
    end if
  end if
End Function

Function addLabel(parent, title, width)
  label = parent.createChild("Label")
  label.text = title
  label.translation = [20,0]  ' offset it into the timeslot rectangle just a little
  label.height = 80
  label.width = width - 40
  label.font.uri = "pkg:/fonts/Vaud-SemiBold.ttf"
  label.font.size = 27
  label.color = "0x000000FF"
  label.vertAlign = "center"
End Function


' Given a channel cursor and playlist, generate a new cursor offset for the current
' minutes past the hour.  This is to visually account for the EPG marker showing
' past history of the current hour.
Function offsetCursorForHourMarker(channelPlaylist As Object, cursor As Object) As Object
  ' the "now" position is not at pixel zero since we show the full current hour
  markerOffset = CreateObject("roDateTime").GetMinutes() * 60

  playlistLength = getPlaylistLength(channelPlaylist)

  ' find the linear position in the playlist
  absoluteCursor = cursor[2]
  for i=0 to cursor[1] - 1
    absoluteCursor = absoluteCursor + Int(channelPlaylist.getChild(i).length)
  end for
  'print "Original absolute cursor " + stri(absoluteCursor)

  'print "Playlist length " + stri(playlistLength)
  'print "Offset " + stri(markerOffset)

  ' find the offset linear position in the playlist
  absoluteCursor = absoluteCursor - markerOffset
  while absoluteCursor < 0  ' playlist can be shorter than the marker, so we might need to do this many times
    absoluteCursor = (absoluteCursor + playlistLength)
  end while
  'print "Shifted absolute cursor " + stri(absoluteCursor)

  ' break down into [episode, position]
  position = absoluteCursor
  for i=0 to channelPlaylist.getChildCount()-1
    length = Int(channelPlaylist.getChild(i).length)
    if position < length then
      return [cursor[0], i, position]
    else
      position = position - length
    end if
  end for
  ' this should not happen. use something sane instead
  return [cursor[0], i, 0]
End Function