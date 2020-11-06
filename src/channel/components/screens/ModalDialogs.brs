' This is a set of functions for displaying and handling button presses
' on a generic error modal.  Screens should include this file directly
' in a <script> tag.


' @modalInfo: assocArray, contains info necessary to show/dismiss the modal. Has the following format:
'              {
'                 title: <string>                   - The title to be displayed on the modal
'                 message: <string>                 - The message to be displayed on the modal
'                 scrollable: <boolean>             - Is the modal vertically scrollable
'                 openTrackEvent: <assocArray>      - The analytics tracking info that was sent when the modal was shown, 
'                                                     will be re-purposed for sending the dismiss dialog tracking event.
'                                                     Should contain "type" and "values" keys.
'                 trackingTask: <roSGNode>          - The tracking task that can be used to send the dismiss dialog tracking event
'                 backButtonCallback: <roFunction>  - A function called if a user attempts "back out" of the modal.
'              }    
' 
' @buttonInfo: array, each index contains an assocArray with the following format:
'               {
'                 text: <string>                - The text on the button
'                 type: <string>                - "accept" or "dismiss", describes the action the user is taking,
'                                                  in relation to the modal. Used in dialog analytics
'                 callback: <roFunction>        - A function that will be called if the button is selected
'                 callbackParams: <array>       - An array which will be passed to the callback as a single paramater
'               }
Function showModal(modalInfo, buttonInfo)
  ' Don't create the modal if a modal already exists, or there is not enough info to create it
  if m.tempModal = invalid and modalInfo <> invalid and buttonInfo <> invalid
    modal = CreateObject("roSGNode", "ModalDialogScreen")
    modal.title = modalInfo.title
    modal.message = modalInfo.message
    modal.scrollable = modalInfo.scrollable

    m.tempModal = {
      buttonInfo: buttonInfo
      modalInfo: modalInfo
    }

    buttons = []
    for i=0 to buttonInfo.count()-1
      button = buttonInfo[i]
      buttons.push(button.text)
    end for

    modal.buttons = buttons
    modal.observeFieldScoped("buttonSelected", "onModalButtonSelected")
    modal.observeFieldScoped("exitButton", "onModalButtonSelected")
    m.top.appendChild(modal)
    modal.visible = true
    modal.setFocus(true)
    ' send the show dialog track event
    if modalInfo.openTrackEvent <> invalid and modalInfo.trackingTask <> invalid
      modalInfo.trackingTask.trackEvent = modalInfo.openTrackEvent
    end if

    return modal
  end if
End Function


Function onModalButtonSelected(msg)
  modal = msg.getRoSGNode()
  buttonSelected = msg.getData()
  closeModal(modal, buttonSelected)
End Function


'@modal: roSGNode, the modal node created in showModal()
'@buttonSelected: string OR integer. If string can be "back" or "options". If integer, represents the index of the button selected.
Function closeModal(modal, buttonSelected = invalid)
  buttonInfo = invalid
  trackEvent = invalid
  trackingTask = invalid
  backButtonCallback = invalid

  if m.tempModal <> invalid
    buttonInfo = m.tempModal.buttonInfo

    if m.tempModal.modalInfo <> invalid
      trackEvent = m.tempModal.modalInfo.openTrackEvent
      trackingTask = m.tempModal.modalInfo.trackingTask
      backButtonCallback = m.tempModal.modalInfo.backButtonCallback
    end if
    
    m.tempModal = invalid
  end if

  'send the dismiss dialog analytic event
  if trackEvent <> invalid and trackEvent.values <> invalid and trackingTask <> invalid
    trackEvent.values.dialog_action = "DISMISS_AUTO"

    if type(buttonSelected) = "String" or type(buttonSelected) = "roString"
      if buttonSelected = "back"
        'the user has pressed the back buttons on the remote
        trackEvent.values.dialog_action = "DISMISS_DELIBERATE"
      end if
    else if buttonInfo <> invalid and buttonSelected <> invalid and buttonInfo[buttonSelected] <> invalid
      'the user selected one of the dialog buttons
      if buttonInfo[buttonSelected].type = "accept"
        trackEvent.values.dialog_action = "ACCEPT_DELIBERATE"
      else if buttonInfo[buttonSelected].type = "dismiss"
        trackEvent.values.dialog_action = "DISMISS_DELIBERATE"
      end if
    end if

    trackingTask.trackEvent = trackEvent
  end if

  'give focus back to the context that had it before invoking the modal
  modal.unobserveFieldScoped("buttonSelected")
  modal.unobserveFieldScoped("exitButton")
  m.top.removeChild(modal)
  m.top.setFocus(true)
  
  'run the callback associated with the selected button
  callback = invalid
  callbackParams = invalid
  if type(buttonSelected) = "String" or type(buttonSelected) = "roString"
    if buttonSelected = "back"
      if backButtonCallback <> invalid
        callback = backButtonCallback
      end if
    end if
  else if buttonInfo <> invalid and buttonSelected <> invalid and buttonInfo[buttonSelected] <> invalid
    callback = buttonInfo[buttonSelected].callback
    if callback <> invalid
      callbackParams = buttonInfo[buttonSelected].callbackParams
    end if
  end if

  if callback <> invalid
    if callbackParams = invalid
      callback()
    else
      callback(callbackParams)
    end if
  end if
