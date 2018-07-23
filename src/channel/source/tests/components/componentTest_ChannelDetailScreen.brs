Function componentTest_ChannelDetailScreen(screen, runTests)
  root = CreateObject("roSGNode", "CategoryContentNode")  
  content = {
    children: [
      {
        id: "channel_x"
        title: "Channel X"
        description: "Stuff brought to you by the letter X -Guy Smilie"
        totalCount: 3
        logoUri: "https://images.adrise.tv/GyNJ_d_bhkrzR2v8Ew-p3Ti0KJY=/1920x1080/smart/img.adrise.tv/0c690475-ea32-4b91-b704-7d3fab94a48f.jpg"
        children: [
          {
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
            inlineLogoUri: "http://images.adrise.tv/LeN4r8F_Jru-2mE_pq3IkGjpHxg=/180x60/img.adrise.tv/57d9cd58-db8c-4d0a-95d4-b18f52877ac5.png"
            subtype: "TubiContentNode"
          }
          {
            id: "101"
            title: "The Good, the Bad and the Ugly"
            HDGRIDPOSTERURL: "https://images.adrise.tv/_avfh3oDxSLPt8YwOw2YoEepaIs=/0x20:799x1162/210x300/smart/img.adrise.tv/a109df97-0fcc-47ad-af5b-4144ef1024e4.jpg"
            description: "Clint Eastwood portrays the invincible 'Man With No Name' in a lethal pursuit of $200,000 in Confederate money.  Lee Van Cleef and Eli Wallach also star in this renowned western."
            backgrounds: ["https://images.adrise.tv/WPioOyHOardHxjusP_1QHE1BVwk=/1920x1080/smart/img.adrise.tv/1067f9da-d57d-472f-9bd0-4c8ace609e0c.jpg"]
            releaseDate: "1969"
            length: 179 * 60
            genres: ["Western"]
            rating: "R"
            hasSubtitles: false
            inlineLogoUri: "http://images.adrise.tv/LeN4r8F_Jru-2mE_pq3IkGjpHxg=/180x60/img.adrise.tv/57d9cd58-db8c-4d0a-95d4-b18f52877ac5.png"
            subtype: "TubiContentNode"
          }
          {
            id: "102"
            title: "The Terminator"
            HDGRIDPOSTERURL: "https://images.adrise.tv/jwypnJcra9lblXT8p_rXTLSA6Bg=/210x300/smart/img.adrise.tv/095979f2-712a-4347-9743-d56fd0407a05.png"
            description: "A humanoid cyborg assassin is sent back in time to kill the woman whose unborn son will become humankind's last hope against the machines."
            backgrounds: ["https://images.adrise.tv/BxIsPp6GlZ0vByxGcJF-NbtqmDA=/1920x1080/smart/img.adrise.tv/3931fda7-5572-4cd8-af35-fd500efdaf26.png"]
            releaseDate: "1981"
            length: 107 * 60
            genres: ["Sci Fi", "Action"]
            hasSubtitles: true
            inlineLogoUri: "http://images.adrise.tv/LeN4r8F_Jru-2mE_pq3IkGjpHxg=/180x60/img.adrise.tv/57d9cd58-db8c-4d0a-95d4-b18f52877ac5.png"
            subtype: "TubiContentNode"
          }
        ]
      }
    ]
  }
  root.update(content)

  data = {
    "content": root

  }
  constants = {}
  constants.deviceInfo = {}
  constants.deviceInfo.limitedUi = false
  constants.deviceInfo.scaledUi = true
  constants.ui = {}
  constants.ui.colors = {}
  constants.ui.colors.focused = "0xffffff"
  constants.ui.uris = {}
  constants.ui.uris.defaultBackground = "pkg:/images/art-blur-background.png"

  globalNode = screen.getGlobalNode()
  globalNode.addField("constants", "assocarray", false)
  globalNode.constants = constants

  globalNode.addField("trackingLoggingTask", "node", false)
  trackingLoggingTask = CreateObject("roSGNode", "Node")
  trackingLoggingTask.addField("trackEvent", "assocarray", false)
  globalNode.trackingLoggingTask = trackingLoggingTask 


  runTests("ChannelDetailScreen", data)
End Function