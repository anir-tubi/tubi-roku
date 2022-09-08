Function init()
  m.maxItemCount = 30

  m.fadeOutPosterAnimationDuration = 2.0

  m.currentItemIndex = 0
  m.items = []

  m.constants = getConstantsFromGlobal()

  m.preloadPoster = m.top.findNode("preloadPoster")
  m.poster = m.top.findNode("poster")
  m.titleLayoutGroup = m.top.findNode("titleLayoutGroup")
  m.titleLabel = m.top.findNode("titleLabel")
  m.tagsLabel = m.top.findNode("tagsLabel")
  m.zoomAnimation = m.top.findNode("zoomAnimation")
  m.slideTimer = m.top.findNode("slideTimer")

  slideDuration = m.constants.timers.screenSaverSlideDuration
  m.slideTimer.duration = slideDuration - m.fadeOutPosterAnimationDuration
  m.zoomAnimation.duration = slideDuration

  m.top.observeFieldScoped("containerResponses", "onContainerResponsesChange")
  m.slideTimer.observeFieldScoped("fire", "onSlideTimerFire")
End Function


Function onContainerResponsesChange(msg)
  items = []
  containerResponses = msg.getData()
  for each containerResponse in containerResponses
    for each item in containerResponse.items
      ' Want to make sure we maintain the max item count limit
      if items.count() = m.maxItemCount then
        exit for
      end if

      ' Want to make sure each item has an image url
      if getImageUrl(item) <> "" then
        items.push(item)
      end if
    end for
  end for

  ' Make sure we at least have one valid item or else fall back to built in screen saver
  if items.count() > 0 then
    m.items = items

    ' We want to load the first image before we fade in
    m.preloadPoster.observeFieldScoped("loadStatus", "onPreloadPosterLoadStatusChange")
    m.preloadPoster.uri = getImageUrl(m.items[m.currentItemIndex])

    m.top.loadStatus = "ready"
  else
    tubiLog("Screen saver had no valid items. Falling back to built in screen saver. Check if you are using staging apis")
    m.top.loadStatus = "failed"
  end if

End Function

Function onPreloadPosterLoadStatusChange(msg)
  preloadPoster = msg.getRoSGNode()

  loadStatus = msg.getData()
  if loadStatus = "ready" then
    preloadPoster.unobserveFieldScoped("loadStatus")
    fadeInItemIndex(m.currentItemIndex)
  else if loadStatus = "failed" then
    ' If it failed preload the next poster
    tubiLog("Failed to load " + preloadPoster.uri)
    m.currentItemIndex = getNextItemIndex()
    preloadPoster.uri = getImageUrl(m.items[m.currentItemIndex])
  end if
End Function


Function fadeInItemIndex(itemIndex)
  item = m.items[itemIndex]

  ' set the slide properties
  m.poster.uri = getImageUrl(item)
  m.titleLabel.text = item.title
  m.tagsLabel.text = item.tags.join(", ")

  ' now fade it in
  fade(m.poster, "in", 0.5)

  ' Slides down and fades in titleLayoutGroup to its set onscreen position
  slideFade(m.titleLayoutGroup, "above", "in", 0.5, 0.5, 30)

  ' preload the next image
  nextItem = m.items[getNextItemIndex()]
  m.preloadPoster.uri = getImageUrl(nextItem)

  ' Start our timer for the next slide to show
  m.slideTimer.control = "start"

  m.zoomAnimation.control = "start"
End Function


Function onSlideTimerFire()
  fadeOutCurrent()
  m.currentItemIndex = getNextItemIndex()
End Function


Function fadeOutCurrent()
  animate(m.poster, {
    "opacity": 0
    "duration": m.fadeOutPosterAnimationDuration
    "completeCallback": onAnimationComplete
  })

  slideFade(m.titleLayoutGroup, "below", "out", 0.5, 0, 60)
End Function


Function onAnimationComplete()
  loadStatus = m.preloadPoster.loadStatus
  if loadStatus = "ready" then
    fadeInItemIndex(m.currentItemIndex)
  else
    ' If the image isn't ready then we will wait for it to be ready to proceed
    m.preloadPoster.observeFieldScoped("loadStatus", "onPreloadPosterLoadStatusChange")
    if loadStatus = "failed" then
      tubiLog("Failed to load " + m.preloadPoster.uri)
      m.currentItemIndex = getNextItemIndex()
      m.preloadPoster.uri = getImageUrl(m.items[m.currentItemIndex])
    end if
  end if
End Function


Function getNextItemIndex()
  index = m.currentItemIndex + 1
  if index >= m.items.count() then
    index = 0
  end if
  return index
End Function


' @item - AA for an item in the m.items array
Function getImageUrl(item)
  if isAA(item) = true then
    images = item.images["landscape_tb"]
    if isArray(images) = true then
      imageUrl = images[0]
      if isString(imageUrl) = true then
        return imageUrl
      end if
    end if
  end if
  return ""
End Function
