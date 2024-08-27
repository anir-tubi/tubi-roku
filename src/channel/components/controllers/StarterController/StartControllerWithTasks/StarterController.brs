' This file includes any logic not shared between the two versions of StarterController

Function setupFullStarterController()
  m.request = TubiRequest(m.constants.settings)

  m.getAuthOperationInProgress = false ' Used to know if we are already getting auth and want to avoid running multiple requests at the same time

  m.isExperimentsConfigReady = false
  m.isExternalConfigReady = false

  starterTask = createObject("roSGNode", "StarterGeneralTask") ' initiate StarterTask
  observeUpdateAuth(starterTask)
  GeneralTaskModule(m, starterTask)

  m.tubiAuthUpdate = TubiAuthUpdate(m.constants)

  retrieveInitialAuthInfo()
End Function


Function sendExposureEvent(namespaceName as string, experimentName as string, experimentsLib)
  exposureInfo = experimentsLib.getExperimentTracking(namespaceName, experimentName)

  if exposureInfo <> invalid
    Auth = TubiAuth(m.constants)
    trackingLib = TubiTracking(m.constants, Auth)
    exposureEvent = trackingLib.getClientEvent(exposureInfo.type, exposureInfo.values)
    reqInfo = trackingLib.createUserTrackingReqInfo(exposureEvent)
    m.makeRequest({
      url: reqInfo.url
      options: reqInfo.options
      requestType: m.constants.reqNames.postAnalytics
      silenceCallbackWarnings: true
    })
  end if
End Function


' Called in StarterController's runControllerStartSequence. Used to specify what remote components URL to use
Function getRemoteComponentsUrl()
  ' if an experiment or remote config needs to update the remoteComponentsUrl, do it here.
      ' (experiment tracking should not happen here. It should happen when the user encounters the experiment!)
      '-------------------------------------------------------------------------------------'
      ' EXPERIMENT EXAMPLE
      ' experiments = TubiExperiments(experimentsInfo)
      ' sideNavEnabled = m.experiments.getExperimentResource("RokuNamespace", "roku_side_nav").enabled
      ' if sideNavEnabled = true
      '   remoteComponentsUrl = "someUrl"
      ' else
      '   remoteComponentsUrl = "someOtherUrl"
      ' end if
      '
      ' sendExposureEvent("RokuNamespace", "roku_side_nav", experiments)
      '
      ' REMOTE/EXTERNAL CONFIG EXAMPLE:
      ' remoteComponentsUrl = m.global.externalConfig.sideNavRemoteComponentsUrl
      '-------------------------------------------------------------------------------------'
      remoteComponentsUrl = m.constants.settings.remoteComponentsUrl

      if m.constants.settings.useFullStarterController <> true then
        experimentsInfo = getExperimentsInfoFromGlobal()
        experiments = TubiExperiments(experimentsInfo)
        if experiments <> invalid then
          if m.constants.settings.mode <> "dev"
            if experiments.getExperimentResource("roku_new_cdn", "roku_new_cdn_v1").enabled = true
              remoteComponentsUrl = m.constants.settings.rcdnRemoteComponentsUrl
            end if
          end if
        end if
      end if
      '-------------------------------------------------------------------------------------'
      '-------------------------------------------------------------------------------------'
      return remoteComponentsUrl
End Function


' Provides a list of nodes that should be notified when the authInfo is updated. Called in onUpdatedAuthRetrieved()
Function getAuthUpdatedNodesList()
  nodes = []
  nodes.push(m.generalTask)
  return nodes
End Function
