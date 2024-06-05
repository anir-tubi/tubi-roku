function getConsentStatusForGroupID(groupId as string) as integer
    status = -1
    statusId = invalid
    if groupId = invalid or groupId.Trim() = "" return status
    groupId = groupId.Trim()
    regGroupData = getRegGroupData()
    if regGroupData <> invalid
        for each item in regGroupData
            if LCase(item) = LCase(groupId)
                groupId = item
                exit for
            end if
        end for
    end if
    if regGroupData <> invalid and regGroupData[groupId] <> invalid
        statusId = regGroupData[groupId]
    end if
    if m.saveGroupqueue <> invalid and m.saveGroupqueue[groupId] <> invalid
        statusId = m.saveGroupqueue[groupId]
    end if
    if statusId <> invalid
        status = 1
        if statusId.Instr("inactive") <> -1
            status = 0
        end if
    end if
    return status
end function

function getConsentStatusForSDKId(skdId as string) as integer
    status = -1
    if skdId = invalid or skdId.Trim() = "" return status
    skdId = skdId.Trim()
    sdkConsentGroup = m.registry.read("sdkConsentGroup")
    if sdkConsentGroup <> invalid
        sdkConsentGroup = ParseJson(sdkConsentGroup)
        for each item in sdkConsentGroup
            if LCase(item) = LCase(skdId)
                skdId = item
                exit for
            end if
        end for
        if sdkConsentGroup.doesExist(skdId)
            groupId = sdkConsentGroup[skdId]
            status = getConsentStatusForGroupID(groupId)
        end if
    end if
    return status
end function

' Method to get vendor count configured for a particular group.
' @param customGroupId String, group id for which vendors have been assigned to.
'        It can be a parent group id like Stack or an individual group like an IAB purpose.
' @return int, count from saved object, 0 (no vendors configured), -1(error cases) are the possible values.
function getVendorCount(customGroupId as string)
    countForCategory = -1
    if customGroupId = invalid or customGroupId.Trim() = ""
        m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, m.constant.error["507"])
    else if m.global._OT_initialize_data = invalid
        m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, "application", m.constant.error["506"])
    else
        params = m.initGroups[customGroupId]
        if params <> invalid
            countForCategory = 0
            if isIAB2V2()
                if optionalChaining(m.global, "_OT_IABVendor_data.iab") = invalid
                    m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, "Iab vendor", m.constant.error["506"])
                else
                    filteredSupportPurposes = optionalChaining(m.global._OT_IABVendor_data, "iab.filteredSupportPurposes")
                    if filteredSupportPurposes <> invalid
                        subGroups = getSubGroups(params.OptanonGroupId)
                        if params.OptanonGroupId <> invalid and ((params.IsIabPurpose <> invalid and params.IsIabPurpose) or (subGroups <> invalid and subGroups.count() > 0))
                            vFilterList = {}
                            if optionalChaining(filteredSupportPurposes, params.OptanonGroupId.toStr()) <> invalid then vFilterList.append(filteredSupportPurposes[params.OptanonGroupId])
                            for each sg in subGroups
                                if optionalChaining(filteredSupportPurposes, sg.OptanonGroupId.toStr()) <> invalid then vFilterList.append(filteredSupportPurposes[sg.OptanonGroupId])
                            end for
                            vcount = vFilterList.keys().count()
                            if vcount <> invalid and vcount > 0 then countForCategory = vcount
                        end if
                    else
                        m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, "vendor count", m.constant.error["506"])
                    end if
                end if
            end if
            m.logger.set(m.errortype.Info, m.errorTags.PublicMethod, m.constant.info["737"], customGroupId + " - " + countForCategory.toStr())
        else
            m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, m.constant.error["507"])
        end if
    end if
    return countForCategory
end function