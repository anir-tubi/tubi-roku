Function init()
  addGlobalFields()

  initializeGlobalFields()

  unitTestNotifier = m.top.createChild("UnitTestNotifier")
  unitTestNotifier.id = "UnitTestNotifier"
  m.top.allowBackgroundTask = true

End Function


Function addGlobalFields()
  m.global.addField("constants", "assocarray", false)
  m.global.addField("theme", "assocarray", false)
  m.global.addField("externalConfigInfo", "assocarray", false)
  m.global.addField("experimentsInfo", "assocarray", false)
  m.global.addField("translationAA", "assocarray", false)
End Function


Function initializeGlobalFields()
  constants = getConstants()
  m.global.constants = constants
  m.global.theme = constants.ui.themes.default
  m.global.externalConfigInfo = {}
  m.global.experimentsInfo = {}
  m.global.translationAA = {}
End Function


' customSuspend is the callback for suspendhandler customization tag,
' will be triggered when home key button is pressed (home key is pressed when unit tests are completed)
Function customSuspend(args)

  unitTestNotifier = m.top.findNode("UnitTestNotifier")
  if unitTestNotifier <> invalid
    unitTestNotifier.customSuspendUnitTest = args
  end if

End Function
