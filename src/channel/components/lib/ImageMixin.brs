' Replaces "{size} with either fhd or hd depending on the resolution the device is running at"
Function setImageUriSize(uri, constants = m.constants)
  searchFor = "{size}"
  if uri.instr(searchFor) >= 0
    if constants = invalid
      constants = getConstantsFromGlobal()
    end if
    resolution = "fhd"
    if constants.deviceInfo.scaledUi = true
      resolution = "hd"
    end if

    uri = uri.replace(searchFor, resolution)
  end if
  return uri
End Function
