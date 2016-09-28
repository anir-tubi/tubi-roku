Function init()
  m.top.observeField("newBackgroundType", "updateBackground")
  m.newBackgroundPoster = invalid
  m.newBackgroundAnimation = invalid
End Function


Function updateBackground()
  TubiLog("BackgroundGroup.updateBackground")

  if m.global.constants.deviceInfo.lowMemory = true
    ' we have a low memory device that won't handle transitions so make it basic
    if m.top.getChildCount() = 0
      addNewBackground()
    else
      updateLowMemBackground()
    end if

  else
    'we have a roku model that can handle images fading without getting clunky and stuck

    'just add a background
    if m.top.getChildCount() = 0
      addNewBackground()
      m.newBackgroundPoster = m.top.getChild(0).findNode("BackgroundImage")

      if m.top.backgroundUri = "pkg:/images/grid-default-blurred.jpg"
        m.newBackgroundAnimation = m.top.getChild(0).findNode("FadeInOnly")
      else
        m.newBackgroundAnimation = m.top.getChild(0).findNode("TransitionIn")
      end if

      if m.newBackgroundPoster.loadStatus = "ready"
        m.newBackgroundAnimation.control = "start"
      else
        m.newBackgroundPoster.observeField("loadStatus", "onBackgroundPosterReady")
      end if

    'occurs when users click through titles before transitions complete,
    'remove any excess backgrounds then transition old background and add a background
    else if m.top.getChildCount() > 1

      'remove any background images that might be still transitioning when we want to start our new transition
      while m.top.getChildCount() > 1
        m.top.removeChildIndex(0)
      end while

      addNewBackground()
      oldTransitionOut = m.top.getChild(0).findNode("TransitionOut")
      oldTransitionOut.control = "start"
      
      m.newBackgroundPoster = m.top.getChild(1).findNode("BackgroundImage")
      
      if m.top.backgroundUri = "pkg:/images/grid-default-blurred.jpg"
        m.newBackgroundAnimation = m.top.getChild(1).findNode("FadeInOnly")
      else
        m.newBackgroundAnimation = m.top.getChild(1).findNode("TransitionIn")
      end if

      if m.newBackgroundPoster.loadStatus = "ready"
        m.newBackgroundAnimation.control = "start"
      else
        m.newBackgroundPoster.observeField("loadStatus", "onBackgroundPosterReady")
      end if
      
      oldTransitionOut.observeField("state", "removeBackground")


    'transition old background and add a background
    else
      addNewBackground()
      oldTransitionOut = m.top.getChild(0).findNode("TransitionOut")
      oldTransitionOut.control = "start"
      
      m.newBackgroundPoster = m.top.getChild(1).findNode("BackgroundImage")
      
      if m.top.backgroundUri = "pkg:/images/grid-default-blurred.jpg"
        m.newBackgroundAnimation = m.top.getChild(1).findNode("FadeInOnly")
      else
        m.newBackgroundAnimation = m.top.getChild(1).findNode("TransitionIn")
      end if

      if m.newBackgroundPoster.loadStatus = "ready"
        m.newBackgroundAnimation.control = "start"
      else
        m.newBackgroundPoster.observeField("loadStatus", "onBackgroundPosterReady")
      end if
      
      oldTransitionOut.observeField("state", "removeBackground")

    end if

  end if


End Function


Function addNewBackground()
  if m.top.newBackgroundType = "grid"
    newBackground = CreateObject("roSGNode", "GridBackground")
  
  else if m.top.newBackgroundType = "details"
    newBackground = CreateObject("roSGNode", "DetailsBackground")

  end if

  newBackground.findNode("BackgroundImage").uri = m.top.backgroundUri

  m.top.appendChild(newBackground)

End Function


Function removeBackground()
  TubiLog("BackgroundGroup.removeBackground")
  oldTransitionOut = m.top.getChild(0).findNode("TransitionOut")
  if oldTransitionOut.state = "stopped"
    oldTransitionOut.unobserveField("state")
    m.top.removeChildIndex(0)
  end if
End Function


Function onBackgroundPosterReady()
  TubiLog("BackgroundGroup.onBackgroundPosterReady")
  if m.newBackgroundPoster.loadStatus = "ready"
    m.newBackgroundAnimation.control = "start"
    m.newBackgroundPoster.unobserveField("loadStatus")    
  end if
End Function


Function updateLowMemBackground()
  TubiLog("BackgroundGroup.updateLowMemBackground")
  backgroundImage = m.top.getChild(0).findNode("BackgroundImage")
  backgroundGradient = m.top.getChild(0).findNode("BackgroundGradient")

  if m.top.newBackgroundType = "grid"
    if backgroundGradient.uri <> "pkg:/images/home-gradient-25.png"
      backgroundImage.visible = false
      backgroundGradient.uri = "pkg:/images/home-gradient-25.png"
      backgroundImage.uri = m.top.backgroundUri
      backgroundImage.visible = true
    else
      backgroundImage.uri = m.top.backgroundUri
    end if

  else if m.top.newBackgroundType = "details"
    if backgroundGradient.uri <> "pkg:/images/detail-gradient-25.png"
      backgroundImage.visible = false
      backgroundGradient.uri = "pkg:/images/detail-gradient-25.png"
      backgroundImage.uri = m.top.backgroundUri
      backgroundImage.visible = true
    else
      backgroundImage.uri = m.top.backgroundUri
    end if
  end if

End Function
