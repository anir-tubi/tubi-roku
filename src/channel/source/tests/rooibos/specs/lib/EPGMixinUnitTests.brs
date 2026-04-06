'@TestSuite [EPGMixin] EPGMixin.brs - getLinearContentBadgeInfo

'@Setup
Function EPGMixinSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It getLinearContentBadgeInfo
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test returns invalid when schedule has no startTime
Function epgMixin_badgeInfo_invalidSchedule_test()
  schedule = { startTime: invalid, endTime: invalid }
  result = getLinearContentBadgeInfo(schedule)
  m.assertInvalid(result)
End Function


'@Test returns replay badge when isReplay is true regardless of timing
Function epgMixin_badgeInfo_replay_test()
  now = CreateObject("roDateTime")
  startTime = CreateObject("roDateTime")
  startTime.fromSeconds(now.asSeconds() - 7200)
  endTime = CreateObject("roDateTime")
  endTime.fromSeconds(now.asSeconds() - 3600)

  schedule = {
    startTime: startTime.toISOString()
    endTime: endTime.toISOString()
  }

  result = getLinearContentBadgeInfo(schedule, true)
  m.assertNotInvalid(result)
  m.assertEqual(result.availability, "replay")
  m.assertNotEmpty(result.badgeText)
End Function


'@Test returns replay badge even for currently live content when isReplay is true
Function epgMixin_badgeInfo_replay_overridesLive_test()
  now = CreateObject("roDateTime")
  startTime = CreateObject("roDateTime")
  startTime.fromSeconds(now.asSeconds() - 3600)
  endTime = CreateObject("roDateTime")
  endTime.fromSeconds(now.asSeconds() + 3600)

  schedule = {
    startTime: startTime.toISOString()
    endTime: endTime.toISOString()
  }

  result = getLinearContentBadgeInfo(schedule, true)
  m.assertNotInvalid(result)
  m.assertEqual(result.availability, "replay")
End Function


'@Test returns live badge when event is currently airing
Function epgMixin_badgeInfo_live_test()
  now = CreateObject("roDateTime")
  startTime = CreateObject("roDateTime")
  startTime.fromSeconds(now.asSeconds() - 3600)
  endTime = CreateObject("roDateTime")
  endTime.fromSeconds(now.asSeconds() + 3600)

  schedule = {
    startTime: startTime.toISOString()
    endTime: endTime.toISOString()
  }

  result = getLinearContentBadgeInfo(schedule, false)
  m.assertNotInvalid(result)
  m.assertEqual(result.availability, "live")
End Function


'@Test returns upcoming with time string for event later today
Function epgMixin_badgeInfo_laterToday_test()
  now = CreateObject("roDateTime")
  now.toLocalTime()

  ' Build a start time 2 hours from now, but clamp to today
  airLocal = CreateObject("roDateTime")
  airLocal.fromSeconds(now.asSeconds() + 7200)

  ' Only run this test if the +2h time is still the same calendar day
  if airLocal.getDayOfMonth() = now.getDayOfMonth() AND airLocal.getMonth() = now.getMonth() AND airLocal.getYear() = now.getYear()
    airUtc = CreateObject("roDateTime")
    airUtc.fromSeconds(CreateObject("roDateTime").asSeconds() + 7200)
    endUtc = CreateObject("roDateTime")
    endUtc.fromSeconds(CreateObject("roDateTime").asSeconds() + 10800)

    schedule = {
      startTime: airUtc.toISOString()
      endTime: endUtc.toISOString()
    }

    result = getLinearContentBadgeInfo(schedule, false)
    m.assertNotInvalid(result)
    m.assertEqual(result.availability, "upcoming")
    m.assertNotEmpty(result.badgeText)
  end if
End Function


'@Test returns upcoming tomorrow badge for event on the next calendar day
Function epgMixin_badgeInfo_tomorrow_test()
  now = CreateObject("roDateTime")
  now.toLocalTime()

  ' Find seconds until end of local day, then add 6 hours into tomorrow.
  ' The resulting event must be (a) >= 86400s away so it bypasses the
  ' countdown branch in getLinearContentBadgeInfo (which shows "Live in Xh"
  ' for anything < 24h out), and (b) inside the isTomorrow window.
  ' After ~18:00 local, secsLeftToday + 21600 < 86400, so the countdown
  ' branch would catch it. Skip the test in that case — the "later today"
  ' test already covers the countdown path.
  secsLeftToday = 86400 - (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds())
  offsetToTomorrow = secsLeftToday + 21600
  if offsetToTomorrow >= 86460
    startUtc = CreateObject("roDateTime")
    startUtc.fromSeconds(CreateObject("roDateTime").asSeconds() + offsetToTomorrow)
    endUtc = CreateObject("roDateTime")
    endUtc.fromSeconds(CreateObject("roDateTime").asSeconds() + offsetToTomorrow + 10800)

    schedule = {
      startTime: startUtc.toISOString()
      endTime: endUtc.toISOString()
    }

    result = getLinearContentBadgeInfo(schedule, false)
    m.assertNotInvalid(result)
    m.assertEqual(result.availability, "upcoming")
    m.assertTrue(result.badgeText.instr("Tomorrow") >= 0 OR result.badgeText.instr("tomorrow") >= 0)
  end if
End Function


'@Test returns upcoming badge for event 5 days away
Function epgMixin_badgeInfo_futureDays_test()
  now = CreateObject("roDateTime")
  startUtc = CreateObject("roDateTime")
  startUtc.fromSeconds(now.asSeconds() + 432000)
  endUtc = CreateObject("roDateTime")
  endUtc.fromSeconds(now.asSeconds() + 442800)

  schedule = {
    startTime: startUtc.toISOString()
    endTime: endUtc.toISOString()
  }

  result = getLinearContentBadgeInfo(schedule, false)
  m.assertNotInvalid(result)
  m.assertEqual(result.availability, "upcoming")
  m.assertNotEmpty(result.badgeText)
End Function


'@Test returns invalid for event that has already ended and is not replay
Function epgMixin_badgeInfo_ended_notReplay_test()
  now = CreateObject("roDateTime")
  startTime = CreateObject("roDateTime")
  startTime.fromSeconds(now.asSeconds() - 7200)
  endTime = CreateObject("roDateTime")
  endTime.fromSeconds(now.asSeconds() - 3600)

  schedule = {
    startTime: startTime.toISOString()
    endTime: endTime.toISOString()
  }

  result = getLinearContentBadgeInfo(schedule, false)
  m.assertInvalid(result)
End Function


'@Test isToday returns true for current day
Function epgMixin_isToday_test()
  now = CreateObject("roDateTime")
  m.assertTrue(isToday(now.toISOString()))
End Function


'@Test isTomorrow returns true for next day
Function epgMixin_isTomorrow_test()
  ' Use raw UTC seconds to avoid double-offset when isTomorrow
  ' applies toLocalTime() internally
  nowUtc = CreateObject("roDateTime")
  tomorrowNoon = CreateObject("roDateTime")
  tomorrowNoon.fromSeconds(nowUtc.asSeconds() + 86400)
  m.assertTrue(isTomorrow(tomorrowNoon.toISOString()))

  ' Today should not be tomorrow
  m.assertFalse(isTomorrow(nowUtc.toISOString()))
End Function
