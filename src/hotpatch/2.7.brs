print "Hot Patch 2.7 {{profile}}"

'''''''''''''''''''''''''''''''
'settings.version must be updated manually in the hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "{{versionUnderscored}}"
' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "{{remoteComponentsLocation}}"


'''''''''''''''''''''''''''''''
' Turn features on/off

' Turn on the back exits sign-in for Roku approval
m.global.utils.constants.ui.signIn.backExitsSignIn = true


'''''''''''''''''''''''''''''''
' Log specific device output
' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }


'correct the client version sent to the active tracking event since "remote is the new default
m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
'correct the client version sent to the active tracking event in the unlikely case of using local components
if m.global.utils.constants.externalConfig.info.remote_components = 0
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("remote", "local")
end if


m.global.utils.constants.thirdParty.youbora = {}
  youboraEnabled = false   ' off by default
  if m.global.utils.constants.externalConfig.info.youbora_enabled = true
    m.global.utils.constants.thirdParty.youbora.enabled = m.global.utils.constants.externalConfig.info.youbora_enabled
  end if
  m.global.utils.constants.thirdParty.youbora.debug = false
  m.global.utils.constants.thirdParty.youbora.config = {}
    ' DEVELOPMENT
    ' m.global.utils.constants.thirdParty.youbora.config.accountCode = "tubitvdev" 'This is the only mandatory param
    ' PRODUCTION
    m.global.utils.constants.thirdParty.youbora.config.accountCode = "tubitv" 'This is the only mandatory param

    m.global.utils.constants.thirdParty.youbora.config.expectAds = true