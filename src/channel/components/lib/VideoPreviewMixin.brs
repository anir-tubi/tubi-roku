Function isVideoPreviewEnabled()
  if m.constants = invalid then
    m.constants = getConstantsFromGlobal()
  end if

  if m.constants.deviceInfo.isAutoplayEnabled = true

    if m.constants.deviceInfo.limitedUi = true then
      return false
    end if

    return true
  else
    return false
  end if

End Function
