Function init()
  m.top.observeField("buttons", "formatDialog")
  m.top.observeField("title", "formatDialog")
  m.top.observeField("message", "formatDialog")
  m.ButtonList = m.top.findNode("ButtonList")
  m.ContentArea = m.top.findNode("ContentArea")
  m.DialogBox = m.top.findNode("DialogBox")
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
    end for
    m.ButtonList.content = newContent
  end if

  contentRect = m.ContentArea.boundingRect()
  m.DialogBox.height = contentRect.height + 65 + 24
  newY = (1080 - m.DialogBox.height) / 2.0
  m.DialogBox.translation = [m.DialogBox.translation[0], newY]
End Function

Function onKeyEvent(key As String, press As Boolean) As Boolean
  ' absorb all key presses when modal is showing
  return true
End Function