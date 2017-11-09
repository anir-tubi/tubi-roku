Function init()
  TubiLog("BackgroundGroup.init")
  m.top.observeField("newBackgroundType", "updateBackground")
  m.top.observeField("enterFromSignIn", "setUnblurred")

  m.newBackgroundPoster = invalid
  m.newBackgroundAnimation = invalid
  m.oldTransitionOut = invalid
  m.currentBackgroundType = invalid
  ' m.unblurredDefaultBackground = "pkg:/images/sign-in-background.png"
  m.blurredDefaultBackground = m.global.constants.ui.uris.defaultBackground
  m.imageIndex = 0

  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.duration = 3

  m.updateCount = 0
  m._ = rodash()
End Function


Function updateBackground()
  TubiLog("BackgroundGroup.updateBackground")
  m.updateCount = m.updateCount + 1

  if m.global.constants.deviceInfo.limitedNewUi = true
    ' we have a low spec device that won't handle transitions so make it basic
    if m.top.getChildCount() = 0
      addLowMemBackground()
    else
      updateLowMemBackground()
    end if

  else
    'we have a roku model that can handle images fading without getting clunky and stuck
    if m.top.newBackgroundType <> m.currentBackgroundType
      'we are creating a new gradient overlay and updating the background image
      'ie. moving from a fullscreen background to a topright background or vice versa
      m.currentBackgroundType = m.top.newBackgroundType
      m.timer.unobserveField("fire")

      'cases
      '1) category screen topright to category screen fullscreen(no gradient)
      '2) category screen topright to details screen fullscreen(gradient)
      '3) details screen fullscreen(gradient) to category screen topright
      
      'remove any background nodes that might be still transitioning when we want to start our new transition
      while m.top.getChildCount() > 1
        if m.newBackgroundAnimation <> invalid
          m.newBackgroundAnimation.control = "stop"
        end if
        m.top.removeChildIndex(0)
      end while

      'identify the animation node for transitioning out the old background image
      m.oldTransitionOut = invalid
      if m.top.getChild(0) <> invalid and m.top.getChild(0).findNode("BackgroundImages") <> invalid and m.top.getChild(0).findNode("BackgroundImages").getChild(0) <> invalid and m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex) <> invalid
        m.oldTransitionOut = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex).findNode("TransitionOut")
      end if

      addNewBackground()
      posterGroup = invalid

      'start transitioning out the old background image and the old gradient
      if m.oldTransitionOut <> invalid and m.top.getChild(0) <> invalid and m.top.getChild(0).findNode("GradientFadeOut") <> invalid
        m.oldTransitionOut.control = "start"
      end if

      'identify the new poster group
      lastAddedPoster = m.top.getChildCount() - 1
      if m.top.getChild(lastAddedPoster) <> invalid and m.top.getChild(lastAddedPoster).findNode("BackgroundImages") <> invalid and m.top.getChild(lastAddedPoster).findNode("BackgroundImages").getChild(0) <> invalid
        posterGroup = m.top.getChild(lastAddedPoster).findNode("BackgroundImages").getChild(0).getChild(0)
      end if

      'start transition in of new poster group (or start listening for the new poster to be loaded)
      if posterGroup <> invalid
        m.newBackgroundPoster = posterGroup.findNode("BackgroundPoster")
        
        if m.newBackgroundPoster.uri = m.blurredDefaultBackground
          m.top.getChild(lastAddedPoster).findNode("BackgroundGradient").opacity = 0.0
          m.newBackgroundAnimation = posterGroup.findNode("FadeInOnly")
        else
          m.newBackgroundAnimation = posterGroup.findNode("TransitionIn")
        end if

        if m.newBackgroundPoster.loadStatus = "ready"
          m.newBackgroundAnimation.observeField("state", "onTransitionComplete")
          m.newBackgroundAnimation.control = "start"
        else
          m.newBackgroundPoster.observeField("loadStatus", "onBackgroundPosterReady")
        end if
      end if
      
      if m.oldTransitionOut <> invalid 
        m.oldTransitionOut.observeField("state", "removeBackground")
      end if


    else
      'normally this is just changing between posters within a category (no need to change the overlay), however, 
      'there is an edge case where a full screen background poster with no overlay on the category screen can transistion to a
      'full screen background poster on the details screen with an overlay
      m.timer.unobserveField("fire")

      'don't update the background image if it hasn't changed (ie. changing categories)
      if m.newBackgroundPoster <> invalid and m.newBackgroundPoster.uri = m.top.backgroundUriList[m.imageIndex]
        return false
      end if

      'remove any background nodes that might be still transitioning when we want to start our new transition
      while m.top.getChildCount() > 1
        if m.newBackgroundAnimation <> invalid
          m.newBackgroundAnimation.control = "stop"
        end if
        m.top.removeChildIndex(0)
      end while

      'remove any image groups/lists that might be still transitioning when we want to start our new transition
      if m.top.getChild(0) <> invalid
        while m.top.getChild(0).findNode("BackgroundImages").getChildCount() > 1
          m.top.getChild(0).findNode("BackgroundImages").removeChildIndex(0)
        end while
      end if

      m.imageIndex = 0
      addNewImageList()

      m.oldTransitionOut = invalid
      if m.top.getChild(0) <> invalid and m.top.getChild(0).findNode("BackgroundImages") <> invalid
        'transition out the old background
        if m.top.getChild(0).findNode("BackgroundImages").getChild(0) <> invalid and m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex) <> invalid
          m.oldTransitionOut = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex).findNode("TransitionOut")

          if m.oldTransitionOut <> invalid
            m.oldTransitionOut.control = "start"
          end if
        end if

        'transition in the new background if ready
        if  m.top.getChild(0).findNode("BackgroundImages").getChild(1) <> invalid
          posterGroup = m.top.getChild(0).findNode("BackgroundImages").getChild(1).getChild(0)

          if posterGroup <> invalid
            m.newBackgroundPoster = posterGroup.findNode("BackgroundPoster")
      
            if m.newBackgroundPoster <> invalid
              if m.newBackgroundPoster.uri = m.blurredDefaultBackground
                m.newBackgroundAnimation = posterGroup.findNode("FadeInOnly")
              else
                m.newBackgroundAnimation = posterGroup.findNode("TransitionIn")
                if m.top.getChild(0).findNode("BackgroundGradient").opacity = 0.0
                  m.top.getChild(0).findNode("BackgroundGradient").opacity = 1.0
                end if
              end if

              if m.newBackgroundPoster.loadStatus = "ready"
                m.newBackgroundAnimation.observeField("state", "onTransitionComplete")
                m.newBackgroundAnimation.control = "start"
              else
                m.newBackgroundPoster.observeField("loadStatus", "onBackgroundPosterReady")
              end if
            end if
          end if
        end if
      end if


      if m.oldTransitionOut <> invalid
        m.oldTransitionOut.observeField("state", "removeImageList")
      end if

    end if
  end if
