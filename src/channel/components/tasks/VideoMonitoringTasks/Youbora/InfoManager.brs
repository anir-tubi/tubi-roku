function InfoManager(plugin, options = invalid)
    YouboraLog("Created InfoManager")
    this = CreateObject("roAssociativeArray")

    'Methods
    this.getRequestParams = InfoManager_getRequestParams
    this.getEntities = InfoManager_getEntities

    this.getResource = function()
        resource = m.options["content.resource"]

        if resource = invalid
            resource = m.plugin.getResource()
        end if

        if resource = invalid
            resource = "Unknown"
        end if

        return resource
    end function

    this.getParsedResource = function ()
        resource = invalid

        if m.options["parse.manifest"] = true
            resource = m.plugin.getParsedResource()
        end if

        return resource

    end function

    this.getTransportFormat = function ()
        format = m.options["content.transportFormat"]
        if format <> "TS" and format <> "MP4" and format <> "CMF" then
            format = invalid
        end if

        if format = invalid and m.options["parse.manifest"] = true
            resource = m.plugin.getParsedResource()
            if Instr(1,resource,".ts") > 0 then
                format = "TS"
            else if Instr(1,resource,".cmfv") > 0 then
                format = "CMF"
            else if Instr(1,resource,".mp4") + Instr(1,resource,".m4s") > 0 then
                format = "MP4"
            end if
        end if

        return format

    end function


    this.getStreamingProtocol = function ()
        protocol = m.options["content.streamingProtocol"]

        if protocol <> "HDS" and protocol <> "HLS" and protocol <> "MSS"  and protocol <> "DASH" and protocol <> "RTMP" and protocol <> "RTP" and protocol <> "RTSP"
            protocol = invalid
        end if

        return protocol

    end function

    this.getPlayhead = function()
        playhead = m.plugin.getPlayhead()

        if playhead = invalid
            playhead = 0.0
        end if

        return playhead
    end function

    this.getMediaDuration = function()
        duration = m.options["content.duration"]

        if duration = invalid
            duration = m.plugin.getMediaDuration()
        end if

        if duration = invalid
            duration = 0
        end if

        return duration
    end function

    this.getTitle = function()
        title = m.options["content.title"]

        if title = invalid
            title = m.plugin.getTitle()
        end if

        return title
    end function

    this.getPlayrate = function()
        return m.plugin.getPlayrate()
    end function

    this.getIsLive = function()
        islive = m.options["content.isLive"]

        if islive = invalid
            islive = m.plugin.getIsLive()
        end if

        if islive = invalid
            islive = false
        end if

        return islive
    end function

    this.getRendition = function()
        rendition = m.options["content.rendition"]

        if rendition = invalid
            rendition = m.plugin.getRendition()
        end if

        return rendition
    end function

    this.getSubtitles = function()
        return m.options["content.subtitles"]
    end function

    this.getBitrate = function()
        bitrate = m.plugin.getBitrate()

        if bitrate = invalid
            bitrate = -1.0
        end if

        return bitrate
    end function

    this.getThroughput = function()
        throughput = m.plugin.getThroughput()

        if throughput = invalid
            throughput = -1.0
        end if

        return throughput
    end function

    this.getTotalBytes = function()
        totalBytes = invalid

        if m.options["content.sendTotalBytes"] = true
            if m.options["content.totalBytes"] = invalid
                totalBytes = m.plugin.getTotalBytes()
            else
                totalBytes =  m.options["content.totalBytes"]
            end if
        else

        end if

        return totalBytes
    end function

    this.getDeviceInfo = function()
        deviceInfo = {}
        if m.options["device.model"] = invalid
            hardwareModel = CreateObject("roDeviceInfo").GetModel()
            'Mapping
            models = {
                'Roku Smart Soundbar
                "9100X" : "Roku Smart Soundbar",
                'Roku Streambar
                "9102X" : "Roku Streambar"
                'Roku Ultra LT
                "4662X" : "Roku Ultra LT",
                'Roku Streaming Stick+
                "3810X" : "Roku Streaming Stick+",
                "3811X" : "Roku Streaming Stick+",
                '4K Roku TV
                "7000X" : "4K Roku TV",
                "A000X" : "4K Roku TV",
                "C000X" : "4K Roku TV",
                "C000GB" : "4K Roku TV",
                'Roku LT
                "2400X" : "Roku LT",
                "2450X" : "Roku LT",
                "2700X" : "Roku LT",
                'Roku 1
                "2710X" : "Roku 1",
                'Roku 2
                "2720X" : "Roku 2",
                "3000X" : "Roku 2",
                "3050X" : "Roku 2",
                "3100X" : "Roku 2",
                "4210X" : "Roku 2",
                'Roku Stick
                "3600X" : "Roku Stick",
                "3800X" : "Roku Stick",
                "3400X" : "Roku Stick",
                "3420X" : "Roku Stick",
                "3500X" : "Roku Stick",
                'Roku 3
                "4200X" : "Roku 3",
                "4230X" : "Roku 3",
                'Roku 4
                "4400X" : "Roku 4",
                'Roku TV
                "5000X" : "Roku TV",
                "6000X" : "Roku TV",
                "8000X" : "Roku TV",
                "D000X" : "Roku TV",
                'Roku Express
                "3700X" : "Roku Express",
                "3710X" : "Roku Express",
                "3900X" : "Roku Express",
                "3910X" : "Roku Express",
                "3930X" : "Roku Express",
                'Roku Express+
                "3931X" : "Roku Express+",
                'Roku Express 4K
                "3940X" : "Roku Express 4K",
                'Roku Express 4K+
                "3941X" : "Roku Express 4K+",
                'Roku Premiere
                "4620X" : "Roku Premiere",
                "4630X" : "Roku Premiere",
                'Roku Ultra
                "4640X" : "Roku Ultra",
                "4660X" : "Roku Ultra",
                "4800X" : "Roku Ultra",
                'Roku SD
                "N1050" : "Roku SD",
                'Roku HD Classic (Roku HD)
                "N1000" : "Roku HD Classic (Roku HD)",
                "N1100" : "Roku HD Classic (Roku HD)",
                'Roku XD
                "2050X" : "Roku XD",
                "2050N" : "Roku XD",
                "N1101" : "Roku XD",
                "2100X" : "Roku XD",
                "2100N" : "Roku XD",
                'Roku HD
                "2000C" : "Roku HD",
                "2500X" : "Roku HD"
            }

            if models.DoesExist(hardwareModel)
                deviceInfo["deviceName"] = models[hardwareModel]
                deviceInfo["model"] = hardwareModel
            end if
        else
            deviceInfo["model"] = m.options["device.model"]
        end if

        if m.options["device.osVersion"] = invalid
            osVersion = CreateObject("roDeviceInfo").GetOSVersion()
            deviceInfo["osVersion"] = osVersion.major + "." + osVersion.minor + "." + osVersion.revision + "." + osVersion.build
        else
            deviceInfo["osVersion"] = m.options["device.osVersion"]
        end if

        if m.options["device.brand"] = invalid
            deviceInfo["brand"] = "Roku"
        else
            deviceInfo["brand"] = m.options["device.brand"]
        end if

        if m.options["device.deviceType"] <> invalid
            deviceInfo["deviceType"] = m.options["device.deviceType"]
        end if

        if m.options["device.deviceCode"] <> invalid
            deviceInfo["deviceCode"] = m.options["device.deviceCode"]
        end if

        if m.options["device.osName"] <> invalid
            deviceInfo["osName"] = m.options["device.osName"]
        end if

        if m.options["device.browserName"] = invalid
            deviceInfo["browserName"] = ""
        else
            deviceInfo["browserName"] = m.options["device.browserName"]
        end if

        if m.options["device.browserVersion"] = invalid
            deviceInfo["browserVersion"] = ""
        else
            deviceInfo["browserVersion"] = m.options["device.browserVersion"]
        end if

        if m.options["device.deviceBrowserType"] = invalid
            deviceInfo["deviceBrowserType"] = ""
        else
            deviceInfo["deviceBrowserType"] = m.options["device.deviceBrowserType"]
        end if

        if m.options["device.browserEngine"] = invalid
            deviceInfo["browserEngine"] = ""
        else
            deviceInfo["browserEngine"] = m.options["device.model"]
        end if

        return deviceInfo
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

    this.getAdNumberInBreak = function()
        number = m.plugin.getAdNumberInBreak()

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

    this.getAdTitle = function()
        return m.options["ad.title"]
    end function

    this.getAdResource = function()
        return m.options["ad.resource"]
    end function

    this.getVideoMetrics = function()
        return m.options["content.metrics"]
    end function

    'Fields
    this.plugin = plugin

    if options = invalid
        this.options = {}
    else
        this.options = options
    end if

    return this



