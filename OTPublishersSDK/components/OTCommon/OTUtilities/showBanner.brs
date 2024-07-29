function isBannerShown() as integer
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "isBannerShown" + m.constant.info["705"])
    isBannerStatus = checkBannerShownRegistry()
    isAllPurposeUpdated = checkAllPurposeUpdatedSync()
    status = 0
    if isBannerStatus
        status = 1
    else if m.global._OT_initialize_data = invalid
        status = -1
    else if isAllPurposeUpdated
        status = 2
    else
        status = 0
    end if
    m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["713"], status.tostr())
    return status
end function

function shouldShowBanner(override = false) as boolean
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "shouldShowBanner" + m.constant.info["705"])
    sdkData = m.global._OT_initialize_data
    TCFString = m.registry.read("IABTCF_TCString")
    if isGppEnabled() then TCFString = m.registry.read("IABGPP_2_String")
    status = false
    ' 1. if OT SDK domain data empty return false.
    if sdkData = invalid or sdkData.culture = invalid
        status = false
    else
        DomainData = optionalChaining(sdkData, "culture.DomainData")
        lastConsentTime = getConsentTimeReg()
        m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["715"], lastConsentTime)
        ' Public Method called by applications to show OT Banner.
        if override
            'show Banner only if data fetched already
            if m.global._OT_initialize_data <> invalid
                m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "110 - ", m.constant.bannerLogging["110"])
                status = true
            else
                m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, m.constant.error["503"])
                status = false
            end if
            '2. If Geo rule set show banner false then return false.
        else if not isGeoRuleSetToShowBanner(DomainData)
            status = false
            '3. If re-consent true with disk consent time then return true.
        else if getReconsentStatus(DomainData, lastConsentTime)
            clearIABConsentsOnAutoReconsent()
            m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "102 - ", m.constant.bannerLogging["102"])
            status = true
            '4.a If auto re-consent expired then return true.
        else if isAutoReconsent(DomainData, lastConsentTime)
            clearIABConsentsOnAutoReconsent()
            m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "103 - ", m.constant.bannerLogging["103"])
            status = true

            '4.b If consent expired for tc String then return true.
        else if isIAB2() and isIABTCStringExpired(DomainData)
            clearIABConsentsOnAutoReconsent()
            m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "104 - ",m.constant.bannerLogging["104"])
            status = true

        else if not isServiceSpecific()
            clearIABConsentsOnAutoReconsent()
            m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "106 - ",m.constant.bannerLogging["106"])
            status = true
            ' 5. If profile merged successfully no need to show banner
        else if checkAllPurposeUpdatedSync()
            status = false
            '6. First time user not given consent then return true
        else if lastConsentTime = 0
            syncProfile = sdkParams().getSyncProfile()
            if syncProfile <> invalid and syncProfile
                if getConsentExpired()
                    m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "105 - ",m.constant.bannerLogging["105"])
                    status = true
                else if not checkAllPurposeUpdatedSync()
                    m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "107 - ",m.constant.bannerLogging["107"])
                    status = true
                end if
            else
                m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "101 - ", m.constant.bannerLogging["101"])
                status = true
            end if
            '7. Show Banner if template downloaded location is IAB region and user has not given
            ' consent in IAB region previously - return true
        else if isIAB2() and not (TCFString <> invalid and TCFString <> "")
            m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["728"])
            m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "109 - ",m.constant.bannerLogging["109"])
            status = true
            '8. Show Banner if an additional group w/o consent has been detected across different
            ' geo-loc / across different data.
        else if not isIAB2V2() and hasGrpConfigChanged()
            m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["729"])
            m.logger.set(m.errortype.Banner, m.errorTags.OTUIDisplayReasonMessage, "111 - ",m.constant.bannerLogging["111"])
            status = true
        end if
    end if
    m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["714"], status)
    return status
end function

function isServiceSpecific()
    IABTCF_IsServiceSpecific = m.registry.read("IABTCF_IsServiceSpecific")
    if isGppEnabled() then IABTCF_IsServiceSpecific = m.registry.read("IABGPP_TCFEU2_IsServiceSpecific")
    return IABTCF_IsServiceSpecific = invalid or IABTCF_IsServiceSpecific = "1" or IABTCF_IsServiceSpecific = "true"
end function

function getConsentExpired()
    sdkData = m.global._OT_initialize_data
    if sdkData <> invalid and sdkData.profile <> invalid and sdkData.profile.doesExist("sync") and sdkData.profile.sync.keys().count() > 0 and sdkData.profile.sync.shouldShowBannerAsConsentExpired <> invalid
        m.registry.write("shouldShowBannerAsConsentExpired", sdkData.profile.sync.shouldShowBannerAsConsentExpired.tostr())
        m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["730"], sdkData.profile.sync.shouldShowBannerAsConsentExpired)
        return sdkData.profile.sync.shouldShowBannerAsConsentExpired
    else
        shouldShowBannerAsConsentExpired = m.registry.read("shouldShowBannerAsConsentExpired")
        return shouldShowBannerAsConsentExpired = "true"
    end if
    return false
end function

function getConsentTimeReg() as integer
    consentTime = 0
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("OT_LastConsentTime")
        consentTime = sdkReg.Read("OT_LastConsentTime").ToInt()
    end if
    return consentTime
end function

