Function init()
  m.buttonList = m.top.findNode("ButtonList")
  m.dialogBox = m.top.findNode("DialogBox")
  m.shade = m.top.findNode("Shade") ' background rectangle to dim the currentScreen
  m.header = m.top.findNode("header")
  m.subheader = m.top.findNode("subheader")
  m.multiStyleLayout = m.top.findNode("multiStyleLayout")
  m.imagesSection = m.top.findNode("imagesSection")
  m.mask = m.top.findNode("mask")
  m.semiCircle = m.top.findNode("semiCircle")

  m.top.observeFieldScoped("buttons", "formatDialog")
  m.top.observeFieldScoped("multiStyleMessage", "formatDialog")
  m.top.observeFieldScoped("multiStyleImageUrl", "formatDialog")
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")

  m.constants = getConstantsFromGlobal()

  '//::TODO::colors - Design will eventually add this black color to all themes but until then, hardcode this with the default shadeColor regardless of theme.
  '//   when Design adds the color to all themes, then set this color within the onThemeChange() observer using the new theme specific color
  m.shade.color = m.constants.ui.themes.default.shadeColor

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.header, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.subheader, typographyConstants.ids.subheaderSmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)

  if msg <> invalid
    m.theme = msg.getData()
  else
    m.theme = getThemeFromGlobal()
  end if

  if m.theme <> invalid
    m.header.color = m.theme.primaryTextColor
    m.subheader.color = m.theme.secondaryTextColor
  end if

End Function


Function formatDialog()
  ' buttons
  if m.top.buttons = invalid then
    m.buttonList.content = invalid
  else if m.buttonList.content = invalid OR m.buttonList.content.getChildCount() = 0
    newContent = CreateObject("roSGNode", "ContentNode")
    nWidestWidth = 0

    for each btnText in m.top.buttons
      buttonContent = newContent.createChild("ContentNode")
      buttonContent.update({
        title: btnText
        id: btnText
      }, true)
      '//   Temporarily create ModalListItem for each button text to find the largest width necessary for the set of buttons,
      '//   in order to determine how wide m.buttonList should be.
      '//   Different languages may make the text wider than usual so we need to ensure the button displays the full text
      listItem = CreateObject("roSGNode", "ListItemButtonWithBg")
      listContent = CreateObject("roSGNode", "ContentNode")
      listContent.title = btnText
      listItem.itemContent = listContent

      if listItem.calculatedWidth > nWidestWidth
        nWidestWidth = listItem.calculatedWidth
      end if

    end for

    'Keeping the default width of 285 for each button and if the text length is greater than 285 then we are
    'determining the width based on the text length.
    if nWidestWidth > m.buttonList.itemSize[0]
      m.buttonList.itemSize = [nWidestWidth, m.buttonList.itemSize[1]]
    end if

    numButtons = m.top.buttons.Count()
    m.buttonList.numRows = numButtons
    m.buttonList.content = newContent
    buttonListWidth = m.buttonList.itemSize[0] + 92 '46 padding each side
    ' If the button list width is less than current settings than not overriding it so that we don't have background cut-off.
    ' This happens when we have only one button.
    if buttonListWidth > m.dialogBox.width
      m.dialogBox.width = buttonListWidth
    end if

    dialogBoxTranslationX = 1920 - m.dialogBox.width
    m.semiCircle.translation = [dialogBoxTranslationX - 160 , 0 ]
    m.dialogBox.translation = [dialogBoxTranslationX, 0]
    m.mask.width = m.dialogBox.width
    m.subHeader.width = m.dialogBox.width - 200
    m.header.width = m.dialogBox.width - 200
  end if

  if m.top.multiStyleMessage <> invalid AND m.top.multiStyleMessage.Count() > 0 AND m.multiStyleLayout.getChildCount() = 0
    m.multiStyleLayout.visible = true

    for each multiMsg in m.top.multiStyleMessage
      multiStyleMsgGroup = CreateObject("roSGNode", "IconTitleSubtitleGroup")
      multiStyleMsgGroup.header = multiMsg.header
      multiStyleMsgGroup.subHeader = multiMsg.subHeader

      if m.theme <> invalid
        multiStyleMsgGroup.headerColor = m.theme.primaryTextColor
        multiStyleMsgGroup.subHeaderColor = m.theme.secondaryTextColor
      end if

      multiStyleMsgGroup.sideIcon = multiMsg.iconUri

      m.multiStyleLayout.appendChild(multiStyleMsgGroup)
    end for
  else if isNonEmptyArray(m.top.imageUrls) = true AND m.multiStyleLayout.getChildCount() = 0
    imageUrls = m.top.imageUrls

    ' Since we need to support multiple images.
    ' Setting image dimensions based on number of images returned.
    ' Idea behind having 2 variable is to provide flexiblity in future to have as many as image layouts as possible.
    ' So that we do not have to create if else logic across the file. We will create the imageDimensions and imageTranslations
    ' Which will control where in the modal the images will be placed and the dimensions of them.
    ' We will use absolute positioning for simplicity.
    imageDimensions = []
    imageTranslations = []

    if imageUrls.count() = 1

      ' set imageDimensions if provided otherwise use the default Braze's dimensions
      if isNonEmptyArray(m.top.imageDimensions) = true AND isNonEmptyArray(m.top.imageDimensions[0]) = true
        imageWidth = m.top.imageDimensions[0][0]
        imageDimensions = m.top.imageDimensions
      else
        imageWidth = 342
        imageDimensions = [[imageWidth, 405]]
      end if


      ' Center aligning the image if only one present.
      translationX = (m.dialogBox.width / 2) - (imageWidth/2)
      m.imagesSection.translation = [translationX, 0]

      imageTranslations = [[0, 0]]
    else
      ' For now since we only support 1 or 3 images layout.
      ' Once we have other variations we will add conditions and settings based on a new layout.
      ' For ex: imageUrls.count() > 3.

      if isNonEmptyArray(m.top.imageDimensions) = true AND isNonEmptyArray(m.top.imageDimensions[0]) = true
        imageDimensions = m.top.imageDimensions
      else
        imageDimensions = [[216, 309], [282, 405], [216, 309]]
      end if

      imageTranslations = [[0, 48], [87, 0], [243, 48]]
      ' Adjusting image section translation to have left side gutter width.
      m.imagesSection.translation = [112, 0]
    end if

    index = 0
    imageList = []
    for each imageUrl in imageUrls
      ' Adding a check to  make sure we do not crash if in case we get more images than supported.
      ' If we gracefully ignoring anything more than what is supported.For now it is 3.
      if imageDimensions[index] <> invalid
        imageWidth = imageDimensions[index][0]
        imageHeight = imageDimensions[index][1]
        imageList.push({
          subtype: "Poster"
          uri: imageUrl
          height: imageHeight
          width: imageWidth
          translation: imageTranslations[index]
          loadDisplayMode: "scaleToFit"
        })
      end if
      index++
    end for

    ' Sorting the images by width so that largest is rendered at the end so that it is always on top.
    imageList.sortBy("width")
    m.imagesSection.update(imageList, true)
    m.imagesSection.visible = true
  end if

End Function
