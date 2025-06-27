' Populates the info panel with the fields necessary for the "item" mode so that it looks
' like the info panel on the homescreen
'
' @content: TubiContentNode, containing a movie or series
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node
Function populateInfoPanelWithHomescreenStyleItemMode(content, infoPanel)
  tubiLog("InfoPanelMixin.populateInfoPanelWithHomescreenStyleItemMode")
  ' used by homescreen, category details screen etc.
  ' IMPORTANT, still need to call infoPanel.calculateHeight after calling this function
  lineOneData = {}
  mode = m.constants.ui.infoPanelModes.item
  lineOneData.length = content.length
  lineTwoData = {
    genres: content.genres
  }

  if isNonEmptyString(content.rottenTomatoScore) = true
    lineTwoData.rottenTomatoText = content.rottenTomatoScore
  end if
  infoPanel.description = content.description

  infoPanel.mode = mode
  infoPanel.title = content.title

  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR (content.subtitleTracks <> invalid AND content.subtitleTracks.isEmpty() = false))
  lineOneData.hasAudioDescription = content.hasAudioDescription
  lineOneData.rating = content.rating
  lineOneData.partnerLogoUri = content.inlineLogoUri

  if content.type = m.constants.ui.contentTypes.series
    lineOneData.type = m.constants.ui.contentTypes.series
    ' lineOneData.seasons =  '//If available, get the number of seasons and set the value here
  end if

  fullHDBadgeText = ""
  if isNonEmptyString(content.resolution) = true
    resolution = content.resolution
    if resolution = "1080" AND getExperimentResource("roku_1080p_resolution", "roku_1080p_resolution_v1").enabled = true
      fullHDBadgeText = getTranslation("resolution_full_hd")
      lineOneData.fullHDBadgeText = fullHDBadgeText
    else if resolution = "2160" then
      lineOneData.has4k = true
    end if
  end if

  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if

  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = lineTwoData
  if content.needsLogin = true
    infoPanel.loginReason = content.loginReason
    infoPanel.needsLogin = true
  else
    infoPanel.needsLogin = false
  end if
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
  tubiLog("InfoPanelMixin.populateInfoPanelWithHomescreenStyleSportsMode")

  infoPanel.title = content.title

  hasVideoresources = content.hasVideoresources
  airDatetime = content.airDatetime
  info = getAvailabilityTypeBadgeAndMatchTimeValues(airDatetime, hasVideoresources)
  matchTime = info.matchTime
  availabilityType = info.availabilityType

  lineOneData = {}
  lineOneData.badgeText = info.badgeText
  lineOneData.hasCC = content.hasSubtitles
  lineOneData.hasAudioDescription = content.hasAudioDescription
  lineOneData.length = content.length

  if availabilityType <> m.constants.ui.contentTimings.upcoming
    lineOneData.hoursOfAiring = matchTime
  end if

  fullHDBadgeText = ""
  if isNonEmptyString(content.resolution) = true
    resolution = content.resolution
    if resolution = "1080" AND getExperimentResource("roku_1080p_resolution", "roku_1080p_resolution_v1").enabled = true
      fullHDBadgeText = getTranslation("resolution_full_hd")
      lineOneData.fullHDBadgeText = fullHDBadgeText
    else if resolution = "2160" then
      lineOneData.has4k = true
    end if
  end if

  lineTwoData = {}

  infoPanel.mode = m.constants.ui.infoPanelModes.sportsEvent
  lineTwoData.roundGroupInfo = content.roundGroupInfo

  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = lineTwoData

  infoPanel.reminderIsSet = (availabilityType = m.constants.ui.contentTimings.upcoming AND getBookmark(content.id) <> invalid)
  if content.needsLogin = true AND m.top.signedIn <> true
    infoPanel.loginReason = content.loginReason 'set loginReason before needs Login
    infoPanel.needsLogin = true
  else
    infoPanel.needsLogin = false
  end if
End Function


' Populates the info panel with the fields necessary for the Linear programs in homeScreen(linear content on non-linear category) mode so that it looks
' like the info panel on the homescreen
'
' @content: TubiContentNode, containing a linear channel with programs as children
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node

