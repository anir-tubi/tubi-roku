Function init()
  tubilog("TubiToastItem.init")
  m.infoPaneContainer = m.top.findNode("infoPaneContainer")
  m.infoPaneMsgArea = m.top.findNode("infoPaneMsgArea")
  m.infoPaneBg = m.top.findNode("infoPaneBg")
  m.infoPaneText = m.top.findNode("infoPaneText")

  m.top.enableRenderTracking = true
  m.top.observeFieldScoped("show", "onShow")
  m.top.opacity = 0
  m.infoPaneBg.uri = "pkg:/images/tab_short_component_alt_$$RES$$.9.png"

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.infoPaneText, typographyConstants.ids.bodySmall)

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.infoPaneBg.blendColor = theme.neutralSolidColor2
    m.infoPaneText.color = theme.secondaryTextColor
  end if
End Function


Function onShow(_msg)
  tubilog("TubiToast.onShow")
  imageWidth = 0
  imageHeight = 0
  headerWidth = 0
  msgWidth = 0
  inputArgs = m.top.toastInfo

  m.top.ttl = inputArgs.selfDestructTimer
  m.top.startingTtl = inputArgs.selfDestructTimer

  'left side image
  if inputArgs.imageUri <> invalid AND inputArgs.imageUri <> ""
    createLeftImage(inputArgs)
    imageWidth = m.leftImage.width + 24 ' 72 image width + 24 spacing between image and message
    imageHeight = m.leftImage.height + 72 '36 upper margin + 36 bottom margin

    'a specific toast for profiles
    if inputArgs.profileInitial <> invalid AND inputArgs.profileInitial <> ""
      updateLeftImageWithInitial(inputArgs)
    end if
  else if m.leftImage <> invalid
    m.infoPaneContainer.removeChild(m.leftImage)
    m.leftImage.uri = ""
    m.leftImage = invalid
  end if

  'header
  if inputArgs.headerText <> invalid AND inputArgs.headerText <> ""
    createHeaderText(inputArgs)
    headerWidth = m.header.boundingRect().width
    ' Since header we are not allowing multiple lines allowing header text to be completely displayed without ellipsis.
    m.header.width = headerWidth
  else if m.header <> invalid
    m.header.text = ""
    m.infoPaneMsgArea.removeChild(m.header)
    m.header = invalid
  end if

  'Message
  if inputArgs.message <> invalid AND inputArgs.message <> ""
    m.infoPaneText.text = inputArgs.message
    m.infoPaneText.visible = true
    m.infoPaneText.scale = [1, 1]
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
  else
    m.infoPaneText.text = ""
    m.infoPaneText.visible = false
    m.infoPaneText.scale = [0, 0]
  end if

  'Calculations of various required fields
  if inputArgs.backGroundColor <> invalid AND inputArgs.backGroundColor <> ""
    m.infoPaneBg.blendColor = inputArgs.backGroundColor
  end if

  ' TODO: Re-visit in future if we can remove all the calculations and make it dynamic with max width set for message element.
  if headerWidth + imageWidth >= 546
    componentWidth = m.top.boundingRect().width
    m.infoPaneBg.width = componentWidth + 36
  else if msgWidth + imageWidth >= 546
    m.infoPaneBg.width = 642
  else if (msgWidth + imageWidth < 345) AND (headerWidth + imageWidth < 345)
    m.infoPaneBg.width = 441
  else if (msgWidth + imageWidth >= 345) OR (headerWidth + imageWidth >= 345)
    m.infoPaneBg.width = msgWidth + imageWidth + 96
    if headerWidth > msgWidth
      m.infoPaneBg.width = headerWidth + imageWidth + 96
    end if
  end if

  finalHorizTranslation = 642 - m.infoPaneBg.width
  m.top.finalHorizTranslation = finalHorizTranslation

  totalHeight = m.infoPaneText.boundingRect().height + 72 'top + bottom margins
  if m.header <> invalid
    totalHeight = totalHeight + m.header.boundingRect().height + 12 'header height + spacing
  end if

  if totalHeight > 177 OR imageHeight > 177
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
      m.header.color = theme.primaryTextColor
    end if
    m.header.maxLines = 1
    m.header.numLines = 1
    m.header.width = 0
    m.header.text = inputArgs.headerText
    m.header.wrap = false
    font = CreateObject("roSGNode", "Font")
    m.header.font = font
    m.infoPaneMsgArea.insertChild(m.header, 0)

    typographyConstants = getTypographyConstants()
    setTypographyOfLabel(m.header, typographyConstants.ids.subHeaderSmall)
  else
    m.header.text = inputArgs.headerText
  end if

  if inputArgs.headerColor <> invalid AND inputArgs.headerColor <> ""
    m.header.color = inputArgs.headerColor
  end if
End Function


Function updateLeftImageWithInitial(inputArgs)
  if m.leftImage <> invalid
    if m.leftImageInitial = invalid
      m.leftImageInitial = createObject("roSGNode", "Label")
      m.leftImageInitial.id = "leftImageInitial"

      typographyConstants = getTypographyConstants()
      setTypographyOfLabel(m.leftImageInitial, typographyConstants.ids.headerSmall)
      m.leftImageInitial.text = inputArgs.profileInitial
      size = m.leftImageInitial.boundingRect()
      width = size.width
      height = size.height

      transX = ((m.leftImage.width - width) / 2)
      transY = ((m.leftImage.height - height) / 2)

      m.leftImage.appendChild(m.leftImageInitial)
      m.leftImageInitial.translation = [transX, transY]
    else

      m.leftImageInitial.text = inputArgs.profileInitial
    end if
  end if

End Function
