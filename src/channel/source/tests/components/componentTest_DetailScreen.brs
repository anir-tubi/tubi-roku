Function componentTest_DetailScreen_AddQueue_History_Channel(screen, runTests)
  data = {
    mode: "item"
    title: "Gladiator"
    releaseDate: "2008"
    length: 155 * 60
    hasCC: true
    rating: "R"
    genres: ["Action", "Adventure", "Oscar"]
    description: "The general who became a slave. The slave who became a gladiator. The Gladiator who defied an empire."
    directors: ["Ridley Scott"]
    starring: ["Russell Crowe", "Joaquin Phoenix", "Connie Nielsen"]
    calculateInfoHeight: true

    isSeries: false
    isBookmark: true
    isHistory: true
    isChannelItem: true
    resumePoint: 456
    hasTrailer: false
    trackingUri: ""
    jumpToItem: 4
    channelTitle: "A&E"
  }

  constants = {}
  constants.deviceInfo = {}
  constants.deviceInfo.limitedUi = false
  constants.ui = {}
  constants.ui.colors = {}
  constants.ui.colors.transparent = "0x00000000"

  globalNode = screen.getGlobalNode()
  globalNode.addField("constants", "assocarray", false)
  globalNode.constants = constants
  
  runTests("DetailScreen", data)
End Function