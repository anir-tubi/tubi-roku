'Add Library for Roku Ad Framework
Library "Roku_Ads.brs"


'The Main function serves to run any remote config and experiment API calls and then choose the appropriate UI
Function Main(startupArgs as Dynamic)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)

  if constants.deviceInfo.newUi = true
    'run remote config for devices in the newUI - anything not in the oldUI models list
    externalConfig = TubiExternalConfig(request, constants)
    externalConfig.init() 'sets external config values on constants
  end if

  'check external config values to see if limitedNewUi (ie. Roku TVs - 5000X) get the new ui or old ui
  if constants.deviceInfo.limitedNewUi = true
    'default the models that require limited versions of the new ui to receive the old ui
    constants.deviceInfo.newUi = false
    if constants.deviceInfo.model = "3500X"
      if constants.externalConfig.info["limited_newui_3500_enabled"] = 1 then
        constants.deviceInfo.newUi = true
      end if
    else if constants.externalConfig.info.limited_newui_enabled = 1
      constants.deviceInfo.newUi = true
    end if
  end if

  if constants.deviceInfo.newUi = true
    MainNewUI(startupArgs, constants)
  else
    MainOldUI(startupArgs)
  end if

End Function






Sub MainOldUI(params as Dynamic)
  placeholderCanvas = CreateObject( "roImageCanvas" )
  placeholderCanvas.SetMessagePort(CreateObject("roMessagePort"))
  placeholderCanvas.Show()

  app = AdriseApp(params)
  m.app = app

  ' This will only run for the test mode
  if app.settings.mode = "test"
    print "Starting all the tests..."
    BrsTestMain()
    return
  end if

  ' apply hotpatch to main brightscript thread
  ' this also verifies startup network connectivity
  if Hotpatch(app.settings.hotPatchUrlOldUI) <> 0 then
    showErrorDialog()
    return ' exit the app on error.  scene graph exits anyway once
              ' we destroy a Scene and try to create it again.
  end if

  app.runApp()
  placeholderCanvas.close()

end Sub



''''''''''''''''''''
' Simple main to launch the unit tests if mode is "test".
' Otherwise, exit immediately.
'
Function MainNewUI(args As Dynamic, constants As Object)

  settings = getSettings()

  if settings.mode = "test" then
    BrsTestMain()
    END
  endif


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
  auth = TubiAuth(constants, request)
  translate = TubiMetadataTranslate(constants)
  metadataFetch = TubiMetadataFetch(constants, request, translate)
  tracking = TubiTracking(constants, request, auth)
  bookmarks = TubiBookmarks(request, auth, constants)
  log = TubiLogger(constants, request, auth)


  'set up all experiments
  experiments = TubiExperiments(request, constants)
  experiments.init() 'sets experiment values on constants
  
  m.global.utils = {
    constants: constants
    request: request
    requestQueue: requestQueue
    tracking: tracking
    auth: auth
    bookmarks: bookmarks
    experiments: experiments
    metadataFetch: metadataFetch
    log: log
  }

  m.global.channel = TubiChannel(m.global.utils)

  port = CreateObject("roMessagePort")

  ' also populates m.global.sgAdShim.ads
  m.global.adShim = TubiSGAdShim(m.global.utils, port)

  ' apply hotpatch to main brightscript thread
  ' this also verifies startup network connectivity
  if Hotpatch(settings.hotPatchUrl) <> 0 then
    showErrorDialog()
    return -1 ' exit the app on error.  scene graph exits anyway once
              ' we destroy a Scene and try to create it again.
  end if

  m.global.channel.runChannel(args, m.global.adShim, port)
end Function



''''''''''''''
' Hotpatch
'
' Download .brs code from a hotpatch URL and execute it 
'
' return codes:
'  0 patch applied, or no patch available
' -1 network error downloading patch file (not 404)
'
Function Hotpatch(hotPatchUrl) As Integer
  if len(hotPatchUrl) > 5
    port = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetMessagePort(port)
    transfer.setUrl(hotPatchUrl)
    if Left(UCase(hotPatchUrl), 5) = "HTTPS"
      transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    end if
    transfer.AsyncGetToString()
    msg = wait(10000, transfer.GetMessagePort())

    hotpatchResult = 0
    if type(msg) = "roUrlEvent"
      if msg.GetResponseCode() = 200 'all good, server responded back with a hotpatch file
        evalString = msg.GetString()

        ' Eval the downloaded script
        if len(evalString) > 10
          errCode = eval(evalString)
          if Type(errCode) = "Integer"
            if errCode=252
              print "(hp len: " + str(len(evalString)) + ")"
            else
              print "evalError "; errCode
              hotpatchResult = -1
            end if
          else if type(errCode) = "roList"
            print "evalError "
            for each error in errCode
              print error
            end for
            hotpatchResult = -1
          end if
        end if

      else if msg.GetResponseCode() > 0 'server responded with 403 error or similar - couldn't find the file but server up
        print "No file at hotpatch location"
        hotpatchResult = -1
      
      else
        ' some network failure
        print "Network error downloading hotpatch file"
        print msg.getFailureReason()
        hotpatchResult = -1
      end if
    else if msg = invalid
      'no response back from hotpatch server - either server completely down or more likely user's internet is not connected
      print "Timeout downloading hotpatch file"
      hotpatchResult = -1
    end if
  end if

  return hotpatchResult
End Function


Function showErrorDialog()
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)


  ' make sure there are constants on the global utils (ie. we are using the old UI),
  ' as they are needed for the error message
  if m.global <> invalid
    if m.global.utils <> invalid
      if m.global.utils.constants = invalid
        m.global.utils.constants = getConstants()
      end if
    else
      m.global.utils = {
        constants: getConstants()
      }
    end if
  else
    m.global = {
      utils: {
        constants: getConstants()
      }
    }
  end if


  sgGlobal.constants = m.global.utils.constants
  controller = screen.CreateScene("ErrorController")
  screen.show()
  controller.observeField("buttonSelected", port)
  controller.error = {
    title: "Network Error"
    message: "Please check your network connection and try again"
    buttonText: "Exit"
  }

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    if msgType <> invalid then exit while
  end while

  screen.close()

End Function

