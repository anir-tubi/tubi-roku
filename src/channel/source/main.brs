'The Main function serves to run any remote config and experiment API calls and then choose the appropriate UI
Function Main(startupArgs as Dynamic)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)

  'run remote config
  externalConfig = TubiExternalConfig(request, constants)
  externalConfig.init() 'sets external config values on constants

  settings = getSettings()

  if startupArgs.ComponentTest <> invalid and startupArgs.ComponentTest <> ""
    ' This will block indefinitely
    ComponentTest(startupArgs.ComponentTest)
  end if

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
  nodeHelpers = TubiNodeHelpers()
  bookmarks = TubiBookmarks(request, auth, constants, nodeHelpers)
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
    nodeHelpers: nodeHelpers
    experiments: experiments
    metadataFetch: metadataFetch
    log: log
  }

  m.global.channel = TubiChannel(m.global.utils)

  ' apply hotpatch to main brightscript thread
  ' this also verifies startup network connectivity
  if Hotpatch(settings.hotPatchUrl) <> 0 then
    showErrorDialog()
    return -1 ' exit the app on error.  scene graph exits anyway once
              ' we destroy a Scene and try to create it again.
  end if

  m.global.channel.runChannel(startupArgs)
End Function



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


  ' make sure there are constants on the global utils
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