end function

function InfoManager_getEntities() as object
    return {
        "rendition": m.getRendition(),
        "title": m.getTitle(),
        "program": m.options["content.program"],
        "cdn": m.options["content.cdn"],
        "subtitles": m.getSubtitles(),
        "contentLanguage": m.options["content.language"]
    }
end function

function InfoManager_getRequestParams(requestName = "" as string, params = invalid)

    if params = invalid
        outParams = {}
    else
        outParams = params
    end if

    'Now is mandatory for EVERY request
    if outParams.DoesExist("accountCode") = false then outParams["accountCode"] = m.options["accountCode"]

    'For requests that create a view or a session
    if requestName = "start" or requestName = "error" or requestName = "sessionStart"
        if outParams.DoesExist("username") = false
            if m.options["user.name"] = invalid
                outParams["username"] = m.options["username"]
            else
                outParams["username"] = m.options["user.name"]
            end if
        end if
        if outParams.DoesExist("email") = false then outParams["email"] = m.options["user.email"]
        if outParams.DoesExist("obfuscateIp") = false then outParams["obfuscateIp"] = m.options["user.obfuscateIp"]
        if outParams.DoesExist("userType") = false
            if m.options["user.type"] = invalid
                outParams["userType"] = m.options["userType"]
            else
                outParams["userType"] = m.options["user.type"]
            end if
        end if
        if outParams.DoesExist("anonymousUser") = false
            if m.options["user.anonymousId"] = invalid
                outParams["anonymousUser"] = m.options["anonymousUser"]
            else
                outParams["anonymousUser"] = m.options["user.anonymousId"]
            end if
        end if
        if outParams.DoesExist("deviceId") = false then outParams["deviceId"] = m.options["device.code"]
        if outParams.DoesExist("deviceInfo") = false then outParams["deviceInfo"] = m.getDeviceInfo()
        'if outParams.DoesExist("deviceInfo") = false then outParams["deviceInfo"] = {"model":m.getDeviceModel()}
        'Network
        if outParams.DoesExist("isp") = false then outParams["isp"] = m.options["network.isp"]
        if outParams.DoesExist("ip") = false then outParams["ip"] = m.options["network.ip"]
        if outParams.DoesExist("connectionType") = false then outParams["connectionType"] = m.options["network.connectionType"]
        'App
        if outParams.DoesExist("appName") = false then outParams["appName"] = m.options["app.name"]
        if outParams.DoesExist("appReleaseVersion") = false then outParams["appReleaseVersion"] = m.options["app.releaseVersion"]
    end if

    if requestName = "data"
        if outParams.DoesExist("system") = false then outParams["system"] = m.options["accountCode"]
        if outParams.DoesExist("pluginName") = false then outParams["pluginName"] = m.plugin.getPluginName()
        if outParams.DoesExist("pluginVersion") = false then outParams["pluginVersion"] = m.plugin.getPluginVersion()
    else if requestName = "start" or requestName = "error"
        'Start and Error share most of the params, but error also has error code and error message
        ' Params
        if outParams.DoesExist("system") = false then outParams["system"] = m.options["accountCode"]
        if outParams.DoesExist("player") = false then outParams["player"] = m.plugin.getPluginName()

        if outParams.DoesExist("transactionCode") = false then outParams["transactionCode"] = m.options["content.transactionCode"]
        if outParams.DoesExist("deviceUUID") = false then outParams["deviceUUID"] = CreateObject("roDeviceInfo").GetChannelClientId()
        'Plugin versioning
        if outParams.DoesExist("pluginVersion") = false then outParams["pluginVersion"] = m.plugin.getPluginVersion()
        if outParams.DoesExist("playerVersion") = false then outParams["playerVersion"] = m.plugin.getPlayerVersion()
        'Media
        if outParams.DoesExist("mediaResource") = false then outParams["mediaResource"] = m.getResource()
        if outParams.DoesExist("parsedResource") = false then outParams["parsedResource"] = m.getParsedResource()
        if outParams.DoesExist("streamingProtocol") = false then outParams["streamingProtocol"] = m.getStreamingProtocol()
        if outParams.DoesExist("transportFormat") = false then outParams["transportFormat"] = m.getTransportFormat()
        if outParams.DoesExist("mediaDuration") = false then outParams["mediaDuration"] = m.getMediaDuration()
        if outParams.DoesExist("live") = false then outParams["live"] = m.getIsLive()
        if outParams.DoesExist("rendition") = false then outParams["rendition"] = m.getRendition()
        if outParams.DoesExist("title") = false then outParams["title"] = m.getTitle()
        if outParams.DoesExist("properties") = false then outParams["properties"] = m.options["content.metadata"]
        if outParams.DoesExist("cdn") = false then outParams["cdn"] = m.options["content.cdn"]
        if outParams.DoesExist("program") = false then outParams["program"] = m.options["content.program"]
        if outParams.DoesExist("saga") = false then outParams["saga"] = m.options["content.saga"]
        if outParams.DoesExist("tvshow") = false then outParams["tvshow"] = m.options["content.tvShow"]
        if outParams.DoesExist("season") = false then outParams["season"] = m.options["content.season"]
        if outParams.DoesExist("titleEpisode") = false then outParams["titleEpisode"] = m.options["content.episodeTitle"]
        if outParams.DoesExist("channel") = false then outParams["channel"] = m.options["content.Channel"]
        if outParams.DoesExist("contentId") = false then outParams["contentId"] = m.options["content.id"]
        if outParams.DoesExist("imdbID") = false then outParams["imdbID"] = m.options["content.imdbId"]
        if outParams.DoesExist("gracenoteID") = false then outParams["gracenoteID"] = m.options["content.gracenoteId"]
        if outParams.DoesExist("contentType") = false then outParams["contentType"] = m.options["content.type"]
        if outParams.DoesExist("genre") = false then outParams["genre"] = m.options["content.genre"]
        if outParams.DoesExist("contentLanguage") = false then outParams["contentLanguage"] = m.options["content.language"]
        if outParams.DoesExist("subtitles") = false then outParams["subtitles"] = m.getSubtitles()
        if outParams.DoesExist("contractedResolution") = false then outParams["contractedResolution"] = m.options["content.contractedResolution"]
        if outParams.DoesExist("cost") = false then outParams["cost"] = m.options["content.cost"]
        if outParams.DoesExist("price") = false then outParams["price"] = m.options["content.price"]
        if outParams.DoesExist("playbackType") = false then outParams["playbackType"] = m.options["content.playbackType"]
        if outParams.DoesExist("drm") = false then outParams["drm"] = m.options["content.drm"]
        if outParams.DoesExist("videoCodec") = false then outParams["videoCodec"] = m.options["content.encoding.videoCodec"]
        if outParams.DoesExist("audioCodec") = false then outParams["audioCodec"] = m.options["content.encoding.audioCodec"]
        if outParams.DoesExist("codecSettings") = false then outParams["codecSettings"] = m.options["content.encoding.codecSettings"]
        if outParams.DoesExist("codecProfile") = false then outParams["codecProfile"] = m.options["content.encoding.codecProfile"]
        if outParams.DoesExist("containerFormat") = false then outParams["containerFormat"] = m.options["content.encoding.containerFormat"]
        'Extra params
        if outParams.DoesExist("dimensions") = false then outParams["dimensions"] = m.options["content.customDimensions"]
        nextraparams = 20
        index = 1
        while (index <= nextraparams)
            optionKey = "extraparam." + index.ToStr()
            paramKey = "param" + index.ToStr()
            optionCustomDimensionKey = "content.customDimension." + index.ToStr()
            paramValue = m.options[optionKey]
            if m.options[optionKey] = invalid then paramValue = m.options[optionCustomDimensionKey]
            if paramValue <> invalid
                if outParams.DoesExist(paramKey) = false then outParams[paramKey] = paramValue
            end if
            index = index + 1
        end while

        'Error-specific params
        if requestName = "error"
            if outParams.DoesExist("msg") = false then outParams["msg"] = "Unknown error"
            if outParams.DoesExist("errorCode") = false then outParams["errorCode"] = 9000
        end if

    else if requestName = "join"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "pause"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "resume"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "stop"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = "-1"
        if outParams.DoesExist("totalBytes") = false then outParams["totalBytes"] = m.getTotalBytes()
    else if requestName = "ping"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("bitrate") = false then outParams["bitrate"] = m.getBitrate()
        if outParams.DoesExist("throughput") = false then outParams["throughput"] = m.getThroughput()
        if outParams.DoesExist("totalBytes") = false then outParams["totalBytes"] = m.getTotalBytes()
        if outParams.DoesExist("playrate") = false then outParams["playrate"] = m.getPlayrate()
        if outParams.DoesExist("metrics") = false then outParams["metrics"] = m.getVideoMetrics()   
    else if requestName = "bufferEnd"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        'Avoid sending a playhead of 0
        if outParams["playhead"] = 0
            outParams["playhead"] = 1
        end if
    else if requestName = "seekEnd"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
    else if requestName = "adStart" or requestName = "adInit"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("position") = false then outParams["position"] = m.getAdPosition()
        if outParams.DoesExist("adResource") = false then outParams["adResource"] = m.options["ad.resource"]
        if outParams.DoesExist("adCampaign") = false then outParams["adCampaign"] = m.options["ad.campaign"]
        if outParams.DoesExist("adTitle") = false then outParams["adTitle"] = m.options["ad.title"]
        if outParams.DoesExist("adCreativeId") = false then outParams["adCreativeId"] = m.options["ad.creativeId"]
        if outParams.DoesExist("adProvider") = false then outParams["adProvider"] = m.options["ad.provider"]
        if outParams.DoesExist("adProperties") = false then outParams["adProperties"] = m.options["ad.metadata"]
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
        if outParams.DoesExist("adNumberInBreak") = false then outParams["adNumberInBreak"] = m.getAdNumberInBreak()
        if outParams.DoesExist("adnalyzerVersion") = false then outParams["adnalyzerVersion"] = "6.5.25 Roku Adnalyzer"
        'Extra params
        nextraparams = 10
        index = 1
        while (index <= nextraparams)
            optionKey = "ad.extraparam." + index.ToStr()
            paramKey = "extraparam" + index.ToStr()
            optionCustomDimensionKey = "ad.customDimension." + index.ToStr()
            paramValue = m.options[optionKey]
            if m.options[optionKey] = invalid then paramValue = m.options[optionCustomDimensionKey]
            if paramValue <> invalid
                if outParams.DoesExist(paramKey) = false then outParams[paramKey] = paramValue
            end if
            index = index + 1
        end while
    else if requestName = "adJoin"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
        if outParams.DoesExist("adNumberInBreak") = false then outParams["adNumberInBreak"] = m.getAdNumberInBreak()
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
    else if requestName = "adQuartile"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
        if outParams.DoesExist("adNumberInBreak") = false then outParams["adNumberInBreak"] = m.getAdNumberInBreak()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
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
        if outParams.DoesExist("adNumberInBreak") = false then outParams["adNumberInBreak"] = m.getAdNumberInBreak()
        if outParams.DoesExist("position") = false then outParams["position"] = m.getAdPosition()
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
    else if requestName = "adError"
        if outParams.DoesExist("playhead") = false then outParams["playhead"] = m.getPlayhead()
        if outParams.DoesExist("position") = false then outParams["position"] = m.getAdPosition()
        if outParams.DoesExist("adResource") = false then outParams["adResource"] = m.options["ad.resource"]
        if outParams.DoesExist("adCampaign") = false then outParams["adCampaign"] = m.options["ad.campaign"]
        if outParams.DoesExist("adTitle") = false then outParams["adTitle"] = m.options["ad.title"]
        if outParams.DoesExist("adProperties") = false then outParams["adProperties"] = m.options["ad.metadata"]
        if outParams.DoesExist("adDuration") = false then outParams["adDuration"] = m.getAdDuration()
        if outParams.DoesExist("adPlayhead") = false then outParams["adPlayhead"] = m.getAdPlayhead()
        if outParams.DoesExist("adNumber") = false then outParams["adNumber"] = m.getAdNumber()
        if outParams.DoesExist("adNumberInBreak") = false then outParams["adNumberInBreak"] = m.getAdNumberInBreak()
    else if requestName = "adBreakStart"
        if outParams.DoesExist("givenAds") = false then outParams["givenAds"] = m.options["ad.givenAds"]
        if outParams.DoesExist("position") = false then outParams["position"] = m.getAdPosition()
        if outParams.DoesExist("expectedAds") = false
            if m.options["ad.expectedPattern"] <> invalid
                if type(m.options["ad.expectedPattern"]) = "roAssociativeArray"
                    array = CreateObject("roArray", 0, true)
                    if m.options["ad.expectedPattern"]["pre"] <> invalid
                        if type(m.options["ad.expectedPattern"]["pre"]) = "roArray"
                            array.Append(m.options["ad.expectedPattern"]["pre"])
                        else
                            YouboraLog("Values inside ad.expectedPattern must be arrays")
                        end if
                    end if
                    if m.options["ad.expectedPattern"]["mid"] <> invalid
                        if type(m.options["ad.expectedPattern"]["mid"]) = "roArray"
                            array.Append(m.options["ad.expectedPattern"]["mid"])
                        else
                            YouboraLog("Values inside ad.expectedPattern must be arrays")
                        end if
                    end if
                    if m.options["ad.expectedPattern"]["post"] <> invalid
                        if type(m.options["ad.expectedPattern"]["post"]) = "roArray"
                            array.Append(m.options["ad.expectedPattern"]["post"])
                        else
                            YouboraLog("Values inside ad.expectedPattern must be arrays")
                        end if
                    end if
                    if array[outParams["breakNumber"]] <> invalid
                        outParams["expectedAds"] = array[outParams["breakNumber"]] 
                    end if
                end if
            end if
        end if
    else if requestName = "adManifest"
        if outParams.DoesExist("givenBreaks") = false then outParams["givenBreaks"] = m.options["ad.givenBreaks"]
        if outParams.DoesExist("breaksTime") = false then outParams["breaksTime"] = m.options["ad.breaksTime"]
        if m.options["ad.expectedBreaks"] <> invalid
            outParams["expectedBreaks"] = m.options["ad.expectedBreaks"]
        else if m.options["ad.expectedPattern"] <> invalid
            if type(m.options["ad.expectedPattern"]) = "roAssociativeArray"
                length = 0
                if m.options["ad.expectedPattern"]["pre"] <> invalid
                    if type(m.options["ad.expectedPattern"]["pre"]) = "roArray"
                        length = length + m.options["ad.expectedPattern"]["pre"].Count()
                    else
                        YouboraLog("Values inside ad.expectedPattern must be arrays")
                    end if
                endif
                if m.options["ad.expectedPattern"]["mid"] <> invalid
                    if type(m.options["ad.expectedPattern"]["mid"]) = "roArray"
                        length = length + m.options["ad.expectedPattern"]["mid"].Count()
                    else
                        YouboraLog("Values inside ad.expectedPattern must be arrays")
                    end if
                endif
                if m.options["ad.expectedPattern"]["post"] <> invalid
                    if type(m.options["ad.expectedPattern"]["post"]) = "roArray"
                        length = length + m.options["ad.expectedPattern"]["post"].Count()
                    else
                        YouboraLog("Values inside ad.expectedPattern must be arrays")
                    end if
                endif
                outParams["expectedBreaks"] = length
            endif
        endif
        if outParams.DoesExist("expectedPattern") = false then outParams["expectedPattern"] = m.options["ad.expectedPattern"]
    else if requestName = "sessionStart"
        if outParams.DoesExist("navContext") = false then outParams["navContext"] = "RokuPlugin"
        if outParams.DoesExist("pluginName") = false then outParams["pluginName"] = m.plugin.getPluginName()
        if outParams.DoesExist("pluginVersion") = false then outParams["pluginVersion"] = m.plugin.getPluginVersion()
        if outParams.DoesExist("obfuscateIp") = false then outParams["obfuscateIp"] = m.options["user.obfuscateIp"]
        if outParams.DoesExist("deviceUUID") = false then outParams["deviceUUID"] = CreateObject("roDeviceInfo").GetChannelClientId()
        nextraparams = 20
        index = 1
        while (index <= nextraparams)
            optionKey = "extraparam." + index.ToStr()
            paramKey = "param" + index.ToStr()
            optionCustomDimensionKey = "content.customDimension." + index.ToStr()
            paramValue = m.options[optionKey]
            if m.options[optionKey] = invalid then paramValue = m.options[optionCustomDimensionKey]
            if paramValue <> invalid
                if outParams.DoesExist(paramKey) = false then outParams[paramKey] = paramValue
            end if
            index = index + 1
        end while
    else if requestName = "sessionNav"
        if outParams.DoesExist("username") = false
            if m.options["user.name"] = invalid
                outParams["username"] = m.options["username"]
            else
                outParams["username"] = m.options["user.name"]
            end if
        end if
        if outParams.DoesExist("navContext") = false then outParams["navContext"] = "RokuPlugin"
        if outParams.DoesExist("route") = false then outParams["route"] = "Roku"
    else if requestName = "sessionBeat"
        ' ──────█▀▄─▄▀▄─▀█▀─█─█─▀─█▀▄─▄▀▀▀─────
        ' ──────█─█─█─█──█──█▀█─█─█─█─█─▀█─────
        ' ──────▀─▀──▀───▀──▀─▀─▀─▀─▀──▀▀──────
        ' ─────────────────────────────────────
        ' ───────────────▀█▀─▄▀▄───────────────
        ' ────────────────█──█─█───────────────
        ' ────────────────▀───▀────────────────
        ' ─────────────────────────────────────
        ' ─────█▀▀▄─█▀▀█───█──█─█▀▀─█▀▀█─█▀▀───
        ' ─────█──█─█──█───█▀▀█─█▀▀─█▄▄▀─█▀▀───
        ' ─────▀▀▀──▀▀▀▀───▀──▀─▀▀▀─▀─▀▀─▀▀▀───
        ' ─────────────────────────────────────
        ' ─────────▄███████████▄▄──────────────
        ' ──────▄██▀──────────▀▀██▄────────────
        ' ────▄█▀────────────────▀██───────────
        ' ──▄█▀────────────────────▀█▄─────────
        ' ─█▀──██──────────────██───▀██────────
        ' █▀──────────────────────────██───────
        ' █──███████████████████───────█───────
        ' █────────────────────────────█───────
        ' █────────────────────────────█───────
        ' █────────────────────────────█───────
        ' █────────────────────────────█───────
        ' █────────────────────────────█───────
        ' █▄───────────────────────────█───────
        ' ▀█▄─────────────────────────██───────
        ' ─▀█▄───────────────────────██────────
        ' ──▀█▄────────────────────▄█▀─────────
        ' ───▀█▄──────────────────██───────────
        ' ─────▀█▄──────────────▄█▀────────────
        ' ───────▀█▄▄▄──────▄▄▄███████▄▄───────
        ' ────────███████████████───▀██████▄───
        ' ─────▄███▀▀────────▀███▄──────█─███──
        ' ───▄███▄─────▄▄▄▄────███────▄▄████▀──
        ' ─▄███▓▓█─────█▓▓█───████████████▀────
        ' ─▀▀██▀▀▀▀▀▀▀▀▀▀███████████────█──────
        ' ────█─▄▄▄▄▄▄▄▄█▀█▓▓─────██────█──────
        ' ────█─█───────█─█─▓▓────██────█──────
        ' ────█▄█───────█▄█──▓▓▓▓▓███▄▄▄█──────
        ' ────────────────────────██──────────
        ' ────────────────────────██───▄███▄───
        ' ────────────────────────██─▄██▓▓▓██──
        ' ───────────────▄██████████─█▓▓▓█▓▓██▄
        ' ─────────────▄██▀───▀▀███──█▓▓▓██▓▓▓█
        ' ─▄███████▄──███───▄▄████───██▓▓████▓█
        ' ▄██▀──▀▀█████████████▀▀─────██▓▓▓▓███
        ' ██▀─────────██──────────────██▓██▓███
        ' ██──────────███──────────────█████─██
        ' ██───────────███──────────────█─██──█
        ' ██────────────██─────────────────█───
        ' ██─────────────██────────────────────
        ' ██─────────────███───────────────────
        ' ██──────────────███▄▄────────────────
        ' ███──────────────▀▀███───────────────
        ' ─███─────────────────────────────────
        ' ──███────────────────────────────────
    end if

    return outParams

end function

function InfoManager_getFromInnerAsocArray(dict as object, dictName as string, key as string)
    if dict <> invalid and dict.DoesExist(dictName) = true
        innerDict = dict[dictName]
        if innerDict <> invalid and type(innerDict) = "roAssociativeArray" and innerDict.DoesExist(key) = true
            value = innerDict[key]
            return value
        end if
    end if

    return invalid
end function
