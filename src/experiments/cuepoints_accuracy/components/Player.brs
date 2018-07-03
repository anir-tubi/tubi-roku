'*********************************************************************
'** (c) 2016-2017 Roku, Inc.  All content herein is protected by U.S.
'** copyright and other applicable intellectual property laws and may
'** not be copied without the express permission of Roku, Inc., which
'** reserves all rights.  Reuse of any of this content for any purpose
'** without the permission of Roku, Inc. is strictly prohibited.
'********************************************************************* 

' Player

sub init()
    m.video = m.top.CreateChild("Video")            
end sub

sub controlChanged()
    'handle orders by the parent/owner
    control = m.top.control
    if control = "play" then
        playContent()
    else if control = "stop" then
        exitPlayer()
    end if
end sub

sub playContent()
    content = m.top.content
    if content <> invalid then
        m.video.content = content
        m.video.visible = false

        if content.relay_position <> invalid and content.relay_position = true
          m.video.observeField("position", "onPosition")
        end if

        m.PlayerTask = CreateObject("roSGNode", "PlayerTask")
        m.PlayerTask.observeField("state", "taskStateChanged")
        m.PlayerTask.video = m.video
        m.PlayerTask.control = "RUN"
    end if
end sub

sub exitPlayer()
    print "Player: exitPlayer()"
    m.video.control = "stop"
    m.video.visible = false
    m.PlayerTask = invalid
    
    'signal upwards that we are done
    m.top.state = "done"
end sub

sub taskStateChanged(event as Object)
    print "Player: taskStateChanged(), id = "; event.getNode(); ", "; event.getField(); " = "; event.getData()
    state = event.GetData()
    if state = "done" or state = "stop"
        m.PlayerTask.unobserveField("state")
        m.video.unobserveField("position")
        exitPlayer()
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ' since m.video is a child of `player` in the scene graph, 
    ' pressing the Back button during play will "bubble up" for us to handle here
    print "Player: keyevent = "; key

    if press and key = "back" then
        'handle Back button, by exiting play
        exitPlayer()
        return true
    end if
    return false
end function



function onPosition(msg)
  curPos = msg.getdata()
  print "Player.onPosition "; curPos
  content = m.top.content
  break = false

  ' Compare by integer with floor (in case notificationInterval is sub-second)
  if content.midroll_position_integer <> invalid and content.midroll_position_integer <> 0
    curPos = Int(curPos)  ' floor
    if curPos = content.midroll_position_integer
      break = true
    end if

  ' Compare by float (might be before or after
  else if content.midroll_position_float <> invalid and content.midroll_position_float <> 0.0
    'if abs(curPos - content.midroll_position_float) <= video.notificationInterval
    if curPos >= content.midroll_position_float
      break = true
    end if

  end if
  ' this will first notify the ad player to call getAds, then stop the video
  if break = true
    m.video.visible = m.video.content.video_node_visible
    m.PlayerTask.position = m.video.position
    m.video.control = "stop"
  end if
end function