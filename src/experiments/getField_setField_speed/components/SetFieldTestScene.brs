Function init()
  di = CreateObject("roDeviceInfo")
  print "Starting Experiment on "; di.GetModel()
  m.timer = CreateObject("roTimespan")
  amts = [100, 500, 1000]
  for each amt in amts
    addFieldsTest(amt)
  end for

  for each amt in amts
    getFieldsTest(amt)
  end for
End Function

Function addFieldsTest(amt)
  addFields("dot", amt)
  addFields("set", amt)
  addFields("setAll", amt)
  addFields("update", amt)
  print ""
End Function

Function getFieldsTest(amt)
  getFields("dot", amt, m.contentNode)
  getFields("get", amt, m.contentNode)
  getFields("getAll", amt, m.contentNode)
  print ""
End Function

Function addFields(method, amt, doPrint=true)
  contentNode = CreateObject("roSGNode", "ContentNode")
  m.timer.mark()

  for i=1 to amt
    if method = "dot"
      contentNode.id = "cnode"
      contentNode.description = "This is the description of the content node."
      contentNode.title = "Content Node Title"
      contentNode.length = 123
      contentNode.url = "https://www.someFakeUrl.com/someFakeString.m3u8"
      contentNode.actors = ["person uno", "person dos", "person tres"]
      contentNode.categories = ["Drama", "Action", "Horror", "Comedy"]
      contentNode.closedCaptions = false
      contentNode.subtitleUrl = "https://www.someFakeUrl.com/someFakeString.tts"
      contentNode.starRating = 60
    else if method = "set"
      contentNode.setField("id", "cnode")
      contentNode.setField("description", "This is the description of the content node.")
      contentNode.setField("title", "Content Node Title")
      contentNode.setField("length", 123)
      contentNode.setField("url", "https://www.someFakeUrl.com/someFakeString.m3u8")
      contentNode.setField("actors", ["person uno", "person dos", "person tres"])
      contentNode.setField("categories", ["Drama", "Action", "Horror", "Comedy"])
      contentNode.setField("closedCaptions", false)
      contentNode.setField("subtitleUrl", "https://www.someFakeUrl.com/someFakeString.tts")
      contentNode.setField("starRating", 60)
    else if method = "setAll"
      aa = {
        id: "cnode"
        description: "This is the description of the content node."
        title: "Content Node Title"
        length: 123
        url: "https://www.someFakeUrl.com/someFakeString.m3u8"
        actors: ["person uno", "person dos", "person tres"]
        categories: ["Drama", "Action", "Horror", "Comedy"]
        closedCaptions: false
        subtitleUrl: "https://www.someFakeUrl.com/someFakeString.tts"
        starRating: 60      
      }
      contentNode.setFields(aa)
    else if method = "update"
      aa = {
        id: "cnode"
        description: "This is the description of the content node."
        title: "Content Node Title"
        length: 123
        url: "https://www.someFakeUrl.com/someFakeString.m3u8"
        actors: ["person uno", "person dos", "person tres"]
        categories: ["Drama", "Action", "Horror", "Comedy"]
        closedCaptions: false
        subtitleUrl: "https://www.someFakeUrl.com/someFakeString.tts"
        starRating: 60      
      }
      contentNode.update(aa)
    end if
  end for

  timeToAdd = m.timer.totalMilliseconds()

  if doPrint = true
    print "Using "; method; " method, it took"; timeToAdd; "ms to add 10 fields to"; amt; " content nodes for a total of"; 10*amt; " fields set."
  end if

  return contentNode
End Function


Function getFields(method, amt, contentNode)
  contentNode = addFields("set", 1, false)
  m.timer.mark()

  for i=0 to amt
    if method = "dot"
      id = contentNode.id
      description = contentNode.description
      title = contentNode.title
      length = contentNode.length
      url = contentNode.url
      actors = contentNode.actors
      categories = contentNode.categories
      closedCaptions = contentNode.closedCaptions
      subtitleUrl = contentNode.subtitleUrl
      starRating = contentNode.starRating
    else if method = "get"
      id = contentNode.getField("id")
      description = contentNode.getField("description")
      title = contentNode.getField("title")
      length = contentNode.getField("length")
      url = contentNode.getField("url")
      actors = contentNode.getField("actors")
      categories = contentNode.getField("categories")
      closedCaptions = contentNode.getField("closedCaptions")
      subtitleUrl = contentNode.getField("subtitleUrl")
      starRating = contentNode.getField("starRating")
    else if method = "getAll"
      aa = contentNode.getFields()
    end if
  end for

  timeToget = m.timer.totalMilliseconds()
  print "Using "; method; " method, it took"; timeToget; "ms to get 10 field values of a content node"; amt " times, for a total of" 10*amt; " fields gotten."  
End Function
