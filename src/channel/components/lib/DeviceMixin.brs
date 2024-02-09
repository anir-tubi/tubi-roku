Function isGDPR(constants = invalid)
  gdprCountries = {
    "gb": true
    "nz": true
  }

  if constants = invalid
    constants = getConstantsFromGlobal()
  end if

  if constants <> invalid
    lowerCountryCode = LCase(constants.deviceInfo.countryCode)
    return (gdprCountries.doesExist(lowerCountryCode) = true)
  else
    ' default to true for least amount of risk
    return true
  end if
End Function