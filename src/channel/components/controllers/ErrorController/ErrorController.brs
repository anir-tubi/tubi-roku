Function init()
  print "init Scene Graph Erorr Controller"
  m.constants = m.global.constants
  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.trackingLoggingTask.control = "RUN"
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.top.observeField("connectionError","showConnectionError")
End Function

Function showConnectionError()
    errorObj = {}
    errorObj.contextCode = m.constants.errors.context.homeScreen 
    errorObj.subtypeCode = m.constants.errors.subtypes.networkError
    errorObj.title = getTranslation("error_connection_title")
    errorObj.message = getTranslation("error_connection_description")
    
    error = {
      info: errorObj
      buttonText: getTranslation("dialog_button_exit")
    }

    showModalDialog(error)
End Function


Function showModalDialog(error)
  tubiLog("ErrorController.showModalDialog")
  rawErrorObj = error.info

  errorCode = getUserFacingErrorCode(rawErrorObj.contextCode, rawErrorObj.subtypeCode, rawErrorObj.externalCode)

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "NETWORK_ERROR" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {})  'a valid page type (see DialogEvent in events.protos)
      dialog_action: "SHOW"
      dialog_sub_type: errorCode
    }
  }

  modalInfo = {
    title: rawErrorObj.title
    message: getErrorMessage(rawErrorObj.message, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
    backButtonCallback: onCloseError
    modalId : m.constants.instantResumeActions.restartApp
  }

  buttonInfo = [
      {
        text: error.buttonText
        type: "accept"
        callback: onCloseError
        callbackParams: invalid
      }
    ]

  showModal(modalInfo, buttonInfo)
End Function


'''''''''''''''''''''''''
' onCloseError
'
' Close the error dialog
Function onCloseError()
  m.top.buttonSelected = true
End Function