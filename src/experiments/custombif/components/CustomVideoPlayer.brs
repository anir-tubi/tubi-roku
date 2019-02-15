'
' Demonstrate a custom UI for BIF images.
'
' This node prevents a Video nodes internally handling of keypresses
' by not setting focus to that node.  A manual implementation of scrubbing
' is implemented and updates the custom BIF poster node with the appropriate
' image.
'
'

function init()
  m.video = m.top.findNode("InternalVideo")
  m.thumbnail = m.top.findNode("Thumbnail")
  m.seekLabel = m.top.findNode("SeekPosition")
  m.positionLabel = m.top.findNode("PlaybackPosition")

  ' If enableUI is false, the transport will not appear at all but the 
  ' ff, rew, pause, and left/right hops all still work as expected.
  ' This is not very useful because the keypresses are consumed and there
  ' is no indication of position in the case of seeks & hops.
  m.video.enableUI = true

  ' If enableTrickPlay is false, the transport will not appear at all.  Also
  ' the user cannot pause, ff, rew, hop, or replay.  All these keypresses
  ' trickle up to the parent node in this case.
  m.video.enableTrickPlay = true

  m.video.bifDisplay.observeField("nearestFrame", "onBifFrame")
  m.video.observeField("state", "onVideoState")
  m.video.observeField("position", "onVideoPosition")
  m.top.observeField("focusedChild", "onFocusChange")

  m.seekPosition = 0  ' new position of the video while seeking, ignored during playback
  m.seekHop = 5       ' time in seconds of each left/right hop
end function

function onFocusChange()
  print "CustomVideoPlayer.onFocusChange"
  ' NOTE: don't set focus to the child Video node so that its on key handling
  ' is not invoked.  Side effect is that all keypresses need to be handled in
  ' this node.
end function

function onBifFrame()
  print "CustomVideoPlayer.onBifFrame uri = "; m.video.bifDisplay.nearestFrame
  ' The requested BIF image has been extracted into a texture and the URI
  ' can be used for a Poster node.
  m.thumbnail.uri = m.video.bifDisplay.nearestFrame
end function


function onKeyEvent(key, press)
  print "CustomVideoPlayer.onKeyEvent key = "; key; " press = "; press
  if press

    if key = "right" or key = "left"
      ' Invoke the "hop" interface with bif images showing
      if m.thumbnail.visible = false
        m.video.control = "pause"
        m.thumbnail.visible = true
        m.seekPosition = m.video.position
        m.video.bifdisplay.getNearestFrame = m.seekPosition
      else
        if key = "right"
          ' Hop forward
          m.seekPosition += m.seekHop
          if m.seekPosition > m.video.content.length
            m.seekPosition = m.video.content.length
          end if
        else if key = "left"
          ' Hop backward
          m.seekPosition -= m.seekHop
          if m.seekPosition < 0
            m.seekPosition = 0
          end if
        end if
        print "seekPosition = "; m.seekPosition
        m.video.bifdisplay.getNearestFrame = m.seekPosition
      end if
      return true
    else if key = "OK" or key = "play"
      if m.thumbnail.visible = true
        ' Resume playback considering the hop position
        m.thumbnail.visible = false
        print "resuming playback at "; m.seekPosition
        m.video.control = "play"
        m.video.seek = m.seekPosition
        return true
      end if
    end if
  end if
  updateLabels()
  return false
end function

function updateLabels()
  m.seekLabel.text = "Seek position: " + m.seekPosition.toStr()
  m.positionLabel.text = "Playback position: " + m.video.position.toStr()
end function

function onVideoState()
  print "CustomVideoPlayer.onVideoState state = "; m.video.state
  updateLabels()
end function

function onVideoPosition()
  print "CustomVideoPlayer.onVideoPosition position = "; m.video.position
  updateLabels()
end function

