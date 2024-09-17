' This is a set of functions for displaying and handling button presses
' on a generic error modal.  Screens should include this file directly
' in a <script> tag.


' @modalInfo: assocArray, contains info necessary to show/dismiss the modal. Has the following format:
'              {
'                 title: <string>                   - The title to be displayed on the modal
'                 message: <string>                 - The message to be displayed on the modal
'                 modalDialogTypes: <string>        - This can be present or absent. If it is present, it needs to be enum value from constants.brs - modalDialogTypes-> "simpleModal"
'                 modalDialogStyles = <string>      - In case of simple modal, This value can indicate if the message is scrollable of not.  -modalDialogStyles -> "scrollableMessage"
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
'
Function showModal(modalInfo, buttonInfo)
  ' Don't create the modal if a modal already exists, or there is not enough info to create it
  if m.tempModal = invalid AND modalInfo <> invalid AND buttonInfo <> invalid
    removeFocusFromRowlist()
    modal = getSimpleModal(modalInfo)

    m.tempModal = {
      buttonInfo: buttonInfo
      modalInfo: modalInfo
    }

    addButtonsToModal(modal, buttonInfo)

    m.top.appendChild(modal)
    modal.visible = true
    modal.setFocus(true)

    ' send the show dialog track event
    if modalInfo.openTrackEvent <> invalid AND modalInfo.trackingTask <> invalid
      modalInfo.trackingTask.trackEvent = modalInfo.openTrackEvent
    end if

    return modal
  end if

  return invalid

End Function


' @modalInfo: assocArray, contains info necessary to show/dismiss MulitStyle modal. Has the following format:
'
'
'              {
'                 header: <string>                   - The header to be displayed on the modal
'                 subHeader: <string>                 - The message to be displayed underneath the header
'                 modalDialogTypes: <string>        - This value should be equal to - modalDialogTypes -> "multiStyle" to speicy that multistyle dialog to be used.
'                 modalDialogStyles = <string>      - Enum values are defined in constants.brs -
'                                                                                             "multiMessageGroup"
'                                                                                             "imageAsBody"
'
'                 openTrackEvent: <assocArray>      - The analytics tracking info that was sent when the modal was shown,
'                                                     will be re-purposed for sending the dismiss dialog tracking event.
'                                                     Should contain "type" and "values" keys.
'                 trackingTask: <roSGNode>          - The tracking task that can be used to send the dismiss dialog tracking event
'                 backButtonCallback: <roFunction>  - A function called if a user attempts "back out" of the modal.
'                 multiStyleMessage: <array>        - A array of <assocArray>s formated :
'                    {
'                       header: <string>            - message header or message main item
'                       subHeader: <string>         - message sub header or message sub item
'                       iconUri: <string>           - uri for the icon to be displayed left side of the message
'                    }
'                 imageUrls: <array>.........- Instead of the multiStyleMessage, displaying a single or multiple images.
'              }
'
' @buttonInfo: array, each index contains an assocArray with the following format:
'               {
'                 text: <string>                - The text on the button
'                 type: <string>                - "accept" or "dismiss", describes the action the user is taking,
'                                                  in relation to the modal. Used in dialog analytics
'                 callback: <roFunction>        - A function that will be called if the button is selected
'                 callbackParams: <array>       - An array which will be passed to the callback as a single paramater
'                 shouldFocusParentBeforeCallback <boolean>   -In some cases we can not set focus back to currentScreen. Example case is where we show registration welcome modal to new users and when user selects
'                                                              signIn button and then focus is set back to currentScreen, which will start playing live channel or video preview before RFI modal shows. This videopreviw/livechannel will keep playing in the background.
'                                                              To avoid such scenarios set shouldFocusParentBeforeCallback to 'false' and handle the focus in call back function.
'               }
'
Function showMultiStyleModal(modalInfo, buttonInfo)

  ' Don't create the modal if a modal already exists, or there is not enough info to create it
  if m.tempModal = invalid AND modalInfo <> invalid AND buttonInfo <> invalid
    removeFocusFromRowlist()
    modal = getMultiStyleModal(modalInfo)
    addButtonsToModal(modal, buttonInfo)

    m.tempModal = {
      buttonInfo: buttonInfo
      modalInfo: modalInfo
    }



    if modalInfo.openTrackEvent <> invalid AND modalInfo.trackingTask <> invalid
      modalInfo.trackingTask.trackEvent = modalInfo.openTrackEvent
    end if

    m.top.appendChild(modal)
    modal.visible = true
    modal.setFocus(true)

    return modal
  end if

  return invalid