Function populateInfoPanelWithLinearProgramHomescreenMode(content, infoPanel)
  tubiLog("InfoPanelMixin.populateInfoPanelWithLinearProgramHomescreenMode")
  currentProgram = getCurrentLiveProgram(content)

  infoPanel.mode = m.constants.ui.infoPanelModes.linearProgramHomescreen

  releaseDate = ""
  timeLeft = ""
  duration = ""
  channelTitle = ""
  leagueName = ""
  rating = ""
  genres = []
  lineOneData = {}

  infoPanel.description = content.description

  if currentProgram <> invalid
    programTitle = currentProgram.title
    infoPanel.title = programTitle
    if currentProgram.epgProgramTitle <> programTitle
      infoPanel.episodeTitle = currentProgram.epgProgramTitle
    end if

    releaseDate = currentProgram.releaseDate
    infoPanel.description = currentProgram.description

    channelTitle = content.title
    if UCase(programTitle) = UCase(channelTitle)
      '//If the channel name is the same as the video title, then no need to display the channel name
      channelTitle = ""
    end if

    rating = currentProgram.rating
    timeleft = calculateProgramTimeLeft(currentProgram)
    genres = currentProgram.genres

    if currentProgram.live = false OR currentProgram.epgProgramType <> m.constants.ui.contentTypes.sportsEvent 'live news
      prgLength = currentProgram.endTime - currentProgram.startTime
      if prgLength > 0
        duration = formatLengthAsHourAndMins(prgLength)
      else if currentProgram.hoursOfAiring <> invalid AND currentProgram.hoursOfAiring <> ""
        startTime = currentProgram.hoursOfAiring.tokenize(" - ")[0]
        duration = getTranslation("epg_started_at") + " " + startTime
      end if
    else
      infoPanel.liveBadgeHeaderText = ""
      if currentProgram.epgProgramType = m.constants.ui.contentTypes.sportsEvent AND currentProgram.live = true
        if currentProgram.hoursOfAiring <> invalid AND currentProgram.hoursOfAiring <> ""
          startTime = currentProgram.hoursOfAiring.tokenize(" - ")[0]
          duration = getTranslation("epg_started_at") + " " + startTime
        end if
        'show the league name only for sports Events which are live
        leagueName = currentProgram.leagueName
      end if
    end if
  else
    infoPanel.description = content.description
    infoPanel.episodeTitle = ""
    infoPanel.title = content.title
    rating = content.rating
    releaseDate = content.releaseDate
    genres = content.genres
  end if

  lineOneData.releaseDate = releaseDate
  lineOneData.programLength = duration
  lineOneData.hasCC = content.hasSubtitles
  lineOneData.programTimeLeft = timeleft
  lineOneData.rating = rating

  fullHDBadgeText = ""
  if isNonEmptyString(content.resolution) = true
    resolution = content.resolution
    if resolution = "1080" AND getExperimentResource("roku_1080p_resolution", "roku_1080p_resolution_v1").enabled = true
      fullHDBadgeText = getTranslation("resolution_full_hd")
      lineOneData.fullHDBadgeText = fullHDBadgeText
    end if
  end if


  lineTwoData = {}
  ' if league is available, show it in the second line, else show genres
  if leagueName <> ""
    lineTwoData.roundGroupInfo = leagueName
  else
    lineTwoData.genres = genres
  end if

  if channelTitle <> ""
    lineTwoData.channelName = channelTitle
  end if

  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = lineTwoData

  if content.needsLogin = true AND m.top.signedIn <> true
    infoPanel.loginReason = content.loginReason
    infoPanel.needsLogin = true
  else
    infoPanel.needsLogin = false
  end if

  infoPanel.width = 960
End Function


' helper function which returns the time left in the format 'x hour and y mins left' if timeleft is more than an hour
' else it retuns 'y mins left'
Function getDurationHoursString(seconds As Integer) As String
  retVal = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minValue = StrI((Int(seconds / 60) mod 60) + 1) 'increase the min by one so that we dont show 0 min

    if hourValue > 0
      retVal =  getTranslation("hour_mins_left", {"hour": StrI(hourValue), "minutes": minValue})
    else
      retVal = getTranslation("mins_left", {"minutes": minValue})
    end if
  end if

  return retVal
End Function


Function calculateProgramTimeLeft(program) as String
  retVal = ""
  now = getCurrentLocalTime()

  if isInt(program.endTime) = true AND program.endTime > now
    timeLeft = program.endTime - now
    retVal = getDurationHoursString(timeLeft)
  end if

  return retVal
End Function