End Function


' @modalInfo: The Associative array that contains all the info for the error modal. See the modalInfo parameter of showModal() for format.
' @tryAgainCallback: (optional) Function to call when the try again button is clicked
' @tryAgainParams: (optional) The parameters to pass to the tryAgainCallback() function when it is called
' @cancelCallback: (optional)  Function to call when the cancel button is clicked
' @cancelParams: (optional)  The parameters to pass to the cancelCallback() function when it is called
' @buttons: (optional) An array of strings for the names of the buttons. Should only be 1 or 2 button names. Default buttons will be used if this is not passed
Function showErrorModal(modalInfo = {}, tryAgainCallback = invalid, tryAgainParams = invalid, cancelCallback = invalid, cancelParams = invalid, buttons = []) As Void
  tubiLog("ModalDialog.showErrorModal")

  if tryAgainCallback <> invalid
    if buttons.count() <> 2
      buttons = [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_close")]
    end if

    buttonInfo = [
      {
        text: buttons[0]
        type: "accept"
        callback: tryAgainCallback
        callbackParams: tryAgainParams
      }
      {
        text: buttons[1]
        type: "dismiss"
        callback: cancelCallback
        callbackParams: cancelParams
      }
    ]
  else
    if buttons.count() <> 1
      buttons = [getTranslation("dialog_button_close")]
    end if

    buttonInfo = [
      {
        text: buttons[0]
        type: "accept"
        callback: cancelCallback
        callbackParams: cancelParams
      }
    ]
  end if

  ' set a default error modal title
  if modalInfo.title = invalid or modalInfo.title = ""
    modalInfo.title = getTranslation("dialog_defaultError_title")
  end if

  ' set a default error modal message (this should never happen in theory)
  if modalInfo.message = invalid or modalInfo.message = ""
    modalInfo.message = getTranslation("dialog_defaultError_description") 
  end if

  ' use the cancel callback as the backButtonCallback - as the behavior should be the same
  modalInfo.backButtonCallback = cancelCallback

  showModal(modalInfo, buttonInfo)
End Function


'''''''''''''''''''''''
' getErrorMessage
'
' @pmessage: string, The message to be displayed to the user
' @userFacingErrorCode: string, an error code as returned by getUserFacingErrorCode()
Function getErrorMessage(message = "", userFacingErrorCode = "") as Object
  errorMessage = message + Chr(10)
  errorMessage += getTranslation("dialog_errorMessageContact") + Chr(10)
  errorMessage += getTranslation("dialog_errorPrefix") + userFacingErrorCode
  return errorMessage
End Function


' @contextCode: string, The context code ID
' @subtypeCode: string, The subtype code ID
' @externalCode: string, optional, The ID that comes from an outside source: i.e. server may provide a 404 error
' Returns a user facing error code as specified by:
' https://tubitv.atlassian.net/wiki/spaces/EC/pages/798359880/User+Facing+Error+Codes
Function getUserFacingErrorCode(contextCode, subtypeCode, externalCode = "")
  sPrefix = "RO"  '//RO = "Roku"

  '//The external code is optional, so if there is no external code, then do not include it in the returned code
  sExternalCode = ""
  if externalCode <> invalid 
    if modal_isstr(externalCode) = true
      sExternalCode = externalCode
    else if modal_isint(externalCode) = true
      sExternalCode = externalCode.toStr()
    end if
    if Len(sExternalCode) > 0
      sExternalCode = "-" + sExternalCode
    end if
  end if

  return sPrefix + "-" + contextCode  + "-" + subtypeCode + sExternalCode
End Function


'isstr
' ::TODO:: this is copied from generalUtils.brs. If/when we make generalUtils available to the general code, then we should link to generalUtils
'Determine if the given object supports the ifString interface
'******************************************************
Function modal_isstr(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifString") = invalid return false
    return true
End Function

'******************************************************
'isint
' ::TODO:: this is copied from generalUtils.brs. If/when we make generalUtils available to the general code, then we should link to generalUtils
'Determine if the given object supports the ifInt interface
'******************************************************
Function modal_isint(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifInt") = invalid return false
    return true
End Function


'''''''''''''''''''''''
' showExitAppModal
'
Function showExitAppModal(dialogEvent, trackingTask, callback = invalid)
  title = getTranslation("dialog_exitApp_title")
  message = getTranslation("dialog_exitApp_description")
  buttons = [getTranslation("dialog_button_exit"), getTranslation("dialog_button_cancel")]
  showSimpleModal(title, message, buttons, dialogEvent, trackingTask, callback)
End Function


'''''''''''''''''''''''
' showSignOutModal
'
Function showSignOutModal(dialogEvent, trackingTask, callback = invalid)
  title = getTranslation("dialog_signOut_title")
  message = getTranslation("dialog_signOut_description")
  buttons = [getTranslation("dialog_signOut_button_ok"), getTranslation("dialog_button_cancel")]
  showSimpleModal(title, message, buttons, dialogEvent, trackingTask, callback)
End Function

'''''''''''''''''''''''
' showInfoModal
'
Function showInfoModal(title, message, dialogEvent, trackingTask, callback = invalid)
  buttons = [getTranslation("dialog_button_close")]
  info = getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback)
  showModal(info.modalInfo, info.buttonInfo)
