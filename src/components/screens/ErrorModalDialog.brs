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