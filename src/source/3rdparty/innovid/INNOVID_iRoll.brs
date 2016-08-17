' example of usage
' iRoll = INNOVID_iRoll()
' iRoll.rockAndiRoll(adTag, [ trackingEvents ], [ listener ])

function INNOVID_iRoll(customRendererUri = invalid as Dynamic) as Object
    print " --- iRoll / Bootstrap # ctor(";customRendererUri;")"

    if customRendererUri = invalid then
        dt = CreateObject("roDateTime")
        cb = Stri(dt.AsSeconds()).Trim() + Mid(Stri(dt.GetMilliseconds() + 1000), 3)

        rendererUri = "http://video.innovid.com/common/roku/innovid-iroll-renderer.brs?cb=" + cb
    else
        rendererUri = customRendererUri
    end if

    return {
        _rendererUri         : rendererUri,
        _prepare             : INNOVID_iRoll_Prepare,
        _getRendererFactory  : INNOVID_iRoll_Renderer_Get_Factory,
        _getRendererSource   : INNOVID_iRoll_Renderer_Get_Source,

        rockAndiRoll : INNOVID_iRoll_Rock_And_iRoll,
        show : INNOVID_iRoll_Rock_And_iRoll
    }
end function

function INNOVID_iRoll_Rock_And_iRoll(adTag as String, trackingEvents = invalid as Dynamic, listener = invalid as Dynamic) as Boolean
    if adTag = invalid then
        print " --- iRoll / Bootstrap # play() - invalid ad tag"
        return false
    end if

    factory = m._getRendererFactory()

    if factory = invalid then
        print " --- iRoll / Bootstrap # play() - ad creation failed"
        return false
    end if

    if trackingEvents = invalid then
        trackingEvents = {}
    end if

    if listener = invalid then
        listener = {}
    end if

    iRoll = factory.create( adTag, trackingEvents, listener )

    ' check if config loaded and processed succesfully
    if iRoll = invalid or type(iRoll, 3) = "roBoolean" then
        return false
    end if

    ' show
    iRoll.show()

    return true
end function

function INNOVID_iRoll_Prepare() as Dynamic
    print " --- iRoll / Bootstrap # prepare() - start"

    factory     = invalid
    rendererSrc = m._getRendererSource()
    evalResult  = Eval( rendererSrc )

    if type(evalResult) = "roList" then
        print " --- iRoll / Bootstrap # prepare() - Error!"
        for each err in evalResult
            print " ---+ ";err
        end for
    else
        print " --- iRoll / Bootstrap # prepare() - ";evalResult
    end if

    print " --- iRoll / Bootstrap # prepare() - end"

    return factory
end function

function INNOVID_iRoll_Renderer_Get_Factory() as Dynamic
    storage = GetGlobalAA()
    factory = storage.Lookup("__iRoll_Factory__")

    if factory = invalid then
        factory = m._prepare()
        storage.AddReplace("__iRoll_Factory__", factory)
        print " --- iRoll / Bootstrap # getRendererFactory() - from uri: ";m._rendererUri
    else
        print " --- iRoll / Bootstrap # getRendererFactory() - cached"
    end if

    return factory
end function

function INNOVID_iRoll_Renderer_Get_Source() as String
    if Instr(1, m._rendererUri, "http://") = 1 or Instr(1, m._rendererUri, "https://") = 1 then
        loader = CreateObject("roUrlTransfer")
        loader.SetUrl( m._rendererUri )

        result = loader.GetToString()
    else
        result = ReadAsciiFile( m._rendererUri )
    end if

    return result
end function
