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

  'magicLink
  m.requestTypes[m.constants.reqNames.magicLink] = {
    parseSuccess: parseMagicLinkSuccess
    parseError: parseMagicLinkError
  }

  'magic link polling
  m.requestTypes[m.constants.reqNames.queryStatusOfMagicLink] = {
    parseSuccess: parsequeryStatusOfMagicLinkSuccess
    parseError: parsequeryStatusOfMagicLinkError
  }

  'set Content Like/Dislike Rating
  m.requestTypes[m.constants.reqNames.setContentRating] = {
    parseSuccess: parseContentRateSuccess
    parseError: parseContentRateError
  }

  'updateParentalRating
  m.requestTypes[m.constants.reqNames.updateParentalRating] = {
    parseSuccess: parseUpdateParentalRatingSuccess
    parseError: parseUpdateParentalRatingError
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

  'tournamentScreen
  m.requestTypes[m.constants.reqNames.getTournamentScreen] = {
    parseSuccess: parseTournamentSuccess
    parseError: parseTournamentError
  }

  ' history
  m.requestTypes[m.constants.reqNames.postUserHistory] = {
    parseSuccess: parseHistorySuccess
  }

  'history delete
  m.requestTypes[m.constants.reqNames.deleteHistory] = {
    parseSuccess: parseDeleteFromHistorySuccess
    parseError: parseDeleteFromHistoryError
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

  'queue bookmarks
  m.requestTypes[m.constants.reqNames.postToQueue] = {
    parseSuccess: parseAddToQueueSuccess
    parseError: parseAddToQueueError
  }

  'delete queue bookmarks
  m.requestTypes[m.constants.reqNames.deleteFromQueue] = {
    parseSuccess: parseRemoveFromQueueSuccess
    parseError: parseRemoveFromQueueError
  }

    'screen saver get container
    m.requestTypes[m.constants.reqNames.getScreenSaverContainer] = {
      parseSuccess: parseGetScreenSaverContainerSuccess
      parseError: parseGenericError
    }

    'screen saver get home screen container ids
    m.requestTypes[m.constants.reqNames.getScreenSaverHomeScreenContainerIds] = {
      parseSuccess: parseGetScreenSaverHomeScreenContainerIdsSuccess
      parseError: parseGenericError
    }

End Function


Function getErrorCodeFromResponse(fullResponse)
  ' default code
  errCode = -1235

  if fullResponse <> invalid AND fullResponse.code <> invalid
    if fullResponse.code >= 200 AND fullResponse.code < 400
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
