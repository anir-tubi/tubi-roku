Function componentTest_SettingsScreen(screen, runTests)
  data = {
    signedIn: true
    name: "Full Name"
    email: "full@name.com"
    parentalSetting: 0
  }
  events = [
    "backgroundUriList"
    "trackingUri"
    "trackingCount"
    "signOutSelected"
    "signInSelected"
    "parentalSettingSelected"
  ]
  globalNode = screen.getGlobalNode()
  globalNode.addField("constants", "assocarray", false)
  globalNode.constants = getConstants()
  return runTests("SettingsScreen", data, events)
End Function