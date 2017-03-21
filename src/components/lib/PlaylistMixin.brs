
' Using the unix epoch as our basis, and assuming the playlist loops indefinitely, calculate 
' distance into the playlist
Function calculateCurrentLiveTVEpisode(playlist As Object) As Object
  if playlist <> invalid then
    playlistLength = 0
    for i=0 to playlist.getChildCount()-1
      playlistLength = playlistLength + playlist.getChild(i).length
    end for

    if playlistLength = 0 then 
      currentContent = 0
      currentPosition = 0
    else
      now = CreateObject("roDateTime").AsSeconds()  ' seconds since epoch

      currentPosition = now MOD Int(playlistLength)
      for i=0 to playlist.getChildCount()-1
        length = playlist.getChild(i).length 
        if length > currentPosition then
          exit for
        end if
        currentPosition = currentPosition - length
      end for
      currentContent = i
    end if
    return [currentContent, Int(currentPosition)]
  else
    return [-1,-1]
  end if
End Function


'
' getPlaylistLength()
'
Function getPlaylistLength(playlist As Object) As Integer
  totalLength = 0

  if playlist <> invalid then
    for i=0 to playlist.getChildCount()-1
      length = playlist.getChild(i).length
      if length <> invalid then totalLength = totalLength + Int(length)
    end for
  end if
  return totalLength
End Function

'
' playlistPositionFromEpisodicPosition()
'
Function playlistPositionFromEpisodicPosition(playlist, position)
  if type(position) <> "roArray" or position.count() <> 2 or playlist = invalid then
    return 0
  endif

  playlistPosition = 0
  for i=0 to position[0]-1
    length = playlist.getChild(i).length
    playlistPosition = playlistPosition + length
  end for
  playlistPosition = playlistPosition + position[1]
  return playlistPosition
End Function

'
' episodicPositionFromPlaylistPosition()
'
Function episodicPositionFromPlaylistPosition(playlist, position)
  if playlist = invalid then
    return [0,0]
  end if
  position = position MOD Int(getPlaylistLength(playlist))
  
  for i=0 to playlist.getChildCount()-1
    length = playlist.getChild(i).length 
    if position < length then
      exit for
    end if
    position = position - length
  end for
  return [i, position]
End Function