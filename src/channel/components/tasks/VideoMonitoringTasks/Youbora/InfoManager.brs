function InfoManager(plugin, options = Invalid)
	YouboraLog("Created InfoManager")
    this = CreateObject("roAssociativeArray")

    'Methods
    this.getRequestParams = InfoManager_getRequestParams

    this.getResource = function()
        resource = m.options["content.resource"]

        if resource = invalid
            resource = m.plugin.getResource()
        endif

        if resource = invalid
            resource = "Unknown"
        endif

        return resource
    end function

    this.getPlayhead = function()
        playhead = m.plugin.getPlayhead()

        if playhead = invalid
            playhead = 0.0
        endif

        return playhead
    end function

    this.getMediaDuration = function()
        duration = m.options["content.duration"]

        if duration = invalid
            duration = m.plugin.getMediaDuration()
        endif

        if duration = invalid
            duration = 0
        endif

        return duration
    end function

    this.getTitle = function()
        title = m.options["content.title"]

        if title = invalid
            title = m.plugin.getTitle()
        endif

        return title
    end function

    this.getIsLive = function()
        islive = m.options["content.isLive"]

        if islive = invalid
            islive = m.plugin.getIsLive()
        endif

        if islive = invalid
            islive = false
        endif

        return islive
    end function

    this.getRendition = function()
        rendition = m.options["content.rendition"]

        if rendition = invalid
            rendition = m.plugin.getRendition()
        endif

        return rendition
    end function

    this.getBitrate = function()
        bitrate = m.plugin.getBitrate()

        if bitrate = invalid
            bitrate = -1.0
        endif

        return bitrate
    end function

    this.getThroughput = function()
        throughput = m.plugin.getThroughput()

        if throughput = invalid
            throughput = -1.0
        endif

        return throughput
    end function

    this.getDeviceModel = function ()
        return CreateObject("roDeviceInfo").GetModel()
    end function

    this.getDeviceIdFromHardware = function ()
        hardwareModel = CreateObject("roDeviceInfo").GetModel()

        'Mapping
        models = {
            'Roku LT
            "2400X" : "39",
            "2450X" : "39",
            "2700X" : "39",
            'Roku 1
            "2710X" : "74",
            'Roku 2
            "2720X" : "75",
            "3000X" : "75",
            "3050X" : "75",
            "3100X" : "75",
            "4210X" : "75",
            'Roku Stick
            "3600X" : "41",
            "3800X" : "41",
            "3810X" : "41",
            "3400X" : "41",
            "3420X" : "41",
            "3500X" : "41",
            'Roku 3
            "4200X" : "40",
            "4230X" : "40",
            'Roku 4
            "4400X" : "45",
            'Roku TV
            "5000X" : "76",
            "6000X" : "76",
            "7000X" : "76",
            "8000X" : "76",
            'Roku Express
            "3700X" : "77",
            "3710X" : "77",
            "3900X" : "77",
            "3910X" : "77",
            'Roku Premiere
            "4620X" : "78",
            "4630X" : "78",
            'Roku Ultra
            "4640X" : "79",
            "4660X" : "79",
            'Roku SD
            "N1050" : "72",
            'Roku HD Classic (Roku HD)
            "N1000" : "38",
            "N1100" : "38",
            'Roku XD
            "2050X" : "73",
            "2050N" : "73",
            "N1101" : "73",
            "2100X" : "73",
            "2100N" : "73",
            'Roku HD
            "2000C" : "38",
            "2500X" : "38"
        }

        if models.DoesExist(hardwareModel)
            return models[hardwareModel]
        else
            return Invalid
        endif

    end function

    this.getAdPosition = function()
        position = m.plugin.getAdPosition()

        if position = invalid
            position = "unknown"
        end if
        return position
    end function

    this.getAdPlayhead = function()
        adPlayhead = m.plugin.getAdPlayhead()
        if adPlayhead = invalid
            adPlayhead = 0
        end if
        return adPlayhead
    end function

    this.getAdNumber = function()
        number = m.plugin.getAdNumber()

        if number = invalid
            number = 1
        end if
        return number
    end function

    this.getAdDuration = function()
        duration = m.plugin.getAdDuration()

        if duration = invalid
            duration = 0
        end if
        return duration
    end function

    'Fields
    this.plugin = plugin

    if options = Invalid
        this.options = {}
    else
        this.options = options
    endif

    return this



end Function