End Function


Function addButtonsToModal(modal, buttonInfo)
  buttons = []
  for i = 0 to buttonInfo.count() - 1
    button = buttonInfo[i]
    buttons.push(button.text)
  end for

  modal.buttons = buttons
  modal.observeFieldScoped("buttonSelected", "onModalButtonSelected")
  modal.observeFieldScoped("exitButton", "onModalButtonSelected")
End Function


Function getMultiStyleModal(modalInfo)
  modal = CreateObject("roSgNode", "MultiStyleDialogScreen")
  header = modalInfo.header
  subHeader = modalInfo.subHeader
  modal.id = getUniqueModalId(header, subHeader)
  modal.multiStyleMessage = modalInfo.multiStyleMessage

  if modalInfo.imageDimensions <> invalid then
    modal.imageDimensions = modalInfo.imageDimensions
  end if

  modal.imageUrls = modalInfo.imageUrls
  modal.header = header
  modal.subHeader = subHeader
  modal.instantResumeAction = modalInfo.instantResumeAction
  return modal
End Function


Function getSimpleModal(modalInfo)
  modal = CreateObject("roSGNode", "ModalDialogScreen")
  title = modalInfo.title
  message = modalInfo.message
  modal.id = getUniqueModalId(title, message)
  modal.title = title
  modal.message = message
  modal.scrollable = modalInfo.scrollable
  modal.instantResumeAction = modalInfo.instantResumeAction
  return modal
End Function


' We need a unique id for our modals due to the animation but we need it to to be consistent across runs so we can test nodes within the dialog as part of our automation so we use a hash of the title and message to give a consistent id
' @title: string, title on the dialog
' @message: string, body of the dialog
Function getUniqueModalId(title, message)

  ba = createObject("roByteArray")
  ba.fromAsciiString(title + message)

  digest = createObject("roEVPDigest")
  digest.setup("md5")
  modalId = digest.process(ba).left(7)
  return modalId
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
  backButtonCallbackParams = invalid

  if m.tempModal <> invalid
    buttonInfo = m.tempModal.buttonInfo

    if m.tempModal.modalInfo <> invalid
      trackEvent = m.tempModal.modalInfo.openTrackEvent
      trackingTask = m.tempModal.modalInfo.trackingTask
      backButtonCallback = m.tempModal.modalInfo.backButtonCallback
      backButtonCallbackParams = m.tempModal.modalInfo.backButtonCallbackParams
    end if

    m.tempModal = invalid
  end if

  'send the dismiss dialog analytic event
  if trackEvent <> invalid AND trackEvent.values <> invalid AND trackingTask <> invalid
    trackEvent.values.dialog_action = "DISMISS_AUTO"
    if buttonSelected = invalid
      trackEvent.values.dialog_action = "ACCEPT_AUTO"
    else if type(buttonSelected) = "String" or type(buttonSelected) = "roString"
      if buttonSelected = "back"
        'the user has pressed the back buttons on the remote
        trackEvent.values.dialog_action = "DISMISS_DELIBERATE"
      end if
    else if buttonInfo <> invalid AND buttonSelected <> invalid AND buttonInfo[buttonSelected] <> invalid
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
  waitForCallBackResponse = false
  'run the callback associated with the selected button
  callback = invalid
  callbackParams = invalid

  if type(buttonSelected) = "String" OR type(buttonSelected) = "roString"
    if buttonSelected = "back"

      if backButtonCallback <> invalid
        callback = backButtonCallback

        if backButtonCallbackParams <> invalid
          callbackParams = backButtonCallbackParams
        end if

      end if

    end if
  else if buttonInfo <> invalid AND buttonSelected <> invalid AND buttonInfo[buttonSelected] <> invalid
    callback = buttonInfo[buttonSelected].callback

    if callback <> invalid
      callbackParams = buttonInfo[buttonSelected].callbackParams
    end if

    '//SPECIAL CASE FOR REGISTRATION MODAL DIALOG. WE CAN NOT SET FOCUS ON HOMESCREEN WHILE WAITING FOR RFI MODAL TO SHOW UP THROUGH CALLBACK,
    '//BECAUSE HOMESCREEN WILL START PLAYING VIDEO PREVIEW OR LIENAR CONTENT
    if buttonInfo[buttonSelected].shouldFocusParentBeforeCallback = false
      waitForCallBackResponse = true
    end if

  end if

  if waitForCallBackResponse = false
    if isFunction(manageChildFocus) = true then 'bs:disable-line 1001 LINT1001
      manageChildFocus() 'bs:disable-line 1140 LINT1001
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


