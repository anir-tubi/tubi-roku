' This is a set of functions for displaying and handling button presses
' on a generic error modal.  Screens should include this file directly
' in a <script> tag.

Function showErrorModal(errorCode As Integer, errorMessage As String, tryAgainCallback=invalid As Dynamic, cancelCallback=invalid As Dynamic) As Void
  modal = CreateObject("roSGNode", "ModalDialogScreen")
  modal.title = "Something went wrong"
  modal.message = "Error " + stri(errorCode) + Chr(10) + errorMessage
  modal.buttons = ["Try Again", "Close"]
  modal.observeField("buttonSelected", "onErrorModalButtonSelected")
  m.errorModalTryAgainCallback_ = tryAgainCallback
  m.errorModalCancelCallback_ = cancelCallback
  m.errorModal_ = modal
  m.top.appendChild(m.errorModal_)
  m.errorModal_.visible = true
  m.errorModal_.setFocus(true)
End Function

Function onErrorModalButtonSelected()
  m.errorModal_.setFocus(false)
  m.top.removeChild(m.errorModal_)
  m.top.setFocus(true)
  if m.errorModal_.buttonSelected = 0 then
    ' try again
    if m.errorModalTryAgainCallback_ <> invalid then m.errorModalTryAgainCallback_()
  else
    ' cancel
    if m.errorModalCancelCallback_ <> invalid then m.errorModalCancelCallback_()
  end if
  m.errorModalTryAgainCallback_ = invalid
  m.errorModalCancelCallback_ = invalid
  m.errorModal_ = invalid
End Function



'''''''''''''''''''''''
' showExitAppModal
'
Function showExitAppModal(callbackName as String)
  title = "Are You Sure?"
  message = "Do you really want to exit Tubi?"
  buttons = ["Exit", "Cancel"]
  showModal(title, message, buttons, callbackName)
End Function


'''''''''''''''''''''''
' showSignOutModal
'
Function showSignOutModal(callbackName as String)
  title = "Are You Sure?"
  message = "You are about to sign out of your Tubi account."
  buttons = ["Sign Out", "Cancel"]
  showModal(title, message, buttons, callbackName)
End Function


'''''''''''''''''''''''
' showModal
'
Function showModal(title, message, buttons, callbackName)
  modal = CreateObject("roSGNode", "ModalDialogScreen")
  modal.title = title
  modal.message = message
  modal.buttons = buttons
  m.top.appendChild(modal)
  ' NOTE! the closeModal callback must be observed AFTER the "callbackName"
  modal.observeField("buttonSelected", callbackName)
  modal.observeField("buttonSelected", "closeModal")
  modal.observeField("exitButton", "closeModal")
  modal.setFocus(true)
End Function

' Used in conjuction with showExitAppModal or showSignOutModal
'
' @modalNode: SGNode, a modal node as returned by one of the above function calls
' side effects are removing focus from the modal and removing the modal from it's parent
' returns invalid
Function closeModal(msg)
  modalNode = msg.getRoSGNode()
  focus = false
  if modalNode.isInFocusChain()
    modalNode.setFocus(false)
    focus = true
  end if
  modalNode.unobserveField("buttonSelected")
  modalNode.unobserveField("exitButton")
  m.top.removeChild(modalNode)
  if focus
    m.top.setFocus(true)
  end if
  return invalid
End Function