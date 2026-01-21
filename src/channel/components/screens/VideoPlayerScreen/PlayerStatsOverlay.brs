Function init()
  topRef = m.top

  m.titleLabel = topRef.findNode("titleLabel")
  m.sectionStreamInfo = topRef.findNode("sectionStreamInfo")
  m.sectionStreamingSeg = topRef.findNode("sectionStreamingSeg")
  m.sectionDownloadedSeg = topRef.findNode("sectionDownloadedSeg")

  m.measuredBitrateKey = topRef.findNode("measuredBitrateKey")
  m.measuredBitrateValue = topRef.findNode("measuredBitrateValue")

  m.streamBitrateKey = topRef.findNode("streamBitrateKey")
  m.streamBitrateValue = topRef.findNode("streamBitrateValue")

  m.streamUrlKey = topRef.findNode("streamUrlKey")
  m.streamUrlValue = topRef.findNode("streamUrlValue")

  m.resolutionKey = topRef.findNode("resolutionKey")
  m.resolutionValue = topRef.findNode("resolutionValue")

  m.drmTypeKey = topRef.findNode("drmTypeKey")
  m.drmTypeValue = topRef.findNode("drmTypeValue")

  m.codecKey = topRef.findNode("codecKey")
  m.codecValue = topRef.findNode("codecValue")

  m.fallbackCountKey = topRef.findNode("fallbackCountKey")
  m.fallbackCountValue = topRef.findNode("fallbackCountValue")

  m.fallbackUrlKey = topRef.findNode("fallbackUrlKey")
  m.fallbackUrlValue = topRef.findNode("fallbackUrlValue")

  m.streamSegSequenceKey = topRef.findNode("streamSegSequenceKey")
  m.streamSegStartTimeKey = topRef.findNode("streamSegStartTimeKey")
  m.streamSegTypeKey = topRef.findNode("streamSegTypeKey")
  m.streamSegBitrateKey = topRef.findNode("streamSegBitrateKey")
  m.streamSegResolutionKey = topRef.findNode("streamSegResolutionKey")
  m.streamSegHdrModeKey = topRef.findNode("streamSegHdrModeKey")
  m.streamSegUrlKey = topRef.findNode("streamSegUrlKey")

  m.streamSegSequenceValue = topRef.findNode("streamSegSequenceValue")
  m.streamSegStartTimeValue = topRef.findNode("streamSegStartTimeValue")
  m.streamSegTypeValue = topRef.findNode("streamSegTypeValue")
  m.streamSegBitrateValue = topRef.findNode("streamSegBitrateValue")
  m.streamSegResolutionValue = topRef.findNode("streamSegResolutionValue")
  m.streamSegHdrModeValue = topRef.findNode("streamSegHdrModeValue")
  m.streamSegUrlValue = topRef.findNode("streamSegUrlValue")

  m.dlSegSequenceKey = topRef.findNode("dlSegSequenceKey")
  m.dlSegStartTimeKey = topRef.findNode("dlSegStartTimeKey")
  m.dlSegTypeKey = topRef.findNode("dlSegTypeKey")
  m.dlSegDurationKey = topRef.findNode("dlSegDurationKey")
  m.dlSegSizeKey = topRef.findNode("dlSegSizeKey")
  m.dlSegBitrateKey = topRef.findNode("dlSegBitrateKey")
  m.dlSegDownloadTimeKey = topRef.findNode("dlSegDownloadTimeKey")
  m.dlSegBufferLevelKey = topRef.findNode("dlSegBufferLevelKey")
  m.dlSegBufferSizeKey = topRef.findNode("dlSegBufferSizeKey")
  m.dlSegUrlKey = topRef.findNode("dlSegUrlKey")

  m.dlSegSequenceValue = topRef.findNode("dlSegSequenceValue")
  m.dlSegStartTimeValue = topRef.findNode("dlSegStartTimeValue")
  m.dlSegTypeValue = topRef.findNode("dlSegTypeValue")
  m.dlSegDurationValue = topRef.findNode("dlSegDurationValue")
  m.dlSegSizeValue = topRef.findNode("dlSegSizeValue")
  m.dlSegBitrateValue = topRef.findNode("dlSegBitrateValue")
  m.dlSegDownloadTimeValue = topRef.findNode("dlSegDownloadTimeValue")
  m.dlSegBufferLevelValue = topRef.findNode("dlSegBufferLevelValue")
  m.dlSegBufferSizeValue = topRef.findNode("dlSegBufferSizeValue")
  m.dlSegUrlValue = topRef.findNode("dlSegUrlValue")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.titleLabel, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.sectionStreamInfo, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.sectionStreamingSeg, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.sectionDownloadedSeg, typographyConstants.ids.bodyMediumStrong)

  ' Set typography for all key labels
  setTypographyOfLabel(m.measuredBitrateKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamBitrateKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamUrlKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.resolutionKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.drmTypeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.codecKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.fallbackCountKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.fallbackUrlKey, typographyConstants.ids.bodyExtraSmallStrong)

  setTypographyOfLabel(m.streamSegSequenceKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamSegStartTimeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamSegTypeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamSegBitrateKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamSegResolutionKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamSegHdrModeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.streamSegUrlKey, typographyConstants.ids.bodyExtraSmallStrong)

  setTypographyOfLabel(m.dlSegSequenceKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegStartTimeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegTypeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegDurationKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegSizeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegBitrateKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegDownloadTimeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegBufferLevelKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegBufferSizeKey, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dlSegUrlKey, typographyConstants.ids.bodyExtraSmallStrong)

  ' Set typography for all value labels
  setTypographyOfLabel(m.measuredBitrateValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamBitrateValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamUrlValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.resolutionValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.drmTypeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.codecValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.fallbackCountValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.fallbackUrlValue, typographyConstants.ids.bodyExtraSmall)

  setTypographyOfLabel(m.streamSegSequenceValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamSegStartTimeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamSegTypeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamSegBitrateValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamSegResolutionValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamSegHdrModeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.streamSegUrlValue, typographyConstants.ids.bodyExtraSmall)

  setTypographyOfLabel(m.dlSegSequenceValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegStartTimeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegTypeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegDurationValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegSizeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegBitrateValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegDownloadTimeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegBufferLevelValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegBufferSizeValue, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.dlSegUrlValue, typographyConstants.ids.bodyExtraSmall)

  topRef.observeFieldScoped("playerStats", "onPlayerStatsChange")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    focusColor = theme.focusedColor
    secondaryColor = theme.secondaryTextColor

    m.titleLabel.color = focusColor
    m.sectionStreamInfo.color = focusColor
    m.sectionStreamingSeg.color = focusColor
    m.sectionDownloadedSeg.color = focusColor

    ' Set colors for all value labels
    m.measuredBitrateValue.color = secondaryColor
    m.streamBitrateValue.color = secondaryColor
    m.streamUrlValue.color = secondaryColor
    m.resolutionValue.color = secondaryColor
    m.drmTypeValue.color = secondaryColor
    m.codecValue.color = secondaryColor
    m.fallbackCountValue.color = secondaryColor
    m.fallbackUrlValue.color = secondaryColor

    m.streamSegSequenceValue.color = secondaryColor
    m.streamSegStartTimeValue.color = secondaryColor
    m.streamSegTypeValue.color = secondaryColor
    m.streamSegBitrateValue.color = secondaryColor
    m.streamSegResolutionValue.color = secondaryColor
    m.streamSegHdrModeValue.color = secondaryColor
    m.streamSegUrlValue.color = secondaryColor

    m.dlSegSequenceValue.color = secondaryColor
    m.dlSegStartTimeValue.color = secondaryColor
    m.dlSegTypeValue.color = secondaryColor
    m.dlSegDurationValue.color = secondaryColor
    m.dlSegSizeValue.color = secondaryColor
    m.dlSegBitrateValue.color = secondaryColor
    m.dlSegDownloadTimeValue.color = secondaryColor
    m.dlSegBufferLevelValue.color = secondaryColor
    m.dlSegBufferSizeValue.color = secondaryColor
    m.dlSegUrlValue.color = secondaryColor
  end if