End Function


'used for the initial set up of the background
Function setUpBackground()
  TubiLog("BackgroundGroup.setUpBackground")
  m.currentBackgroundType = m.top.newBackgroundType

  ' 'pre load the blurred default background in case it doesn't exist
  ' 'addNewBackground() needs a non empty backgroundUriList to work properly
  ' m.top.backgroundUriList = [m.unblurredDefaultBackground]

  ' 'set the unblurred background and make it visible
  ' addNewBackground(true)

  ' if m.top.getChild(0) <> invalid
  '   m.top.getChild(0).findNode("BackgroundGradient").opacity = 1.0
  '   m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(0).findNode("BackgroundPoster").opacity = 1.0
  ' end if

  m.top.backgroundUriList = [m.blurredDefaultBackground]

  if m.global.constants.deviceInfo.limitedNewUi = true
    addLowMemBackground()
  else
    'set the blurred background - opacity is still 0 at this point
    addNewImageList()
  end if
End Function


Function addNewBackground(isIntro=false as Boolean)
  'we have a new background type, so we need to switch out the whole background including the gradient
  ' if isIntro = true
  '   newBackground = CreateObject("roSGNode", "TopRightBackground")
  '   posterType = "FullscreenPoster"

  ' else if m.top.newBackgroundType = "topright"
  if m.top.newBackgroundType = "topright"
    newBackground = CreateObject("roSGNode", "TopRightBackground")
    posterType = "ToprightPoster"
  
  else if m.top.newBackgroundType = "fullscreen"
    newBackground = CreateObject("roSGNode", "FullScreenBackground")
    posterType = "FullscreenPoster"

  else
    return false
  end if

  'populate posters
  backgroundImages = newBackground.findNode("BackgroundImages")
  imageList = getImageList(posterType)

  backgroundImages.appendChild(imageList)

  m.top.appendChild(newBackground)
