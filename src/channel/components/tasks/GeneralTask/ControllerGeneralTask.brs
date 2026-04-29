
' sets requestTypes with various success and error callbacks
' add new assocarray (api requestType key & value) into m.requestTypes to handle new api parsing
Function registerParsingCallbacks()
  ' generic requests
  m.requestTypes[m.constants.reqNames.generic] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.genericWithResponseContext] = {
    parseSuccess: parseGenericWithResponseContextSuccess
    parseError: parseGenericWithResponseContextError
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

  m.requestTypes[m.constants.reqNames.signUpForKids] = {
    parseSuccess: parseSignUpSuccessForKids
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

  'get Content Like/Dislike Rating
  m.requestTypes[m.constants.reqNames.getContentRating] = {
    parseSuccess: parseGetContentRatingSuccess
    parseError: parseGenericError
  }

  'set Content Like/Dislike Rating
  m.requestTypes[m.constants.reqNames.setContentRating] = {
    parseSuccess: parseContentRateSuccess
    parseError: parseContentRateError
  }

  'updateParentalRating
  m.requestTypes[m.constants.reqNames.updateParentalRating] = {
    parseSuccess: parseUpdateParentalRatingSuccess
    parseError: parseGenericError
  }

  'updateParentalRatingForKidsAccount
  m.requestTypes[m.constants.reqNames.patchKidsParentalRating] = {
    parseSuccess: parseUpdateParentalRatingSuccess
    parseError: parseGenericError
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

  ' autopilot related content
  m.requestTypes[m.constants.reqNames.getRelatedContent] = {
    parseSuccess: parseDetailScreenRelatedContentSuccess
    parseError: parseGenericError
  }

  ' season list by series ID
  m.requestTypes[m.constants.reqNames.getSeasonListBySeriesId] = {
    parseSuccess: parseSeasonListSuccess
    parseError: parseGenericError
  }

  ' series episodes by season
  m.requestTypes[m.constants.reqNames.getSeriesEpisodesBySeason] = {
    parseSuccess: parseSeriesEpisodesBySeasonSuccess
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
    passRawResponse: true
  }

  ' minihomescreen
  m.requestTypes[m.constants.reqNames.getMiniHomescreen] = {
    parseSuccess: parseMiniHomeScreenContentSuccess
    parseError: parseGenericError
  }

  ' category
  ' Crash debugging so making local variable to have it show up in crash report
  reqNamesGetCategory = m.constants.reqNames.getCategory
  m.requestTypes[reqNamesGetCategory] = {
    parseSuccess: parseCategoryContentSuccess
    parseError: parseCategoryContentError
  }

  ' getAutocomplete
  ' Crash debugging so making local variable to have it show up in crash report
  reqNamesGetAutocomplete = m.constants.reqNames.getAutocomplete
  m.requestTypes[reqNamesGetAutocomplete] = {
    parseSuccess: parseAutocompleteAPISuccess
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

  ' homescreen ads
  m.requestTypes[m.constants.reqNames.getHomescreenAds] = {
    parseSuccess: parseHomeScreenAdsSuccess
    parseError: parseHomeScreenAdsError
  }

  ' video player scrubber showcase ads
  m.requestTypes[m.constants.reqNames.getVideoPlayerScrubberShowcase] = {
    parseSuccess: parseVideoPlayerScrubberShowcaseSuccess
    parseError: parseVideoPlayerScrubberShowcaseError
  }

  ' sponsored hub ads
  m.requestTypes[m.constants.reqNames.getSponsoredHubAds] = {
    parseSuccess: parseSponsoredHubAdsSuccess
    parseError: parseSponsoredHubAdsError
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

  ' my stuff screen
  m.requestTypes[m.constants.reqNames.getMyStuffContainers] = {
    parseSuccess: parseCategoryMyStuffContentSuccess
    parseError: parseGenericError
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
    parseSuccess: parseGetUserSettingsSuccess
    parseError: parseGenericError
  }

  ' posts tracking request.
  m.requestTypes[m.constants.reqNames.postAnalytics] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  ' external config request
  m.requestTypes[m.constants.reqNames.getExternalConfigs] = {
    parseSuccess: parseGetExternalConfigSuccess
    parseError: parseGenericError
  }

  'tubi experiments.
  m.requestTypes[m.constants.reqNames.getNamespaces] = {
    parseSuccess: parseTubiExperimentsNamespaceRequestSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.getSoTStaticConfig] = {
    parseSuccess: parseSoTStaticConfigSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.statsigInitialize] = {
    parseSuccess: parseStatsigLibInitializeSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.getEpgListing] = {
    parseSuccess: parseEpgListingSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.validatePassword] = {
    parseSuccess: parseValidatePasswordSuccess
    parseError: parseValidatePasswordError
  }

  m.requestTypes[m.constants.reqNames.validatePin] = {
    parseSuccess: parseValidatePinSuccess
    parseError: parseValidatePinError
  }

  m.requestTypes[m.constants.reqNames.postPinUpdateForKids] = {
    parseSuccess: parseUpdatePinSuccess
    parseError: parseUpdatePinError
  }

  m.requestTypes[m.constants.reqNames.fetchStatsigExperimentsActive] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.fetchStatsigExperimentsPaused] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.getCollection] = {
    parseSuccess: parseCollectionSuccess
    parseError: parseGenericError
    passRawResponse: true
  }

  m.requestTypes[m.constants.reqNames.getAllPivots] = {
    parseSuccess: parsePivotsSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.getPivotContainers] = {
    parseSuccess: parsePivotContainersSuccess
    parseError: parseGenericError
    passRawResponse: true
  }

  m.requestTypes[m.constants.reqNames.getBranchManifest] = {
    parseSuccess: parseGenericSuccess
    parseError: parseGenericError
  }

  m.requestTypes[m.constants.reqNames.createOTP] = {
    parseSuccess: parseCreateOTPSuccess
    parseError: parseSignInError
  }
End Function


' Called from the base general task listen method. Below overridden method will be used to register helpers/utilities.
Function instantiateLibs()
  m.experiments = TubiExperiments(m.experimentsInfo)
  m.statSigExperiments = StatsigExperimentsInterface(m.statSigExperimentsInfo)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, m.experiments, m.soTStaticConfig, m.statSigExperiments)
End Function
