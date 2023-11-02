' Populates the info panel with the fields necessary for the "item" mode so that it looks
' like the info panel on the homescreen
'
' @content: TubiContentNode, containing a movie or series
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node
Function populateInfoPanelWithHomescreenStyleItemMode(content, infoPanel)
  ' used by homescreen, category details screen, tournament screen, etc.
  ' IMPORTANT, still need to call infoPanel.calculateHeight after calling this function
  infoPanel.mode = m.constants.ui.infoPanelModes.item
  infoPanel.title = content.title
  infoPanel.description = content.description

  lineOneData = {}
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)
  lineOneData.rating = content.rating

  rating = UCase(content.rating)
  if FALSE AND (rating = "R" OR rating = "TV-MA" OR rating = "TV-14" OR rating = "NC-17" OR rating = "NR") AND m.constants.deviceinfo.countrycode = "US"
    getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v1")
  end if

  lineOneData.partnerLogoUri = content.inlineLogoUri

  if content.type = m.constants.ui.contentTypes.series
    lineOneData.type = m.constants.ui.contentTypes.series
    ' lineOneData.seasons =  '//If available, get the number of seasons and set the value here
  end if

  if content.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
    lineOneData.has4k = true
  end if

  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if

  lineTwoData = {
    genres: content.genres
  }

  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = lineTwoData
  infoPanel.needsLogin = (content.needsLogin = true)
  infoPanel.reminderIsSet = false
  infoPanel.width = 960
End Function


' Populates the info panel with the fields necessary for the "sportsEvent" mode so that it looks
' like the info panel on the homescreen
'
' @content: TubiContentNode, containing a sports event
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node
Function populateInfoPanelWithHomescreenStyleSportsMode(content, infoPanel)
  infoPanel.mode = m.constants.ui.infoPanelModes.sportsEvent
  infoPanel.title = content.title

  hasVideoresources = content.hasVideoresources
  airDatetime = content.airDatetime
  info = getAvailabilityTypeBadgeAndMatchTimeValues(airDatetime, hasVideoresources)
  matchTime = info.matchTime
  badgeText = info.badgeText
  availabilityType = info.availabilityType

  lineOneData = {}
  lineOneData.roundGroupInfo = content.roundGroupInfo

  lineOneData.badgeText = badgeText
  lineOneData.hasCC = content.hasSubtitles
  lineOneData.length = content.length

  if availabilityType <> m.constants.ui.contentTimings.upcoming
    lineOneData.hoursOfAiring = matchTime
  end if

  if content.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
    lineOneData.has4k = true
  end if

  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = {
    roundGroupInfo: content.roundGroupInfo
  }
  infoPanel.reminderIsSet = (availabilityType = m.constants.ui.contentTimings.upcoming AND getBookmark(content.id) <> invalid)
  infoPanel.needsLogin = (content.needsLogin AND m.top.signedIn <> true)
  infoPanel.width = 960
End Function


' Populates the info panel with the fields necessary for the Linear programs in homeScreen(linear content on non-linear category) mode so that it looks
' like the info panel on the homescreen
'
' @content: TubiContentNode, containing a linear channel with programs as children
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node

Function populateInfoPanelWithProgramHomescreenMode(content, infoPanel)
  infoPanel.mode = m.constants.ui.infoPanelModes.programHomescreen
  '//TODO - Check if we use thumbnail URIs here or inlineLogoUri ??
  infoPanel.topHeaderImageUri = content.inlineLogoUri

  currentProgram = getCurrentLiveProgram(content)
  badgeText = ""
  programTime = ""
  infoPanel.description = content.description

  if currentProgram <> invalid
    infoPanel.title = currentProgram.title
    infoPanel.episodeTitle = currentProgram.epgProgramTitle
    badgeText = UCase(getTranslation("screenSearch_liveText"))
    programTime = currentProgram.hoursOfAiring
    infoPanel.description = currentProgram.description
  else
    infoPanel.description = content.description
    infoPanel.title = content.title
  end if

  lineOneData = {}
  lineOneData.badgeText = badgeText
  lineOneData.hasCC = content.hasSubtitles
  lineOneData.hoursOfAiring = programTime

  infoPanel.lineOneData = lineOneData

  infoPanel.needsLogin = (content.needsLogin AND m.top.signedIn <> true)
  infoPanel.width = 960
End Function
