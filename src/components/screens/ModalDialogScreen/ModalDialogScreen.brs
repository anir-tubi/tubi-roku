Function init()
  m.top.observeField("buttons", "formatDialog")
  m.top.observeField("title", "formatDialog")
  m.top.observeField("message", "formatDialog")
  m.top.observeField("scrollable", "formatDialog")
  m.ButtonList = m.top.findNode("ButtonList")
  m.ContentArea = m.top.findNode("ContentArea")
  m.DialogBox = m.top.findNode("DialogBox")
  m.Message = m.top.findNode("Message")
  m.ScrollableMessage = m.top.findNode("ScrollableMessage")
  m.ScrollableBackground = m.top.findNode("ScrollableBackground")
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
    for each b in m.top.buttons
      button = newContent.createChild("ContentNode")      
      button.title = b
      button.id = b
    end for
    m.ButtonList.content = newContent
  end if

  'text area
  if m.top.scrollable then
    m.ScrollableBackground.visible = true
    m.ScrollableBackground.height = 320
    m.ScrollableMessage.visible = true
    m.ScrollableMessage.height = 300
    m.Message.visible = false
    m.ScrollableMessage.text = m.top.message
  else
    m.ScrollableBackground.visible = false
    m.ScrollableBackground.height = 0
    m.ScrollableMessage.visible = false
    m.ScrollableMessage.height = 0
    m.Message.visible = true
    m.Message.text = m.top.message
  end if

  ' Position the dialog vertically and horizontally centered on the screen
  contentRect = m.ContentArea.boundingRect()
  m.DialogBox.height = contentRect.height + 65 + 24
  newY = (1080 - m.DialogBox.height) / 2.0
  m.DialogBox.translation = [m.DialogBox.translation[0], newY]
End Function

Function onKeyEvent(key As String, press As Boolean) As Boolean
  if press and m.top.scrollable then
    if key = "up" and m.ButtonList.hasFocus() then
      m.ScrollableMessage.setFocus(true)
      return true
    else if (key = "down" or key = "left" or key = "right") and m.ScrollableMessage.hasFocus() then
      m.ButtonList.setFocus(true)
      return true
    end if
  end if
  return false
End Function