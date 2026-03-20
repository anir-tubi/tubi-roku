Function init()

  m.constants = m.global.constants

  generalTask = CreateObject("roSGNode", "BaseGeneralTask") ' initiate GeneralTask
  ' Initiate GeneralTaskModule by passing caller context.
  ' Calling GeneralTaskModule() will append methods to the local m.
  ' DO NOT overwrite m variable methods/properties which belongs to GeneralTaskModule.
  GeneralTaskModule(m, generalTask)

  m.top.observeFieldScoped("customSuspendUnitTest", "onCustomSuspendUnitTest")

End Function


' onCustomSuspendUnitTest will be triggered when unit tests are completed by github action
Function onCustomSuspendUnitTest(msg)
  tubiLog("UnitTestNotifier.onCustomSuspendUnitTest")
  customSuspendArgs = msg.getData()

  if customSuspendArgs.lastSuspendOrResumeReason = "home"
    sendNotificationToGithubRunner()
  end if
End Function


Function sendNotificationToGithubRunner()

  localHostUri = m.constants.settings.localHostUri
  urlPath = localHostUri + "/unit_tests_completed"
  m.makeRequest({
    url: urlPath
    requestType: m.constants.reqNames.generic
    options: {}
    silenceCallbackWarnings: true
    responseType: "string"
    analyticsScreenId: "unknown"
  })

End Function