function getReconsentStatus(DomainData, userLastConsentTime) as boolean
    lastReconsentDate = optionalChaining(DomainData, "LastReconsentDate")
    if lastReconsentDate = invalid
        return false
    end if
    ' lastReconsentDate will get the date in milliseconds, so divide by 1000 to convert to seconds
    lastReconsentDateFromServer = lastReconsentDate / 1000
    oldLastReconsentDateFromServer = getLastReconsentConsentDate()
    if not userLastConsentTime = 0 and lastReconsentDateFromServer > userLastConsentTime
        'timestamp lastReconsentDateFromServer is later than timestamp user consent
        m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["731"])
        return true
    else if userLastConsentTime = 0 and not oldLastReconsentDateFromServer = -1 and lastReconsentDateFromServer > oldLastReconsentDateFromServer
        'timestamp lastReconsentDateFromServer is later than timestamp of previous lastReconsentDateFromServer
        m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["732"])
        return true
    end if
    return false
end function

function hasGrpConfigChanged()
    hasGrpchanged = false
    currGroups = getValidGroup()
    regGroupData = getRegGroupData()
    if currGroups <> invalid and currGroups.count() > 0 and regGroupData <> invalid and regGroupData.keys().count() > 0
        for each item in currGroups
            if item.Type <> invalid and item.Type <> "BRANCH" and not isIab_STACK(item.Type) and not (regGroupData.doesExist(item.CustomGroupId) or regGroupData.doesExist("Li_" + item.CustomGroupId))
                m.logger.set(m.errortype.info, m.errorTags.OneTrust, "hasGrpConfigChanged: group type - " + item.Type + " group -" + item.CustomGroupId)
                hasGrpchanged = true
                exit for
            end if
        end for
    end if
    return hasGrpchanged
end function

function isGeoRuleSetToShowBanner(domainData) as boolean
    if domainData <> invalid and domainData.ShowAlertNotice
        showAlertNotice = domainData.ShowAlertNotice
        if showAlertNotice
            m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["724"].Replace("$status", "enabled"))
            return true
        else
            m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["724"].Replace("$status", "disabled"))
            return false
        end if
    end if
    return false
end function

' function to check if auto re-consent has to be enabled
function isAutoReconsent(DomainData, lastConsentTime)
    autoReconsent = false
    if lastConsentTime <> invalid and not lastConsentTime = 0
        ' current timestamp (seconds)
        currentTimeSeconds = CreateObject("roDateTime").AsSeconds()
        ' difference in seconds
        diff = currentTimeSeconds - lastConsentTime
        ' difference in no. of days
        days = diff / (24 * 60 * 60)
        ReconsentFrequencyDays = DomainData.ReconsentFrequencyDays
        if ReconsentFrequencyDays <> invalid
            ' reconsent frequency days coming in appdata
            ' compare and return
            return days >= ReconsentFrequencyDays
        end if
    end if
    return autoReconsent
end function

' function to check if auto re-consent has to be enabled
function isIABTCStringExpired(DomainData)
    IABTCF_LastUpdated = m.registry.read("IABTCF_LastUpdated")
    if isGppEnabled() then IABTCF_LastUpdated = m.registry.read("IABGPP_TCFEU2_LastUpdated")
    if IABTCF_LastUpdated = invalid
        return false
    end if
    dt = CreateObject("roDateTime")
    ' set IABTCF_LastUpdated ISO "2009-01-01T01:00:00.000Z" date to roDateTime
    dt.fromISO8601String(IABTCF_LastUpdated)
    ' get updated IABTCF_LastUpdated in seconds
    lastConsentTime = dt.AsSeconds()
    if lastConsentTime <> invalid and not lastConsentTime = 0
        ' current timestamp (seconds)
        currentTimeSeconds = CreateObject("roDateTime").AsSeconds()
        ' difference in seconds
        diff = currentTimeSeconds - lastConsentTime
        ' difference in no. of days
        days = diff / (24 * 60 * 60)
        IABReconsentFrequencyDays = DomainData.IABReconsentFrequencyDays
        if IABReconsentFrequencyDays <> invalid
            ' reconsent frequency days coming in appdata
            ' compare and return
            return days > IABReconsentFrequencyDays
        end if
    end if
    return false
end function

function checkBannerShownRegistry() as boolean
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("bannerDisplayed")
        return true
    else
        return false
    end if
end function

' Call this method if culturalDomainData has LastReconsentDate key.
function initLastReConsentDate(culturalDomainData)
    'If LastReConsentDate not initialized then only init.
    if getLastReconsentConsentDate() = -1
        lastReConsentString = ""
        if optionalChaining(culturalDomainData, "LastReconsentDate") <> invalid
            lastReConsentString = culturalDomainData.LastReconsentDate.tostr()
        end if
        m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["734"], lastReConsentString)
        if lastReConsentString = "" or optionalChaining(culturalDomainData, "LastReconsentDate") = invalid
            updateLastReConsentDate("0")
        else
            updateLastReConsentDate(lastReConsentString)
        end if
    end if
end function


' @return -1 if user is not given consent yet/init not called and Returns 0 if user given consent and
' OTT_LAST_RE_CONSENT_DATE is not published with re-consent yet.Otherwise returns last re-consent date.
function getLastReconsentConsentDate()
    lastConsentTime = m.registry.read("OTT_LAST_RE_CONSENT_DATE")
    if lastConsentTime = invalid
        m.logger.set(m.errortype.info, m.errorTags.OneTrust, m.constant.info["733"])
        return -1
    end if
    lastConsentTime = parseJson(lastConsentTime)
    ' lastConsentTime will get the date in milliseconds, so divide by 1000 to convert to seconds
    if lastConsentTime <> 0 then lastConsentTime = lastConsentTime / 1000
    return lastConsentTime
end function

function updateLastReConsentDate(lastReConsentString)
    m.registry.write("OTT_LAST_RE_CONSENT_DATE", lastReConsentString)
end function

function getLastReconsentDate()
    sdkData = m.global._OT_initialize_data
    domainData = optionalChaining(sdkData, "culture.DomainData")
    if optionalChaining(domainData, "LastReconsentDate") <> invalid
        return domainData.LastReconsentDate.tostr()
    end if
    return "0"
end function