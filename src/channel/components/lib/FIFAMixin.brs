' This function will retrun whether the current date is during tournament, after or pre torunament
' return values are
'     = duringTournament - during the tournament time period
'     = afterTournament  - after end date of tournament
'     = preTournament   -  before the start of the tournament

Function tournamentTimeFrame() as String
  tubilog("TournamentScreenHelpers.tournamentTimeFrame")

  todayDate = CreateObject("roDateTime")
  todayDate.ToLocalTime()
  today = todayDate.asSeconds()

  startDate = m.constants.tournament.startDate
  endDate = m.constants.tournament.endDate

  ' //BELOW BLOCK IS ADDED FOR QA TESTING. QA can change the dates on <env>.yml file for testing pre/during/post tournament cases
  if m.constants.settings.mode <> "production"
    today = getCurrentUTCTimeWithOffset(m.constants)
    if isNonEmptyString(m.constants.settings.tournamentStartDate)
      startDate = m.constants.settings.tournamentStartDate
    end if
    if isNonEmptyString(m.constants.settings.tournamentEndDate)
      endDate = m.constants.settings.tournamentEndDate
    end if
  end if

  tournamentStartDate = CreateObject("roDateTime")
  tournamentStartDate.FromISO8601String(startDate)
  tournamentStartDate.ToLocalTime()

  tournamentEndDate = CreateObject("roDateTime")
  tournamentEndDate.FromISO8601String(endDate)
  tournamentEndDate.ToLocalTime()

  if today >= tournamentStartDate.asSeconds() AND today <= tournamentEndDate.asSeconds()
    return "duringTournament"
  else if today > tournamentEndDate.asSeconds()
    return "afterTournament"
  else
    return "preTournament"
  end if

End Function