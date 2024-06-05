function getHttp(_OT_config) as string
    ssl = _OT_config.ssl
    if ssl
        return "https"
    else
        return "http"
    end if
end function

function getBaseUrl(_OT_config) as string
    return _OT_config.acquisition.server
end function

function getUrl(name = "applicationdata") 
    _OT_config = getOTconfig()
    url = {
        applicationdata: getHttp(_OT_config) + "://" + getBaseUrl(_OT_config) + "/" + _OT_config.initialization.apiEp
        encode: _OT_config.encodeAPI
    }
    return url[name]
end function

function getOTconfig()
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["700"])
    ' jenkins will update the version in OTconfig file to automation the sdk version 
    return ParseJson(ReadAsciiFile("pkg:/components/OTPublishersSDK/OTconfig.json"))
end function