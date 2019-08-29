print "Hot Patch 2.10 {{profile}}"

'''''''''''''''''''''''''''''''
'settings.version must be updated manually in the hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "{{versionUnderscored}}"
' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "{{remoteComponentsLocation}}"


'''''''''''''''''''''''''''''''
' Log specific device output
' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }


'''''''''''''''''''''''''''''''
' Turn features on/off

'If this is a new submission release, set this to false. (this will ensure the remote components is not used.)
'If this is a remote release, set this to true.
m.global.utils.constants.remoteComponents = false

'Display upgrade modal
m.global.utils.constants.showUpgradeAlert = false

'Let youbora be enabled by the remote config and use the production account code
if m.global.utils.constants.externalConfig.info.youbora_enabled = true
  m.global.utils.constants.thirdParty.youbora.enabled = m.global.utils.constants.externalConfig.info.youbora_enabled
end if
m.global.utils.constants.thirdParty.youbora.config.accountCode = "tubitv" 'This is the only mandatory param




' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
' AFTER THIS LINE, CODE IN HOTPATCH CAN BE DELETED WHEN SUBMITTING NEW VERSION TO ROKU
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
