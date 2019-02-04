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
  m.Dialog = m.top.createChild("ModalDialogScreen")
  m.Dialog.title = error.title
  m.Dialog.message = error.message
  m.Dialog.buttons = [error.buttonText]
  m.Dialog.observeField("buttonSelected", "onCloseError")
  m.Dialog.setFocus(true)

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
  m.Dialog.unobserveField("buttonSelected")
  m.top.buttonSelected = true
End Function