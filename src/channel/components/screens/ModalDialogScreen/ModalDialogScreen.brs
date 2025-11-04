Function init()
  m.top.observeField("buttons", "formatDialog")
  m.top.observeField("title", "formatDialog")
  m.top.observeField("message", "formatDialog")
  m.top.observeField("scrollable", "formatDialog")
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")
  m.ButtonList = m.top.findNode("ButtonList")
  m.ContentArea = m.top.findNode("ContentArea")
  m.DialogBox = m.top.findNode("DialogBox")
  m.Message = m.top.findNode("Message")
  m.subMessage = m.top.findNode("subMessage")
  m.MessageGroup = m.top.findNode("MessageGroup")
  m.scrollableMessage = m.top.findNode("ScrollableMessage")
  m.ScrollableBackground = m.top.findNode("ScrollableBackground")
  m.Shade = m.top.findNode("Shade")
  m.Title = m.top.findNode("Title")
  m.signUpLogo = m.top.findNode("signUpLogo")

  m.top.observeFieldScoped("isModalUIChanged", "onIsModalUIChangedChanged")


  m.constants = getConstantsFromGlobal()

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.Message, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.subMessage, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.ScrollableMessage, typographyConstants.ids.bodyMedium)

  '//::TODO::colors - Design will eventually add this black color to all themes but until then, hardcode this with the default shadeColor regardless of theme.
  '//   when Design adds the color to all themes, then set this color within the onThemeChange() observer using the new theme specific color
  m.Shade.color = m.constants.ui.themes.default.shadeColor
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
    m.ScrollableBackground.color = theme.shadeColor
    m.Message.color = theme.primaryTextColor
    m.subMessage.color = theme.secondaryTextColor
    m.Title.color = theme.primaryTextColor
    m.DialogBox.color = theme.neutralSolidColor
  end if
End Function


''''''''''''''''''''
' formatDialog
'
' Set up the buttons and size the dialog box to fit the content
Function formatDialog()

  ' buttons
  if m.top.buttons = invalid then
    m.ButtonList.content = invalid
  else
    newContent = CreateObject("roSGNode", "ContentNode")
    nWidestWidth = 0
    for each b in m.top.buttons
      button = newContent.createChild("ContentNode")
      button.title = b
      button.id = b
      '//   Temporarily create ModalListItem for each button text to find the largest width necessary for the set of buttons,
      '//   in order to determine how wide m.ButtonList should be.
      '//   Different languages may make the text wider than usual so we need to ensure the button displays the full text
      listItem = CreateObject("roSGNode", "ModalListItem")
      listContent = CreateObject("roSGNode", "ContentNode")
      listContent.title = b
      listItem.itemContent = listContent

      if listItem.calculatedWidth > nWidestWidth
        nWidestWidth = listItem.calculatedWidth
      end if
    end for
    'Keeping the default width of 475 for each button and if the text length is greater than 475 then we are
    'determining the width based on the text length.
    if nWidestWidth > m.ButtonList.itemSize[0]
      m.ButtonList.itemSize = [nWidestWidth, m.ButtonList.itemSize[1]]
    end if
    m.ButtonList.content = newContent
  end if

  'text area
  if m.top.scrollable then
    m.MessageGroup.removeChild(m.Message)
    m.MessageGroup.appendChild(m.ScrollableBackground) ' for making this idempotent
    m.ScrollableBackground.visible = true
    m.ScrollableBackground.height = 320
    m.ScrollableMessage.visible = true
    m.ScrollableMessage.height = 300
    m.ScrollableMessage.text = m.top.message
  else
    m.MessageGroup.removeChild(m.ScrollableBackground)
    m.Message.visible = true
    m.Message.text = m.top.message
    m.subMessage.text = m.top.subMessage
  end if

  ' Position the dialog vertically and horizontally centered on the screen
  contentRect = m.ContentArea.boundingRect()
  buttonRect = m.ButtonList.boundingRect()
  m.DialogBox.height = contentRect.height + buttonRect.height + 65 + 24 ' 65 is from top to title, 24 is from button to bottom of dialog
  newY = (1080 - m.DialogBox.height) / 2.0
  m.DialogBox.translation = [m.DialogBox.translation[0], newY]
End Function


Function onIsModalUIChangedChanged(msg)
  isModalUIChanged = msg.getData()
  isSignUpLogoPresent = (m.signUpLogo.getParent() <> invalid)
  isSubMessagePresent = (m.subMessage.getParent() <> invalid)
  buttonListXPosition = 20

  if isModalUIChanged = true
    if isSignUpLogoPresent = false
      m.ContentArea.insertChild(m.signUpLogo, 0)
    end if

    if isSubMessagePresent = false
      m.MessageGroup.insertChild(m.subMessage, 1)
    end if

    m.ScrollableBackground.translation = [40, 40]
    m.signUpLogo.visible = true
    m.subMessage.visible = true
    m.Title.maxLines = 3
    m.ButtonList.bgURL = "pkg:/images/pill_top_nav_$$RES$$.9.png"
    m.ButtonList.numRows = "1"
    m.ButtonList.numColumns = "3"
    m.ContentArea.itemSpacings = [24, 12, 72]
    m.ButtonList.itemSize = [120, 80]
    buttonListXPosition = 60
  else
    if isSignUpLogoPresent = true
      m.ContentArea.removeChild(m.signUpLogo)
    end if

    if isSubMessagePresent = true
      m.MessageGroup.removeChild(m.subMessage)
    end if

    m.signUpLogo.visible = false
    m.subMessage.visible = false
    m.Title.maxLines = 1
    m.ButtonList.bgURL = ""
    m.ButtonList.numRows = "3"
    m.ButtonList.numColumns = "1"
    m.ContentArea.itemSpacings = [50, 36]
    m.ButtonList.itemSize = [475, 80]
  end if

  m.ButtonList.translation = [buttonListXPosition, m.ContentArea.boundingRect().height + 108]
End Function
