'@SGNode CategoryDetailsScreenTest
'@TestSuite [CategoryDetailsScreen] CategoryDetailsScreen.brs


'@Setup
Function categoryDetailsScreenSetup()
  channelContent = CreateObject("roSGNode", "TubiContentNode")
  channelContentData = {
    id: "channel_x"
    title: "Channel X"
    description: "Stuff brought to you by the letter X -Guy Smilie"
    totalCount: 3
    logoUri: "https://images.adrise.tv/GyNJ_d_bhkrzR2v8Ew-p3Ti0KJY=/1920x1080/smart/img.adrise.tv/0c690475-ea32-4b91-b704-7d3fab94a48f.jpg"
    slug: "channel_x"
  }
  channelContent.update(channelContentData)
  m.channelContent = channelContent

  itemContent = CreateObject("roSGNode", "TubiContentNode")
  itemContentData = {
    id: "100"
    title: "Gladiator"
    HDGRIDPOSTERURL: "https://images.adrise.tv/pImLSl2T7-w4l1CQdRp77XuFoj0=/210x300/smart/img.adrise.tv/ee632fb0-3cd3-40cb-a282-31faf1b1f7a6.jpg"
    description: "The general who became a slave. The slave who became a gladiator. The Gladiator who defied an empire."
    backgrounds: ["https://images.adrise.tv/GyNJ_d_bhkrzR2v8Ew-p3Ti0KJY=/1920x1080/smart/img.adrise.tv/0c690475-ea32-4b91-b704-7d3fab94a48f.jpg"]
    releaseDate: "2008"
    length: 155 * 60
    rating: "R"
    genres: ["Action", "Adventure", "Oscar"]
    hasSubtitles: true
    hasAudioDescription: true
    inlineLogoUri: "http://images.adrise.tv/LeN4r8F_Jru-2mE_pq3IkGjpHxg=/180x60/img.adrise.tv/57d9cd58-db8c-4d0a-95d4-b18f52877ac5.png"
  }
  itemContent.update(itemContentData)
  m.itemContent = itemContent
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests populating the InfoPanel on the ChannelScreen
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test populateInfoPanelItem unit test
Function categoryDetailsScreen_populateInfoPanelItem_test()
  content = m.itemContent
  controlInfoPanel = CreateObject("roSGNode", "InfoPanel")
  controlInfoPanel.title = content.title
  controlInfoPanel.description = content.description
  controlInfoPanel.mode = "item"
  controlInfoPanel.calculateHeight = true
  controlInfoPanel.sotMarkers = {}
  controlInfoPanel.sotMetaData = invalid
  controlInfoPanel.sotTopLabelSignals = []
  controlInfoPanel.lineOneData = {
    hasCC: content.hasSubtitles
    hasAudioDescription: content.hasAudioDescription
    length: content.length
    partnerLogoUri: content.inlineLogoUri
    rating: content.rating
    releaseDate: content.releaseDate
    availabilityEnds: content.availabilityEnds
  }
  controlInfoPanel.lineTwoData = {
    genres: content.genres
  }

  emptyInfoPanel = CreateObject("roSGNode", "InfoPanel")
  populatedInfoPanel = populateInfoPanel(emptyInfoPanel, content)

  ' can't test equality of nodes, so test if they have the same fields
  m.assertEqual(populatedInfoPanel.getFields(), controlInfoPanel.getFields())
End Function
