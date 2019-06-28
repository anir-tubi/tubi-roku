'''''''''''''''''''''''''''
' slideFade
'
' Animate the target component in or out with a slide and fade effect
'
' @startOrEndLocation - 'above' 'below' 'left' 'right'.  If animating IN, this is start location, otherwise end
' @inOrOut - 'in' or 'out'
Function slideFade(target As Object, startOrEndLocation As String, inOrOut As String, duration=2.0 As Float, delay=0.0 As Float)
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
    slideX = target.translation[0] + 100
    slideY = target.translation[1]
  else if startOrEndLocation = "left"
    slideX = target.translation[0] - 100
    slideY = target.translation[1]
  else if startOrEndLocation = "above"
    slideX = target.translation[0]
    slideY = target.translation[1] - 100
  else if startOrEndLocation = "below"
    slideX = target.translation[0]
    slideY = target.translation[1] + 100
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


Function fade(target As Object, outOrIn As String, duration As Float, delay=0.0 As Float)
  animationOptions = {
    duration: duration
    delay: delay
  }
  if outOrIn = "out"
    animationOptions.opacity = 0.0
    return animate(target, animationOptions)
  else if outOrIn = "in"
    animationOptions.opacity = 1.0
    return animate(target, animationOptions)
  end if
End Function



''''''''''''
' animate
'
' Animate a target components scale, opacity, and translation with optional delay.
' @target: SGNode:, a node on which animations will be performed
' @options: assocArray, animation options. Valid options are:
'           origin: vector2d array, representing an x,y translation from which a slide animation starts
'           destination: vector2d array, representing an x,y translation to which a slide animation ends
'           opacity: float, representing the final opacity in a fade animation
'           scale: float, representing the final scale of a resize animation
'           color: hex value e.g. RGBA 0xFFFFFFFF, representing the final color of a color change animation
'           duration: float, the duration of the animation
'           delay: float, a delay time before the animation begins
'           easeFunction: string, one of the allowed SceneGraph animation ease functions

' NOTE!: It's CRITICAL that the target object has a globally unique id.  This is a limitation
'        of the Animation node which references the target by ID.
' NOTE2!: It's CRITICAL that target a child of the component in which animate() is called. It cannot
'         be called with m.top, nor some item which is not a descendant of m.top.  This is due
'         to the way Animate uses findNode internally to find the animation target by id.
' NOTE3!: Potential leak here if animations are applied to dynamically created targets.  While targets
'         may be removed and go out of scope, their animations don't get garbage collected with them.
' TODO(Chris): check for abandoned animations here and remove them
Function animate(target As Object, options as Object) As Object
  if target <> invalid and target.id <> invalid and type(target) = "roSGNode"
    if options.origin = invalid then options.origin = target.translation
    if options.duration = invalid then options.duration = 2.0
    if options.delay = invalid then options.delay = 0
    if options.easeFunction = invalid then options.easeFunction = "inOutCubic"

    tubiLog("animate target = " + target.id)
    animationId = "GeneralAnimation-" + target.id

    ' Reuse an existing animation if available
    animation = m.top.findNode(animationId)
    if animation = invalid then
      animation = m.top.createChild("Animation")
      animation.id = animationId
    else if animation.state <> "stopped"
      animation.control = "stop"
    end if

    fadeinterpolator = animation.findNode("FadeInterpolator-" + target.id)
    if fadeinterpolator = invalid and options.opacity <> invalid
      fadeinterpolator = animation.createChild("FloatFieldInterpolator")
      fadeinterpolator.id = "FadeInterpolator-" + target.id
      fadeinterpolator.fieldToInterp = target.id + ".opacity"
    else if fadeinterpolator <> invalid and options.opacity = invalid
      animation.removeChild(fadeinterpolator)
    end if

    slideinterpolator = animation.findNode("SlideInterpolator-" + target.id)
    if slideinterpolator = invalid and (options.destination <> invalid and options.origin <> invalid)
      if options.origin[0] <> options.destination[0] or options.origin[1] <> options.destination[1]
        slideinterpolator = animation.createChild("Vector2DFieldInterpolator")
        slideinterpolator.id = "SlideInterpolator-" + target.id
        slideinterpolator.fieldToInterp = target.id + ".translation"
      end if
    else if slideinterpolator <> invalid and (options.destination = invalid or options.origin = invalid)
      animation.removeChild(slideinterpolator)
    end if

    scaleinterpolator = animation.findNode("ScaleInterpolator-" + target.id)
    if scaleinterpolator = invalid and options.scale <> invalid
      scaleinterpolator = animation.createChild("Vector2DFieldInterpolator")
      scaleinterpolator.id = "ScaleInterpolator-" + target.id
      scaleinterpolator.fieldToInterp = target.id + ".scale"
    else if scaleinterpolator <> invalid and options.scale = invalid
      animation.removeChild(scaleinterpolator)
    end if

    colorinterpolator = animation.findNode("ColorInterpolator-" + target.id)
    if colorinterpolator = invalid and (options.color <> invalid and target.color <> invalid)
      colorinterpolator = animation.createChild("ColorFieldInterpolator")
      colorinterpolator.id = "ColorInterpolator-" + target.id
      colorinterpolator.fieldToInterp = target.id + ".color"
    else if colorinterpolator <> invalid and (options.color = invalid or target.color = invalid)
      animation.removeChild(colorinterpolator)
    end if

    ' fake a delay
    totalTime = options.delay + options.duration
    if totalTime = 0.0 then
      delayTime = 0.0
    else
      delayTime = options.delay / totalTime
    end if

    if fadeinterpolator <> invalid
      fadeinterpolator.key = [0.0, delayTime, 1.0]
      fadeinterpolator.keyValue = [target.opacity, target.opacity, options.opacity]
    end if

    if slideinterpolator <> invalid
      slideinterpolator.key = [0.0, delayTime, 1.0]
      ' BUG: For some reason, keyValue cannot be set with the following line.  The firmware complains
      '      about a type mismatch.  Hence the verbose line below that which seems overly pedantic.
      '      slideinterpolator.keyValue = [origin, origin, destination]
      slideinterpolator.keyValue = [[options.origin[0], options.origin[1]], [options.origin[0], options.origin[1]], [options.destination[0], options.destination[1]]]
    end if

    if scaleinterpolator <> invalid
      scaleinterpolator.key = [0.0, delayTime, 1.0]
      'see above comment about slideinterpolator keyValue format
      scaleinterpolator.keyValue = [[target.scale[0], target.scale[1]], [target.scale[0], target.scale[1]], [options.scale, options.scale]]
    end if

    if colorinterpolator <> invalid
      colorinterpolator.key = [0.0, delayTime, 1.0]
      colorinterpolator.keyValue = [target.color, target.color, options.color]
    end if

    animation.duration = totalTime
    animation.easeFunction = options.easeFunction
    animation.control = "start"
    return animation
  else
    return invalid
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
  if target <> invalid and target.id <> invalid and type(target) = "roSGNode"
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
