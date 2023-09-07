Function isGDPR()
  gdprCountries = {
    "gb": true
    "nz": true
  }
  constants = getConstantsFromGlobal()
  lowerCountryCode = LCase(constants.deviceInfo.countryCode)
  return (gdprCountries.doesExist(lowerCountryCode) = true)
End Function