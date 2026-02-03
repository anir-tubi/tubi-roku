Function getPlaybackErrorInfo(position, downloadedSegment, streamingSegment, streamInfo, errorCode, errorStr, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }
  if errorCode = -3
    errorInfo.error_message = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."
    ' Check for position to be > 0 in order to prevent segments from previous videos to populate
    ' the error messaging for the current video.
    if position > 0 AND downloadedSegment <> invalid
      ' in the case of errorCode = -3, it likely means there was a 504 or 404 response from the server which ultimately was the source of the error.
      ' we get the last downloaded segment which is the last good segment instead of the current streaming segment, which may be several segments ahead of the bad segment.
      ' in this case, the segment causing the error is the segment AFTER the logged segment.
      errorInfo.segment_sequence = downloadedSegment.segSequence
      errorInfo.segment_url = removeQueryParams(downloadedSegment.SegUrl)
      errorInfo.segment_bitrate = downloadedSegment.BitrateBps
    end if
  else if errorStr <> invalid
    errorInfo.error_message = errorStr
    if position > 0 AND streamingSegment <> invalid
      ' streamingSegment can be invalid when the server returns a 504, 404, etc.
      errorInfo.segment_url = removeQueryParams(streamingSegment.segUrl)
      errorInfo.segment_start_time = streamingSegment.segStartTime
      errorInfo.segment_sequence = streamingSegment.segSequence
      errorInfo.segment_bitrate = streamingSegment.segBitrateBps
    end if
  end if
  errorInfo.error_code = errorCode

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 AND streamInfo <> invalid
    errorInfo.video_url = removeQueryParams(streamInfo.streamUrl)
  else if content <> invalid
    errorInfo.video_url = removeQueryParams(content.url)
  end if

  return errorInfo
End Function


' Helper function to check if an error code is a network retryable error
' @errorCode: integer, the video player error code
' @retryConfig: object, the retry configuration containing errorCodes map
' @returns: boolean, true if error code is in the network retryable error codes map
Function isNetworkRetryableError(errorCode as Integer, retryConfig as Object) as Boolean
  if retryConfig <> invalid AND retryConfig.network <> invalid AND retryConfig.network.errorCodes <> invalid
    errorCodeKey = errorCode.toStr()
    return retryConfig.network.errorCodes.DoesExist(errorCodeKey)
  end if
  return false
End Function


' Helper function to determine retry strategy based on error code
' @errorCode: integer, the video player error code
' @returns: string, the strategy to use: "retry_network", "fallback_codec", "fallback_drm", or "fatal"
Function getErrorRetryStrategy(errorCode as Integer) as String
  errorCodeKey = errorCode.toStr()
  if m.errorRetryStrategyMap.DoesExist(errorCodeKey)
    return m.errorRetryStrategyMap[errorCodeKey]
  else
    return "fatal"
  end if
End Function
