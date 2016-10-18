Function init()
  TubiLog("BackgroundGroup.init")
  m.top.observeField("newBackgroundType", "updateBackground")
  m.top.observeField("enterFromSignIn", "setUnblurred")
  m.top.observeField("catScreenStart", "startTimer")

  m.newBackgroundPoster = invalid
  m.newBackgroundAnimation = invalid
  m.oldTransitionOut = invalid
  m.currentBackgroundType = invalid
  m.unblurredDefaultBackground = "pkg:/images/non-blurred-default-background.jpg"
  m.blurredDefaultBackground = "pkg:/images/grid-default-blurred.jpg"
  m.imageIndex = 0

  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.duration = 3

  setUpBackground()
  m.updateCount = 0
End Function


Function updateBackground()
  TubiLog("BackgroundGroup.updateBackground")
  m.updateCount = m.updateCount + 1

  if m.global.constants.deviceInfo.lowMemory = true
    ' we have a low memory device that won't handle transitions so make it basic
    if m.top.getChildCount() = 0
      addLowMemBackground()
    else
      updateLowMemBackground()
    end if

  else
    'we have a roku model that can handle images fading without getting clunky and stuck

    'we don't want to transition the background on the first jump to the featured category
    if m.updateCount < 2
      return false
    end if


    if m.top.newBackgroundType <> m.currentBackgroundType
      'we are creating a new gradient overlay and updating the background image
      'ie. moving from the category screen to details screen or vice versa
      m.currentBackgroundType = m.top.newBackgroundType
      m.timer.unobserveField("fire")
      
      'remove any background nodes that might be still transitioning when we want to start our new transition
      while m.top.getChildCount() > 1
        if m.newBackgroundAnimation <> invalid
          m.newBackgroundAnimation.control = "stop"
        end if
        m.top.removeChildIndex(0)
      end while

      addNewBackground()
      m.oldTransitionOut = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex).findNode("TransitionOut")
      m.oldTransitionOut.control = "start"
      m.top.getChild(0).findNode("GradientFadeOut").control = "start"
      
      posterGroup = m.top.getChild(1).findNode("BackgroundImages").getChild(0).getChild(0)

      if posterGroup <> invalid
        m.newBackgroundPoster = posterGroup.findNode("BackgroundPoster")
        
        if m.newBackgroundPoster.uri = m.blurredDefaultBackground
          m.newBackgroundAnimation = posterGroup.findNode("FadeInOnly")
        else
          m.newBackgroundAnimation = posterGroup.findNode("TransitionIn")
        end if

        ' m.top.getChild(1).findNode("GradientFadeIn").control = "start"

        if m.newBackgroundPoster.loadStatus = "ready"
          m.newBackgroundAnimation.observeField("state", "onTransitionComplete")
          m.newBackgroundAnimation.control = "start"
        else
          m.newBackgroundPoster.observeField("loadStatus", "onBackgroundPosterReady")
        end if
      end if
      
      m.oldTransitionOut.observeField("state", "removeBackground")



    else
      'we are not changing the gradient overlay because the background types are the same
      'so we are just updating the background image list

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
      while m.top.getChild(0).findNode("BackgroundImages").getChildCount() > 1
        m.top.getChild(0).findNode("BackgroundImages").removeChildIndex(0)
      end while

      m.imageIndex = 0
      addNewImageList()

      m.oldTransitionOut = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex).findNode("TransitionOut")
      m.oldTransitionOut.control = "start"

      posterGroup = m.top.getChild(0).findNode("BackgroundImages").getChild(1).getChild(0)
      
      m.newBackgroundPoster = posterGroup.findNode("BackgroundPoster")

      if m.newBackgroundPoster.uri = m.blurredDefaultBackground
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
      
      m.oldTransitionOut.observeField("state", "removeImageList")

    end if
  end if
End Function


'used for the initial set up of the background
Function setUpBackground()
  TubiLog("BackgroundGroup.setUpBackground")
  m.currentBackgroundType = m.top.newBackgroundType

  'pre load the blurred default background in case it doesn't exist
  'addNewBackground() needs a non empty backgroundUriList to work properly
  m.top.backgroundUriList = [m.unblurredDefaultBackground]

  'set the unblurred background and make it visible
  addNewBackground(true)
  m.top.getChild(0).findNode("BackgroundGradient").opacity = 1.0
  m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(0).findNode("BackgroundPoster").opacity = 1.0

  m.top.backgroundUriList = [m.blurredDefaultBackground]

  'set the blurred background - opacity is still 0 at this point
  addNewImageList()
