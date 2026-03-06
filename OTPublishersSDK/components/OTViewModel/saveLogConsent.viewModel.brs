Function saveLogConsent(viewData, OTinitialize)
  if isString(viewData.interactionType) AND viewData.interactionType = "PREFERENCE_CENTER_CLOSE" AND isValid(m.top.bannerExits) AND m.top.bannerExits
    viewData.interactionType = "BANNER_CLOSE"
  end if
  if not (isValid(viewData) AND isString(viewData.interactionType) AND viewData.interactionType = "PREFERENCE_CENTER_CLOSE")
    data = getSaveLogConsentdata(viewData, OTinitialize.consentData)
    m.OTinitializeTemp = OTinitialize
    createTaskPromise("OTNetworkTask", data, false, "response").then(sub(task)
      results = task.response
      if results <> invalid AND results.errors <> invalid AND results.errors.count() = 0
        setShouldShowBannerStatus(1)
        setStorageKeys(results)
        eventListeners(m.OTinitializeTemp.top.eventlistener, "OTConsentUpdated", true, invalid, { name: "OTConsentUpdated", response: true, success: results })
      else
        if results <> invalid AND results.errors <> invalid AND results.errors.count() > 0
          for each item in results.errors
            m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], task.name + " Api " + item.code.tostr() + "-" + item.message)
          end for
        else
          results = {
            errors: [{ message: m.constant.failed["603"] }]
          }
          m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], m.constant.failed["603"])
        end if
        eventListeners(m.OTinitializeTemp.top.eventlistener, "OTConsentUpdated", true, invalid, { name: "OTConsentUpdated", response: false, error: results.errors })
      end if
      RunGarbageCollector()
      m.OTinitializeTemp = invalid
    end sub)
  end if
End Function
