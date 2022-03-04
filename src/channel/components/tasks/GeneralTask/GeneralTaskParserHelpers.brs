' createParsingCallbacks
' 
' sets requestTypes with various success and error callbacks
' add new assocarray (api requestType key & value) into m.requestTypes to handle new api parsing
Function createParsingCallbacks()

  m.requestTypes = {}

  ' generic requests
  m.requestTypes[m.constants.reqNames.generic] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  ' sprites
  m.requestTypes[m.constants.reqNames.getThumbnails] = {
    parseSuccess: parseVideoScreenSpritesSuccess
  }

  ' up next / autoplay
  m.requestTypes[m.constants.reqNames.getUpNextContent] = {
    parseSuccess: parseVideoScreenUpNextSuccess
    parseError: parseGenericError
  }

  ' live manifest
  m.requestTypes[m.constants.reqNames.getLiveManifest] = {
    parseSuccess: parseLiveVideoManifestSuccess
    parseError: parseGenericError
  }

  ' email exists
  m.requestTypes[m.constants.reqNames.emailExists] = {
    parseSuccess: parseEmailExistsSuccess
    parseError: parseEmailExistsError
  }

  ' signup
  m.requestTypes[m.constants.reqNames.signUp] = {
    parseSuccess: parseSignUpSuccess
    parseError: parseSignUpError
  }  

  ' signin
  m.requestTypes[m.constants.reqNames.signIn] = {
    parseSuccess: parseSignInSuccess
    parseError: parseSignInError
  }

  ' device register (check age)
  m.requestTypes[m.constants.reqNames.deviceRegister] = {
    parseSuccess: parseAgeVerificationScreenDeviceRegistrationSuccess
    parseError: parseAgeVerificationScreenDeviceRegistrationError
  }

  ' check birthday (check if birthday exists for logged in user)
  m.requestTypes[m.constants.reqNames.checkBirthdayInfo] = {
    parseSuccess: parseAgeVerificationScreenCheckBirthdaySuccess
    parseError: parseAgeVerificationScreenCheckBirthdayError
  }

  ' single content
  m.requestTypes[m.constants.reqNames.getSingleContent] = {
    parseSuccess: parseDetailScreenSingleContentSuccess
    parseError: parseGenericError
  }

  ' related content
  m.requestTypes[m.constants.reqNames.getRelatedContent] = {
    parseSuccess: parseDetailScreenRelatedContentSuccess
  }

  ' channel guide
  m.requestTypes[m.constants.reqNames.getChannelGuide] = {
    parseSuccess: parseChannelGuideFetchSuccess
    parseError: parseGenericError
  }

  'epgChannelIds
  m.requestTypes[m.constants.reqNames.getEPGChannelIds] = {
    parseSuccess: parseEPGChannelIdsSuccess
    parseError: parseEPGChannelIdsError
  }

  'epgProgram
  m.requestTypes[m.constants.reqNames.getEPGPrograms] = {
    parseSuccess: parseEPGProgramsSuccess
    parseError: parseEPGProgramsError
  }

  ' history
  m.requestTypes[m.constants.reqNames.postUserHistory] = {
    parseSuccess: parseHistorySuccess
  }

  ' homescreen
  m.requestTypes[m.constants.reqNames.getHomescreen] = {
    parseSuccess: parseHomeScreenContentSuccess
    parseError: parseGenericError
  }

  ' category
  m.requestTypes[m.constants.reqNames.getCategory] = {
    parseSuccess: parseCategoryContentSuccess
    parseError: parseGenericError
  }

  ' getSearchScreen
  m.requestTypes[m.constants.reqNames.getSearchScreen] = {
    parseSuccess: parseSearchAPISuccess
    parseError: parseGenericError
  }

  ' search default
  m.requestTypes[m.constants.reqNames.getSearchDefault] = {
    parseSuccess: parseDefaultSearchSuccess
    parseError: parseGenericError
  }

  ' category list screen
  m.requestTypes[m.constants.reqNames.getCategoriesListScreen] = {
    parseSuccess: parseCategoryListSuccess
    parseError: parseCategoryListError
  }

  ' category details screen
  m.requestTypes[m.constants.reqNames.getCategoryDetailsScreen] = {
    parseSuccess: parseCategoryDetailsSuccess
    parseError: parseGenericError
  }

End Function


Function getErrorCodeFromResponse(fullResponse)
  ' default code
  errCode = -1235
  
  if fullResponse <> invalid and fullResponse.code <> invalid
    if fullResponse.code >= 200 and fullResponse.code < 400
      ' got a valid response code from the server, but there was some other issue with the response
      errCode = -1237
    else
      ' HTTP or Curl code
      errCode = fullResponse.code
    end if
  else
    deviceInfo = CreateObject("roDeviceInfo")
    if deviceInfo.GetLinkStatus() = false
      ' firmware thinks the device does not have internet access
      errCode = -1236
    end if
  end if

  return errCode
End Function