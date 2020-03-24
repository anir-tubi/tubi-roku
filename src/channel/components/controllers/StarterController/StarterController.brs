Function init()
  m.constants = getConstants()
  m.hasExperiments = false
  m.hasRemoteConfigs = false
  m.experimentsTask = m.top.createChild("ExperimentsTask")
  m.experimentsTask.observeField("experimentsInfo", "onExperimentsInfoReturned")
  m.experimentsTask.observeField("externalConfigInfo", "onExternalConfigInfoReturned")
  m.experimentsTask.constants = m.constants
  m.experimentsTask.control = "RUN"

  m.top.observeField("getUrl", "onUrlRequest")
End Function


Function onUrlRequest()
  if m.top.getUrl = true and m.hasExperiments = true and m.hasRemoteConfigs = true
    'Handle any remote config updates here:
    'Let youbora be enabled by the remote config
    if m.constants.externalConfig.info.youbora_enabled = true
      m.constants.thirdParty.youbora.enabled = m.constants.externalConfig.info.youbora_enabled
    end if

    m.top.newBuildConstants = m.constants

    if m.constants.remoteComponents = false
      m.top.useRemoteComponents = m.constants.remoteComponents
    else
      remoteComponentsUrl = m.constants.settings.remoteComponentsUrl

      ' if an experiment or remote config needs to update the remoteComponentsUrl, do it here.
      ' (experiment tracking should not happen here. It should happen when the user encounters the experiment!)
      '-------------------------------------------------------------------------------------'
      ' experiment example: 
      ' request = TubiRequest(m.constants.settings.mode)
      ' experiments = TubiExperiments(m.constants)
      ' sideNav = m.experiments.getExperimentValue("RokuNamespace", "roku_side_nav")
      ' if sideNav = "on"
      '   remoteComponentsUrl = "someUrl"
      ' else
      '   remoteComponentsUrl = "someOtherUrl"
      ' end if
      ' 
      ' remote/external config example:
      ' remoteComponentsUrl = m.constants.externalConfig.sideNavRemoteComponentsUrl


      '-------------------------------------------------------------------------------------'
      print "remoteComponentsUrl "; remoteComponentsUrl
      m.top.remoteComponentsUrl = remoteComponentsUrl
    end if
  end if
End Function


Function onExperimentsInfoReturned(msg)
  m.constants.experiments.info = msg.getData()
  m.hasExperiments = true
  onUrlRequest()
End Function


Function onExternalConfigInfoReturned(msg)
  m.constants.externalConfig.info = msg.getData()
  m.hasRemoteConfigs = true
  onUrlRequest()
End Function