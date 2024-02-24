
' sets requestTypes with various success and error callbacks
' add new assocarray (api requestType key & value) into m.requestTypes to handle new api parsing
Function registerParsingCallbacks()
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

  ' Remove parseDetailScreenSingleContentError and change back to parseGenericError once we figure out the root cause of series
  ' invalid for component interaction events.
  '
  ' single content
  m.requestTypes[m.constants.reqNames.getSingleContent] = {
    parseSuccess: parseDetailScreenSingleContentSuccess
    parseError: parseDetailScreenSingleContentError
  }

  ' multiple content
  m.requestTypes[m.constants.reqNames.getMultipleContent] = {
    parseSuccess: parseMultipleContentSuccess
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

  ' post history
  m.requestTypes[m.constants.reqNames.postUserHistory] = {
    parseSuccess: parseHistorySuccess
  }

  'history delete
  m.requestTypes[m.constants.reqNames.deleteHistory] = {
    parseSuccess: parseDeleteFromHistorySuccess
    parseError: parseDeleteFromHistoryError
  }

  'get history list
  m.requestTypes[m.constants.reqNames.getHistory] = {
    parseSuccess: parseGetHistoryIdsSuccess
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

  'get queue bookmarks list
  m.requestTypes[m.constants.reqNames.getQueue] = {
    parseSuccess: parseGetQueueIdsSuccess
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

  'screen saver get container
  m.requestTypes[m.constants.reqNames.getScreensaverContainer] = {
    parseSuccess: parseGetScreensaverContainerSuccess
    parseError: parseGenericError
  }

  'screen saver get home screen container ids
  m.requestTypes[m.constants.reqNames.getScreensaverHomeScreenContainerIds] = {
    parseSuccess: parseGetScreensaverHomeScreenContainerIdsSuccess
    parseError: parseGenericError
  }

  ' my stuff screen
  m.requestTypes[m.constants.reqNames.getMyStuffContainers] = {
    parseSuccess: parseCategoryMyStuffContentSuccess
    parseError: parseGenericError
  }

  'queue bookmarks
  m.requestTypes[m.constants.reqNames.postToQueue] = {
    parseSuccess: parseAddToQueueSuccess
    parseError: parseAddToQueueError
  }

  ' gets the list of user/device level server persistent data.
  m.requestTypes[m.constants.reqNames.getServerPersistentData] = {
    parseSuccess: parseGetServerPersistentData
    parseError: parseGenericError
  }

  ' pauseAds
  m.requestTypes[m.constants.reqNames.getPauseAd] = {
    parseSuccess: parsePauseAdSuccess
  }

  ' Get Consent.
  m.requestTypes[m.constants.reqNames.getConsent] = {
    parseSuccess: parseGetConsent
  }

  ' Patch Consent.
  m.requestTypes[m.constants.reqNames.patchConsent] = {
    parseSuccess: parseGenericSuccess
  }

  ' gets the list of user/device level server persistent data.
  m.requestTypes[m.constants.reqNames.getUserSettings] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  ' gets the list of user/device level server persistent data.
  m.requestTypes[m.constants.reqNames.getDsarQrCode] = {
    parseSuccess: parseGenericSuccess
  }
End Function


' Called from the base general task listen method. Below overridden method will be used to register helpers/utilities.
Function instantiateLibs()
  experiments = TubiExperiments(m.constants)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)
End Function