End Function


Function removeBackground()
  TubiLog("BackgroundGroup.removeBackground")
  m.top.getChild(0).findNode("BackgroundGradient").opacity = 0.0
  if m.oldTransitionOut.state = "stopped"
    m.oldTransitionOut.unobserveField("state")
    m.top.removeChildIndex(0)
  end if
End Function


Function addNewImageList()
  if m.top.newBackgroundType = "topright"
    posterType = "ToprightPoster"
  else if m.top.newBackgroundType = "fullscreen"
    posterType = "FullscreenPoster"
  else
    return false
  end if

  if m.top.getChild(0) = invalid
    addNewBackground()
  end if

  backgroundImages = m.top.getChild(0).findNode("BackgroundImages")
  imageList = getImageList(posterType)
  backgroundImages.appendChild(imageList)
End Function


Function getImageList(posterType as String) as Object
  imageList = CreateObject("roSGNode", "Group")

  for i=0 to m.top.backgroundUriList.count()-1 step 1
    poster = CreateObject("roSGNode", posterType)
    poster.findNode("BackgroundPoster").uri = m.top.backgroundUriList[i]
    imageList.appendChild(poster)
  end for

  return imageList
End Function


Function removeImageList()
  TubiLog("BackgroundGroup.removeImageList")
  if m.oldTransitionOut.state = "stopped"
    m.oldTransitionOut.unobserveField("state")
    m.top.getChild(0).findNode("BackgroundImages").removeChildIndex(0)
  end if
End Function


Function onBackgroundPosterReady()
  TubiLog("BackgroundGroup.onBackgroundPosterReady")
  if m.newBackgroundPoster.loadStatus = "ready"
    m.newBackgroundAnimation.observeField("state", "onTransitionComplete")
    m.newBackgroundAnimation.control = "start"
    m.newBackgroundPoster.unobserveField("loadStatus")
  end if
End Function


Function onTransitionComplete()
  if m.newBackgroundAnimation.state = "stopped"
    m.newBackgroundAnimation.unobserveField("state")

    if m.top.backgroundUriList.count() > 1
      m.timer.observeField("fire", "rotateBackgrounds")
      m.timer.control = "start"
    end if
  end if
End Function


Function rotateBackgrounds()
  m.timer.unobserveField("fire")
  if m.imageIndex + 1 > m.top.backgroundUriList.count() - 1
    futureIndex = 0
  else
    futureIndex = m.imageIndex + 1
  end if

  fadeOut = invalid
  fadeIn = invalid

  if m.top.getChild(0) <> invalid and m.top.getChild(0).findNode("BackgroundImages") <> invalid and m.top.getChild(0).findNode("BackgroundImages").getChild(0) <> invalid
    if m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex) <> invalid
      fadeOut = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex).findNode("TransitionOut")
    end if

    if m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(futureIndex) <> invalid
      fadeIn = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(futureIndex).findNode("FadeInOnly")
      fadeIn.observeField("state", "onTransitionComplete")
      m.newBackgroundPoster = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(futureIndex).findNode("BackgroundPoster")
      m.newBackgroundAnimation = fadeIn
    end if
  end if

  
  if fadeOut <> invalid
    fadeOut.control = "start"
  end if

  if fadeIn <> invalid
    fadeIn.control = "start"
  end if

  m.imageIndex = futureIndex
