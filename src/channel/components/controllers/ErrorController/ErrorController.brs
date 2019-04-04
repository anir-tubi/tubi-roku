Function init()
  m.constants = m.global.constants
  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.trackingLoggingTask.control = "RUN"
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.top.observeField("error","showModalDialog")
End Function

Function showModalDialog()
  tubiLog("ErrorController.showModalDialog")
  error = m.top.error
  rawErrorObj = error.info

  errorObj = createErrorObject(rawErrorObj.contextCode, rawErrorObj.subtypeCode, rawErrorObj.message, rawErrorObj.externalCode, rawErrorObj.title)
  showErrorModal(errorObj, invalid, [], onCloseError, [], [error.buttonText])

  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "WARNING" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("", {})  'a valid page type (see DialogEvent in events.protos)
    }
  }
End Function

'''''''''''''''''''''''''
' onCloseError
'
' Close the error dialog
Function onCloseError()
  m.top.removeChild(m.Dialog)
  m.top.buttonSelected = true
End Function