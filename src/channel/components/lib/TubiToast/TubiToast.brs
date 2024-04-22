Function init()
  tubilog("TubiToast.init")
  m.itemContainer = m.top.findNode("itemContainer")
  m.timer = m.top.findNode("toastTimer")
  m.top.observeFieldScoped("show", "onShowToast")
  m.timer.observeFieldScoped("fire", "onToastTimerFired")
  m.showQueue = []
  m.verticalSpace = 32
  m.horizontalSlideAmt = 100
End Function


Function onShowToast()
  tubilog("TubiToast.onShowToast")
  toastInfo = m.top.toastInfo

  if toastInfo <> invalid AND toastInfo.isStyled = true
    toastItem = createObject("roSGNode", "StyledToastItem")
  else
    toastItem = createObject("roSGNode", "TubiToastItem")
  end if

  deviceInfo = createObject("roDeviceInfo")
  uuid = deviceInfo.getRandomUUID()
  toastItem.id = "tubiToast-" + uuid
  toastItem.toastInfo = toastInfo
  toastItem.show = true
  m.showQueue.unshift(toastItem)

  if m.timer.control <> "start"
    m.timer.control = "start"
  end if
End Function


Function onToastTimerFired()
  tubilog("TubiToast.onToastTimerFired")
  timerDuration = m.timer.duration
  yAmt = 0
  toastsToAdd = []


  ' set up the toasts that need to be inserted since the last time this callback fired
  for i = 0 to m.showQueue.count() - 1
    toastToAdd = m.showQueue[i]
    toastToAddX = toastToAdd.finalHorizTranslation
    toastToAddY = toastToAdd.translation[1]
    finalVertTranslation = toastToAddY + yAmt
    toastToAdd.finalVertTranslation = finalVertTranslation

    toastToAdd.translation = [toastToAddX, finalVertTranslation]
    yAmt += toastToAdd.height + m.verticalSpace
    toastsToAdd.push(toastToAdd)
  end for

  m.itemContainer.insertChildren(toastsToAdd, 0)
  m.showQueue = []

  childrenToRemove = []

  ' handle any animations that need to occur
  for i = 0 to m.itemContainer.getChildCount() - 1
    toast = m.itemContainer.getChild(i)

    if toast <> invalid
      if i > 3
        toast.ttl = 0.01
      end if

      ttl = toast.ttl

      if isNewToast(toast) = true
        ' handle newly added toasts
        toast.ttl = ttl - timerDuration
        animation = slideFade(toast, "right", "in", 0.4, 0.2, m.horizontalSlideAmt)
        if animation <> invalid
          toast.animationId = animation.id
        end if
      else
        ' handle pre existing toasts
        if ttl > timerDuration
          ' handle toasts that may need to slide down
          toast.ttl = ttl - timerDuration

          if yAmt <> 0
            ' needs to slide vertically (may or may not also need to slide horizontally)
            finalVertTranslation = toast.finalVertTranslation + yAmt
            finalTranslation = [toast.finalHorizTranslation, finalVertTranslation]
            toast.finalVertTranslation = finalVertTranslation

            if toast.opacity <> 1.0
              ' if opacity is not 1.0, this means the initial slideFade animation when the toast
              ' was inserted didn't complete yet. So we need to account for it by continuing the fade in.
              animation = slideFadeGeneral(toast, finalTranslation, "in", 0.4)
              if animation <> invalid
                toast.animationId = animation.id
              end if
            else
              animation = slideTo(toast, finalTranslation, 0.4)
              if animation <> invalid
                toast.animationId = animation.id
              end if
            end if
          end if
        else if ttl <= timerDuration AND ttl > 0
          ' handle toasts that need to fade out
          toast.ttl = ttl - timerDuration
          animation = fade(toast, "out", 0.4)
          if animation <> invalid
            toast.animationId = animation.id
          end if

          yAmt = yAmt - (toast.height + m.verticalSpace)
        else if ttl <= 0
          animationToRemove = m.top.findNode(toast.animationId)
          m.top.removeChild(animationToRemove)
          childrenToRemove.push(toast)
        end if
      end if
    end if
  end for

  m.itemContainer.removeChildren(childrenToRemove)

  if m.itemContainer.getChildCount() = 0
    m.timer.control = "stop"
    removeAllAnimations()
  end if
End Function


Function isNewToast(toast)
  return toast.startingTtl = toast.ttl
End Function


Function removeAllAnimations()
  childrenToRemove = []
  for i = 0 to m.top.getChildCount() - 1
    child = m.top.getChild(i)

    if child.isSubtype("Animation")
      childrenToRemove.push(child)
    end if
  end for

  m.top.removeChildren(childrenToRemove)
End Function