function initializeCCPAValues()
    sdkData = m.global._OT_initialize_data
    if sdkData <> invalid and sdkData.culture <> invalid and sdkData.culture.MobileData <> invalid and sdkData.culture.MobileData.ccpaData <> invalid
        countryCode = sdkData.domain.countryCode
        regionCode = sdkData.domain.regionCode
        geoLocation = sdkData.culture.MobileData.ccpaData.ccpaGeo
        m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["720"], countryCode)
        m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["721"], regionCode)
        m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["722"], geoLocation)
        setCCPAValues()
    else
        saveUSP()
    end if
end function

function setCCPAValues()
    uspString = ""
    sdkData = m.global._OT_initialize_data
    if isCCPA()
        explicitNotice = sdkData.culture.MobileData.ccpaData.ccpaExpNotice
        lsPact = sdkData.culture.MobileData.ccpaData.ccpaLspa
        parentId = sdkData.culture.MobileData.ccpaData.parentCCPACategory
        if parentId <> ""
            parentGroupDetail = getValidGroup(parentId)
            if parentGroupDetail <> invalid
                gStatus = parentGroupDetail.Status
                if gStatus.Instr("inactive") <> -1
                    statusIndication = "Y"
                else
                    statusIndication = "N"
                end if
                uspString = "1" + getStringIndication(explicitNotice) + statusIndication + getStringIndication(lsPact)
            else
                m.logger.set(m.errortype.Warning, m.errorTags.OneTrust, m.constant.Warning["908"])
            end if
        end if
        saveUSP(uspString)
    end if
    return uspString
end function

function isCCPA()
    sdkData = m.global._OT_initialize_data
    havingCCPA = false
    if sdkData <> invalid and sdkData.culture <> invalid and sdkData.culture.MobileData <> invalid and sdkData.culture.MobileData.ccpaData <> invalid
        countryCode = sdkData.domain.countryCode
        regionCode = sdkData.domain.regionCode
        geoLocation = sdkData.culture.MobileData.ccpaData.ccpaGeo
        if sdkData.culture.MobileData.ccpaData.computeCCPA and ((Lcase(geoLocation) = "all") or (geoLocation = countryCode) or (geoLocation = regionCode))
            havingCCPA = true
        end if
    end if
    return havingCCPA
end function

function getStringIndication(value as boolean) as string
    if value
        return "Y"
    else
        return "N"
    end if
end function

function saveUSP(uspString = "1---" as string)
    if uspString <> "1---"
        m.logger.set(m.errortype.info, m.errorTags.Token, m.constant.info["707"], uspString)
        if not m.global.doesExist("IABUSPrivacy_String") then m.global.Addfield("IABUSPrivacy_String", "string", false)
        m.global.IABUSPrivacy_String = uspString
        m.registry.write("IABUSPrivacy_String", uspString)
    end if
end function

function removeUSPRegistry()
    m.registry.delete("IABUSPrivacy_String")
end function

function removeUSPGlobal() 
    if m.global.doesExist("IABUSPrivacy_String") then m.global.removeField("IABUSPrivacy_String")
end function