Function componentTest_CategoryGridList(screen, runTests)
  root = CreateObject("roSGNode", "CategoryContentNode")
  content = {
    children: [
      { id: "Category1", title: "Category1" }
      { id: "Category2", title: "Category2" }
      { id: "Category3", title: "Category3" }
      { id: "Category4", title: "Category4" }
    ]
  }
  root.update(content)

  data = {
    "content": root
  }
  constants = {}
  constants.deviceInfo = {}
  constants.deviceInfo.captionsMode = "off"
  constants.deviceInfo.limitedUi = false
  constants.deviceInfo.scaledUi = true
  constants.performance = {}
  constants.performance.categoryGridList = {}
  constants.performance.categoryGridList.initialBlockSize = 10
  constants.performance.categoryGridList.finalBlockSize = 10
  constants.performance.categoryGridList.categoryWindowSize = 10
  constants.performance.categoryGridList.eagerLoad = false
  constants.platform = "roku"
  constants.player = {}
  constants.player.creditsDuration = 0
  constants.reqNames = {}
  constants.reqNames.getCategory = "getCategory"
  constants.settings = {}
  constants.settings.allowAfterHours = false
  constants.settings.shortAppName = "test"
  constants.ui = {}
  constants.ui.colors = {}
  constants.ui.colors.focused = "0xffffff"
  constants.ui.contentTypes = {}
  constants.ui.categoryScreen = {}
  constants.ui.categoryIds = {}
  constants.ui.categoryIds.queue = "Queue"
  constants.ui.categoryIds.history = "History"
  constants.urls = {}
  constants.urls.matrix = {}
  constants.urls.matrix.container = ""

  globalNode = screen.getGlobalNode()
  globalNode.addField("constants", "assocarray", false)
  globalNode.constants = constants

  globalNode.addField("metadataFetchTask", "node", false)
  metadataFetchTask = CreateObject("roSGNode", "Node")
  metadataFetchTask.addField("batchRequest", "assocarray", false)
  globalNode.metadataFetchTask = metadataFetchTask 

  runTests("CategoryGridListTest", data)
End Function