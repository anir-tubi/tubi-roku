Function setStorageKeys(data)
  try
    if data <> invalid
      if data.storageKeys <> invalid
        AddtlConsent = getStorageKeys("IABTCF_AddtlConsent")
        AddtlConsentGpp = getStorageKeys("IABGPP_TCFEU2_AddtlConsent")
        if isString(AddtlConsentGpp) then AddtlConsent = AddtlConsentGpp
        if isString(AddtlConsent) then m.registry.write("AddtlConsent", AddtlConsent)
        TCString = getStorageKeys("IABTCF_TCString")
        TCStringGPP = getStorageKeys("IABGPP_2_String")
        if isString(TCStringGPP) then TCString = TCStringGPP
        if isString(TCString) then m.registry.write("TCString", TCString)
        GppString = getStorageKeys("IABGPP_HDR_GppString")
        if isString(GppString)
          m.registry.write("GppString", GppString)
        end if

        m.registry.deleteSection("TCF")
        m.registry.deleteSection("GPP")
        for each key in data.storageKeys
          if isValid(key)
            sectionKey = "OTsdkReg"
            if key.Instr("IABTCF_") <> -1 OR key = "IABUSPrivacy_String" then sectionKey = "TCF"
            if key.Instr("IABGPP_") <> -1 then sectionKey = "GPP"
            value = data.storageKeys[key]
            if isValid(value) then m.registry.write(key, value, sectionKey)
          end if
        end for

        AddtlConsenttemp = getStorageKeys("IABTCF_AddtlConsent")
        if not isString(AddtlConsenttemp) then AddtlConsenttemp = getStorageKeys("IABGPP_TCFEU2_AddtlConsent")
        if isString(AddtlConsenttemp) then m.registry.delete("AddtlConsent")
        TCStringtemp = getStorageKeys("IABTCF_TCString")
        if not isString(TCStringtemp) then TCStringtemp = getStorageKeys("IABGPP_2_String")
        if isString(TCStringtemp) then m.registry.delete("TCString")
        GppStringtemp = getStorageKeys("IABGPP_HDR_GppString")
        if isString(GppStringtemp) then m.registry.delete("GppString")

        consentData = invalid
        if m.OTinitialize <> invalid AND m.OTinitialize.consentData <> invalid
          consentData = m.OTinitialize.consentData
        else if m.consentData <> invalid
          consentData = m.consentData
        end if
        if consentData <> invalid
          if data.storageKeys["OT_GroupConsents"] <> invalid then consentData["OT_GroupConsents"] = data.storageKeys["OT_GroupConsents"]
          if data.storageKeys["OT_GroupLIConsents"] <> invalid then consentData["OT_GroupLIConsents"] = data.storageKeys["OT_GroupLIConsents"]
          if data.storageKeys["OT_SdkConsents"] <> invalid then consentData["OT_SdkConsents"] = data.storageKeys["OT_SdkConsents"]
          if data.storageKeys["IABTCF_AddtlConsent"] <> invalid then consentData["OT_AddtlConsent"] = data.storageKeys["IABTCF_AddtlConsent"]
          if data.storageKeys["IABTCF_VendorConsents"] <> invalid then consentData["OT_VendorConsents"] = data.storageKeys["IABTCF_VendorConsents"]
          if data.storageKeys["IABTCF_VendorLegitimateInterests"] <> invalid then consentData["OT_vendorLIConsents"] = data.storageKeys["IABTCF_VendorLegitimateInterests"]
          if data.storageKeys["IABGPP_TCFEU2_AddtlConsent"] <> invalid then consentData["OT_AddtlConsent"] = data.storageKeys["IABGPP_TCFEU2_AddtlConsent"]
          if data.storageKeys["IABGPP_TCFEU2_VendorConsents"] <> invalid then consentData["OT_VendorConsents"] = data.storageKeys["IABGPP_TCFEU2_VendorConsents"]
          if data.storageKeys["IABGPP_TCFEU2_VendorLegitimateInterests"] <> invalid then consentData["OT_vendorLIConsents"] = data.storageKeys["IABGPP_TCFEU2_VendorLegitimateInterests"]
          if m.OTinitialize <> invalid AND m.OTinitialize.consentData <> invalid
            m.OTinitialize.consentData = consentData
          else if m.consentData <> invalid
            m.consentData = consentData
          end if
        end if
      else
        print "storageKeys not present"
      end if
      if data.otConsentString <> invalid
        m.registry.write("otConsentString", data.otConsentString)
      else
        print "otConsentString not present"
      end if
    end if
  catch e
    print "error  setStorageKeys = " e
  end try
End Function

Function getStorageKeys(key as String)
  sectionKey = "OTsdkReg"
  if isValid(key)
    if key.Instr("IABTCF_") <> -1 OR key = "IABUSPrivacy_String" then sectionKey = "TCF"
    if key.Instr("IABGPP_") <> -1 then sectionKey = "GPP"
    return m.registry.read(key, sectionKey)
  else
    return invalid
  end if
End Function