'@modal: roSGNode, the modal node created in showModal()
Function hideModal(modal)
  modal.isHidden = true
  modal.visible = false
End Function


'@modal: roSGNode, the modal node created in showModal()
Function unhideModal(modal)
  modal.isHidden = false
  modal.visible = true

  modal.setFocus(true)
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
  ' use the cancel callback params as the backButtonCallbackParams - as the params should also be the same
  modalInfo.backButtonCallbackParams = cancelParams
  modalInfo.instantResumeAction = m.constants.instantResumeActions.restartApp

  showModal(modalInfo, buttonInfo)
End Function


'''''''''''''''''''''''
' getErrorMessage
'
' @message: string, The message to be displayed to the user
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

  if isNonEmptyString(contextCode) = true
    contextCode = "-" + contextCode 
  end if
  
  if isNonEmptyString(subtypeCode) = true
    subtypeCode = "-" + subtypeCode
  end if

  return sPrefix + contextCode + subtypeCode + sExternalCode
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
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, trackingTask, callback)
End Function


'''''''''''''''''''''''
' showSignOutModal
'
Function showSignOutModal(dialogEvent, trackingTask, callback = invalid)
  title = getTranslation("dialog_signOut_title")
  message = getTranslation("dialog_signOut_description")
  buttons = [getTranslation("dialog_signOut_button_ok"), getTranslation("dialog_button_cancel")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, trackingTask, callback)
End Function

