Function init()
  m.constants = getConstants()
  m.top.observeField("getUrl", "onUrlRequest")
End Function

Function onUrlRequest()
  m.constants.externalConfig.info = m.top.externalConfigValues
  m.constants.experiments.info = m.top.experimentValues

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
    ' request = TubiRequest()
    ' experiments = TubiExperiments(m.constants)
    ' sideNav = experiments.getExperimentValue("RokuNamespace", "roku_side_nav")
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
End Function