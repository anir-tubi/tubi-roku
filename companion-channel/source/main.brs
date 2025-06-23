Function Main()
  screen = createObject("roSGScreen")
  m.port = createObject("roMessagePort")
  screen.setMessagePort(m.port)
  m.scene = screen.createScene("AppScene")
  screen.show()

  ' Used to add required node creation needed for RDB component during vscode build
  ' vscode_rdb_on_device_component_entry

  while true
    wait(0, m.port)
  end while
End Function
