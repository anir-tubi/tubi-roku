Function init()
' THIS TASK IS TIGHTLY COUPLED TO THE MATRIX API AS OF 2/22/18
'
' UPDATES TO THE fetchloop(), sendAA(), and buildNodes() 
' FUNCTIONS WILL BE NECESSARY IF THE API CHANGES OR A DIFFERENT API IS TO BE EXPERIMENTED ON
  m.top.functionName = "fetchLoop"
End Function

Function fetchLoop()
  print "Beginning fetch loop"

  m.contentCount = 100
  msgPort = createObject("roMessagePort")
  m.jsonTimer = createObject("roTimespan")
  m.AATimer = createObject("roTimespan")
  m.nodeTimer = createObject("roTimespan")
  m.top.observeField("content", msgPort)
  m.top.observeField("jsonReceived", msgPort)
  m.top.observeField("AAReceived", msgPort)
  m.top.observeField("nodeTreesReceived", msgPort)
  
  url = "https://uapi.adrise.tv/matrix/homescreen?"
  urlParameters = {
    app_id: "tubitv"
    platform: "roku"
    limit: m.contentCount
    expand: 1
  }
  for each param in urlParameters
    url = url + param + "=" + urlParameters[param].toStr() + "&"
  end for
  url = url.left(url.len()-1) 'remove the last "&" or "?" '
  print url

  request = createObject("roUrlTransfer")
  request.setMessagePort(msgPort)
  if Left(UCase(url), 5) = "HTTPS" then request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.setUrl(url)
  requestId = request.asyncGetToString()

  while true
    msg = wait(0, msgPort)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 400
        print "received a valid response"
        response = msg.getString()
        m.top.content = response
      else
        print "Request Failed: exiting experiment"
        print msg.getResponseCode()
        print msg.getData
        m.top.exit = true
      end if
    else if type(msg) = "roSGNodeEvent"
      print "field "; msg.getField(); " was updated"
      if msg.getField() = "content"
        startExperiment()
      else if msg.getField() = "jsonReceived"
        onJsonReceived()
      else if msg.getField() = "AAReceived"
        onAAReceived()
      else if msg.getField() = "nodeTreesReceived"
        onNodeTreesReceived()
      end if
    end if
  end while
End Function


Function startExperiment()
  m.jsonTimer.mark()
  response = ParseJSON(m.top.content)
  categories = buildCategories(response)
  json = FormatJson(categories)
  m.top.json = json
End Function


Function onJsonReceived()
  jsonTime = m.jsonTimer.TotalMilliseconds()
  print "Time to send json across boundary (ms): "; jsonTime
  m.jsonTimer = invalid
  sendAA()
End Function


Function sendAA()
  m.AATimer.mark()
  response = ParseJSON(m.top.content)
  parseTime = m.AATimer.TotalMilliseconds()
  catCount = response.containers.count()
  contentCount = response.contents.count()
  print "Time to parse JSON in TASK thread with "; catCount; " categories and "; contentCount; " contents (ms): "; parseTime

  categories = buildCategories(response)
  m.AATimer.mark()
  m.top.aa = categories
End Function


Function onAAReceived()
  AATime = m.AATimer.TotalMilliseconds()
  print "Time to send AA across boundary (ms): "; AATime
  m.AATimer = invalid
  sendNodes()
End Function


Function sendNodes()
  AA = ParseJSON(m.top.content)
  nodes = buildNodes(AA, "TASK")

  contentCount = 0
  for i=0 to nodes.getChildCount()-1
    contentCount = contentCount + nodes.getChild(i).getChildCount()
  end for
  print "Node Tree to be sent--------------------------"
  print "Category Nodes: "; nodes.getChildCount()
  print "Content Nodes: "; contentCount
  m.nodeTimer.mark()
  m.top.nodeTree = nodes
End Function


Function onNodeTreesReceived()
  nodeTime = m.nodeTimer.TotalMilliseconds()
  print "Time to send node tree across boundary (ms): "; nodeTime
  m.nodeTimer = invalid
  m.top.exit = true
End Function
