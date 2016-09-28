'define all the constants, like URLs that will be needed in the app
Function getConstants()
  constants = {}

  ' Compile-time generated
  constants.settings = getSettings()

  ' Device info
  constants.deviceInfo = {}
    di = CreateObject("roDeviceInfo")

    firmware = di.GetVersion() '034.08E01185A' string
    firmwareVersion = Val(Mid(firmware, 3, 4)) '4.08'  float
    firmwareVersionMajor = Val(Mid(firmware, 3, 1))  '4'  integer
    firmwareVersionMinor = Val(Mid(firmware, 5, 2))  '8'  integer
    firmwareBuild = Mid(firmware, 9, 4) '01185'  string

    if firmwareVersion >= 6.01 and not di.IsAdIdTrackingDisabled()
      deviceAdId = di.GetAdvertisingId()
    else
      deviceAdId = invalid
    end if

    if firmwareVersion >= 4.3
      countryCode = di.GetCountryCode()
    else
      countryCode = invalid
    end if

    if di.GetDisplayType() = "HDTV"
      definition = "hd"
    else
      definition = "sd"
    end if

    ' 256MB models, so we can reduce our expectations
    lowMemoryModels = {
      "2400X": true
  	  "2450X": true
      "2500X": true
      "2700X": true
      "2710X": true
      "2720X": true
      "3000X": true
      "3050X": true
      "3100X": true
      "3400X": true
      "3420X": true
    }
    if lowMemoryModels[di.GetModel()] <> invalid
      lowMemory = true
    else
      lowMemory = false
    end if

    constants.deviceInfo.deviceId = di.GetDeviceUniqueId()
    constants.deviceInfo.deviceAdId = deviceAdId 'will be invalid if ad tracking is turned off by user or old version of firmware
    constants.deviceInfo.ipAddresses = di.GetIPAddrs() 'array of network interface ip addresses (normally will only contain 1 element)
    constants.deviceInfo.firmwareVersion = firmwareVersion
    constants.deviceInfo.firmwareBuild = firmwareBuild
    constants.deviceInfo.userAgent = "Roku/DVP-" + firmwareVersionMajor.toStr() + "." + firmwareVersionMinor.toStr() + " (" + firmware + ")"
    constants.deviceInfo.userAgentModel = "Roku/DVP-" + firmwareVersionMajor.toStr() + "." + firmwareVersionMinor.toStr() + " (" + firmware + ") " + di.GetModel() 
    constants.deviceInfo.model = di.GetModel()
    constants.deviceInfo.definition = definition
    constants.deviceInfo.displayType = di.GetDisplayType()
    constants.deviceInfo.displayMode = di.GetDisplayMode()
    constants.deviceInfo.aspectRatio = di.GetDisplayAspectRatio()
    constants.deviceInfo.displaySize = di.GetDisplaySize()
    constants.deviceInfo.displayWidth = di.GetDisplaySize().w
    constants.deviceInfo.displayHeight = di.GetDisplaySize().h
    constants.deviceInfo.captionsMode = di.GetCaptionsMode()
    constants.deviceInfo.countryCode = countryCode ' will be invalid if old version of firmware
    constants.deviceInfo.lowMemory = lowMemory

  'the name of the top level scene in the scene graph XML
  constants.startScene = "AppScene"

  'the names of the registry memory sections that will save bookmark and previously viewed info
  constants.reqNames = {}
    constants.reqNames.getFullBookmarks = "getFullBookmarks" 
    constants.reqNames.getFullHistory = "getFullHistory"

  'Nielsen ID token for integrating with Nielsen DAR
  constants.nielsenToken = "PC60BD376-8551-4688-BEF4-E8B45A39D4C7"

  'platform is used when communitcating with CMS API
  constants.platform = "roku"

  'previously found in settings as "shortAppName"
  constants.appName = "tubitv"

  ' for Facebook AN4TV Application Detection library
  constants.fban4tvtoken = "1722980957943658|67139dcc7c459bada13b13bcd3cc51ee"

  constants.urls = {}
    'ad server url
    ' constants.urls.adsBaseUrl = "http://ads.adrise1.tv/" 'use to avoid getting ads during testing
    constants.urls.adsBaseUrl = "http://ads.adrise.tv/"

    'contents url
    constants.urls.cms = {}
      constants.urls.cms.urlBase = "https://uapi.adrise.tv/cms"
      constants.urls.cms.contents = constants.urls.cms.urlBase + "/contents"
      constants.urls.cms.singleContent = constants.urls.cms.urlBase + "/content"
      constants.urls.cms.categories = constants.urls.cms.urlBase + "/categories"

    'users url
    constants.urls.users = {}
      constants.urls.users.urlBase = "https://uapi.adrise.tv/user_device"
      constants.urls.users.refreshToken = constants.urls.users.urlBase + "/login/refresh"
      constants.urls.users.migrateLogin = constants.urls.users.urlBase + "/login/migrate"
      constants.urls.users.queues = constants.urls.users.urlBase + "/queues"
      constants.urls.users.history = constants.urls.users.urlBase + "/histories"


    'search url
    constants.urls.searchBaseUrl = "http://cms.adrise.com/"

    'user event tracking url
    constants.urls.dataScience = {}
      constants.urls.dataScience.urlBase = "https://uapi.adrise.tv/datascience"
      constants.urls.datascience.event = constants.urls.dataScience.urlBase + "/event"

    'cuepoints url
    constants.urls.cuepointsBaseUrl = "http://ads.adrise.tv/cue-points/"

    'linear schedule url
    constants.urls.linearUrl = "http://cms.adrise.com/v3/livetv?cid=roku&platform=roku&id=tubitv"

    'linear poster art urls'
    constants.urls.linearPosterSDUrl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-SD.jpg"
    constants.urls.linearPosterHDUrl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-HD.jpg"

    ' splash video
    constants.urls.splashVideoUrl = "http://c11.adrise.tv/v2/sources/content-owners/adrise-no-ads/321538/v201608050030-1280x720-,425,1062,1760,2128,3114,k.mp4.m3u8"

  'http request types
  constants.reqTypes = {}
    constants.reqTypes.get = "GET"
    constants.reqTypes.post = "POST"
    constants.reqTypes.put = "PUT"
    constants.reqTypes.del = "DELETE"

  'common http request headers
  constants.headers = {}
    constants.headers.json = {"Content-Type": "application/json"}

  'content type strings that we might get returned from uapi
  constants.uapiContentTypes = {}
    constants.uapiContentTypes.movie = "movie"
    constants.uapiContentTypes.series = "series"
    constants.uapiContentTypes.episode = "episode"

  'uapi actions - add or delete from user categories
  constants.uapiActions = {}
    constants.uapiActions.add = "add"
    constants.uapiActions.remove = "remove"


  'constants needed for the video player
  constants.player = {}

    'how often the video player sends play progress events
    constants.player.pingFrequency = 10

    'video player returns one of the following
    constants.player.playerResults = {}
      constants.player.playerResults.completed = "COMPLETED"
      constants.player.playerResults.closed = "CLOSED"
      constants.player.playerResults.failed = "FAILED"
      'used internal to the player, should never be returned
      constants.player.playerResults.commercial = "STOPFORCOMMERCIAL"
      constants.player.playerResults.ignore = "IGNORE"
      constants.player.playerResults.resumePlay = "RESUMEPLAY"

    'urls for the images that are required for the transport
    constants.player.transportImages = {}
      constants.player.transportImages.hd = {}
      constants.player.transportImages.hd.rw = "pkg://images/transport/hd/rw.png"
      constants.player.transportImages.hd.rwOrange = "pkg://images/transport/hd/rw_orange.png"
      constants.player.transportImages.hd.ff = "pkg://images/transport/hd/ff.png"
      constants.player.transportImages.hd.ffOrange = "pkg://images/transport/hd/ff_orange.png"
      constants.player.transportImages.hd.star = "pkg://images/transport/hd/star.png"
      constants.player.transportImages.hd.play = "pkg://images/transport/hd/play.png"
      constants.player.transportImages.hd.pauseSmall = "pkg://images/transport/hd/pause_small.png"
      constants.player.transportImages.hd.pauseBig = "pkg://images/transport/hd/pause_big.png"

      constants.player.transportImages.sd = {}
      constants.player.transportImages.sd.rw = "pkg://images/transport/sd/rw.png"
      constants.player.transportImages.sd.rwOrange = "pkg://images/transport/sd/rw_orange.png"
      constants.player.transportImages.sd.ff = "pkg://images/transport/sd/ff.png"
      constants.player.transportImages.sd.ffOrange = "pkg://images/transport/sd/ff_orange.png"
      constants.player.transportImages.sd.star = "pkg://images/transport/sd/star.png"
      constants.player.transportImages.sd.play = "pkg://images/transport/sd/play.png"
      constants.player.transportImages.sd.pauseSmall = "pkg://images/transport/sd/pause_small.png"
      constants.player.transportImages.sd.pauseBig = "pkg://images/transport/sd/pause_big.png"      


  'UI properties that should be passed into the scene graph
  constants.ui = {}

    'static - pre defined category names
    constants.ui.categoryNames = {}
      constants.ui.categoryNames.topCategory = "Featured"
      constants.ui.categoryNames.signedOutTools = "Search & Sign In"
      constants.ui.categoryNames.signedInTools = "Search & Sign Out"
      constants.ui.categoryNames.history = "Continue Watching"
      constants.ui.categoryNames.queue = "My Queue"

    constants.ui.text = {}
      'a default text to serve as the title of the page until the UI receives category information
      constants.ui.text.titleText = "Welcome to Tubi TV"

      constants.ui.text.defaultCategoryDescription = "You are now tuned in to Tubi TV. Your home for all the best content. If you love it, we got it."
      constants.ui.text.resumePlayButton = "Resume "
      constants.ui.text.playButton = "Play"
      constants.ui.text.playFromStartButton = "Play From Start"
      constants.ui.text.episodeListButton = "Episodes List"
      constants.ui.text.subtitlesButton = "Subtitles"
      constants.ui.text.addToQueueButton = "Add To Queue"
      constants.ui.text.removeFromQueueButton = "Remove From Queue"
      constants.ui.text.removeFromHistoryButton = "Remove From History"

    constants.ui.contentTypes = {}
      constants.ui.contentTypes.series = "series"
      constants.ui.contentTypes.video = "video"
      constants.ui.contentTypes.episode = "episode"
      constants.ui.contentTypes.season = "season"
      constants.ui.contentTypes.category = "category"

    'used as label ids in the videos options list
    constants.ui.options = {}
      constants.ui.options.resume = "resume"
      constants.ui.options.playOption = "playOption"
      constants.ui.options.episodes = "episodes"
      constants.ui.options.subtitles = "subtitles"
      constants.ui.options.removeQueue = "removeQueue"
      constants.ui.options.addQueue = "addQueue"
      constants.ui.options.removeHistory = "removeHistory"

    'allowed options for stateNode.rebuild
    constants.ui.rebuilds = {}
      constants.ui.rebuilds.clear = ""
      constants.ui.rebuilds.season = "season"
      constants.ui.rebuilds.episode = "episode"
      constants.ui.rebuilds.closePlayer = "closePlayer"

    'screen ids in the UI
    constants.ui.screenIds = {}
      constants.ui.screenIds.details = "detailScreen"
      constants.ui.screenIds.category = "categoryScreen"

    constants.ui.uris = {}
      'background gradient urls
      constants.ui.uris.homeBackgroundGradient = "pkg:/images/home-gradient-25.png"
      constants.ui.uris.detailBackgroundGradient = "pkg:/images/detail-gradient-25.png"

    constants.ui.colors = {}
      'template colors
      constants.ui.colors.transparent = "0x00000000"
      constants.ui.colors.backgroundColor = "0x000000FF"
      constants.ui.colors.focused = "0xFF9933FF"
      constants.ui.colors.unfocused = "0xFFFFFFFF"
      constants.ui.colors.primaryText = "0xFFFFFFFF"
      constants.ui.colors.secondaryText = "0x777777FF"
      constants.ui.colors.shade = "0x191919FF"
      constants.ui.colors.spinnerBox = "0x2C2C2CFF"

      'textbox text colors
      constants.ui.colors.unselectedEntryText = "0x191919FF"
      constants.ui.colors.selectedEntryText = "0xFF9933FF"
      constants.ui.colors.selectedEntryBox = "0xF4D8BCFF"
      constants.ui.colors.unselectedEntryBox = "0xFFFFFFFF"
      
      'colors for individual elements - can be made individual or controlled by template colors
      constants.ui.colors.heroFilter = constants.ui.colors.backgroundColor
      constants.ui.colors.titleHeader = constants.ui.colors.primaryText
      constants.ui.colors.titleMetaData = constants.ui.colors.secondaryText
      constants.ui.colors.titleDescription = constants.ui.colors.primaryText
      constants.ui.colors.focusedCategoryList = constants.ui.colors.focused
      constants.ui.colors.unfocusedCategoryList = constants.ui.colors.unfocused
      constants.ui.colors.categoryContentBorder = constants.ui.colors.focused
      constants.ui.colors.categoryContentInnerBorder = constants.ui.colors.backgroundColor
      constants.ui.colors.categoryListCursor = constants.ui.colors.focused
      constants.ui.colors.posterLabel = constants.ui.colors.primaryText
      constants.ui.colors.videoOptionsMainSelection = constants.ui.colors.focused
      constants.ui.colors.videoOptionsHistoryIndicator = constants.ui.colors.unfocused
      constants.ui.colors.videoOptionsMainSelectionText = constants.ui.colors.unfocused
      constants.ui.colors.focusedVideoOptions = constants.ui.colors.focused
      constants.ui.colors.unfocusedVideoOptions = constants.ui.colors.unfocused
      constants.ui.colors.videoOptionsCursor = constants.ui.colors.focused
      constants.ui.colors.seasonContentTitle = constants.ui.colors.primaryText
      constants.ui.colors.episodeBorder = constants.ui.colors.focused
      constants.ui.colors.episodeInnerBorder = constants.ui.colors.backgroundColor

    'x and y coordinates of where to place UI elements
    constants.ui.positions = {}
      constants.ui.positions.heroImage = [0, 0]
      constants.ui.positions.viewTitleArea = [47, 28]
      constants.ui.positions.titleHeader = [0, 0] 'relative to the viewTitleArea's origin
      constants.ui.positions.titleFirstContent = [0, 46] 'relative to the viewTitleArea's origin
      constants.ui.positions.titleSecondContent = [0, 70] 'relative to the viewTitleArea's origin
      ' constants.ui.positions.titleThirdContent = [0, 105] 'relative to the viewTitleArea's origin
      constants.ui.positions.categoryList = [47, 240]
      constants.ui.positions.categoryContent = [243, 240]
      constants.ui.positions.allCategoriesContent = [0, 0]
      constants.ui.positions.categoryContentItems = [0, 0]
      constants.ui.positions.categoryContentBorder = [0, 0]
      constants.ui.positions.categoryListCursor = [-8, 2]
      constants.ui.positions.posterLabel = [15, 115]
      constants.ui.positions.posterLabelGradient = [0, 99]
      constants.ui.positions.videoOptionsList = [47, 240]
      constants.ui.positions.videoOptionsMainSelection = [0, 0]
      constants.ui.positions.videoOptions = [14, 8]
      constants.ui.positions.videoOptionsHistoryIndicator = [0, 34]
      constants.ui.positions.videoOptionsNoHero = [1033, 64]
      constants.ui.positions.episodesGroup = [47, 238]
      constants.ui.positions.episodesContent = [0, 32]  'this is the row container, the episode poster will be offset vertically and horizontally by the width of border
      constants.ui.positions.episodesGroupSeasonTitles = [0, 0]
      constants.ui.positions.episodesBorderStart = [0, 32]

    'width and height sizes for UI elements
    constants.ui.sizes = {}
      constants.ui.sizes.logoHeight = constants.deviceInfo.displayHeight
      constants.ui.sizes.logoWidth = constants.deviceInfo.displayWidth
      constants.ui.sizes.heroImageHeight = constants.deviceInfo.displayHeight
      constants.ui.sizes.heroImageWidth = constants.deviceInfo.displayWidth
      constants.ui.sizes.heroFilterHeight = constants.deviceInfo.displayHeight
      constants.ui.sizes.heroFilterWidth = constants.deviceInfo.displayWidth
      constants.ui.sizes.viewTitleAreaHeight = 218
      constants.ui.sizes.viewTitleAreaWidth = 655
      constants.ui.sizes.viewTitleAreaHeaderTextHeight = 30 'this is given to the font node and represents a point measurement
      constants.ui.sizes.viewTitleAreaBodyTextHeight = 18  'this is given to the font node and represents a point measurement
      constants.ui.sizes.viewTitleAreaTextSpacing = -4 'used as line spacing between description lines
      constants.ui.sizes.viewTitleAreaSectionSpacing = 27 'used as line spacing between metadata section and description section
      constants.ui.sizes.titleHeader = constants.ui.sizes.viewTitleAreaWidth
      constants.ui.sizes.titleMetaDataWidth = constants.ui.sizes.viewTitleAreaWidth
      constants.ui.sizes.titleDescriptionWidth = constants.ui.sizes.viewTitleAreaWidth
      constants.ui.sizes.categoryListTextHeight = 18
      constants.ui.sizes.categoryListLineHeightAdjustor = 7
      constants.ui.sizes.categoryListCursorHeight = 20
      constants.ui.sizes.categoryListCursorWidth = 4
      constants.ui.sizes.categoryListWidth = 196
      constants.ui.sizes.categoryListHeight = 480
      constants.ui.sizes.categoryListSpacing = 25
      constants.ui.sizes.categoryContentItemsHeight = 480
      constants.ui.sizes.categoryContentItemsWidth = 1037
      constants.ui.sizes.categoryContentItemsVerticalSpacing = 15
      constants.ui.sizes.categoryContentItemsHorizontalSpacing = 15
      constants.ui.sizes.categoryContentItemsVerticalSpacingFeatured = 15
      constants.ui.sizes.categoryContentItemsHorizontalSpacingFeatured = 15
      constants.ui.sizes.categoryContentPosterHeight = 217
      constants.ui.sizes.categoryContentPosterWidth = 151
      constants.ui.sizes.categoryContentBorderThickness = 4
      constants.ui.sizes.categoryContentBorderHeight = 225
      constants.ui.sizes.categoryContentBorderWidth = 159
      constants.ui.sizes.categoryContentPosterHeightFeatured = 139
      constants.ui.sizes.categoryContentPosterWidthFeatured = 307
      constants.ui.sizes.categoryContentBorderHeightFeatured = 147
      constants.ui.sizes.categoryContentBorderWidthFeatured = 315
      constants.ui.sizes.categoryContentViewArea = [0.0, 0.0, 1273, 460]
      constants.ui.sizes.posterLabelWidth = constants.ui.sizes.categoryContentPosterWidthFeatured - constants.ui.positions.posterLabel[0]
      constants.ui.sizes.posterLabelTextHeight = 16 'this is given to the font node and represents a point measurement
      constants.ui.sizes.posterLabelGradientHeight = 40
      constants.ui.sizes.posterLabelGradientWidth = constants.ui.sizes.categoryContentPosterWidthFeatured
      constants.ui.sizes.videoOptionsMainSelectionHeight = 38
      constants.ui.sizes.videoOptionsMainSelectionWidth = 215
      constants.ui.sizes.videoOptionsHistoryIndicatorHeight = 4
      constants.ui.sizes.videoOptionsHistoryIndicatorWidth = constants.ui.sizes.videoOptionsMainSelectionWidth
      constants.ui.sizes.videoOptionsTextHeight = 18
      constants.ui.sizes.videoOptionsLabelWidth = 200
      constants.ui.sizes.videoOptionsLabelHeight = 38
      constants.ui.sizes.videoOptionsLabelVerticalSpacing = 38
      constants.ui.sizes.viewOptionsListCursorHeight = constants.ui.sizes.categoryListCursorHeight
      constants.ui.sizes.viewOptionsListCursorWidth = constants.ui.sizes.categoryListCursorWidth
      constants.ui.sizes.viewOptionsListCursorOffsetVertical = 2
      constants.ui.sizes.viewOptionsListCursorOffsetHorizontal = -10
      constants.ui.sizes.videoOptionsNoHeroHeight = 287
      constants.ui.sizes.videoOptionsNoHeroWidth = 200
      constants.ui.sizes.episodesGroupPosterHeight = constants.ui.sizes.categoryContentPosterHeightFeatured
      constants.ui.sizes.episodesGroupPosterWidth = constants.ui.sizes.categoryContentPosterWidthFeatured
      constants.ui.sizes.episodesGroupPosterVerticalSpacing = 0
      constants.ui.sizes.episodesGroupPosterHorizontalSpacing = 15
      constants.ui.sizes.seasonTextHeight = 18
      constants.ui.sizes.episodeTextHeight = 16
      constants.ui.sizes.seasonContentHeight = 175
      constants.ui.sizes.seasonContentWidth = 0
      constants.ui.sizes.seasonContentVerticalSpacing = 18
      constants.ui.sizes.seasonContentTitleHeight = 18
      constants.ui.sizes.seasonContentTitleWidth = constants.ui.sizes.seasonContentWidth
      constants.ui.sizes.episodeContentWidth = 1233
      constants.ui.sizes.episodeContentHeight = 139
      constants.ui.sizes.episodesGroupViewArea = [0.0, 0.0, 1273, 460]
      constants.ui.sizes.episodeBorderHeight = constants.ui.sizes.categoryContentBorderHeightFeatured
      constants.ui.sizes.episodeBorderWidth = constants.ui.sizes.categoryContentBorderWidthFeatured


    'amounts that may be used throughout the UI
    constants.ui.amounts = {}
      constants.ui.amounts.loadedPosters = 42 'used to determine how many posters to initialize in a category
      constants.ui.amounts.posterBuffer = 14
      constants.ui.amounts.maxPosters = 42 'used to determine the max amount of posters in a category allowed at one time
      constants.ui.amounts.categoryReplaceWait = 0.5 'number of seconds to wait before updating category contents
      constants.ui.amounts.viewTitleAreaDescriptionMaxLines = 4
      constants.ui.amounts.categoryContentItemsNumRows = 2
      constants.ui.amounts.categoryContentItemsNumRowsFeatured = 3
      constants.ui.amounts.seasonContentNumRows = 1
      constants.ui.amounts.numVisibleEpisodes = 3
      constants.ui.amounts.numVisibleSeasons = 2

    'fonts for UI elmements
    constants.ui.fonts = {}
      constants.ui.fonts.openSans = {}
        constants.ui.fonts.openSans.regular = "pkg:/fonts/OpenSans-Regular.ttf"
        constants.ui.fonts.openSans.bold = "pkg:/fonts/OpenSans-Bold.ttf"
        constants.ui.fonts.openSans.semiBold = "pkg:/fonts/OpenSans-Semibold.ttf"
        constants.ui.fonts.openSans.italics = "pkg:/fonts/OpenSans-Italic.ttf"
        constants.ui.fonts.openSans.light = "pkg:/fonts/OpenSans-Light.ttf"

      constants.ui.fonts.categoryListFontType = constants.ui.fonts.openSans.light
      constants.ui.fonts.viewTitleAreaHeaderFontType = constants.ui.fonts.openSans.semiBold
      constants.ui.fonts.viewTitleAreaBodyFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.posterLabelFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.videoOptionsFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.seasonFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.episodeFontType = constants.ui.fonts.openSans.regular

    'boolean settings for UI elements
    constants.ui.booleans = {}
      constants.ui.booleans.isPosterLabelVisible = false
      constants.ui.booleans.isPosterLabelVisibleFeatured = true
      constants.ui.booleans.isEpisodeLabelVisible = true

  return constants  
end Function