'''''''''''''''''''''''
' showInfoModal
'
Function showInfoModal(title, message, dialogEvent, trackingTask, callback = invalid)
  buttons = [getTranslation("dialog_button_close")]
  info = getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback)
  info.modalInfo.instantResumeAction = m.constants.instantResumeActions.closeDialog
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
  info.modalInfo.instantResumeAction = m.constants.instantResumeActions.closeDialog
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
' @instantResumeAction: string, provides the information on what action should take for error and action modals.
Function showSimpleModal(title, message, buttons, dialogEvent, trackingTask, callback = invalid, cancelCallback = invalid, instantResumeAction = "")
  info = getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback, cancelCallback, instantResumeAction)
  showModal(info.modalInfo, info.buttonInfo)
End Function


'Wrapper function to showSimpleModal() with customization of instantResumeAction = "closeDialog"

'Use this modal when we are trying to pass "closeDialog" as the instantResumeAction parameter. This method is used when modals are not instant resumable.

'@title: string, the title of the dialog, displayed in larger font
' @message: string, the main message of the dialog to be displayed to the user
' @buttons: array of strings (max 2 indexes), a button will be created for each index with the label of the button equal to the index's string.
'           An empty array will create a single "OK" button by default.
' @dialogEvent: assocArray, contains the info necessary to send a dialog open analytics event, has keys: "type" and "values"
' @trackingTask: roSGNode, an instance of the trackingLoggingTask - used to send close dialog events when the dialog is closed.
' @callback: (optional) roFunction, a function that will be triggered when the first button is selected
' @cancelCallback: (optional) Function will be triggered when the second button is clicked (function will not have any params)
Function showSimpleInstantResumableModal(title, message, buttons, dialogEvent, trackingTask, callback = invalid, cancelCallback = invalid)
  showSimpleModal(title, message, buttons, dialogEvent, trackingTask, callback, cancelCallback, m.constants.instantResumeActions.closeDialog)
End Function


' Helper function with same interface as showSimpleModal().
' Allows small variations on showSimpleModal in the case that additional info needs to be added to the modalInfo
' prior to calling showModal. For example showDescriptionModal() needs to add the scrollable key.
'
' Returns an assocArray with the keys modalInfo and buttonInfo.
Function getSimpleModalInfo(title, message, buttons, dialogEvent, trackingTask, callback = invalid, cancelCallback = invalid, instantResumeAction = "")
  modalInfo = {
    title: title
    message: message
    openTrackEvent: dialogEvent
    trackingTask: trackingTask
    backButtonCallback : cancelCallback
    instantResumeAction : instantResumeAction
  }

  buttonInfo = []

  'always create at least one button
  firstButtonText = getTranslation("dialog_button_ok")
  if type(buttons) = "roArray" AND (type(buttons[0]) = "roString" or type(buttons[0]) = "String")
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
  if type(buttons) = "roArray" AND (type(buttons[1]) = "roString" or type(buttons[1]) = "String")
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


' Helper function to return the top most modal being displayed with respect to the current m.top
Function getTopModal()

  for i = m.top.getChildCount()-1 to 0 Step -1
    child = m.top.getChild(i)
    if child.isSubtype("BaseDialogScreen") = true
      return child
    end if
  end for

  return invalid
End Function


' @modalInfo: assocArray, contains info necessary to show/dismiss ToastStyle modal. Has the following format:
'
'
'              {
'                 header: <string>                   - The header to be displayed on the modal
'                 subheader: <string>                 - The subheader to be displayed underneath the header
'                 openTrackEvent: <assocArray>      - The analytics tracking info that was sent when the modal was shown,
'                                                     will be re-purposed for sending the dismiss dialog tracking event.
'                                                     Should contain "type" and "values" keys.
'                 trackingTask: <roSGNode>          - The tracking task that can be used to send the dismiss dialog tracking event
'                 backButtonCallback: <roFunction>  - A function called if a user attempts "back out" of the modal.'
' @buttonInfo: array, each index contains an assocArray with the following format:
'               {
'                 text: <string>                - The text on the button
'                 type: <string>                - "accept" or "dismiss", describes the action the user is taking,
'                                                  in relation to the modal. Used in dialog analytics
'                 callback: <roFunction>        - A function that will be called if the button is selected
'                 callbackParams: <array>       - An array which will be passed to the callback as a single paramater
'                 shouldFocusParentBeforeCallback <boolean>   -In some cases we can not set focus back to currentScreen. Example case is where we show registration welcome modal to new users and when user selects
'                                                              signIn button and then focus is set back to currentScreen, which will start playing live channel or video preview before RFI modal shows. This videopreviw/livechannel will keep playing in the background.
'                                                              To avoid such scenarios set shouldFocusParentBeforeCallback to 'false' and handle the focus in call back function.
'               }
'
Function showToastStyleModal(modalInfo, buttonInfo)
  ' Don't create the modal if a modal already exists, or there is not enough info to create it
  if m.tempModal = invalid AND modalInfo <> invalid AND buttonInfo <> invalid
    removeFocusFromRowlist()
    modal = CreateObject("roSgNode", "ToastStyleDialogScreen")
    modal.update({
      header: modalInfo.header
      subheader: modalInfo.subheader
      instantResumeAction: modalInfo.instantResumeAction
    })
    modal.id = getUniqueModalId(modalInfo.header, modalInfo.subheader)

    m.tempModal = {
      buttonInfo: buttonInfo
      modalInfo: modalInfo
    }

    addButtonsToModal(modal, buttonInfo)

    m.top.appendChild(modal)
    modal.visible = true
    modal.setFocus(true)

    ' send the show dialog track event
    if modalInfo.openTrackEvent <> invalid AND modalInfo.trackingTask <> invalid
      modalInfo.trackingTask.trackEvent = modalInfo.openTrackEvent
    end if

    return modal
  end if

  return invalid
End Function


Function removeFocusFromRowlist()
  if type(getCurrentScreen) = "Function" 'bs:disable-line 1001 LINT1001
    screen = getCurrentScreen() 'bs:disable-line 1140 LINT1001
    ' Due to a bug in roku when we set focus to rowlist and immediately set focus to modal.
    ' Modal does not seem to be receive focus properly. So we are force removing focus away from rowlist before displaying the modal.
    if screen.hasField("removeFocusFromRowList") = true
      screen.removeFocusFromRowList = true
    end if
  end if
End Function
