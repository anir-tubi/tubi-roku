'''''''''''''''''''''''''''
' slideFade
'
' Animate the target component in or out with a slide and fade effect
'
' @startOrEndLocation - 'above' 'below' 'left' 'right'.  If animating IN, this is start location, otherwise end
' @inOrOut - 'in' or 'out'
' @translationDifference - how many pixels the target should slide
Function slideFade(target As Object, startOrEndLocation As String, inOrOut As String, duration=2.0 As Float, delay=0.0 As Float, translationDifference = 100 as Integer)
  animationOptions = {
    duration: duration
    delay: delay
  }

  ' this function persists an origin so the caller doesn't have to
  if target.hasField("slideFadeOrigin") then
    target.translation = target.slideFadeOrigin
  else
    target.addField("slideFadeOrigin", "vector2d", false)
    target.slideFadeOrigin = target.translation
  end if

  if startOrEndLocation = "right"
    slideX = target.translation[0] + translationDifference
    slideY = target.translation[1]
  else if startOrEndLocation = "left"
    slideX = target.translation[0] - translationDifference
    slideY = target.translation[1]
  else if startOrEndLocation = "above"
    slideX = target.translation[0]
    slideY = target.translation[1] - translationDifference
  else if startOrEndLocation = "below"
    slideX = target.translation[0]
    slideY = target.translation[1] + translationDifference
  else 'no slide
    slideX = target.translation[0]
    slideY = target.translation[1]
  end if

  if inOrOut = "in"
    animationOptions.opacity = 1.0
    animationOptions.origin = [slideX, slideY]
    animationOptions.destination = target.translation
  else
    animationOptions.opacity = 0.0
    animationOptions.origin = target.translation
    animationOptions.destination = [slideX, slideY]
  end if
  return animate(target, animationOptions)
End Function


' Animate the target component in or out with a slide and fade effect.
' Similar to slideFade but allows arbitrary directions, not only 90 degrees
'
' @target: roSGNode: the component that will be animated
' @endTranslation: 2d Array, the translation to which the target will be slid
' @inOrOut: "in" or "out", "in" to animate opacity to 1.0. "out" to animate opacity to 0.0
' @duration: float, the amount of time it will take the animation to complete, in seconds
' @delay: float, the amount of time to wait before starting the animation, in seconds
Function slideFadeGeneral(target, endTranslation, inOrOut, duration=2.0, delay=0.0)
  animationOptions = {
    duration: duration
    delay: delay
  }

  ' this function persists an origin so the caller doesn't have to
  if target.hasField("slideFadeOrigin") then
    target.translation = target.slideFadeOrigin
  else
    target.addField("slideFadeOrigin", "vector2d", false)
    target.slideFadeOrigin = target.translation
  end if

  if type(endTranslation) = "roArray" AND endTranslation.count() = 2
    slideX = endTranslation[0]
    slideY = endTranslation[1]
    animationOptions.origin = target.translation
    animationOptions.destination = [slideX, slideY]
  end if

  if inOrOut = "in"
    animationOptions.opacity = 1.0
  else
    animationOptions.opacity = 0.0
  end if

  return animate(target, animationOptions)
End Function


'''''''''''''
' slideTo
'
' simple helper to slide the component to the destination.
Function slideTo(target As Object, destination As Object, duration As Float, delay=0.0 As Float)
  animationOptions = {
    duration: duration
    delay: delay
    destination: destination
  }
  return animate(target, animationOptions)
End Function


'''''''''''''
' bubbleIn
'
' Effect to reveal by scaling from 0 to 1
Function bubbleIn(target As Object, duration As Float, delay=0.0 As Float)
  target.scale = [0.0, 0.0]
  animationOptions = {
    duration: duration
    delay: delay
    opacity: 1.0
    scale: 1.0
  }
  return animate(target, animationOptions)
End Function


'''''''''''''
' resize
'
' animate the width and height of the target simultaneously
Function resize(target As Object, width As Float, height As Float, duration As Float, delay=0.0 As Float)
  animationOptions = {
    duration: duration
    delay: delay
    width: width
    height: height
  }
  return animate(target, animationOptions)
End Function


'''''''''''''
' resizeToLocation
'
' animate the width and height of the target while simultaneously animating the translation
Function resizeToLocation(target As Object, width As Float, height As Float, destination As Object, duration As Float, delay=0.0 As Float)
  animationOptions = {
    duration: duration
    delay: delay
    width: width
    height: height
    destination: destination
  }
  return animate(target, animationOptions)
End Function


'''''''''''''
' animateItemSize
'
' animate the itemSize property of the target
' @param target: Object, the target element that is being animated 
' @param itemSize: vector2d array, the itemSize property of the target that will be animated
' @param duration: float, the duration of the animation
' @param delay: float, the delay (if any) of the animation
Function animateItemSize(target As Object, itemSize As Object, duration As Float, delay=0.0 As Float)
  animationOptions = {
    duration: duration
    delay: delay
    itemSize: itemSize
  }
  return animate(target, animationOptions)
End Function


'''''''''''''
' colorSlide
'
' transitions the color of a node
Function colorChange(target As Object, color As String, duration As Float, delay=0.0 As Float)
  animationOptions = {
    color: color
    duration: duration
    delay: delay
  }
  return animate(target, animationOptions)
End Function


Function fade(target As Object, outOrIn As String, duration As Float, delay=0.0 As Float, endingOpacity = -1)
  animationOptions = {
    duration: duration
    delay: delay
  }

  if endingOpacity < 0
    if outOrIn = "out"
      animationOptions.opacity = 0.0
    else if outOrIn = "in"
      animationOptions.opacity = 1.0
    end if
  else
    '// If the ending opacity is passed then overwrite the value set by the outOrIn string
    if endingOpacity > 1
      endingOpacity = 1
    end if
    animationOptions.opacity = endingOpacity
  end if

  if animationOptions.opacity = target.opacity
    '//The desired opacity has already been reached, so no need to animate
    animationOptions.duration = 0
    animationOptions.delay = 0
  end if

  return animate(target, animationOptions)
End Function


''''''''''''
' animate
'
' Animate a target components scale, opacity, and translation with optional delay.
' @target: SGNode:, a node on which animations will be performed
' @options: assocArray, animation options. Valid options are:
'           origin: vector2d array, representing an x,y translation from which a slide animation starts
'           destination: vector2d array, representing an x,y translation to which a slide animation ends
'           itemSize: vector2d array, representing a width/height itemSize to which a resize animation ends
'           opacity: float, representing the final opacity in a fade animation
'           scale: float, representing the final scale of a resize animation
'           color: hex value e.g. RGBA 0xFFFFFFFF, representing the final color of a color change animation
'           duration: float, the duration of the animation
'           delay: float, a delay time before the animation begins
'           easeFunction: string, one of the allowed SceneGraph animation ease functions
'           completeCallback: function, callback function fired when animation completes

' NOTE!: It's CRITICAL that the target object has a globally unique id.  This is a limitation
'        of the Animation node which references the target by ID.
' NOTE2!: It's CRITICAL that target a child of the component in which animate() is called. It cannot
'         be called with m.top, nor some item which is not a descendant of m.top.  This is due
'         to the way Animate uses findNode internally to find the animation target by id.
' NOTE3!: Potential leak here if animations are applied to dynamically created targets.  While targets
'         may be removed and go out of scope, their animations don't get garbage collected with them.
' TODO(Chris): check for abandoned animations here and remove them
Function animate(target As Object, options as Object) As Object
  if type(target) = "roSGNode" AND target.id <> ""
    if options.origin = invalid then options.origin = target.translation
    if options.duration = invalid then options.duration = 2.0
    if options.delay = invalid then options.delay = 0
    if options.easeFunction = invalid then options.easeFunction = "inOutCubic"
    if options.allowOnLowSpecDevices = invalid then options.allowOnLowSpecDevices = false

    tubiLog("animate target = " + target.id)
    animationId = "GeneralAnimation-" + target.id

    bAnimate = true
    ' if low-spec device, then instantly change to target option rather than using animation
    '//TODO investigate using optional=true parameter on animation
    if m.constants = invalid
      m.constants = getConstantsFromGlobal()
    end if

    if m.constants <> invalid AND m.constants.deviceInfo.limitedUi = true
      ' hardcoding easeFunction=linear for better performance in lower-end even if allowOnLowSpecDevices=true
      options.easeFunction = "linear"

      if options.allowOnLowSpecDevices = false
        tubiLog("Do not animate due to being a low-spec device, " + target.id)
        bAnimate = false
      end if

    end if

    if options.duration <= 0
      tubiLog("Do not animate due to duration being 0")
      bAnimate = false
    end if

    ' Reuse an existing animation if available
    animation = m.top.findNode(animationId)
    if animation = invalid then
      animation = m.top.createChild("Animation")
      animation.id = animationId
    else if animation.state <> "stopped"
      animation.control = "stop"
    end if

    fadeInterpolator = animation.findNode("FadeInterpolator-" + target.id)
    if fadeInterpolator = invalid AND options.opacity <> invalid
      fadeInterpolator = animation.createChild("FloatFieldInterpolator")
      fadeInterpolator.id = "FadeInterpolator-" + target.id
      fadeInterpolator.fieldToInterp = target.id + ".opacity"
    else if fadeInterpolator <> invalid AND options.opacity = invalid
      animation.removeChild(fadeInterpolator)
    end if

    slideInterpolator = animation.findNode("SlideInterpolator-" + target.id)
    if slideInterpolator = invalid AND (options.destination <> invalid AND options.origin <> invalid)
      if options.origin[0] <> options.destination[0] OR options.origin[1] <> options.destination[1]
        slideInterpolator = animation.createChild("Vector2DFieldInterpolator")
        slideInterpolator.id = "SlideInterpolator-" + target.id
        slideInterpolator.fieldToInterp = target.id + ".translation"
      end if
    else if slideInterpolator <> invalid AND (options.destination = invalid OR options.origin = invalid)
      animation.removeChild(slideInterpolator)
    end if

    itemSizeInterpolator = animation.findNode("ItemSizeInterpolator-" + target.id)
    targetItemSize = target.itemSize
    if itemSizeInterpolator = invalid AND options.itemSize <> invalid AND targetItemSize <> invalid
      if targetItemSize[0] <> options.itemSize[0] OR targetItemSize[1] <> options.itemSize[1]
        itemSizeInterpolator = animation.createChild("Vector2DFieldInterpolator")
        itemSizeInterpolator.id = "ItemSizeInterpolator-" + target.id
        itemSizeInterpolator.fieldToInterp = target.id + ".itemSize"
      end if
    else if itemSizeInterpolator <> invalid AND options.itemSize = invalid
      animation.removeChild(itemSizeInterpolator)
    end if

    scaleInterpolator = animation.findNode("ScaleInterpolator-" + target.id)
    if scaleInterpolator = invalid AND options.scale <> invalid
      scaleInterpolator = animation.createChild("Vector2DFieldInterpolator")
      scaleInterpolator.id = "ScaleInterpolator-" + target.id
      scaleInterpolator.fieldToInterp = target.id + ".scale"
    else if scaleInterpolator <> invalid AND options.scale = invalid
      animation.removeChild(scaleInterpolator)
    end if

    colorInterpolator = animation.findNode("ColorInterpolator-" + target.id)
    if colorInterpolator = invalid AND (options.color <> invalid AND target.color <> invalid)
      colorInterpolator = animation.createChild("ColorFieldInterpolator")
      colorInterpolator.id = "ColorInterpolator-" + target.id
      colorInterpolator.fieldToInterp = target.id + ".color"
    else if colorInterpolator <> invalid AND (options.color = invalid OR target.color = invalid)
      animation.removeChild(colorInterpolator)
    end if

    heightInterpolator = animation.findNode("HeightInterpolator-" + target.id)
    if heightInterpolator = invalid AND (options.height <> invalid AND target.height <> invalid AND options.height <> target.height)
      heightInterpolator = animation.createChild("FloatFieldInterpolator")
      heightInterpolator.id = "HeightInterpolator-" + target.id
      heightInterpolator.fieldToInterp = target.id + ".height"
    else if heightInterpolator <> invalid AND (options.height = invalid OR options.height = target.height)
      animation.removeChild(heightInterpolator)
    end if

    widthInterpolator = animation.findNode("WidthInterpolator-" + target.id)
    if widthInterpolator = invalid AND (options.width <> invalid AND target.width <> invalid AND options.width <> target.width)
      widthInterpolator = animation.createChild("FloatFieldInterpolator")
      widthInterpolator.id = "WidthInterpolator-" + target.id
      widthInterpolator.fieldToInterp = target.id + ".width"
    else if widthInterpolator <> invalid AND (options.width = invalid OR options.width = target.width)
      animation.removeChild(widthInterpolator)
    end if

    ' fake a delay
    totalTime = options.delay + options.duration
    if totalTime = 0.0 then
      delayTime = 0.0
    else
      delayTime = options.delay / totalTime
    end if

    if fadeInterpolator <> invalid
      fadeInterpolator.key = [0.0, delayTime, 1.0]
      fadeInterpolator.keyValue = [target.opacity, target.opacity, options.opacity]

      if bAnimate = false
        target.opacity = options.opacity
      end if
    end if

    if slideInterpolator <> invalid
      slideInterpolator.key = [0.0, delayTime, 1.0]
      ' BUG: For some reason, keyValue cannot be set with the following line.  The firmware complains
      '      about a type mismatch.  Hence the verbose line below that which seems overly pedantic.
      '      slideInterpolator.keyValue = [origin, origin, destination]
      if options.destination <> invalid
        slideInterpolator.keyValue = [[options.origin[0], options.origin[1]], [options.origin[0], options.origin[1]], [options.destination[0], options.destination[1]]]

        if bAnimate = false
          target.translation = [options.destination[0], options.destination[1]]
        end if
      end if
    end if

    if itemSizeInterpolator <> invalid
      itemSizeInterpolator.key = [0.0, delayTime, 1.0]
      if options.itemSize <> invalid
        'see above comment about slideInterpolator keyValue format
        itemSizeInterpolator.keyValue = [[target.itemSize[0], target.itemSize[1]], [target.itemSize[0], target.itemSize[1]], [options.itemSize[0], options.itemSize[1]]]

        if bAnimate = false
          target.itemSize = [options.itemSize[0], options.itemSize[1]]
        end if
      end if
    end if

    if scaleInterpolator <> invalid
      scaleInterpolator.key = [0.0, delayTime, 1.0]
      'see above comment about slideInterpolator keyValue format
      scaleInterpolator.keyValue = [[target.scale[0], target.scale[1]], [target.scale[0], target.scale[1]], [options.scale, options.scale]]

      if bAnimate = false
        target.scale = [options.scale, options.scale]
      end if
    end if

    if colorInterpolator <> invalid
      colorInterpolator.key = [0.0, delayTime, 1.0]
      colorInterpolator.keyValue = [target.color, target.color, options.color]

      if bAnimate = false
        target.color = options.color
      end if
    end if

    if heightInterpolator <> invalid
      heightInterpolator.key = [0.0, delayTime, 1.0]
      heightInterpolator.keyValue = [target.height, target.height, options.height]

      if bAnimate = false
        target.height = options.height
      end if
    end if

    if widthInterpolator <> invalid
      widthInterpolator.key = [0.0, delayTime, 1.0]
      widthInterpolator.keyValue = [target.width, target.width, options.width]

      if bAnimate = false
        target.width = options.width
      end if
    end if

    if bAnimate = true
      animation.duration = totalTime
      animation.easeFunction = options.easeFunction
      animation.unobserveFieldScoped("state")

      if options.completeCallback <> invalid then
        m[animationId + "CompleteCallback"] = options.completeCallback
        animation.observeFieldScoped("state", "AnimationMixin_onAnimationStateChange")
      end if

      animation.control = "start"
      return animation
    else
      return invalid
    end if
  else
    return invalid
  end if
End Function


' callback intermediary for all animations with a complete callback
Function AnimationMixin_onAnimationStateChange(msg)
  if msg.getData() = "stopped" then
    animationId = msg.getRoSGNode().id
    key = animationId + "CompleteCallback"
    completeCallback = m[key]
    if completeCallback <> invalid then
      m.delete(key)
      completeCallback()
    end if
  end if
End Function



''''''''''''
' finishAnimation
'
' Jump to the final state of an animation that was triggered with the animate() function above
' @target: SGNode:, a node on which animations will be performed
'
' returns true if an animation was ended, returns false if the animation was not ended
'
' Note: this function only works on ending animations created by using the animate() function in this AnimationMixin file.
' It will not end animations built from other sources (like animation nodes included in a component's XML)
Function finishAnimation(target as Object) as Boolean
  if target <> invalid AND target.id <> invalid AND type(target) = "roSGNode"
    'Find the existing animation
    animationId = "GeneralAnimation-" + target.id
    animation = m.top.findNode(animationId)

    if animation <> invalid
      animation.control = "finish"
      return true
    end if
  end if

  return false
End Function


' Helper function to stop an animation. Usually used in case we want to start an animation
' on a UI component that is still running an animation (in which case we should stop it before
' starting the new animation)
'
' @animation: roSGNode, an Animation node (usually returned by animate() in this mixin)
Function stopAnimation(animation)
  if type(animation) = "roSGNode" AND animation.isSubType("AnimationBase")
    if animation.state <> "stopped"
      animation.control = "stop"
    end if
  end if
  return animation
End Function
