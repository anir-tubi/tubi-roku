Function setShouldShowBannerStatus(status)
  isShouldShowBanner = m.registry.read("shouldShowBanner")
  if (not isString(isShouldShowBanner) AND status = -1) OR status <> -1 then m.registry.write("shouldShowBanner", status)
End Function

Function setIsBannerShownStatus(status as Integer)
  ' old bannerDisplayed - need to depricate in cmp api
  bannerShown = m.registry.read("isBannerShown")
  if not (bannerShown = "1" OR bannerShown = "2") OR status = 2 then m.registry.write("isBannerShown", status)
End Function

Function bannerLoggingReason(data)
  m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, data.bannerReasonCode.toStr() + " - ", data.bannerReason)
End Function