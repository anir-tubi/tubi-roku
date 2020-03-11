'Pass the ID associated with the ID to get the translated string
' Note: the component calling getTranslation() must 
' have pkg:/source/lib/TubiLanguageTranslate.brs added as a script
'
'@param sID: The ID associated with the desired translation string
'@param aDynamicStrings: Optional associated array of param/value pairings that should be used to replace strings in the translation.  
'       Placement of dynamic strings within a static string translation is used when it may not be known where the dynamic string should be placed within the static string.  For example: "Welcome Jack" vs "Jack Bienvenidos" 
'@return String - The translated string associated with the string ID. If unsuccessful, it will return an empty string.
Function getTranslation(sID as string, aDynamicStrings = {}) as String
  '//What is the current language
  constants = m.constants
  if constants = invalid
    constants = m.global.constants
  end if

  sLocaleID = constants.deviceInfo.locale
  sDefaultLocaleID = "en_US"

  sTranslatedString = getTranslationBasedOnLocale(sID, sLocaleID)
  if sTranslatedString = "" and sLocaleID <> sDefaultLocaleID
    '//If no translation was found, then use the default locale 
    sLocaleID = sDefaultLocaleID
    sTranslatedString = getTranslationBasedOnLocale(sID, sLocaleID)
  end if

  for each param in aDynamicStrings
    sToString = aDynamicStrings[param]
    if param <> invalid and sToString <> invalid
      '//place dynamic text in the translation. Look for and replace brackets {} with the dynamic string
      sFromString = "{" + param + "}"
      sTranslatedString = sTranslatedString.replace(sFromString, sToString)
    end if
  end for

  return sTranslatedString
End Function


'The getTranslation() method calls this function to get the translation based on passed language ID
'
'@param sStringID: The ID associated with the desired translation string
'@param sLocaleID: The ID associated with the desired language
'@return String - The translated string associated with the string ID. If unsuccessful, it will return an empty string.
Function getTranslationBasedOnLocale(sStringID as String, sLocaleID as String) as String
  sTranslatedString = ""
  translations = invalid
  if m.global.translationAA <> invalid
    translations = m.global.translationAA[sLocaleID]
  end if
  if translations = invalid   
    '//The associative array for the passed locale does not exist, so get and parse the file associated with that locale
    getAndParseTranslation(sLocaleID)
    '//If the previous line was successful in parsing the translation file, then the translation file associated with the passed locale will now exist on the m.global.translationArray"
    if m.global.translationAA <> invalid
      translations = m.global.translationAA[sLocaleID]
    end if
  end if

  if translations <> invalid and translations[sStringID] <> invalid
    sTranslatedString = translations[sStringID]
  end if

  return sTranslatedString
End Function


'The getTranslationBasedOnLocale() method calls this function to get the translated file if it has not already 
'been loaded and then proceeds to parse the file and keep it in memory
'
'@param sLocaleID: The ID associated with the desired language
'@return Boolean - Was the language translation file been successfuly parsed? 
Function getAndParseTranslation(sLocaleID as String) as Boolean
  bSuccess = false
  url = "pkg:/locale/" + sLocaleID + "/translations.json"
  json = ReadAsciiFile(url)
  if json <> ""
    parsed = parseJSON(json)
    if parsed <> invalid
      if m.global.translationAA = invalid
        m.global.addField("translationAA", "assocarray", false)
        m.global.translationAA = {}
      end if

      copytranslationAA = m.global.translationAA
      copytranslationAA[sLocaleID] = parsed
      m.global.translationAA = copytranslationAA
      bSuccess = true
    end if
  end if
  return bSuccess
End Function