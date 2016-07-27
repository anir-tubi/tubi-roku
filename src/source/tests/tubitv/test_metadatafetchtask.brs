' Test 2 simultaneous requests happening in the metadata fetch task thread
Function testSGMetadataFetchTask(t As Object)
  screen = CreateObject("roSGScreen")
  scene = screen.CreateScene("Scene")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  screen.Show()

  ' add a place to catch the response
  scene.addField("content1", "string", true)
  scene.addField("content2", "string", true)
  scene.observeField("content1", port)
  scene.observeField("content2", port)
  task = scene.createChild("MetadataFetchTask")
  task.control = "RUN" 

  ' give the task thread time to start and observe
  sleep(500)

  server = createMetadataFetchTaskServer(65535)
  server.SetMessagePort(port)

  ' this will launch the requests
  task.request = {
    node: scene
    field: "content1"
    url: "http://127.0.0.1:65535/"
    options: {}
    name: ""
  }

  task.request = {
    node: scene
    field: "content2"
    url: "http://127.0.0.1:65535/"
    options: {}
    name: ""
  }

  responses = 0
  while true
    msg = wait(5000, port)
    if type(msg) = "roSocketEvent" then
      connection = server.accept()
      buffer = connection.receiveStr(1024)
      json = FormatJSON({
        name: "content"
        value: "12345"
      })

      response =            "HTTP/1.1 200 OK" + Chr(13) + Chr(10)
      response = response + "Content-length: " + stri(json.len()) + Chr(13) + Chr(10)
      response = response + "Connection: close" + Chr(13) + Chr(10)
      response = response + Chr(13) + Chr(10)
      response = response + json + Chr(13) + Chr(10)
      response = response + Chr(13) + Chr(10)
      connection.sendstr(response)
      connection.close()
    else if type(msg) = "roSGNodeEvent" then
      responses = responses + 1
      if responses = 2 then exit while
    else if msg = invalid then
      exit while
    end if
  end while

  task.control = "STOP" 
  screen.close()
  server.close()
  if responses < 2 then t.fail()
End Function


Function createMetadataFetchTaskServer(tcpPort As Integer)
  server = CreateObject("roStreamSocket")
  address = CreateObject("roSocketAddress")
  address.setPort(tcpPort)
  server.setAddress(address)
  server.notifyReadable(true)
  server.listen(4)
  return server
End Function