End Function


'runs when a user selects to "Sign in" from the category screen. 
'Since this will take us to the sign up flow we want to set up a clean start for when we return
Function setUnblurred()
  TubiLog("BackgroundGroup.setUnblurred")
  if m.top.enterFromSignIn = true

    m.updateCount = 0

    'remove any backgrounds
    while m.top.getChildCount() > 0
      if m.newBackgroundAnimation <> invalid
        m.newBackgroundAnimation.control = "stop"
      end if
      m.top.removeChildIndex(0)
    end while

    setUpBackground()

  end if
End Function


Function addLowMemBackground()
  TubiLog("BackgroundGroup.addLowMemBackground")
  if m.top.newBackgroundType = "topright"
    newBackground = CreateObject("roSGNode", "TopRightBackground")
    newBackground.findNode("BackgroundImages").createChild("Group").createChild("ToprightPoster")
  else if m.top.newBackgroundType = "fullscreen"
    newBackground = CreateObject("roSGNode", "FullScreenBackground")
    newBackground.findNode("BackgroundImages").createChild("Group").createChild("FullscreenPoster")
  end if

  poster = newBackground.findNode("BackgroundPoster")
  ' Reduce VRAM usage by 25%
  poster.loadWidth = poster.loadWidth * 0.5
  poster.loadHeight = poster.loadHeight * 0.5
  poster.uri = m.top.backgroundUriList[0]

  m.top.appendChild(newBackground)
  m.top.getChild(0).findNode("BackgroundGradient").opacity = 1.0
  m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(0).findNode("BackgroundPoster").opacity = 1.0
End Function


Function updateLowMemBackground()
  TubiLog("BackgroundGroup.updateLowMemBackground")
  backgroundImage = m.top.getChild(0).findNode("BackgroundPoster")
  backgroundGradient = m.top.getChild(0).findNode("BackgroundGradient")

  if m.top.newBackgroundType = "topright"
    backgroundGradient.visible = true
    if backgroundGradient.uri <> "pkg:/images/home-gradient-25.png"
      backgroundImage.visible = false
      backgroundGradient.uri = "pkg:/images/home-gradient-25.png"
      backgroundImage.uri = m.top.backgroundUriList[0]
      backgroundImage.loadWidth="1615"
      backgroundImage.width="1615"
      backgroundImage.loadHeight="909"
      backgroundImage.height="909"
      backgroundImage.translation="[305,0]"
      backgroundImage.visible = true
    else if not m._.empty(m.top.backgroundUriList)
      backgroundImage.uri = m.top.backgroundUriList[0]
    end if

  else if m.top.newBackgroundType = "fullscreen"
    if backgroundGradient.uri <> "pkg:/images/detail-gradient-25.png"
      if m.top.backgroundUriList[0] = m.blurredDefaultBackground
        backgroundGradient.visible = false
      else
        backgroundGradient.visible = true
      end if

      backgroundImage.visible = false
      backgroundGradient.uri = "pkg:/images/detail-gradient-25.png"
      backgroundImage.uri = m.top.backgroundUriList[0]
      backgroundImage.loadWidth="1920"
      backgroundImage.width="1920"
      backgroundImage.loadHeight="1080"
      backgroundImage.height="1080"
      backgroundImage.translation="[0,0]"
      backgroundImage.visible = true
    else if not m._.empty(m.top.backgroundUriList)
      backgroundImage.uri = m.top.backgroundUriList[0]
    end if
  end if

End Function
