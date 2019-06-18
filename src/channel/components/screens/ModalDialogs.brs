' This is a set of functions for displaying and handling button presses
' on a generic error modal.  Screens should include this file directly
' in a <script> tag.
' @param errorObj: The Associative array that contains all the info for the error message
' @param tryAgainCallback: (optional) Function to call when the try again button is clicked
' @param tryAgainParams: (optional) The parameters to pass to the tryAgainCallback() function when it is called
' @param cancelCallback: (optional)  Function to call when the cancel button is clicked
' @param cancelParams: (optional)  The parameters to pass to the cancelCallback() function when it is called
' @param buttons: (optional) An array of strings for the names of the buttons. Should onluy be 1 or 2 button names. Default buttons will be used if this is not passed

Function showErrorModal(errorObj As Object, tryAgainCallback=invalid As Dynamic, tryAgainParams=[] As Object, cancelCallback=invalid As Dynamic, cancelParams=[] As Object, buttons=[] as Object) As Void
  tubiLog("ModalDialog.showErrorModal")
  modal = CreateObject("roSGNode", "ModalDialogScreen")
  modal.title = errorObj.title
  errorCode = errorObj.code
  errorMessage = errorObj.message

  message = "Error: " + errorCode + Chr(10)
  message += errorMessage + Chr(10)
  message += "Please contact: support@tubi.tv"
  modal.message = message
  if tryAgainCallback <> invalid
    if buttons.count() = 2
      modal.buttons = [buttons[0], buttons[1]]
    else 
      modal.buttons = ["Try Again", "Close"]
    end if
  else
    if buttons.count() = 1
      modal.buttons = [buttons[0]]
    else 
      modal.buttons = ["Close"]
    end if
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


'''''''''''''''''''''''
' createErrorObject
'   This create an associatiove array to be used to display error messages.
'   Some of the contents of this object are dictated by the error codes specified on the following URL: 
'   https://tubitv.atlassian.net/wiki/spaces/EC/pages/798359880/User+Facing+Error+Codes
'
' @param contextCode: The context code ID
' @param subtypeCode: The subtype code ID
' @param message: The message to be displayed when displaying this error
' @param externalCode: The ID that comes from an outside source: i.e. server may provide a 404 error
' @param title: The title of the error window to be displayed when displaying this error
' Returns an associative array that is used to create the error object param for the showErrorModal() function
Function createErrorObject(contextCode as String, subtypeCode as String, message = "" as String, externalCode = "", title = "" as String) as Object
  oError = {}

  oError.contextCode = contextCode
  oError.subtypeCode = subtypeCode
  '//The external code is optional, so if there is no external code, then do not include it in the returned code
  sExternalCode = ""
  if externalCode <> invalid 
    if isstr(externalCode) = true
      sExternalCode = externalCode
    else if isint(externalCode) = true
      sExternalCode = externalCode.toStr()
    end if
    if sExternalCode = "-1"
      '//no external code should be set to -1 as that is a value set by the client code as a default error code
      sExternalCode = ""
    else if Len(sExternalCode) > 0
      sExternalCode = "-" + sExternalCode
    end if
  end if
  oError.externalCode = externalCode
  oError.message = message
  if Len(title) <= 0
    title = "Something went wrong"
  end if
  oError.title = title

  '//Format error codes according to the following specs
  '//   https://tubitv.atlassian.net/wiki/spaces/EC/pages/798359880/User+Facing+Error+Codes
  sPrefix = "RO"  '//RO = "Roku"
  
  oError.code = sPrefix + "-" + oError.contextCode  + "-" + oError.subtypeCode + sExternalCode

  return oError
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

'isstr
' ::TODO:: this is copied from generalUtils.brs. If/when we make generalUtils available to the general code, then we should link to generalUtils
'Determine if the given object supports the ifString interface
'******************************************************
Function isstr(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifString") = invalid return false
    return true
End Function

'******************************************************
'isint
' ::TODO:: this is copied from generalUtils.brs. If/when we make generalUtils available to the general code, then we should link to generalUtils
'Determine if the given object supports the ifInt interface
'******************************************************
Function isint(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifInt") = invalid return false
    return true
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
  tubiLog("ModalDialog.closeModal")
  if type(msg) = "roSGNode"
    modalNode = msg  '
  else if type(msg) = "roSGNodeEvent"
    modalNode = msg.getRoSGNode()
  end if

  if modalNode <> invalid
    modalHasFocus = false
    if modalNode.isInFocusChain()
      modalHasFocus = true
    end if
    modalNode.unobserveField("buttonSelected")
    modalNode.unobserveField("exitButton")
    m.top.removeChild(modalNode)
    if modalHasFocus
      m.top.setFocus(true)
    end if
  end if
  return invalid
End Function
