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



' EXIT APP MODAL-----------------------------------------------
' A set of functions used to ask a user if they truly intended to exit the app 
'
' Use like:
'
' m.exitModal = showExitAppModal("onExitModalSelected")
' Function onExitAppModalButtonSelected()
'   result = getModalResult(m.exitModal)
'   doStuff(result) 'context specific actions based on what the user selected
'   m.exitModal = closeModal(m.exitModal)   'set to invalid
'   setFocusToLastFocusedComponent()
' End Function
'
'
Function showExitAppModal(callbackName as String)
  exitModal = CreateObject("roSGNode", "ModalDialogScreen")
  exitModal.title = "Are You Sure?"
  exitModal.message = "Do you really want to exit Tubi?"
  exitModal.buttons = ["Exit", "Cancel"]

  m.top.appendChild(exitModal)
  exitModal.visible = true
  exitModal.observeField("buttonSelected", callbackName)
  exitModal.setFocus(true)

  return exitModal
End Function


' SIGN OUT MODAL-----------------------------------------------
' A set of functions used to ask a user if they truly intended to sign out
'
' Use like:
'
' m.signOutModal = showSignOutModal("onSignOutModalSelected")
' Function onSignOutAppModalButtonSelected()
'   result = getModalResult(m.signOutModal)
'   doStuff(result) 'context specific actions based on what the user selected
'   m.signOutModal = closeModal(m.signOutModal)   'set to invalid
'   setFocusToLastFocusedComponent()
' End Function
'
'
Function showSignOutModal(callbackName as String)
  signOutModal = CreateObject("roSGNode", "ModalDialogScreen")
  signOutModal.title = "Are You Sure?"
  signOutModal.message = "You are about to sign out of your Tubi account."
  signOutModal.buttons = ["Sign Out", "Cancel"]

  m.top.appendChild(signOutModal)
  signOutModal.visible = true
  signOutModal.observeField("buttonSelected", callbackName)
  signOutModal.setFocus(true)

  return signOutModal
End Function


' Used in conjuction with showExitAppModal or showSignOutModal
'
' @modalNode: SGNode, a modal node as returned by one of the above function calls
' returns an integer representing the index of the choice selected
Function getModalResult(modalNode)
  return modalNode.buttonSelected
End Function


' Used in conjuction with showExitAppModal or showSignOutModal
'
' @modalNode: SGNode, a modal node as returned by one of the above function calls
' side effects are removing focus from the modal and removing the modal from it's parent
' returns invalid
Function closeModal(modalNode)
  modalNode.setFocus(false)
  modalNode.unobserveField("buttonSelected")
  m.top.removeChild(modalNode)
  return invalid
End Function


