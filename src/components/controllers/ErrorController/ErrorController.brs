Function init()
  tubiLog("ErrorController.init")
  m.top.observeField("error","showModalDialog")
End Function

Function showModalDialog()
  tubiLog("ErrorController.showModalDialog")
  error = m.top.error
  m.Dialog = m.top.createChild("ModalDialogScreen")
  m.Dialog.title = error.title
  m.Dialog.message = error.message
  m.Dialog.buttons = [error.buttonText]
  m.Dialog.observeField("buttonSelected", "onCloseError")
  m.Dialog.setFocus(true)
End Function

'''''''''''''''''''''''''
' onCloseError
'
' Close the error dialog
Function onCloseError()
  tubiLog("ErrorController.onCloseError")
  m.top.removeChild(m.Dialog)
  m.Dialog.unobserveField("buttonSelected")
  m.top.buttonSelected = true
End Function