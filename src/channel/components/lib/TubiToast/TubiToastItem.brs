Function init()
  tubilog("TubiToastItem.init")
  m.infoPaneContainer = m.top.findNode("infoPaneContainer")
  m.infoPaneMsgArea = m.top.findNode("infoPaneMsgArea")
  m.infoPaneBg = m.top.findNode("infoPaneBg")
  m.constants = getConstantsFromGlobal()
  m.infoPaneText = m.top.findNode("infoPaneText")

  m.top.enableRenderTracking = true
  m.top.observeFieldScoped("show", "onShow")
  m.top.opacity = 0
  m.infoPaneBg.uri = "pkg:/images/tab_short_component_alt_{size}.9.png"

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function

Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.infoPaneBg.blendColor = theme.inverseBackgroundColor
    m.infoPaneText.color = theme.inverseSecondaryTextColor
  end if
End Function

Function onShow(msg)
  tubilog("TubiToast.onShow")
  imageWidth = 0
  imageHeight = 0
  headerWidth = 0
  msgWidth = 0
  inputArgs = m.top.showToastMessage

  m.top.ttl = inputArgs.selfDestructTimer
  m.top.startingTtl = inputArgs.selfDestructTimer


  'left side image
  if inputArgs.imageUri <> invalid AND inputArgs.imageUri <> ""
    createLeftImage(inputArgs)
    imageWidth = m.leftImage.width + 24 ' 72 image width + 24 spacing between image and message
    imageHeight = m.leftImage.height + 72 '36 upper margin + 36 bottom margin
  else if m.leftImage <> invalid
    m.infoPaneContainer.removeChild(m.leftImage)
    m.leftImage.uri = ""
    m.leftImage = invalid
  end if

  'header
  if inputArgs.headerText <> invalid AND inputArgs.headerText <> ""
    createHeaderText(inputArgs)

    headerWidth = m.header.boundingRect().width

    if headerWidth > 546
      m.header.width = 546 - imageWidth
    else
      m.header.width = headerWidth
    end if

  else if m.header <> invalid
    m.header.text = ""
    m.infoPaneMsgArea.removeChild(m.header)
    m.header = invalid
  end if

  'Message
  if inputArgs.message <> invalid AND inputArgs.message <> ""
    m.infoPaneText.text = inputArgs.message
    msgWidth = m.infoPaneText.boundingRect().width

    if msgWidth + imageWidth >= 546
      m.infoPaneText.width = 546 - imageWidth
    else if msgWidth + imageWidth < 345
      m.infoPaneText.width = 345 - imageWidth
    else if msgWidth + imageWidth >= 345
      m.infoPaneText.width = msgWidth
    end if

    if inputArgs.messageColor <> invalid AND inputArgs.messageColor <> ""
      m.infoPaneText.color = inputArgs.messageColor
    end if
  end if

  'Calculations of various required fields

  if inputArgs.backGroundColor <> invalid AND inputArgs.backGroundColor <> ""
    m.infoPaneBg.blendColor = inputArgs.backGroundColor
  end if

  if (msgWidth + imageWidth >= 546) OR (headerWidth + imageWidth >= 546)
    m.infoPaneBg.width = 642
  else if (msgWidth + imageWidth < 345) AND (headerWidth +  imageWidth < 345)
    m.infoPaneBg.width = 441
  else if (msgWidth + imageWidth >= 345) OR (headerWidth + imageWidth >= 345)
    m.infoPaneBg.width = msgWidth + imageWidth + 96
    if headerWidth > msgWidth
      m.infoPaneBg.width = headerWidth + imageWidth + 96
    end if
  end if

  finalHorizTranslation = 642 - m.infoPaneBg.width
  m.top.finalHorizTranslation = finalHorizTranslation

  totalHeight =  m.infoPaneText.boundingRect().height  + 72 'top + bottom margins
  if m.header <> invalid
    totalHeight = totalHeight + m.header.boundingRect().height + 12 'header height + spacing
  end if

  if  totalHeight > 177 OR imageHeight > 177
    m.infoPaneBg.height = 177
  else if totalHeight < 112 AND imageHeight < 112
    m.infoPaneBg.height = 112
  else if totalHeight > imageHeight
    m.infoPaneBg.height = totalHeight
  else
    m.infoPaneBg.height = imageHeight
  end if

  centerY = m.infoPaneBg.height / 2
  m.infoPaneContainer.translation = [48, centerY]

  m.top.visible = true
End Function


Function createLeftImage(inputArgs)
  if m.leftImage = invalid
    m.leftImage = createObject("roSGNode", "poster")
    m.leftImage.uri = inputArgs.imageUri
    m.leftImage.height = 72
    m.leftImage.width = 72
    m.infoPaneContainer.insertChild(m.leftImage, 0)

    if inputArgs.imageHeight <> invalid AND inputArgs.imageHeight > 0
      if inputArgs.imageHeight > 105
        m.leftImage.height = 105 ' max 177 - 36 upper margin - 36 bottom margin
      else
        m.leftImage.height = inputArgs.imageHeight
      end if
    end if

    if inputArgs.imageWidth <> invalid AND inputArgs.imageWidth > 0
      if inputArgs.imageWidth > 546
        m.leftImage.width = 546
      else
        m.leftImage.width = inputArgs.imageWidth
      end if
    end if
  else
    m.leftImage.uri = inputArgs.imageUri
  end if
End Function


Function createHeaderText(inputArgs)
  theme = getThemeFromGlobal()
  if m.header = invalid
    m.header = createObject("roSGNode", "Label")
    m.header.id = "infoPaneHeader"
    if theme <> invalid
      m.header.color = theme.inversePrimaryTextColor
    end if
    m.header.maxLines = "1"
    m.header.numLines = "1"
    m.header.width = "0"
    m.header.text = inputArgs.headerText
    m.header.wrap="false"
    font = CreateObject("roSGNode", "Font")
    font.uri = "pkg:/fonts/Vaud-Bold.ttf"
    font.size = 28
    m.header.font = font
    m.infoPaneMsgArea.insertChild(m.header, 0)
  else
    m.header.text = inputArgs.headerText
  end if

  if inputArgs.headerColor <> invalid AND inputArgs.headerColor <> ""
    m.header.color = inputArgs.headerColor
  end if
End Function