End Function


'''''''''''''''''''''''
' showDescriptionModal
'
Function showDescriptionModal(message, dialogEvent, trackingTask, callback = invalid)
  title = getTranslation("dialog_fullSynopsis_title")
  buttons = [getTranslation("dialog_button_close")]
  info = getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback)
  info.modalInfo.scrollable = true
  showModal(info.modalInfo, info.buttonInfo)
End Function


' Creates a modal dialog with 2 buttons. The expected behavior is that the 2nd button will act as a cancel option for the user
' and close the modal without taking any further action. This is just a wrapper around showModal() with simpler paramaters.
' 
' callbacks passed to showSimpleModal cannot take any parameters and if you want to have callbacks with parameters, use showModal()
'
' @title: string, the title of the dialog, displayed in larger font
' @message: string, the main message of the dialog to be displayed to the user
' @buttons: array of strings (max 2 indexes), a button will be created for each index with the label of the button equal to the index's string.
'           An empty array will create a single "OK" button by default.
' @dialogEvent: assocArray, contains the info necessary to send a dialog open analytics event, has keys: "type" and "values"
' @trackingTask: roSGNode, an instance of the trackingLoggingTask - used to send close dialog events when the dialog is closed.
' @callback: (optional) roFunction, a function that will be triggered when the first button is selected
' @cancelCallback: (optional) Function will be triggered when the second button is clicked (function will not have any params)        
Function showSimpleModal(title, message, buttons, dialogEvent, trackingTask, callback = invalid, cancelCallback = invalid)
  info = getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback, cancelCallback)
  showModal(info.modalInfo, info.buttonInfo)
End Function


' Helper function with same interface as showSimpleModal().
' Allows small variations on showSimpleModal in the case that additional info needs to be added to the modalInfo
' prior to calling showModal. For example showDescriptionModal() needs to add the scrollable key.
'
' Returns an assocArray with the keys modalInfo and buttonInfo.
Function getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback = invalid, cancelCallback = invalid)
  modalInfo = {
    title: title
    message: message
    openTrackEvent: dialogEvent
    trackingTask: trackingTask
    backButtonCallback : cancelCallback
  }

  buttonInfo = []

  'always create at least one button
  firstButtonText = getTranslation("dialog_button_ok")
  if type(buttons) = "roArray" and (type(buttons[0]) = "roString" or type(buttons[0]) = "String")
    firstButtonText = buttons[0]
  end if
  buttonOne = {
    text: firstButtonText
    type: "accept"
    callback: callback
    callbackParams: invalid
  }
  buttonInfo.push(buttonOne)

  'second button is optional
  if type(buttons) = "roArray" and (type(buttons[1]) = "roString" or type(buttons[1]) = "String")
    buttonTwo = {
      text: buttons[1]
      type: "dismiss"
      callback: cancelCallback
      callbackParams: invalid
    }
    buttonInfo.push(buttonTwo)
  end if

  return {
    modalInfo: modalInfo
    buttonInfo: buttonInfo
  }
End Function
