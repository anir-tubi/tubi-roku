'Add Library for Roku Ad Framework
Library "Roku_Ads.brs"

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
  
  request = TubiRequest()
  requestQueue = TubiRequestQueue()
  tracking = TubiTracking(request)

  m.global.utils = {
    constants: getConstants()
    tracking: tracking
    request: request
    requestQueue: requestQueue
    ' auth: TubiAuth()
    ' log: TubiLog()
  }

  m.global.player = TubiPlayer(m.global.utils)

  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.constants = m.global.utils.constants

  controller = screen.CreateScene("ContentController")
  screen.show()

  ' THIS ONLY WORKS ON 7.1+ firmware!
  controller.observeField("playContent", port)

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return 0
    
    else if msgType = "roSGNodeEvent"
      node = msg.getNode()
      field = msg.getField()
      data = msg.getData()
      
      if field = "playContent"
        playerContent = data.getFields()
        playerContent.stream = {url: playerContent.url}
        playerResult = m.global.player.playVideo(playerContent)

        if playerResult = m.global.utils.constants.player.playerResult.completed
          'TODO: BRYAN, Update a field (TBD) to tell the scene graph that the video has completed
          '             So that the scene graph can advance the episode or category grids
        end if

        'TODO: BRYAN, Update the content node with new nowPos/playStart values so the scene graph can update the resume views
      end if 
    end if

  end while

end Function