End Function


'this is used specifically when we are listening for if the category screen was loaded via the catScreenStart field
Function startTimer()
  TubiLog("BackgroundGroup.startTimer on CategoryScreen start")
  m.timer.unobserveField("fire")
  m.timer.control = "stop"
  m.timer.observeField("fire", "blurBackground")
  m.timer.control = "start"
End Function


Function addNewBackground(isIntro=false as Boolean)
  'we have a new background type, so we need to switch out the whole background including the gradient
  if isIntro = true
    newBackground = CreateObject("roSGNode", "GridBackground")
    posterType = "DetailsPoster"

  else if m.top.newBackgroundType = "grid"
    newBackground = CreateObject("roSGNode", "GridBackground")
    posterType = "GridPoster"
  
  else if m.top.newBackgroundType = "details"
    newBackground = CreateObject("roSGNode", "DetailsBackground")
    posterType = "DetailsPoster"

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
  if m.oldTransitionOut.state = "stopped"
    m.oldTransitionOut.unobserveField("state")
    m.top.removeChildIndex(0)
  end if
End Function


Function addNewImageList()
  if m.top.newBackgroundType = "grid"
    posterType = "GridPoster"
  else if m.top.newBackgroundType = "details"
    posterType = "DetailsPoster"
  else
    return false
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

  fadeOut = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(m.imageIndex).findNode("TransitionOut")
  fadeIn = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(futureIndex).findNode("FadeInOnly")

  fadeIn.observeField("state", "onTransitionComplete")
  m.newBackgroundPoster = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(futureIndex).findNode("BackgroundPoster")
  m.newBackgroundAnimation = fadeIn
  
  fadeOut.control = "start"
  fadeIn.control = "start"

  m.imageIndex = futureIndex
End Function


'runs when a user selects to "Sign In" from the category screen. 
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


Function blurBackground()
  TubiLog("BackgroundGroup.blurBackground")
  m.timer.unobserveField("fire")
  current = m.top.getChild(0).findNode("BackgroundImages").getChild(0).getChild(0)
  
  if current <> invalid and current.findNode("BackgroundPoster").uri = m.unblurredDefaultBackground
    future = m.top.getChild(0).findNode("BackgroundImages").getChild(1).getChild(0)
    fadeOut = current.findNode("TransitionOut")
    fadeIn = future.findNode("FadeInOnly")

    fadeOut.control = "start"
    fadeIn.control = "start"

    m.newBackgroundPoster = future.findNode("BackgroundPoster")
    m.newBackgroundAnimation = fadeIn
  end if
End Function


Function addLowMemBackground()
  if m.top.newBackgroundType = "grid"
    newBackground = CreateObject("roSGNode", "GridBackground")
  
  else if m.top.newBackgroundType = "details"
    newBackground = CreateObject("roSGNode", "DetailsBackground")

  end if

  newBackground.findNode("BackgroundPoster").uri = m.top.backgroundUriList[0]

  m.top.appendChild(newBackground)
End Function


Function updateLowMemBackground()
  TubiLog("BackgroundGroup.updateLowMemBackground")
  backgroundImage = m.top.getChild(0).findNode("BackgroundPoster")
  backgroundGradient = m.top.getChild(0).findNode("BackgroundGradient")

  if m.top.newBackgroundType = "grid"
    if backgroundGradient.uri <> "pkg:/images/home-gradient-25.png"
      backgroundImage.visible = false
      backgroundGradient.uri = "pkg:/images/home-gradient-25.png"
      backgroundImage.uri = m.top.backgroundUriList[0]
      backgroundImage.visible = true
    else
      backgroundImage.uri = m.top.backgroundUriList[0]
    end if

  else if m.top.newBackgroundType = "details"
    if backgroundGradient.uri <> "pkg:/images/detail-gradient-25.png"
      backgroundImage.visible = false
      backgroundGradient.uri = "pkg:/images/detail-gradient-25.png"
      backgroundImage.uri = m.top.backgroundUriList[0]
      backgroundImage.visible = true
    else
      backgroundImage.uri = m.top.backgroundUriList[0]
    end if
  end if

End Function
