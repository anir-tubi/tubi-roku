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
' exitModal = showExitAppModal()
' exitModal.observeField("buttonSelected", "onExitAppModalButtonSelected")
' Function onExitAppModalButtonSelected()
'   result = getExitAppModalResult()
'   doStuff(result) 'context specific actions based on what the user selected
'   closeExitAppModal()
' End Function
'
'
Function showExitAppModal()
  exitModal = CreateObject("roSGNode", "ModalDialogScreen")
  exitModal.title = "Are you Sure?"
  exitModal.message = "Do you really want to exit Tubi TV?"
  exitModal.buttons = ["Exit", "Cancel"]

  m.exitModal_ = exitModal
  m.top.appendChild(m.exitModal_)
  m.exitModal_.visible = true
  m.exitModal_.setFocus(true)

  return exitModal
End Function


Function getExitAppModalResult()
  return m.exitModal_.buttonSelected
End Function


Function closeExitAppModal()
  m.exitModal_.setFocus(false)
  m.top.removeChild(m.exitModal_)
  m.exitModal_ = invalid
End Function