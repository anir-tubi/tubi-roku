sub init()
  m.deviceInfo                = CreateObject("roDeviceInfo")
  m.timer                     = CreateObject("roTimespan")
  m.image                     = m.top.findNode("Image")
  m.image.observeField("loadStatus", "onLoadStatus")
  m.experimentLabel           = m.top.findNode("Experiment")
  m.displaySizeLabel          = m.top.findNode("DisplaySize")
  m.uiResolutionLabel         = m.top.findNode("UIResolution")
  m.posterUriLabel            = m.top.findNode("PosterUri")
  m.posterSizeLabel           = m.top.findNode("PosterSize")
  m.posterLoadSizeLabel       = m.top.findNode("PosterLoadSize")
  m.posterBitmapSizeLabel     = m.top.findNode("PosterBitmapSize")
  m.posterLoadDisplayModeLabel  = m.top.findNode("PosterLoadDisplayMode")
  m.posterLoadStatusLabel     = m.top.findNode("PosterLoadStatus")
  m.posterLoadTimeLabel       = m.top.findNode("PosterLoadTime")

  ' settings which change on key presses
  m.imageUris = [
    "pkg:/images/1920x1080.jpg"
    "pkg:/images/524x295.jpg"
  ]
  m.loadDisplayModes = [
    "noScale"
    "scaleToFit"
    "scaleToFill"
    "scaleToZoom"
  ]
  m.loadSizes = [
    [0,0]
    [1920,1080]
    [1280,720]
  ]
  m.numExperiments = m.imageUris.count() * m.loadDisplayModes.count() * m.loadSizes.count()
  m.testIndex = 16
  setExperiment(m.testIndex)
  m.top.setFocus(true)
end sub

function setExperiment(index)
  print "setExperiment("; index; ")"
  loadSize = m.loadSizes[index MOD m.loadSizes.count()]
  index = index \ m.loadSizes.count()
  loadDisplayMode = m.loadDisplayModes[index MOD m.loadDisplayModes.count()]
  index = index \ m.loadDisplayModes.count()
  imageUri = m.imageUris[index MOD m.imageUris.count()]
  index = index \ m.imageUris.count()

  ' create a new poster node each time to enforce reloading the image
  oldImage = m.image
  m.image = CreateObject("roSGNode", "Poster")
  m.image.observeField("loadStatus", "onLoadStatus")
  m.top.replaceChild(m.image, 0)
  m.image.id = "Image"
  m.image.width = oldImage.width
  m.image.height = oldImage.height
  m.image.loadWidth = loadSize[0]
  m.image.loadHeight = loadSize[1]
  m.image.loadDisplayMode = loadDisplayMode
  m.image.uri = imageUri
end function

function onKeyEvent(key, press)
  if press then
    if key = "up"
      m.testIndex = (m.testIndex - 1 + m.numExperiments) MOD m.numExperiments
    else if key = "down"
      m.testIndex = (m.testIndex + 1) MOD m.numExperiments
    end if
    setExperiment(m.testIndex)
  end if
  return true
end function

function drawInfo(loadTime)
  m.experimentLabel.text = "Experiment: " + m.testIndex.toStr()
  m.posterUriLabel.text = "Poster URI: " + m.image.uri
  displaySize = m.deviceInfo.GetDisplaySize()
  m.displaySizeLabel.text = "DisplaySize: " + displaySize.w.toStr() + "x" + displaySize.h.toStr()
  uiResolution = m.deviceInfo.GetUIResolution()
  m.uiResolutionLabel.text = "UIResolution: " + uiResolution.width.toStr() + "x" + uiResolution.height.toStr()
  m.posterSizeLabel.text = "PosterSize (width,height): " + m.image.width.toStr() + "x" + m.image.height.toStr()
  m.posterLoadSizeLabel.text = "PosterLoadSize (loadWidth,loadHeight): " + m.image.loadWidth.toStr() + "x" + m.image.loadHeight.toStr()
  m.posterBitmapSizeLabel.text = "PosterBitmapSize (bitmapWidth,bitmapHeight): " + m.image.bitmapWidth.toStr() + "x" + m.image.bitmapHeight.toStr()
  m.posterLoadDisplayModeLabel.text = "PosterLoadDisplayMode: " + m.image.loadDisplayMode
  m.posterLoadTimeLabel.text = "PosterLoadTime (ms): " + loadTime.toStr()
end function

function onLoadStatus()
  print "onLoadStatus status = "; m.image.loadStatus
  if m.image.loadStatus = "loading"
    m.timer.mark()
  elseif m.image.loadStatus = "ready"
    ' only draw info after image has loaded so we can get accurate timing of image loads
    loadTime = m.timer.TotalMilliseconds()
    drawInfo(loadTime)
  end if
  m.posterLoadStatusLabel.text = "PosterLoadStatus: " + m.image.loadStatus
end function