print "Hot Patch 2.8 {{profile}}"

'''''''''''''''''''''''''''''''
'settings.version must be updated manually in the hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "{{versionUnderscored}}"
' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "{{remoteComponentsLocation}}"


'''''''''''''''''''''''''''''''
' Turn features on/off



'''''''''''''''''''''''''''''''
' Log specific device output
' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }


'Let youbora be enabled by the remote config and use the production account code
if m.global.utils.constants.externalConfig.info.youbora_enabled = true
  m.global.utils.constants.thirdParty.youbora.enabled = m.global.utils.constants.externalConfig.info.youbora_enabled
end if
m.global.utils.constants.thirdParty.youbora.config.accountCode = "tubitv" 'This is the only mandatory param
