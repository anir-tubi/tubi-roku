'*********************************************************************
'** (c) 2016-2017 Roku, Inc.  All content herein is protected by U.S.
'** copyright and other applicable intellectual property laws and may
'** not be copied without the express permission of Roku, Inc., which
'** reserves all rights.  Reuse of any of this content for any purpose
'** without the permission of Roku, Inc. is strictly prohibited.
'********************************************************************* 

Library "Roku_Ads.brs"

sub init()
    m.top.functionName = "playContentWithAds" 
    m.top.id = "PlayerTask"
end sub

sub playContentWithAds()
   
    video = m.top.video
    ' `view` is the node under which RAF should display its UI (passed as 3rd argument of showAds())
    view = video.getParent() 

    content = video.content
    keepPlaying = true

    port = CreateObject("roMessagePort")
    if keepPlaying then
        video.observeField("position", port)
        video.observeField("state", port)
        video.visible = true
        video.control = "play"
        video.setFocus(true) 'so we can handle a Back key interruption
    end if

    curPos = 0
    adPods = invalid
    isPlayingPostroll = false
    while keepPlaying
        msg = wait(0, port)
        if type(msg) = "roSGNodeEvent"
            if msg.GetField() = "position" then
                ' keep track of where we reached in content
                curPos = msg.GetData() 
            else if msg.GetField() = "state" then
                curState = msg.GetData()
                print "PlayerTask: state = "; curState
                if curState = "stopped" then
                    exit while
                else if curState = "finished" then
                    print "PlayerTask: main content finished"
                    exit while
                else if curState = "error" then
                  print "PlayerTask: errorCode = "; video.errorCode
                  print "PlayerTask: errorMsg = "; video.errorMsg
                end if
            end if
        end if
    end while

    print "PlayerTask: exiting playContentWithAds()"
end sub