function InfoManager_getRequestParams(requestName = "" as String, params = Invalid)

    if params = Invalid
        outParams = {}
    else
        outParams = params
    end if

    if requestName = "data"
        if outParams.DoesExist("system") = false then outParams["system"] = m.options["accountCode"]
        if outParams.DoesExist("pluginName") = false then outParams["pluginName"] = m.plugin.getPluginName()
        if outParams.DoesExist("pluginVersion") = false then outParams["pluginVersion"] = m.plugin.getPluginVersion()
        if outParams.DoesExist("username") = false then outParams["username"] = m.options["username"]
    else if requestName = "start" or requestName = "error"
        'Start and Error share most of the params, but error also has error code and error message
        ' Params
        if outParams.DoesExist("system") = false then outParams["system"] = m.options["accountCode"]
        if outParams.DoesExist("player") = false then outParams["player"] = m.plugin.getPluginName()
        if outParams.DoesExist("username") = false then outParams["username"] = m.options["username"]
        if outParams.DoesExist("anonymousUser") = false then outParams["anonymousUser"] = m.options["anonymousUser"]
        if outParams.DoesExist("transactionCode") = false then outParams["transactionCode"] = m.options["content.transactionCode"]
        if outParams.DoesExist("deviceId") = false then outParams["deviceId"] = m.options["device.code"]
        'If no forced deviceId, get it from the device itself
        if outParams["deviceId"] = Invalid
            outParams["deviceId"] = m.getDeviceIdFromHardware()
        endif
        if outParams.DoesExist("deviceInfo") = false then outParams["deviceInfo"] = {"model":m.getDeviceModel()}
        'Plugin versioning
        if outParams.DoesExist("pluginVersion") = false then outParams["pluginVersion"] = m.plugin.getPluginVersion()
        if outParams.DoesExist("playerVersion") = false then outParams["playerVersion"] = m.plugin.getPlayerVersion()
        'Media
        if outParams.DoesExist("mediaResource") = false then outParams["mediaResource"] = m.getResource()
        if outParams.DoesExist("mediaDuration") = false then outParams["mediaDuration"] = m.getMediaDuration()
        if outParams.DoesExist("live") = false then outParams["live"] = m.getIsLive()
        if outParams.DoesExist("rendition") = false then outParams["rendition"] = m.getRendition()
        if outParams.DoesExist("title") = false then outParams["title"] = m.getTitle()
        if outParams.DoesExist("properties") = false then outParams["properties"] = m.options["content.metadata"]
        if outParams.DoesExist("cdn") = false then outParams["cdn"] = m.options["content.cdn"]
        'Network
        if outParams.DoesExist("isp") = false then outParams["isp"] = m.options["network.isp"]
        if outParams.DoesExist("ip") = false then outParams["ip"] = m.options["network.ip"]
        'Extra params
        nextraparams = 20
        index = 1
        while (index <= nextraparams)
            optionKey = "extraparam." + index.ToStr()
            paramKey = "param"+index.ToStr()
            paramValue = m.options[optionKey]
            if paramValue <> Invalid
                if outParams.DoesExist(paramKey) = false then outParams[paramKey] = paramValue
            endif
            index = index + 1
        end while


        'Error-specific params
        if requestName = "error"
            if outParams.DoesExist("msg") = false then outParams["msg"] = "Unknown error"
            if outParams.DoesExist("errorCode") = false then outParams["errorCode"] = 9000
        endif

    else if requestName = "join"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("mediaDuration") = false then outParams["mediaDuration"] = m.getMediaDuration()
    else if requestName = "pause"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "resume"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "stop"
        'no params
    else if requestName = "ping"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("bitrate") = false then outParams["bitrate"] = m.getBitrate()
        if outParams.DoesExist("throughput") = false then outParams["throughput"] = m.getThroughput()

    else if requestName = "bufferEnd"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        'Avoid sending a playhead of 0
        if outParams["playhead"] = 0
            outParams["playhead"] = 1
        endif
    else if requestName = "seekEnd"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "adStart"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adPosition") = false then outParams["adPosition"] = m.getAdPosition()
        if outParams.DoesExist("adResource") = false then outParams["adResource"] = m.options["ad.resource"]
        if outParams.DoesExist("adCampaign") = false then outParams["adCampaign"] = m.options["ad.campaign"]
        if outParams.DoesExist("adTitle") = false then outParams["adTitle"] = m.options["ad.title"]
        if outParams.DoesExist("adProperties") = false then outParams["adProperties"] = m.options["ad.metadata"]
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
    else if requestName = "adJoin"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
    else if requestName = "adPause"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
    else if requestName = "adResume"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
    else if requestName = "adStop"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
        if outParams.DoesExist("adPosition") = false then outParams["adPosition"] = m.getAdPosition()
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
    else if requestName = "adError"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adPosition") = false then outParams["adPosition"] = m.getAdPosition()
        if outParams.DoesExist("adResource") = false then outParams["adResource"] = m.options["ad.resource"]
        if outParams.DoesExist("adCampaign") = false then outParams["adCampaign"] = m.options["ad.campaign"]
        if outParams.DoesExist("adTitle") = false then outParams["adTitle"] = m.options["ad.title"]
        if outParams.DoesExist("adProperties") = false then outParams["adProperties"] = m.options["ad.metadata"]
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
    endif

    return outParams

end function

function InfoManager_getFromInnerAsocArray(dict as Object, dictName as string, key as string)
    if dict <> Invalid and dict.DoesExist(dictName) = true
        innerDict = dict[dictName]
        if innerDict <> Invalid and type(innerDict) = "roAssociativeArray" and innerDict.DoesExist(key) = true
            value = innerDict[key]
            return value
        endif
    endif

    return invalid
end function
