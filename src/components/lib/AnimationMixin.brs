'''''''''''''''''''''''''''
' slideFade
'
' Animate the target component in or out with a slide and fade effect
'
' @startOrEndLocation - 'above' 'below' 'left' 'right'.  If animating IN, this is start location, otherwise end
' @inOrOut - 'in' or 'out'
Function slideFade(target As Object, startOrEndLocation As String, inOrOut As String, duration=2.0 As Float, delay=0.0 As Float)

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
    targetOpacity = 1.0
    slideOrigin = [slideX, slideY]
    slideDestination = target.translation
  else
    targetOpacity = 0.0
    slideOrigin = target.translation
    slideDestination = [slideX, slideY]
  end if
  return animate(target, slideOrigin, slideDestination, targetOpacity, 1.0, duration, delay)
End Function


'''''''''''''
' slideTo
'
' simple helper to slide the component to the destination.
Function slideTo(target As Object, destination As Object, duration As Float)
  return animate(target, target.translation, destination, target.opacity, 1.0, duration)
End Function


'''''''''''''
' bubbleIn
'
' Effect to reveal by scaling from 0 to 1
Function bubbleIn(target As Object, duration As Float)
  target.scale = [0.0, 0.0]
  return animate(target, target.translation, target.translation, target.opacity, 1.0, duration)
End Function



Function fade(target As Object, outOrIn As String, duration As Float, delay=0.0 As Float)
  if outOrIn = "out"
    return animate(target, target.translation, target.translation, 0.0, 1.0, duration, delay)
  else if outOrIn = "in"
    return animate(target, target.translation, target.translation, 1.0, 1.0, duration, delay)
  end if
End Function

''''''''''''
' animate
'
' Animate a target components scale, opacity, and translation with optional delay.  
'
' NOTE!: It's CRITICAL that the target object has a globally unique id.  This is a limitation
'        of the Animation node which references the target by ID.
' NOTE2!: It's CRITICAL that target a child of the component in which animate() is called. It cannot
'         be called with m.top, nor some item which is not a descendant of m.top.  This is due
'         to the way Animate uses findNode internally to find the animation target by id.
' NOTE3!: Potential leak here if animations are applied to dynamically created targets.  While targets
'         may be removed and go out of scope, their animations don't get garbage collected with them.
' TODO(Chris): check for abandoned animations here and remove them
Function animate(target As Object, origin As Object, destination As Object, opacity As Float, scale=1.0 As Float, duration=2.0 As Float, delay=0.0 As Float) As Object
  tubiLog("slideFade target = " + target.id)

  animationId = "SlideFadeAnimation-" + target.id

  ' Reuse an existing animation if available
  animation = m.top.findNode(animationId)
  if animation = invalid then 
    animation = m.top.createChild("Animation")
    animation.id = "SlideFadeAnimation-" + target.id

    fadeinterpolator = animation.createChild("FloatFieldInterpolator")
    fadeinterpolator.id = "FadeInterpolator-" + target.id
    fadeinterpolator.fieldToInterp = target.id + ".opacity"

    slideinterpolator = animation.createChild("Vector2DFieldInterpolator")
    slideinterpolator.id = "SlideInterpolator-" + target.id
    slideinterpolator.fieldToInterp = target.id + ".translation" 

    scaleinterpolator = animation.createChild("Vector2DFieldInterpolator")
    scaleinterpolator.id = "ScaleInterpolator-" + target.id
    scaleinterpolator.fieldToInterp = target.id + ".scale" 
  else
    fadeinterpolator = animation.findNode("FadeInterpolator-" + target.id)
    slideinterpolator = animation.findNode("SlideInterpolator-" + target.id)
    scaleinterpolator = animation.findNode("ScaleInterpolator-" + target.id)
    if animation.state <> "stopped" then animation.control = "stop"
  end if
  
  ' fake a delay
  totalTime = delay + duration
  if totalTime = 0.0 then 
    delayTime = 0.0
  else
    delayTime = delay / totalTime
  end if
  fadeinterpolator.key = [0.0, delayTime, 1.0]
  slideinterpolator.key = [0.0, delayTime, 1.0]
  scaleinterpolator.key = [0.0, delayTime, 1.0]
  animation.duration = totalTime

  animation.easeFunction = "inOutCubic"
  fadeinterpolator.keyValue = [target.opacity, target.opacity, opacity]
  ' BUG: For some reason, keyValue cannot be set with the following line.  The firmware complains
  '      about a type mismatch.  Hence the verbose line below that which seems overly pedantic.
  'slideinterpolator.keyValue = [origin, origin, destination]
  slideinterpolator.keyValue = [[origin[0], origin[1]], [origin[0], origin[1]], [destination[0], destination[1]]]
  scaleinterpolator.keyValue = [[target.scale[0], target.scale[1]], [target.scale[0], target.scale[1]], [scale, scale]]

  animation.control = "start"
  return animation
End Function