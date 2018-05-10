Function init()
  m.top.observeField("spriteUrls", "showSprite")
  m.top.observeField("numSprites", "showSprite")
  m.top.observeField("width", "showSprite")
  m.top.observeField("height", "showSprite")
  m.top.observeField("spriteDirection", "showSprite")
  m.top.observeField("spriteSheetWidth", "showSprite")
  m.top.observeField("spriteSheetHeight", "showSprite")
  m.top.observeField("jumpToSprite", "showSprite")
  m.preload = m.top.findNode("Preload")
  m.preload2 = m.top.findNode("Preload2")
  m.poster = m.top.findNode("Poster")
  m.poster.observeField("loadStatus", "onLoadStatus")
  m.timer = CreateObject("roTimespan")
End Function

Function onLoadStatus()
  if m.poster.loadStatus = "ready"
    showSprite()
  else if m.poster.loadStatus = "loading"
    m.startLoadTime = m.timer.TotalMilliseconds()
  end if
End Function

' Set the component offset and clipping rect
Function showSprite()
  page = 0
  index = 0
  if m.top.numSprites <> 0
    page = m.top.jumpToSprite \ m.top.numSprites
    index = m.top.jumpToSprite MOD m.top.numSprites
  end if
  if m.top.spriteDirection = "horiz"
    m.poster.width = m.top.width * m.top.numSprites
    m.poster.height = m.top.height
  else
    m.poster.width = m.top.width
    m.poster.height = m.top.height * m.top.numSprites
  end if
  loadDisplayMode = "noScale"
  loadWidth = 0
  loadHeight = 0
  if m.top.spriteSheetWidth <> 0 or m.top.spriteSheetHeight <> 0
    loadDisplayMode = "scaleToFit"
    if m.top.spriteSheetWidth <> 0
      loadWidth = m.top.spriteSheetWidth
    end if
    if m.top.spriteSheetHeight <> 0
      loadHeight = m.top.spriteSheetHeight
    end if
  end if
  m.poster.loadDisplayMode = loadDisplayMode
  m.poster.loadWidth = loadWidth
  m.poster.loadHeight = loadHeight
  m.preload.loadDisplayMode = loadDisplayMode
  m.preload.loadWidth = loadWidth
  m.preload.loadHeight = loadHeight
  m.preload2.loadDisplayMode = loadDisplayMode
  m.preload2.loadWidth = loadWidth
  m.preload2.loadHeight = loadHeight
  if m.top.spriteUrls[page] <> invalid
    m.poster.uri = m.top.spriteUrls[page]
    m.preload.uri = m.top.spriteUrls[page+1]
    m.preload2.uri = m.top.spriteUrls[page+2]
    offsetX = 0
    offsetY = 0
    if m.top.spriteDirection = "horiz"
      offsetX = m.top.width * index
    else
      offsetY = m.top.height * index
    end if
    m.poster.translation = [-offsetX, -offsetY]
    m.top.clippingRect = [
      0
      0
      m.top.width
      m.top.height
    ]
  end if
End Function