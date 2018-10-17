' This is a set of functions for displaying and handling button presses
' on a generic error modal.  Screens should include this file directly
' in a <script> tag.

Function showErrorModal(errorCode As Integer, errorMessage As String, tryAgainCallback=invalid As Dynamic, tryAgainParams=[] As Object, cancelCallback=invalid As Dynamic, cancelParams=[] As Object) As Void
  tubiLog("ModalDialog.showErrorModal")
  modal = CreateObject("roSGNode", "ModalDialogScreen")
  modal.title = "Something went wrong"
  modal.message = "Error " + stri(errorCode) + Chr(10) + errorMessage
  if tryAgainCallback <> invalid
    modal.buttons = ["Try Again", "Close"]
  else
    modal.buttons = ["Close"]
  end if
  modal.observeField("buttonSelected", "onErrorModalButtonSelected")
  m.errorModalTryAgainCallback_ = tryAgainCallback
  m.errorModalTryAgainParams_ = tryAgainParams
  m.errorModalCancelCallback_ = cancelCallback
  m.errorModalCancelParams_ = cancelParams
  m.errorModal_ = modal
  m.top.appendChild(m.errorModal_)
  m.errorModal_.visible = true
  m.errorModal_.setFocus(true)
End Function

Function onErrorModalButtonSelected()
  tubiLog("ModalDialog.onErrorModalButtonSelected")
  m.errorModal_.setFocus(false)
  m.top.removeChild(m.errorModal_)
  m.top.setFocus(true)
  if m.errorModal_.buttonSelected = 0 and m.errorModal_.buttons.count() > 1
    ' try again
    if m.errorModalTryAgainCallback_ <> invalid
      if m.errorModalTryAgainParams_.count() > 0
        m.errorModalTryAgainCallback_(m.errorModalTryAgainParams_)
      else
        m.errorModalTryAgainCallback_()
      end if
    end if
  else
    ' cancel/close
    if m.errorModalCancelCallback_ <> invalid
      if m.errorModalCancelParams_.count() > 0
        m.errorModalCancelCallback_(m.errorModalCancelParams_)
      else
        m.errorModalCancelCallback_()
      end if
    end if
  end if
  m.errorModalTryAgainCallback_ = invalid
  m.errorModalTryAgainParams_ = invalid
  m.errorModalCancelCallback_ = invalid
  m.errorModalCancelParams_ = invalid
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
' Returns the newly created modal, in case the caller needs to forcefully close it
Function showModal(title, message, buttons, callbackName, backToExit=true)
  tubiLog("ModalDialog.showModal")
  modal = CreateObject("roSGNode", "ModalDialogScreen")
  modal.title = title
  modal.message = message
  modal.buttons = buttons
  m.top.appendChild(modal)
  ' NOTE! the closeModal callback must be observed AFTER the "callbackName"
  modal.observeField("buttonSelected", callbackName)
  modal.observeField("buttonSelected", "closeModal")
  if backToExit = true
    modal.observeField("exitButton", "closeModal")
  end if
  modal.setFocus(true)
  return modal
End Function


'''''''''''''''''''''''
' closeModal
'
' Used in conjuction with showExitAppModal or showSignOutModal
'
' @msg: a modal node reference, or a roSGNodeEvent if triggered as a callback
' side effects are removing focus from the modal and removing the modal from it's parent
' returns invalid
Function closeModal(msg)
  if type(msg) = "roSGNode"
    modalNode = msg  '
  else if type(msg) = "roSGNodeEvent"
    modalNode = msg.getRoSGNode()
  end if

  if modalNode <> invalid
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
  end if
  return invalid
End Function
