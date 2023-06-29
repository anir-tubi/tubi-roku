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
  m.MessageGroup = m.top.findNode("MessageGroup")
  m.ScrollableBackground = m.top.findNode("ScrollableBackground")
  m.Shade = m.top.findNode("Shade")
  m.Title = m.top.findNode("Title")


  m.constants = getConstantsFromGlobal()

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
      listContent =  CreateObject("roSGNode", "ContentNode")
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
    m.MessageGroup.appendChild(m.ScrollableBackground)  ' for making this idempotent
    m.ScrollableBackground.visible = true
    m.ScrollableBackground.height = 320
    m.ScrollableMessage.visible = true
    m.ScrollableMessage.height = 300
    m.ScrollableMessage.text = m.top.message
  else
    m.MessageGroup.removeChild(m.ScrollableBackground)
    m.Message.visible = true
    m.Message.text = m.top.message
  end if

  ' Position the dialog vertically and horizontally centered on the screen
  contentRect = m.ContentArea.boundingRect()
  m.DialogBox.height = contentRect.height + 65 + 24  ' 65 is from top to title, 24 is from button to bottom of dialog
  newY = (1080 - m.DialogBox.height) / 2.0
  m.DialogBox.translation = [m.DialogBox.translation[0], newY]
End Function
