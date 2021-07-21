sub init()
    YouboraLog("YBPluginCustom.brs - init")
end sub


'overriding the YBPluginRokuVideo's getBitrate
function getBitrate()
    'This is only for HLS and DASH
    if m.top.segInfo <> invalid
        m.segBitrate =  m.top.segInfo.segBitrateBps
    end if    
    return m.segBitrate
end function


'overriding the YBPluginRokuVideo's getRendition
function getRendition()
    'This is only for HLS and DASH
    return  m.rendition
end function


'This method helps to construct rendition value based on segBitrate & UI resolution
' rendition format will be wxh@bitrate
Function constructYouboraRendition(segInfo)
    rendition = invalid
    if segInfo <> invalid
        segBitrate = segInfo.segBitrateBps
        if segBitrate <> invalid
            if segBitrate < 1000
                segBitrate = segBitrate.ToStr() + "bps"
            else if segBitrate < 1000000
                segBitrate = (segBitrate/1000).ToStr() + "Kbps"
            else
                rendAux = segBitrate / 1000000.0 'Divide by mega
                rendAux = Cint(rendAux * 100) / 100.0
                segBitrate = rendAux.ToStr() + "Mbps"
            end if
            if segInfo.Width <> invalid and segInfo.Height <> invalid then
                width = segInfo.Width.ToStr()
                height = segInfo.Height.ToStr()
            else
                width = m.constants.deviceInfo.displayWidth.ToStr()
                height = m.constants.deviceInfo.displayHeight.ToStr()
            end if
            rendition = width + "x" + height + chr(64) + segBitrate
        end if
    end if
    return rendition
  
End Function


' Getting segment info from player and setting to m.rendition
Function onSegInfoChange(msg)
    m.segInfo = msg.getData()
    m.rendition = constructYouboraRendition(m.segInfo)
End Function