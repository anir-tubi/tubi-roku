Function isVideoPreviewEnabled()
  if m.constants = Invalid then
    m.constants = getConstantsFromGlobal()
  end if

  if m.constants.deviceInfo.limitedUi = true then
    return false
  end if

  return getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled
End Function
