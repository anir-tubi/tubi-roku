Function init()
  m.maxItemCount = 30

  ' We always want to have the same absolute position. This works around the issue if the sideNav menu is open we don't want to be shifted over to the right.
  m.top.inheritParentTransform = false

  m.fadeOutPosterAnimationDuration = 2.0

  m.loadingItemIndex = 0
  m.showingItemIndex = -1
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
  m.preloadPoster.observeFieldScoped("loadStatus", "onPreloadPosterLoadStatusChange")

  ' Used to track when we are ok to fade in the next image based off of preloadPoster loadStatus
  m.animationIsFinished = false
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

  ' Make sure we at least have one valid item
  if items.count() > 0 then
    m.items = items

    m.animationIsFinished = true ' Setting to true to allow autotransition after preloadPoster loads

    m.poster.observeFieldScoped("loadStatus", "onPosterLoadStatusChange")

    ' We want to load the first image before we fade in. We use poster instead of preloadPoster because if the second image is already cached and the loadStatus changes again in the same render cycle it will stay in loadingStatus indefinitely. Ran into this issue on a 4670X
    m.poster.uri = getImageUrl(items[m.loadingItemIndex])
  else
    ' Go ahead and exit the screensaver since we don't have any content to show. Perhaps we eventually add back in the fallback screensaver
    m.top.exitInfo = {}
  end if
End Function


Function onPosterLoadStatusChange(msg)
  if msg.getData() = "ready" then
    m.poster.unobserveFieldScoped("loadStatus")
    fadeInItemIndex(m.loadingItemIndex)
  end if
End Function


Function onPreloadPosterLoadStatusChange(msg)
  loadStatus = msg.getData()

  if loadStatus = "ready" then
    conditionallyFadeInNextItem()
  else if loadStatus = "failed" then
    ' If it failed preload the next poster
    tubiLog("Failed to load " + m.preloadPoster.uri)

    m.loadingItemIndex = getNextItemIndex()
    m.preloadPoster.uri = getImageUrl(m.items[m.loadingItemIndex])
  end if
End Function


Function conditionallyFadeInNextItem()
  if m.preloadPoster.loadStatus = "ready" AND m.animationIsFinished = true then
    m.animationIsFinished = false
    fadeInItemIndex(m.loadingItemIndex)
  end if
End Function


Function fadeInItemIndex(itemIndex)
  item = m.items[itemIndex]

  ' set the slide properties
  m.poster.uri = getImageUrl(item)
  m.showingItemIndex = itemIndex
  m.titleLabel.text = item.title
  m.tagsLabel.text = item.tags.join(", ")

  ' now fade it in
  fade(m.poster, "in", 0.5)

  ' Slides down and fades in titleLayoutGroup to its set onscreen position
  slideFade(m.titleLayoutGroup, "above", "in", 0.5, 0.5, 30)

  ' Start our timer for the next slide to show
  m.slideTimer.control = "start"
  m.zoomAnimation.control = "start"
  m.animationIsFinished = false

  m.loadingItemIndex = getNextItemIndex()
  m.preloadPoster.uri = getImageUrl(m.items[m.loadingItemIndex])
End Function

Function onSlideTimerFire()
  fadeOutCurrent()
End Function


Function fadeOutCurrent()
  m.fadeOutPosterAnimation = animate(m.poster, {
    "opacity": 0
    "duration": m.fadeOutPosterAnimationDuration
    "completeCallback": onAnimationComplete
  })

  slideFade(m.titleLayoutGroup, "below", "out", 0.5, 0, 60)
End Function


Function onAnimationComplete()
  m.animationIsFinished = true
  conditionallyFadeInNextItem()
End Function


Function getNextItemIndex()
  index = m.loadingItemIndex + 1
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


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press then
    ' Only passing an empty object for now
    m.top.exitInfo = {}
  end if

  return true
End Function