End Function


Function onPlayerStatsChange(msg)
  stats = msg.getData()

  if isAA(stats) = true

    streamInfo = stats.streamInfo
    streamSeg = stats.streamingSegment
    dlSeg = stats.downloadedSegment

    if isAA(streamInfo) = true

      if streamInfo.measuredBitrate <> invalid
        m.measuredBitrateValue.text = formatNumber(streamInfo.measuredBitrate) + " bps"
      else
        m.measuredBitrateValue.text = "Unknown"
      end if

      if streamInfo.streamBitrate <> invalid
        m.streamBitrateValue.text = formatNumber(streamInfo.streamBitrate) + " bps"
      else
        m.streamBitrateValue.text = "Unknown"
      end if

      if isNonEmptyString(streamInfo.streamUrl) = true
        streamUrl = streamInfo.streamUrl
        m.streamUrlValue.text = removeExcessUrl(streamUrl)
      else
        m.streamUrlValue.text = "Unknown"
      end if

      if isNonEmptyString(streamInfo.resolution) = true
        m.resolutionValue.text = streamInfo.resolution
      else
        m.resolutionValue.text = "Unknown"
      end if

      if isNonEmptyString(streamInfo.drmType) = true
        m.drmTypeValue.text = streamInfo.drmType
      else
        m.drmTypeValue.text = "Unknown"
      end if

      if isNonEmptyString(streamInfo.codec) = true
        m.codecValue.text = streamInfo.codec
      else
        m.codecValue.text = "Unknown"
      end if

      ' Fallback Count - calculated from currentVideoResourceIndex
      codecIndex = 0
      drmIndex = 0
      totalFallbacks = 0

      if streamInfo.currentVideoResourceIndex <> invalid AND isArray(streamInfo.currentVideoResourceIndex) = true
        codecIndex = streamInfo.currentVideoResourceIndex[0]
        drmIndex = streamInfo.currentVideoResourceIndex[1]
        totalFallbacks = codecIndex + drmIndex
        m.fallbackCountValue.text = totalFallbacks.toStr()
      else
        m.fallbackCountValue.text = "0"
      end if

      ' Fallback URL - collect all attempted URLs based on fallback count
      fallbackUrls = []

      if totalFallbacks > 0 AND streamInfo.videoResources <> invalid AND isArray(streamInfo.videoResources) = true
        ' Iterate through codec indices (0 to codecIndex)
        for cIdx = 0 to codecIndex
          if cIdx < streamInfo.videoResources.count()
            codecResources = streamInfo.videoResources[cIdx]

            if isArray(codecResources) = true
              ' For each codec, iterate through DRM indices
              if cIdx < codecIndex
                ' For previous codecs, collect all DRM URLs
                for dIdx = 0 to codecResources.count() - 1
                  resource = codecResources[dIdx]
                  if isAA(resource) = true AND isNonEmptyString(resource.url) = true
                    updatedUrl = removeExcessUrl(resource.url)
                    fallbackUrls.push(updatedUrl)
                  end if
                end for
              else if cIdx = codecIndex
                ' For current codec, only collect up to current DRM index
                for dIdx = 0 to drmIndex - 1
                  if dIdx < codecResources.count()
                    resource = codecResources[dIdx]
                    if isAA(resource) = true AND isNonEmptyString(resource.url) = true
                      updatedUrl = removeExcessUrl(resource.url)
                      fallbackUrls.push(updatedUrl)
                    end if
                  end if
                end for
              end if
            end if
          end if
        end for

        ' Display newline-separated URLs
        if fallbackUrls.count() > 0
          m.fallbackUrlValue.text = fallbackUrls.join(", ")
        else
          m.fallbackUrlValue.text = "N/A"
        end if
      else if totalFallbacks = 0
        m.fallbackUrlValue.text = "No fallback"
      else
        m.fallbackUrlValue.text = "N/A"
      end if

    end if

    if isAA(streamSeg) = true

      if streamSeg.segSequence <> invalid
        m.streamSegSequenceValue.text = streamSeg.segSequence.toStr()
      else
        m.streamSegSequenceValue.text = "Unknown"
      end if

      if streamSeg.segStartTime <> invalid
        m.streamSegStartTimeValue.text = formatDecimal(streamSeg.segStartTime, 2) + " s"
      else
        m.streamSegStartTimeValue.text = "Unknown"
      end if

      if isNonEmptyString(streamSeg.segTypeStr) = true
        m.streamSegTypeValue.text = streamSeg.segTypeStr
      else if streamSeg.segType <> invalid
        m.streamSegTypeValue.text = getSegmentTypeName(streamSeg.segType)
      else
        m.streamSegTypeValue.text = "Unknown"
      end if

      if streamSeg.segBitrateBps <> invalid
        m.streamSegBitrateValue.text = formatNumber(streamSeg.segBitrateBps) + " bps"
      else
        m.streamSegBitrateValue.text = "Unknown"
      end if

      if streamSeg.width <> invalid AND streamSeg.height <> invalid
        m.streamSegResolutionValue.text = streamSeg.width.toStr() + " x " + streamSeg.height.toStr()
      else
        m.streamSegResolutionValue.text = "Unknown"
      end if

      if isNonEmptyString(streamSeg.hdrModeStr) = true
        m.streamSegHdrModeValue.text = streamSeg.hdrModeStr
      else
        m.streamSegHdrModeValue.text = "None"
      end if

      if isNonEmptyString(streamSeg.segUrl) = true
        m.streamSegUrlValue.text = removeExcessUrl(streamSeg.segUrl)
      else
        m.streamSegUrlValue.text = "Unknown"
      end if
    end if

    if isAA(dlSeg) = true

      if dlSeg.segSequence <> invalid
        m.dlSegSequenceValue.text = dlSeg.segSequence.toStr()
      else
        m.dlSegSequenceValue.text = "Unknown"
      end if

      if dlSeg.segStartTime <> invalid
        m.dlSegStartTimeValue.text = formatDecimal(dlSeg.segStartTime, 2) + " s"
      else
        m.dlSegStartTimeValue.text = "Unknown"
      end if

      if dlSeg.segType <> invalid
        m.dlSegTypeValue.text = getSegmentTypeName(dlSeg.segType)
      else
        m.dlSegTypeValue.text = "Unknown"
      end if

      if dlSeg.segDuration <> invalid
        m.dlSegDurationValue.text = dlSeg.segDuration.toStr() + " ms"
      else
        m.dlSegDurationValue.text = "Unknown"
      end if

      if dlSeg.segSize <> invalid
        m.dlSegSizeValue.text = formatBytes(dlSeg.segSize)
      else
        m.dlSegSizeValue.text = "Unknown"
      end if

      if dlSeg.bitrateBps <> invalid
        m.dlSegBitrateValue.text = formatNumber(dlSeg.bitrateBps) + " bps"
      else
        m.dlSegBitrateValue.text = "Unknown"
      end if

      if dlSeg.downloadDuration <> invalid
        m.dlSegDownloadTimeValue.text = dlSeg.downloadDuration.toStr() + " ms"
      else
        m.dlSegDownloadTimeValue.text = "Unknown"
      end if

      if dlSeg.bufferLevel <> invalid
        m.dlSegBufferLevelValue.text = formatDecimal(dlSeg.bufferLevel, 2) + " s"
      else
        m.dlSegBufferLevelValue.text = "Unknown"
      end if

      if dlSeg.bufferSize <> invalid
        m.dlSegBufferSizeValue.text = formatBytes(dlSeg.bufferSize)
      else
        m.dlSegBufferSizeValue.text = "Unknown"
      end if

      if isNonEmptyString(dlSeg.segUrl) = true
        m.dlSegUrlValue.text = removeExcessUrl(dlSeg.segUrl)
      else
        m.dlSegUrlValue.text = "Unknown"
      end if
    end if

  end if
