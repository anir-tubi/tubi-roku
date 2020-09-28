Function init()
  m.constants = m.global.constants
  m.top.observeField("spriteUrls", "showSprite")
  m.top.observeField("numSprites", "showSprite")
  m.top.observeField("width", "showSprite")
  m.top.observeField("height", "showSprite")
  m.top.observeField("rows", "showSprite")
  m.top.observeField("columns", "showSprite")
  m.top.observeField("thumbnailWidth", "showSprite")
  m.top.observeField("thumbnailHeight", "showSprite")
  m.top.observeField("spriteDirection", "showSprite")
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
  '//Index = the location within the image array, Zero based
  index = 0
  '//nColumnIndex = the number of column that the image is found within, Zero based
  nColumnIndex = 0
  '//nRowIndex = the number of row that the image is found within, Zero based
  nRowIndex = 0
  nColumns = m.top.columns 
  nRows = m.top.rows
  if nRows <= 0
    '//Assume at least 1 row
    nRows = 1
  end if

  if m.top.numSprites <> 0
    if nColumns <= 0 
      nColumns = m.top.numSprites
    end if
    page = m.top.jumpToSprite \ m.top.numSprites
    index = (m.top.jumpToSprite MOD m.top.numSprites)
  end if

  if nColumns > 0
    nColumnIndex = index MOD nColumns
    nRowIndex = Int(index/nColumns)
  end if

  m.poster.width = m.top.width * nColumns
  m.poster.height = m.top.height * nRows

  loadDisplayMode = "noScale"
  loadWidth = 0
  loadHeight = 0

  nSheetWidth = m.top.thumbnailWidth * nColumns
  nSheetHeight = m.top.thumbnailHeight * nRows
  if (nSheetWidth > 0 and nSheetHeight > 0) and (nSheetWidth > m.constants.deviceInfo.displayWidth or nSheetHeight > m.constants.deviceInfo.displayHeight)
    loadDisplayMode = "scaleToFit"
    ' Scale the poster down should bring the image dimensions down below the 4kx4k texture size limit
    ' which would otherwise cause the images to fail to load.
    ' scaleFactor needs to be ~0.4 to show on non 4k capable devices
    scaleFactorWidth = 1
    scaleFactorHeight = 1
    if nSheetWidth > m.constants.deviceInfo.displayWidth
      scaleFactorWidth = m.constants.deviceInfo.displayWidth/nSheetWidth
    end if
    if nSheetHeight > m.constants.deviceInfo.displayHeight
      scaleFactorHeight = m.constants.deviceInfo.displayHeight/nSheetHeight
    end if

    scaleFactor = scaleFactorWidth
    if scaleFactorHeight < scaleFactorWidth
      '//Choose the smallest of the scale factors
      scaleFactor = scaleFactorHeight
    end if
    loadWidth = m.poster.width * scaleFactor
    loadHeight = m.poster.height * scaleFactor
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

    offsetX = m.top.width * nColumnIndex
    offsetY = m.top.height * nRowIndex
    m.poster.translation = [-offsetX, -offsetY]
    m.top.clippingRect = [
      0
      0
      m.top.width
      m.top.height
    ]
  end if
End Function