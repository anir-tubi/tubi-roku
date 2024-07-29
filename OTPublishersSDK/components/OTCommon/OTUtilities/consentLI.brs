function isLegitimateInterest(prop, LegIntSettings)
    return prop <> invalid and prop.IsIabPurpose <> invalid and prop.IsIabPurpose and isIab_PURPOSE(prop.Type) and prop.HasLegIntOptOut <> invalid AND prop.HasLegIntOptOut and LegIntSettings <> invalid AND LegIntSettings.PAllowLI
end function

function isVendorLegitimateInterest(prop, LegIntSettings)
    return prop <> invalid and prop.shouldShowLegitimateInterestToggleForVendor <> invalid AND prop.shouldShowLegitimateInterestToggleForVendor and LegIntSettings <> invalid AND LegIntSettings.PAllowLI
end function

function getLegIntSettings()
    sdkData = m.global._OT_initialize_data
    LegIntSettings = optionalChaining(sdkData, "culture.DomainData.LegIntSettings")
    PAllowLI = invalid
    if LegIntSettings <> invalid
        PAllowLI = LegIntSettings
    end if
    return PAllowLI
end function