End Function


Function formatNumber(num as Dynamic) as String
  if num = invalid then return "0"

  numStr = num.toStr()
  result = ""
  count = 0

  for i = numStr.len() - 1 to 0 step -1
    if count > 0 AND count mod 3 = 0
      result = "," + result
    end if
    result = numStr.mid(i, 1) + result
    count = count + 1
  end for

  return result
End Function


Function formatBytes(bytes as Dynamic) as String
  if bytes = invalid then return "0 B"

  if bytes < 1024
    return bytes.toStr() + " B"
  else if bytes < 1048576 ' 1024 * 1024
    kb = bytes / 1024.0
    return formatDecimal(kb, 2) + " KB"
  else if bytes < 1073741824 ' 1024 * 1024 * 1024
    mb = bytes / 1048576.0
    return formatDecimal(mb, 2) + " MB"
  else
    gb = bytes / 1073741824.0
    return formatDecimal(gb, 2) + " GB"
  end if
End Function


Function formatDecimal(num as Dynamic, decimals as Integer) as String
  if num = invalid then return "0"

  numStr = num.toStr()
  dotIndex = numStr.instr(".")

  if dotIndex > -1
    if numStr.len() > dotIndex + decimals + 1
      return numStr.left(dotIndex + decimals + 1)
    else
      return numStr
    end if
  else
    return numStr
  end if
End Function


Function getSegmentTypeName(segType as Dynamic) as String
  if segType = invalid then return "Unknown"

  if segType = 0
    return "Muxed"
  else if segType = 1
    return "Video"
  else if segType = 2
    return "Audio"
  else if segType = 3
    return "Subtitle"
  else
    return "Type " + segType.toStr()
  end if
End Function
