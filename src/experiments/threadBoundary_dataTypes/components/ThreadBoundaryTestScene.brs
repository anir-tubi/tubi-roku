Function init()
  print "Starting Experiment"
  m.contentTask = m.top.findNode("ContentTask")
  m.top.observeField("json", "onJsonReceived")
  m.top.observeField("AA", "onAAReceived")
  m.top.observeField("nodeTree", "onNodeTreeReceived")
  m.top.observeField("exit", "onExitReceived")

  m.contentTask.control = "RUN"
End Function

Function onJsonReceived()
  m.contentTask.jsonReceived = true
  json = m.top.json

  timer = CreateObject("roTimespan")
  categories = ParseJson(json)
  parseTime = timer.TotalMilliseconds()
  catCount = categories.count()
  contentCount = 0
  for each category in categories
    contentCount = contentCount + category.children.count()
  end for
  print "Time to parse JSON in RENDER thread with "; catCount; " categories and "; contentCount; " contents (ms): "; parseTime
End Function


Function onAAReceived()
  m.contentTask.AAReceived = true
  AA = m.top.AA
End Function


Function onNodeTreeReceived()
  m.contentTask.nodeTreesReceived = true
End Function