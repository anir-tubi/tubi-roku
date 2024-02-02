Function init()
  topRef = m.top
  m.buttonList = topRef.findNode("buttonList")
  m.dialogBox = topRef.findNode("dialogBox")
  m.header = topRef.findNode("header")
  m.subheader = topRef.findNode("subheader")
  m.contentArea = topRef.findNode("contentArea")

  topRef.observeFieldScoped("buttons", "onButtonListChange")

  m.constants = getConstantsFromGlobal()

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.header, typographyConstants.ids.subHeaderSmall)
  setTypographyOfLabel(m.subheader, typographyConstants.ids.bodySmall)

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
    m.dialogBox.blendColor = m.theme.neutralSolidColor2
  end if
End Function


Function onButtonListChange(msg)
  buttons = msg.getData()
  buttonListContentNode = CreateObject("roSGNode", "ContentNode")
  longestTextWidth = 0

  for each buttonText in buttons
    buttonContent = buttonListContentNode.createChild("ContentNode")
    buttonContent.update({
      title: buttonText
      id: buttonText
      mode: "dark" ' Since the button could displayed in light vs dark background.
    }, true)
    ' Creating the button nodes to find out the longest text width due to limitation of arraygrid to dynamically adjust the width.
    listItem = CreateObject("roSGNode", "ListItemButtonWithBg")
    listContent = CreateObject("roSGNode", "ContentNode")
    listContent.title = buttonText
    listItem.itemContent = listContent

    if listItem.calculatedWidth > longestTextWidth
      longestTextWidth = listItem.calculatedWidth
    end if
  end for

  'Keeping the default width of 234 for each button and if the text length is greater than 234 then we are
  'determining the width based on the text length.
  if longestTextWidth > m.buttonList.itemSize[0]
    m.buttonList.itemSize = [longestTextWidth, m.buttonList.itemSize[1]]
  end if

  totalButtons = m.top.buttons.Count()
  m.buttonList.numColumns = totalButtons
  m.buttonList.content = buttonListContentNode
  contentAreaBoundingRect = m.contentArea.boundingRect()
  padding = 48
  m.dialogBox.width = contentAreaBoundingRect.width + padding
  dialogBoxTranslationX = 1920 - m.dialogBox.width - 63 ' where 63 is the gutter padding on the right side.
  m.dialogBox.translation = [dialogBoxTranslationX, m.dialogBox.translation[1]]
  ' Adjusting the height of the dialog based on content area height.
  contentAreaHeight = contentAreaBoundingRect.height
  m.dialogBox.height = contentAreaHeight + padding

  ' Center align the content.
  m.contentArea.translation = [m.dialogBox.width / 2, m.contentArea.translation[1]]
End Function
