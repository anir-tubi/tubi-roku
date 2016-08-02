''''''''''''''''''''
' Simple main to launch the unit tests if mode is "test".
' Otherwise, exit immediately.
'
Function Main()
  settings = getSettings()

  if settings.mode = "test" then
    BrsTestMain()
    END
  endif

  ' Load scene graph
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)

  ' Set up the global settings.  SceneGraph will receive a clone object, not a reference.
  ' Sources used in both BRS & SG threads will use:
  '     m.global.settings
  '     m.global.manifest
  '     m.global.theme
  '
  m.global = {} ' important syntactically to keep the settings at m.global.settings, whether
                ' used from the main Brightscript thread or the SceneGraph thread
  m.global["constants"] = getConstants()
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.constants = m.global.constants

  'TODO(Chris): replace this empty scene with the real compoments later
  controller = screen.CreateScene("Scene")
  screen.show()

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return 0
    end if
  end while

end Function
