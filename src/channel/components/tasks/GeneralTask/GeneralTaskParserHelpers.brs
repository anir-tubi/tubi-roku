' createParsingCallbacks
' 
' sets requestTypes with various success and error callbacks
' add new assocarray (api requestType key & value) into m.requestTypes to handle new api parsing
Function createParsingCallbacks()

  m.requestTypes = {}

  ' sprites
  m.requestTypes[m.constants.reqNames.getThumbnails] = {
    parseSuccess: parseVideoScreenSpritesSuccess
  }

  ' up next / autoplay
  m.requestTypes[m.constants.reqNames.getUpNextContent] = {
    parseSuccess: parseVideoScreenUpNextSuccess
    parseError: parseVideoScreenUpNextError
  }

  ' live manifest
  m.requestTypes[m.constants.reqNames.getLiveManifest] = {
    parseSuccess: parseLiveVideoManifestSuccess
    parseError: parseLiveVideoManifestError
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
    parseError: parseDetailScreenSingleContentError
  }

  ' related content
  m.requestTypes[m.constants.reqNames.getRelatedContent] = {
    parseSuccess: parseDetailScreenRelatedContentSuccess
  }

  ' channel guide
  m.requestTypes[m.constants.reqNames.getChannelGuide] = {
    parseSuccess: parseChannelGuideFetchSuccess
    parseError: parseChannelGuideFetchError
  }

  ' history
  m.requestTypes[m.constants.reqNames.postUserHistory] = {
    parseSuccess: parseHistorySuccess
  }

  ' homescreen
  m.requestTypes[m.constants.reqNames.getHomescreen] = {
    parseSuccess: parseHomeScreenContentSuccess
    parseError: parseHomeScreenContentError
  }

  ' category
  m.requestTypes[m.constants.reqNames.getCategory] = {
    parseSuccess: parseCategoryContentSuccess
    parseError: parseCategoryContentError
  }
  
  ' getSearchScreen
  m.requestTypes[m.constants.reqNames.getSearchScreen] = {
    parseSuccess: parseSearchAPISuccess
    parseError: parseSearchAPIError
  }

  ' search default
  m.requestTypes[m.constants.reqNames.getSearchDefault] = {
    parseSuccess: parseDefaultSearchSuccess
    parseError: parseDefaultSearchError
  }

  ' category list screen
  m.requestTypes[m.constants.reqNames.getCategoriesListScreen] = {
    parseSuccess: parseCategoryListSuccess
    parseError: parseCategoryListError
  }

  ' category details screen
  m.requestTypes[m.constants.reqNames.getCategoryDetailsScreen] = {
    parseSuccess: parseCategoryDetailsSuccess
    parseError: parseCategoryDetailsError
  }

End Function


Function getErrorCodeFromResponse(fullResponse)
  ' default code
  errCode = -1235
  
  if fullResponse <> invalid and fullResponse.code <> invalid
    ' HTTP or Curl code
    errCode = fullResponse.code
  else
    deviceInfo = CreateObject("roDeviceInfo")
    if deviceInfo.GetLinkStatus() = false
      ' firmware thinks the device does not have internet access
      errCode = -1236
    end if
  end if

  return errCode
End Function