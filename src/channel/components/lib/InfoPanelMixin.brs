' Populates the info panel with the fields necessary for the "item" mode so that it looks
' like the info panel on the homescreen
'
' @content: TubiContentNode, containing a movie or series
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node
Function populateInfoPanelWithHomescreenStyleItemMode(content, infoPanel)
  ' used by homescreen, category details screen etc.
  ' IMPORTANT, still need to call infoPanel.calculateHeight after calling this function
  infoPanel.mode = m.constants.ui.infoPanelModes.item
  infoPanel.title = content.title
  infoPanel.description = content.description

  lineOneData = {}
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)
  lineOneData.hasAudioDescription = content.hasAudioDescription
  lineOneData.rating = content.rating

  rating = UCase(content.rating)
  if (rating = "R" OR rating = "TV-MA" OR rating = "NC-17") AND m.constants.deviceinfo.countrycode = "US" AND isLoggedInUser() = false
    getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v2")
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


' Populates the info panel with the fields necessary for the "continue watching" mode which contains mainly progress bar and time left on movie or current episode.
' Delete this Function if experiment roku_progress_bar_on_infopanel concludes
'
' @content: TubiContentNode, containing a movie or series
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node
Function populateInfoPanelWithCWSignedInUserStyleItemMode(content, infoPanel)
  infoPanel.mode = m.constants.ui.infoPanelModes.CWSignedInUser
  infoPanel.title = content.title
  infoPanel.description = content.description
  infoPanel.needsLogin = content.needsLogin
  infoPanel.reminderIsSet = false
  duration = content.length
  episodeTitle = ""

  lineOneData = {}
  history = getHistory(content.id)
  if history <> invalid
    nowPos = history.nowPos

    if content.type = m.constants.ui.contentTypes.series

      if history.currentEpisodeId <> invalid AND history.currentEpisodeId <> ""
        episode = m.top.refreshInfoPanelWithEpisode
        if episode <> invalid AND episode.seriesId = content.id
          infoPanel.description = episode.description
          duration = episode.length
          episodeTitle = episode.title
          episodeHistory = history.findNode(episode.id)

          if episodeHistory <> invalid
            nowPos = episodeHistory.nowPos
          end if

        end if
      end if

    end if

  else
    nowPos = 0
  end if

  if duration <= 0
    percentage = 0
  else
    percentage = (nowPos / duration)

  end if

  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0

  progressPercent = percentage * 100

  lineTwoData = {}
  lineTwoData.progressPercent = progressPercent
  lineTwoData.displayProgressBar = true

  seconds = duration - nowPos

  if episodeTitle <> ""
    lineOneData.timeLeft = getDurationHoursString(seconds) + " " + Chr(&hb7) + " " + episodeTitle
  else
    lineOneData.timeLeft = getDurationHoursString(seconds)
  end if

  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = lineTwoData
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
  lineOneData.hasAudioDescription = content.hasAudioDescription
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
' Delete this Function if roku_sports_onnow_rows experiment does not graduate
'
' @content: TubiContentNode, containing a linear channel with programs as children
' @infoPanel: InfoPanel node
'
' @sideEffects: updates fields on the passed in infoPanel node

Function populateInfoPanelWithLinearProgramHomescreenMode(content, infoPanel)
  infoPanel.mode = m.constants.ui.infoPanelModes.linearProgramHomescreen
  currentProgram = getCurrentLiveProgram(content)

  releaseDate = ""
  timeLeft = ""
  duration = ""
  channelName = ""
  league = ""
  rating = ""
  genres = []

  infoPanel.description = content.description

  if currentProgram <> invalid
    infoPanel.title = currentProgram.title
    infoPanel.episodeTitle = currentProgram.epgProgramTitle
    releaseDate = currentProgram.releaseDate
    infoPanel.description = currentProgram.description

    channelName = content.title
    rating = currentProgram.rating
    timeleft = calculateProgramTimeLeft(currentProgram)
    genres = currentProgram.genres

    if currentProgram.live = false OR currentProgram.epgProgramType <> m.constants.ui.contentTypes.sportsEvent 'live news
      prgLength = currentProgram.endTime - currentProgram.startTime
      if prgLength > 0
        duration = formatLengthAsHourAndMins(prgLength)
      end if
    else
      if currentProgram.epgProgramType = m.constants.ui.contentTypes.sportsEvent AND currentProgram.live = true
        if currentProgram.hoursOfAiring <> invalid AND currentProgram.hoursOfAiring <> ""
          startTime = currentProgram.hoursOfAiring.tokenize(" - ")[0]
          duration = getTranslation("epg_started_at") + " " + startTime
        end if
        'show the league only for sports Events which are live
        league = currentProgram.league
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

  lineOneData = {}
  lineOneData.releaseDate = releaseDate
  lineOneData.programLength = duration
  lineOneData.hasCC = content.hasSubtitles
  lineOneData.programTimeLeft = timeleft
  lineOneData.rating = rating


  lineTwoData = {}
  ' if league is available, show it in the second line, else show genres
  if league <> ""
    lineTwoData.roundGroupInfo = league
  else
    lineTwoData.genres = genres
  end if

  if channelName <> "" then lineTwoData.channelName = channelName
  infoPanel.lineOneData = lineOneData
  infoPanel.lineTwoData = lineTwoData

  infoPanel.needsLogin = (content.needsLogin AND m.top.signedIn <> true)
  infoPanel.width = 960
End Function


' Populates the info panel with the fields necessary for the Linear programs in homeScreen(linear content on non-linear category) mode so that it looks
' like the info panel on the homescreen
' Delete this Function if roku_sports_onnow_rows experiment graduates
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
  lineOneData.hasAudioDescription = content.hasAudioDescription
  lineOneData.hoursOfAiring = programTime

  infoPanel.lineOneData = lineOneData

  infoPanel.needsLogin = (content.needsLogin AND m.top.signedIn <> true)
  infoPanel.width = 960
End Function



' //TODO: Delete this Function if experiment roku_progress_bar_on_infopanel does not graduate
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
