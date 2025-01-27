'/* cSpell:disable */

' set translations on global
' side effect: places a set of translations for the locale on m.global.translationsAA
Function initTranslations()
  clearTranslations()
  locale = getLocale()
  setTranslationAAOnGlobal(locale)
End Function


' Tell the code to clear the translations. It is necessary to call this when the remote components is called and there
' are new strings that are contained in the remote components.
Function clearTranslations()
  if m.global.translationAA <> invalid
    m.global.translationAA = invalid
  end if
End Function


'Pass the ID associated with the ID to get the translated string
' Note: the component calling getTranslation() must
' have pkg:/source/lib/TubiLanguageTranslate.brs added as a script
'
'@param sID: The ID associated with the desired translation string
'@param aDynamicStrings: Optional associated array of param/value pairings that should be used to replace strings in the translation.
'       Placement of dynamic strings within a static string translation is used when it may not be known where the dynamic string
'       should be placed within the static string.  For example: "Welcome Jack" vs "Jack Bienvenidos"
'@return String - The translated string associated with the string ID. If unsuccessful, it will return an empty string.
Function getTranslation(sID as string, aDynamicStrings = {}) as String
  '//What is the current language
  locale = getLocale()
  defaultLocale = getDefaultLocale()

  sTranslatedString = getTranslationBasedOnLocale(sID, locale)
  if sTranslatedString = ""
    sTranslatedString = getTranslationBasedOnLanguage(sID, locale)
    if sTranslatedString = "" AND locale <> defaultLocale
      '//If no translation was found, then use the default locale
      sTranslatedString = getTranslationBasedOnLocale(sID, defaultLocale)
    end if
  end if

  for each param in aDynamicStrings
    sToString = aDynamicStrings[param]

    if param <> invalid AND sToString <> invalid
      '//place dynamic text in the translation. Look for and replace brackets {} with the dynamic string
      sFromString = "{" + param + "}"
      sTranslatedString = sTranslatedString.replace(sFromString, sToString)
    end if
  end for

  return sTranslatedString
End Function


Function getLocale()
  constants = m.constants

  if constants = invalid
    localGlobal = m.global
    if localGlobal <> invalid
      constants = localGlobal.constants
    end if
  end if

  locale = getDefaultLocale()
  if constants <> invalid
    locale = constants.deviceInfo.locale
  end if

  return locale
End Function


Function getDefaultLocale()
  'setting en_US as the default/fall back option
  return "en_US"
End Function


'This function gets the default locale ID based on the passed language ID
'
'@param sLanguageID: The ID associated with the desired language.
'@return String - Tthe default locale ID
Function getDefaultLocaleIDBasedOnLanguage(sLanguageID as String) as String
  sLocaleID = ""

  if sLanguageID = "en"
    sLocaleID = "en_US"
  else if sLanguageID = "es"
    sLocaleID = "es_MX"
  else if sLanguageID = "fr"
    sLocaleID = "fr_CA"
  end if

  return sLocaleID
End Function


'This function gets the translation based on passed language ID. If no general language
'translation is available, then a default locale translation will be used.
'
'@param sStringID: The ID associated with the desired translation string
'@param sLocaleID: The ID associated with the desired language. This ID includes both the country and langauge.
'@return String - The translated string associated with the string ID. If unsuccessful, it will return an empty string.
Function getTranslationBasedOnLanguage(sStringID as String, sLocaleID as String) as String
  sTranslatedString = ""
  sLanguageID = Left(sLocaleID, 2)
  '//get the language ID based on the passed localeID

  if sLanguageID <> ""
    '//get the default locale ID based on a language ID: i.e. en > en_US
    sDefaultLocaleID = getDefaultLocaleIDBasedOnLanguage(sLanguageID)
    if sDefaultLocaleID <> ""
      '//get the translation based on a default language file based on a language: i.e. english -> US English
      sTranslatedString = getTranslationBasedOnLocale(sStringID, sDefaultLocaleID)
    end if
  end if

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

  ' We only store m.translationAA in GeneralTask currently to allow accessing translations without rendezvous
  translationAA = m.translationAA
  if translationAA = invalid then
    translationAA = m.global.translationAA
  end if

  if translationAA <> invalid then
    translations = translationAA[sLocaleID]
  end if

  if translations = invalid
    '//The associative array for the passed locale does not exist, so get the associative array associated with that locale
    setTranslationAAonGlobal(sLocaleID)
    '//If the previous line was successful in getting the proper AA, then the translation file associated
    ' with the passed locale will now exist on the m.global.translationArray"
    if m.global.translationAA <> invalid
      translations = m.global.translationAA[sLocaleID]
    end if
  end if
  if translations <> invalid AND translations[sStringID] <> invalid AND translations[sStringID].message <> invalid
    sTranslatedString = translations[sStringID].message
    sTranslatedString = sTranslatedString.replace("\n", chr(10))
  end if

  return sTranslatedString
End Function


'The getTranslationBasedOnLocale() method calls this function to get the proper associative array if it has not already
'been stored into in memory
'
'@param locale: string, a valid locale (ex. "en_US", "es_MX")
'@return Boolean - Was the language associative array been successfully gotten?
Function setTranslationAAOnGlobal(locale as String) as Boolean
  bSuccess = false
  '//ideally we would store the translation files in separate files but the ReadAsciiFile() function does not work in the remote component package
  ' url = "pkg:/locale/" + locale + "/translations.json"
  ' json = ReadAsciiFile(url)

  '//Go thru all the possible locales that Roku supports to return the proper associative array
  translationSet = invalid
  locale = LCase(locale)
  translationSet = getTranslationSetByLocale(locale)

  if translationSet <> invalid
    if m.global.translationAA = invalid
      m.global.addField("translationAA", "assocarray", false)
      m.global.translationAA = {}
    end if

    copytranslationAA = m.global.translationAA
    copytranslationAA[locale] = translationSet
    m.global.translationAA = copytranslationAA
    bSuccess = true
  end if

  return bSuccess
End Function


Function getTranslationSetByLocale(locale)
  translationSet = invalid
  locale = LCase(locale)

  if locale = "en_us"
    translationSet = getTranslation_en_US()
  else if locale = "es_mx"
    translationSet = getTranslation_es_MX()
  else if locale = "es_es"
    ' translationSet = getTranslation_es_ES()
  else if locale = "en_gb"
    translationSet = getTranslation_en_GB()
  else if locale = "fr_ca"
    translationSet = getTranslation_fr_CA()
  else if locale = "fr_fr"
  else if locale = "de_de"
  else if locale = "it_it"
  else if locale = "pt_br"
  end if

  return translationSet
End Function

'''''''''''''''''''
' formatLengthSelectedLocale
'
' take an integer length in seconds and give it an setlocale descriptions like "1 h 36 min"
' ::NOTE:: when calling this function, make sure the calling file is including TubiLanguageTranslate.brs as a dependency
Function formatLengthSelectedLocale(length As Dynamic) As String
  if type(length) = "roFloat" or type(length) = "Float" or type(length) = "Double" then
    length = Int(length)
  end if
  if type(length) = "Integer" or type(length) = "roInt"
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = ""
    sTranslationID = invalid
    if hours = 0 AND minutes = 0 then
      '//Display just seconds
      sTranslationID = "metadata_seconds"
    else
      if hours > 0 AND minutes > 0
        '//Display hours AND minutes
        sTranslationID = "metadata_hoursAndMinutes"
      else if hours > 0
        '//Display just hours
        sTranslationID = "metadata_hours"
      else
        '//Display just minutes
        sTranslationID = "metadata_minutes"
      end if
    end if

    if sTranslationID <> invalid
      aaParams = {
        hours: stri(hours).trim(),
        minutes: stri(minutes).trim(),
        seconds: stri(seconds).trim()
      }
      result = getTranslation(sTranslationID, aaParams)
    end if

    return result
  else
    return ""
  end if
End Function


'//::NOTE:: Below this line are functions to get associative arrays for various locales. The associative arrays within the functions
'//are generated by a script that downloads the translations from https://crowdin.com/project/tubiapps.
'//If you wish to add/delete/modify a static string, do NOT edit the associative arrays below. Instead modify the
'//en_US.json file located in the locale folder and upload the json file to the crowdin to be translated.

' Return the associative array associated with the enUS locale
Function getTranslation_en_US()
  return {
    "foxVideoPlayer_error_contentUnavailableMessage": {
      "description": "Used when the fox video player displays a dialog requiring the error_contentUnavailableMessage text string.",
      "message": "Our apologies but the content is unavailable at this time. Please try again later.\nIf you continue to experience this issue, please visit help.tubitv.com."
    },
    "foxVideoPlayer_error_generic": {
      "description": "Used when the fox video player displays a dialog requiring the error_generic text string.",
      "message": "Our apologies but the content is unavailable at this time. Please try again later.\nIf you continue to experience this issue, please visit help.tubitv.com."
    },
    "menu_signIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into app.",
      "message": "Sign In"
    },
    "menu_goHome": {
      "description": "Menu option on the app's myStuff screen, Allows the user to  navigate to the home screen.",
      "message": "Go Home"
    },
    "menu_signedIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Shows that the user is signed in.",
      "message": "Hi {name}"
    },
    "menu_kids": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into kids mode.",
      "message": "Kids"
    },
    "menu_exitKids": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to exit kids mode.",
      "message": "Exit Kids"
    },
    "menu_search": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the search screen.",
      "message": "Search"
    },
    "menu_foryou": {
      "description": "Menu option on the app's top nav for pillshaped, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "For You"
    },
    "component_library_failed":{
      "description": "Latest Version of Tubi app failed to load due to some error",
      "message": "{errCode}\nThe Tubi channel failed to load fully. Some functionality may be missing."
    },
    "epg_starts_at": {
      "description": "Program time Title when user selects a future program on EPG.",
      "message": "Starts at"
    },
    "epg_started_at": {
      "description": "Program time Title for live program.",
      "message": "Started at"
    },
    "detail_screen_like_disLike_toast_header": {
      "description": "header text to be displayed on Toast-message when user like/dislike a title",
      "message": "Thanks for your feedback!"
    },
    "detail_screen_like_toast_message": {
      "description": "Message to be displayed on Toast-message when user liked a title",
      "message": "We'll suggest more titles like this in future recommendations."
    },
    "detail_screen_disLike_toast_message": {
      "description": "Message to be displayed on Toast-message when user disliked a title",
      "message": "We'll suggest less titles like this in future recommendations."
    },
    "menu_home": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Home"
    },
    "menu_categories": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the categories screen.",
      "message": "Categories"
    },
    "menu_channels": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the channels screen.",
      "message": "Channels"
    },
    "menu_networks": {
      "description": "Title for a container of channels tiles.",
      "message": "Networks"
    },
    "menu_movies": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the movies screen.",
      "message": "Movies"
    },
    "menu_tv": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the tv shows screen.",
      "message": "TV Shows"
    },
    "menu_livetv": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the live TV screen.",
      "message": "Live TV"
    },
    "menu_mystuff": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the my stuff screen.",
      "message": "My Stuff"
    },
    "menu_settings": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the settings screen.",
      "message": "Settings"
    },
    "menu_exit": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to exit the app.",
      "message": "Exit"
    },
    "screenHome_item_showAllGames": {
      "description": "The text to display on Show All Games tile",
      "message": "Show All"
    },
    "screenHome_button_spotlight_details": {
      "description": "On the home screen of the spotlight row, this is the text of a details button that allows the user to go to the details screen",
      "message": "Details"
    },
    "screenHome_button_spotlight_watch_live": {
      "description": "On the home screen of the spotlight row, this is the text of a watch live button that allows the user to start playing focused live content",
      "message": "Watch Live"
    },
    "screenHome_button_spotlight_watch_now": {
      "description": "On the home screen of the spotlight row, this is the text of a watch now button that allows the user to start playing focused linear content",
      "message": "Watch Now"
    },
    "loadingIndicator": {
      "description": "When something is loading, this text appears so the user knows something is loading.",
      "message": "Loading..."
    },
    "dialog_errorPrefix": {
      "description": "When the user is displayed an error, this is the prefix of the error ID that is presented to them: i.e. Error 101",
      "message": "Error: "
    },
    "dialog_defaultError_title": {
      "description": "The default title of a popup error dialog",
      "message": "Something went wrong"
    },
    "dialog_uidExpiraionError_title": {
      "description": "The title of a popup error dialog when link has been expired during signup process",
      "message": "This verification link has expired"
    },
    "dialog_defaultError_description": {
      "description": "The default message of a popup error dialog",
      "message": "We're sorry for the inconvenience. For assistance, please contact support@tubi.tv \n"
    },
    "dialog_magicLink_error_description": {
      "description": "The message of a popup error dialog when user magicLink API fails and user doesn't get verification link to their emial",
      "message": "We are having trouble processing this request. Please check your internet connection or retry clicking Resend Verification Link"
    },
    "dialog_uidExpiraionError_description": {
      "description": "The description of a popup error dialog when link has been expired during signup process",
      "message": "For a new verification link, please click again on Resend Verification link"
    },
    "dialog_errorMessageContact": {
      "description": "The contact info displayed in an error dialog",
      "message": "Please email support@tubi.tv if this keeps happening."
    },
    "dialog_button_exit": {
      "description": "In a popup dialog that asks if the user if they wish to exit the app. This is the button that will confirm their exit.",
      "message": "Exit"
    },
    "dialog_button_signIn": {
      "description": "The label of the button in a dialog window that allows the user to sign into the app.",
      "message": "Sign In"
    },
    "dialog_button_cancel": {
      "description": "Label of a dialog button to cancel out of the dialog",
      "message": "Cancel"
    },
    "dialog_button_continue": {
      "description": "Label of a dialog button to continue to the next step that the dialog is saying",
      "message": "Continue"
    },
    "dialog_button_forgot_password": {
      "description": "Label of a dialog button to take the user to the steps in case he/she has forgotten the account password. ",
      "message": "Forgot Password"
    },
    "dialog_button_submit": {
      "description": "Label of the dialog button to submit what the window is asking it to do.",
      "message": "Submit"
    },
    "dialog_button_tryAgain": {
      "description": "Label of the dialog button to try again what the app had attempted to do.",
      "message": "Try Again"
    },
    "dialog_button_close": {
      "description": "Label of the dialog button to close the dialog window",
      "message": "Close"
    },
    "dialog_button_skip": {
      "description": "Label of the dialog button to skip what is being asked",
      "message": "Skip"
    },
    "dialog_button_ok": {
      "description": "Label of the dialog button to confirm the action the dialog is asking",
      "message": "OK"
    },
    "dialog_button_off": {
      "description": "Label of the dialog button to turn something off: i.e. turn off closed captions",
      "message": "Off"
    },
    "dialog_button_on": {
      "description": "Label of the dialog button to turn something on: i.e. turn on autoplay preview",
      "message": "On"
    },
    "dialog_button_settings": {
      "description": "Label of the dialog button to cause the app to go to the settings screen.",
      "message": "Go To Settings"
    },
    "dialog_email_verification_email_already_sent": {
      "description": "The first line of the email verification description dialog",
      "message": "A verification email has already been sent to"
    },
    "dialog_email_verification_check_spam": {
      "description": "The second line of the email verification description dialog",
      "message": "Please remember to check your spam folder"
    },
    "dialog_button_resend_verification_link": {
      "description": "Label of the dialog button to resend the email verification link",
      "message": "Yes, Resend Verification Email"
    },
    "dialog_button_attempts_title": {
      "description": "Title of the dialog after user selects resend verification link more than 3 times",
      "message": "Too Many Attempts"
    },
    "dialog_button_multiple_emails_sent": {
      "description": "The first line of the too many attempts dialog",
      "message": "Multiple verification emails have already been sent to"
    },
    "dialog_errorOops_title": {
      "description": "A general error title for an error dialog window",
      "message": "Oops!"
    },
    "dialog_espanolDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav espanol menu item but the item has been disabled",
      "message": "Español Disabled"
    },
    "dialog_moviesDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav movies menu item but the item has been disabled",
      "message": "Movies Disabled"
    },
    "dialog_tvDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav TV menu item but the item has been disabled",
      "message": "TV Shows Disabled"
    },
    "dialog_linearEPGDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav Live TV menu item but the item has been disabled",
      "message": "Live TV Disabled"
    },
    "dialog_sideNavItemDisabled_description": {
      "description": "Message of a Dialog Window that is shown when the user clicked on a sidenav menu item but the item has been disabled",
      "message": "Please exit Tubi Kids to use this feature."
    },
    "dialog_sideNavItemDisabled_Parental_description": {
      "description": "Message of a Dialog Window that is shown when the user clicked on a sidenav menu item but the item has been disabled due to parental set to Teens",
      "message": "Please turn off parental controls to use this feature."
    },
    "dialog_contentNotAvailable_Parental_description": {
      "description": "Message of a Dialog Window that is shown when a deeplink content can not played because of user's parental control setting",
      "message": "Please turn off parental controls to watch this content."
    },
    "error_connection_title": {
      "description": "title of error window when there is a connection error",
      "message": "Connection Error"
    },
    "error_connection_description": {
      "description": "description of error window when there is a connection error",
      "message": "There may be an issue with your network connection, or with Tubi's server. Please check your network connection and try again. \n"
    },
    "dialog_updateVersion_title": {
      "description": "title of a dialog window that is shown when the user has an older version of the app",
      "message": "Please update the Tubi channel"
    },
    "dialog_updateVersion_description": {
      "description": "message of a dialog window that is shown when the user has an older version of the app",
      "message": "This version of Tubi is no longer supported. To update, please exit the Tubi app and go to: \n \n Settings > System > System update > Check now"
    },
    "dialog_fullSynopsis_title": {
      "description": "title of a dialog window that shows the full description of a video item",
      "message": "Full Synopsis"
    },
    "dialog_parentalPassword_title": {
      "description": "title of the dialog window when guest user signs in and still needs to enter his/her password to change the parental controls",
      "message": "Enter your password"
    },
    "dialog_parentalPassword_description": {
      "description": "description of the dialog window when guest user signs in and still needs to enter his/her password to change the parental controls",
      "message": "Thank you for signing in. To update the parental controls to your desired setting, please enter your password."
    },
    "dialog_signIn_title": {
      "description": "title of a dialog window when it asks the user to sign in",
      "message": "Please Sign In"
    },
    "dialog_confirmCorrectAge_title": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct year",
      "message": "Were you born in {birthYear}?"
    },
    "dialog_confirmCorrectAge_title_age": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct age",
      "message": "Are you {age} years old?"
    },
    "dialog_confirmCorrectAge_description": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct year",
      "message": "Please confirm to continue"
    },
    "dialog_confirmCorrectAge_confirm": {
      "description": "label of a dialog window button that will confirm app user's age is correct",
      "message": "Yes"
    },
    "dialog_confirmCorrectAge_edit": {
      "description": "label of a dialog window button that will let user edit their age again",
      "message": "Edit"
    },
    "dialog_kidsExit_title": {
      "description": "title of a dialog window when the user is attempting to exit kids Mode",
      "message": "Exit Kids"
    },
    "dialog_kidsExit_button_ok": {
      "description": "label of a dialog window button that will confirm app should exit kids mode",
      "message": "Exit Kids"
    },
    "dialog_kidsExitLimited_description": {
      "description": "description of a dialog window that describes what the user should do to exit kids mode",
      "message": "To exit Kids, please update your parental controls in account settings."
    },
    "dialog_kidsWelcome_title": {
      "description": "A message welcoming the user to Tubi Kids",
      "message": "Welcome to Tubi Kids"
    },
    "dialog_kidsWelcomeAgeGate_description": {
      "description": "A description informing users they cannot exit Tubi Kids for the next 24 hours",
      "message": "You cannot exit Tubi Kids at this time. Please try again in 24 hours. Questions? Drop us a line at www.tubi.tv/support"
    },
    "dialog_cannotExitKidsMode_title": {
      "description": "Title for dialog telling the user they can not exit kids mode",
      "message": "Cannot Exit Kids Mode"
    },
    "dialog_cannotExitKidsMode_description": {
      "description": "Description for dialog telling the user they can not exit kids mode",
      "message": "Please try again in 24 hours.\nQuestions? Drop us an email at support@tubi.tv"
    },
    "dialog_exitApp_title": {
      "description": "Title of the dialog window that asks the user if they want to exit the app",
      "message": "Are You Sure?"
    },
    "dialog_exitApp_description": {
      "description": "description of the dialog window that asks the user if they want to exit the app",
      "message": "Do you really want to exit Tubi?"
    },
    "error_noGetChannels_description": {
      "description": "description of the error dialog when channel content could not get received from the server.",
      "message": "Could not retrieve channel content."
    },
    "error_noGetChannelGuide_description": {
      "description": "description of the error dialog when channel guide content could not get received from the server.",
      "message": "Could not retrieve channel guide."
    },
    "error_noContent_description": {
      "description": "description of the error dialog when there was no content to be gathered from the server.",
      "message": "This page currently does not have any content."
    },
    "error_mustBeSignedIn_description": {
      "description": "Description of the warning dialog when user needs to be signed in to view a video.",
      "message": "To watch this video for free, please sign in or register."
    },
    "error_matureContent_title": {
      "description": "Title of the dialog window when user attempts to play mature content but they need to be signed in first",
      "message": "Mature Content"
    },
    "dialog_signOut_title": {
      "description": "Title of the dialog window that asks the user if they want to sign out of the app",
      "message": "Are You Sure?"
    },
    "dialog_signOut_description": {
      "description": "description of the dialog window that asks the user if they want to sign out of the app",
      "message": "You are about to sign out of your Tubi account."
    },
    "dialog_signOut_button_ok": {
      "description": "label of the confirmation button of the dialog window that asks the user if they want to sign out of the app",
      "message": "Sign Out"
    },
    "error_check_birthdate_description": {
      "description": "message letting the user know that they were not able to be signed in",
      "message": "There was an issue when trying to sign you in. Please enter the channel and sign in again."
    },
    "screenSearch_defaultLinearSearch": {
      "description": "Directions on the search page",
      "message": "Search for movies, TV shows, Live TV, and people"
    },
    "screenSearch_defaultSearch": {
      "description": "Directions on the search page",
      "message": "Search for movies, TV shows, and people"
    },
    "screenSearch_trendingSearch": {
      "description": "A header message that shows on top of default search results in search screen",
      "message": "Trending Searches"
    },
    "screenSearch_kidsWarning": {
      "description": "More directions on the search screen to suggest switching to kids mode.  Should be limited to be around 40 characters or fewer.",
      "message": "Switch to Kids for kids safe search results"
    },
    "screenSearch_loading": {
      "description": "The label of the loading indictor on the search screen",
      "message": "Updating your results..."
    },
    "screenSearch_noResults": {
      "description": "onscreen message when there are no search results.",
      "message": "We couldn't find results for '{term}' \n Please try again"
    },
    "screenSearch_results": {
      "description": "message after loading search results.",
      "message": "Results"
    },
    "screenSearch_matchingTitles": {
      "description": "text after number of search results for searchedString",
      "message": "titles matching"
    },
    "screenSearch_liveText": {
      "description": "The label on the search results poster next to the live streaming icon",
      "message": "Live"
    },
    "screenDetails_button_queue": {
      "description": "label of the button that will add the video title to the user's list",
      "message": "Add to My List"
    },
    "screenDetails_button_noQueue": {
      "description": "label of the button that will remove the video title from the user's list",
      "message": "Remove from My List"
    },
    "screenDetails_button_noHistory": {
      "description": "label of the button that will remove the video title from the user's viewing history",
      "message": "Remove from history"
    },
    "screenDetails_button_changingRating": {
      "description": "label of the button when the user has clicked the button and the like/dislike state of the video title is changing",
      "message": "Changing Rating..."
    },
    "screenDetails_button_queueNow": {
      "description": "label of the button when the user has clicked the button and the video title is being added to the user's list",
      "message": "Adding..."
    },
    "screenDetails_button_removing": {
      "description": "label of the button when the user has clicked the button and the video title is being removed from the user's list or viewing history",
      "message": "Removing..."
    },
    "screenDetails_button_gotoChannel": {
      "description": "Label of the button that will take the user to the channel associated with the current video title",
      "message": "Go to {channel}"
    },
    "screenDetails_error_addQueue_title": {
      "description": "Title of the warning dialog when user is attempting to add an item to their list but are not signed in",
      "message": "Account needed"
    },
    "screenDetails_error_addQueueMovie_description": {
      "description": "Description of the warning dialog when user is attempting to add a movie to their list but are not signed in",
      "message": "Sign in or register for a Tubi account to add this movie to your list."
    },
    "screenDetails_error_addQueueSeries_description": {
      "description": "Description of the warning dialog when user is attempting to add a TV show/series to their list but are not signed in",
      "message": "Sign in or register for a Tubi account to add this TV show to your list."
    },
    "screenDetails_error_setReminderSports_description": {
      "description": "Description of the warning dialog when user is attempting to set reminder but are not signed in",
      "message": "Sign in or register for a Tubi account to set a reminder."
    },
    "screenDetails_error_addQueueSports_description": {
      "description": "Description of the warning dialog when user is attempting to add a game to their list but are not signed in",
      "message": "Sign in or register for a Tubi account to add this game to you list."
    },
    "screenDetails_error_getContent_description": {
      "description": "Description of error when app is not able to get content.",
      "message": "Could not retrieve content information from server."
    },
    "error_deeplink_content": {
      "description": "Error message when the app can not retrieve the deeplink content.",
      "message": "The title you're trying to watch is not currently available"
    },
    "error_deeplink_page": {
      "description": "Error message when the app can not retrieve the page requested through deeplink",
      "message": "The page you're looking for is not currently available"
    },
    "error_tryAgain_title": {
      "description": "Error message when the user has the option to try the operation again.",
      "message": "Let’s try that again"
    },
    "screenDetails_queue_content_added_to_list_description": {
      "description": "Message when a content is added to the user's list after sign in.",
      "message": "Content"
    },
    "screenDetails_queue_added_to_list_description": {
      "description": "Message when a movie/series/replay game is added to the user's list after sign in.",
      "message": "{contentTitle} has been added to the List."
    },
    "screenDetails_queue_added_to_reminder_list_description": {
      "description": "Message when a upcoming game is added to the user's reminder list after sign in.",
      "message": "{upcomingTitle} has been set to the reminders."
    },
    "screenDetails_error_queueMovie_description": {
      "description": "Error message when a movie is not added to the user's list.",
      "message": "We’re not sure what happened but something went wrong when trying to add this movie to your list."
    },
    "screenDetails_error_queueSeries_description": {
      "description": "Error message when a tv show/series is not added to the user's list.",
      "message": "We’re not sure what happened but something went wrong when trying to add this TV show to your list."
    },
    "screenDetails_error_noQueueMovie_description": {
      "description": "Error message when a movie is not removed from the user's list.",
      "message": "We’re not sure what happened but something went wrong when trying to remove this movie from your list."
    },
    "screenDetails_error_noQueueSeries_description": {
      "description": "Error message when a tv show/series is not removed from the user's list.",
      "message": "We’re not sure what happened but something went wrong when trying to remove this TV show from your list."
    },
    "screenDetails_error_noQueueUpcoming_description": {
      "description": "Error message when a upcoming game is not removed from the user's reminders list.",
      "message": "We’re not sure what happened but something went wrong when trying to remove the reminder."
    },
    "screenDetails_error_noQueueReplay_description": {
      "description": "Error message when a replay game is not removed from the user's list.",
      "message": "We’re not sure what happened but something went wrong when trying to remove the sports event from the list."
    },
    "screenDetails_error_likeDislike_description": {
      "description": "Error message when a video title's like/dislike rating is not changed.",
      "message": "We’re not sure what happened but something went wrong when trying to change the rating."
    },
    "screenDetails_error_noHistory_description": {
      "description": "Error message when video is not removed from the user's viewing history.",
      "message": "Something went wrong while removing the content from your history."
    },
    "screenSettings_signIn_description": {
      "description": "Directions for the signin page",
      "message": "Sign in to your Tubi account on your computer or phone to see your saved TV shows and movies on My List, continue watching where you left off and get personal recommendations synced across your phone, television, tablet or computer."
    },
    "screenSettings_signOut_description": {
      "description": "Description on SignIn page when user is signed in",
      "message": "You're signed in as {name}"
    },
    "screenSettings_signOut_description2": {
      "description": "More details on the SignIn page when user is signed in",
      "message": "Email: {email}"
    },
    "screenSettings_fullDeviceID": {
      "description": "Text proceeding the full device ID",
      "message": "Full Device ID"
    },
    "screenSettings_about_title": {
      "description": "The title of the about screen",
      "message": "About Tubi"
    },
    "screenSettings_about_description": {
      "description": "The description on the about screen",
      "message": "Tubi is the leading free, premium, video streaming app. We have a large and diverse library of content with many thousands of titles and 3x fewer ads than cable TV."
    },
    "screenSettings_about_title2": {
      "description": "The subtitle on the about screen",
      "message": "Need Help?"
    },
    "screenSettings_about_description2": {
      "description": "The 2nd description on the about screen",
      "message": "Visit {help_url}\n\nEmail our Support team at support@tubi.tv\n\nReach us on Facebook, Instagram, Twitter, and on our website at:\n{support_url}\n\nVersion {version}\nShort Device ID: {id} (press OK to see full Device ID)\n\n© {year} Tubi, Inc. all rights reserved."
    },
    "screenSettings_menu_parentalControls": {
      "description": "The label for the parental controls",
      "message": "Parental Controls"
    },
    "screenSettings_menu_autoplayPreview": {
      "description": "The label for the autoplay preview",
      "message": "Autoplay Previews"
    },
    "screenSettings_menu_autoplayControls": {
      "description": "The Label for the autoplay controls to turn video preview and autoplay of the next video on or off.",
      "message": "Autoplay Controls"
    },
    "screenSettings_menu_autoplayNextVideo": {
      "description": "The label for the autoplay next video",
      "message": "Autoplay Next Video"
    },
    "screenSettings_parentalControls_group_LittleKids": {
      "description": "Little Kids of the parental controls",
      "message": "Little Kids",
      "note": "This translation is used as screenSettings_parentalControls_group_LittleKids, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_OlderKids": {
      "description": "Older Kids of the parental controls",
      "message": "Older Kids",
      "note": "This translation is used as screenSettings_parentalControls_group_OlderKids, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_Teens": {
      "description": "Teens of the parental controls",
      "message": "Teens",
      "note": "This translation is used as screenSettings_parentalControls_group_Teens, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_Adults": {
      "description": "Adults of the parental controls",
      "message": "Adults",
      "note": "This translation is used as screenSettings_parentalControls_group_Adults, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_instructions": {
      "description": "Description of the parental controls screen",
      "message": "Please select the appropriate viewing age for Tubi TV. Your selection will determine which movie and show ratings you can view in the app. If this selection is changed, you will be required to enter your account password."
    },
    "screenSettings_autoplayPreview_instructions": {
      "description": "Description of the autoplay preview user choice screen",
      "message": "You can turn the autoplay functionality on or off, which allows you to preview the video while browsing."
    },
    "screenSettings_autoplayTimer_instructions": {
      "description": "Description of the autoplay timer user choice screen",
      "message": "Content is set up to automatically play another video when what you're watching is about to end."
    },
    "screenSettings_autoplayTimer_instructions_guest_users": {
      "description": "Description of the autoplay timer user choice screen for guest users",
      "message": "Content is set up to automatically play another video when what you're watching is about to end. You need to sign in to use this feature."
    },
    "screenSettings_autoplayPreview_featureDisabledMessage": {
      "description": "Message to display when the user has set Autoplay to false in Roku(not tubi) main settings.",
      "message": "Autoplay is currently controlled in Roku Settings. To change this setting, go to Roku Settings -> Accessibility -> Auto-play video."
    },
    "screenSettings_menu_about": {
      "description": "A menu Item for the Settings screen",
      "message": "About"
    },
    "screenSettings_menu_privacyPolicy": {
      "description": "A menu Item for the Settings screen",
      "message": "Privacy Policy"
    },
    "screenSettings_menu_tos": {
      "description": "A menu Item for the Settings screen",
      "message": "Terms of Service"
    },
    "screenSettings_menu_yourPrivacyChoices": {
      "description": "A menu Item for the Settings screen",
      "message": "Your Privacy Choices"
    },
    "screenSettings_menu_PrivacyCenter": {
      "description": "A menu Item for the Settings screen",
      "message": "Privacy Center"
    },
    "screenSettings_menu_signOut": {
      "description": "A menu Item for the Settings screen",
      "message": "Sign Out"
    },
    "screenSettings_signInPanel_title": {
      "description": "The title of the Sign In Panel of the Settings screen",
      "message": "You’re not signed in yet"
    },
    "screenSettings_parentalPassword_title": {
      "description": "Directions for signed out users who attempt to change the parental controls",
      "message": "Enter Password to update parental controls"
    },
    "screenSettings_parentalPassword_button_hide": {
      "description": "Label of button on the password entry screen to hide the password",
      "message": "Hide Password"
    },
    "screenSettings_parentalPassword_button_show": {
      "description": "Label of button on the password entry screen to display the password",
      "message": "Show Password"
    },
    "screenSettings_error_parentalFailedChange_title": {
      "description": "title of error screen when parental controls failed to update",
      "message": "Update Failed"
    },
    "screenSettings_error_parentalFailedChange_description": {
      "description": "description of error screen when parental controls failed to update",
      "message": "Failed to update parental control settings.  Please try re-entering your password."
    },
    "screenSettings_error_parentalChanges": {
      "description": "title of dialog message when parental controls has changed",
      "message": "Parental Controls Settings Change"
    },
    "screenSettings_error_parentalChanges_description_default": {
      "description": "description of dialog message when parental controls has changed",
      "message": "Parental controls setting has changed. Parental controls will be password protected after 5 minutes."
    },
    "screenSettings_error_parentalChanges_description_group0": {
      "description": "Success message when parental controls has changed to group 0",
      "message": "Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group1": {
      "description": "Success message when parental controls has changed to group 1",
      "message": "Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group2": {
      "description": "Success message when parental controls has changed to group 2",
      "message": "Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group3": {
      "description": "Success message when parental controls has changed to group 3",
      "message": "Parental controls setting has changed to Adults. Parental controls will be password protected after 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_signInParental_description": {
      "description": "Description of message to let users know that they must be signed in to adjust the parental controls.",
      "message": "You must be signed in to adjust parental controls"
    },
    "screenSettings_error_signInAutoplayPreview_description": {
      "description": "Description of message to let users know that they must be signed in to change the AutoplayPreview choice.",
      "message": "You must be signed in to change Autoplay Preview preferences."
    },
    "screenCategories_error_retrieve_message": {
      "description": "Onscreen message to indicate categories content could not be gathered",
      "message": "Could not retrieve categories content."
    },
    "screenHome_error_fetchCategories_description": {
      "description": "Onscreen message to indicate categories content could not be loaded",
      "message": "Unable to load some categories."
    },
    "screenHome_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate home content could not be loaded",
      "message": "Unable to load the Tubi Home screen."
    },
    "screenEspanol_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate espanol content could not be loaded",
      "message": "Unable to load the Tubi Espanol screen."
    },
    "screenMovies_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate movies content could not be loaded",
      "message": "Unable to load the Tubi Movies screen."
    },
    "screenKids_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate kids home content could not be loaded",
      "message": "Unable to load the Tubi Kids screen."
    },
    "screenTv_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate TV content could not be loaded",
      "message": "Unable to load the Tubi TV Shows screen."
    },
    "epg_minutes_left": {
      "description": "Indicate the number of minutes left. Use an abbreviation for minutes to save space and so we don't have to worry about plural and singular forms of the word minutes.",
      "message": "{minutes}m left"
    },
    "hour_mins_left":{
      "description": "Indicates time left in the format 'x hour y mins left'",
      "message": "{hour} hour {minutes} mins left"
    },
    "mins_left":{
      "description": "Indicates time left in the format 'y mins left'",
      "message": "{minutes} mins left"
    },
    "today":{
      "description": "Today",
      "message": "TODAY"
    },
    "tomorrow":{
      "description": "Tomorrow",
      "message": "TOMORROW"
    },
    "onNow":{
      "description": "badge text to show program is not live but on now",
      "message": "ON NOW"
    },
    "day_1":{
      "description": "shortened version Monday, formatted with , and a space",
      "message": "Mon, "
    },
    "day_2":{
      "description": "shortened version Tuesday, formatted with , and a space",
      "message": "Tue, "
    },
    "day_3":{
      "description": "shortened version Wednessday, formatted with , and a space",
      "message": "Wed, "
    },
    "day_4":{
      "description": "shortened version Thursday, formatted with , and a space",
      "message": "Thur, "
    },
    "day_5":{
      "description": "shortened version Friday, formatted with , and a space",
      "message": "Fri, "
    },
    "day_6":{
      "description": "shortened version Saturday, formatted with , and a space",
      "message": "Sat, "
    },
    "day_7":{
      "description": "shortened version Sunday, formatted with , and a space",
      "message": "Sun, "
    },
    "short_version_date_format_1":{
      "description": "Shortened version of date format for the month of January",
      "message": "Jan {day}, {year}"
    },
    "short_version_date_format_2":{
      "description": "Shortened version of date format for the month of February",
      "message": "Feb {day}, {year}"
    },
    "short_version_date_format_3":{
      "description": "Shortened version of date format for the month of March",
      "message": "Mar {day}, {year}"
    },
    "short_version_date_format_4":{
      "description": "Shortened version of date format for the month of April",
      "message": "Apr {day}, {year}"
    },
    "short_version_date_format_5":{
      "description": "Shortened version of date format for the month of May",
      "message": "May {day}, {year}"
    },
    "short_version_date_format_6":{
      "description": "Shortened version of date format for the month of June",
      "message": "Jun {day}, {year}"
    },
    "short_version_date_format_7":{
      "description": "Shortened version of date format for the month of July",
      "message": "Jul {day}, {year}"
    },
    "short_version_date_format_8":{
      "description": "Shortened version of date format for the month of August",
      "message": "Aug {day}, {year}"
    },
    "short_version_date_format_9":{
      "description": "Shortened version of date format for the month of September",
      "message": "Sep {day}, {year}"
    },
    "short_version_date_format_10":{
      "description": "Shortened version of date format for the month of October",
      "message": "Oct {day}, {year}"
    },
    "short_version_date_format_11":{
      "description": "Shortened version of date format for the month of November",
      "message": "Nov {day}, {year}"
    },
    "short_version_date_format_12":{
      "description": "Shortened version of date format for the month of December",
      "message": "Dec {day}, {year}"
    },
    "channelGuide_error_fetchContent_description": {
      "description": "Onscreen message to indicate channel Guide content could not be loaded",
      "message": "Unable to load the Channel Guide."
    },
    "screenMyStuff_signedOutUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "Make Tubi Yours for Free (Forever)"
    },
    "screenMyStuff_signedOutUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Find your favorites fast, pick up where you left off–all in one place."
    },
    "screenMyStuff_signedOutUIBlurb": {
      "description": "The blurb of the MyStuff Screen for the guest user.",
      "message": "And always free."
    },
    "screenMyStuff_signedOutUIButton": {
      "description": "The button of the MyStuff Screen for the guest user.",
      "message": "Unlock Now"
    },
    "screenMyStuff_allEmptyUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "My Stuff is Empty"
    },
    "screenMyStuff_allEmptyUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Use the bookmark button to save series and movies to your My List."
    },
    "screenDetails_button_trailer": {
      "description": "Label of button to allow users to watch a preview of the current video title",
      "message": "Watch Trailer"
    },
    "screenDetails_button_episodes": {
      "description": "Label of button to allow users to display the list of episodes/seasons of the current video title. Should be title case.",
      "message": "All Episodes"
    },
    "screenDetails_button_episodes_more": {
      "description": "Label displayed over episodes list + YMAL on the details Screen.",
      "message": "Episodes And More"
    },
    "screenDetails_relatedTitles": {
      "description": "Label of button to allow users to view other video titles related to the current video title",
      "message": "You Might Also Like"
    },
    "screenDetails_button_play": {
      "description": "Label of button to allow users to play the current video title",
      "message": "Play"
    },
    "screenDetails_button_startOver": {
      "description": "Label of button to allow users to start over and play the current video title",
      "message": "Play from Beginning"
    },
    "screenDetails_button_like_instructions": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": " - Remove Rating"
    },
    "screenDetails_button_like": {
      "description": "Label of button to allow users to like the current video title",
      "message": "Like"
    },
    "screenDetails_button_likeIt": {
      "description": "Label of button to allow users to like the current video title",
      "message": "I like it"
    },
    "screenDetails_button_removeRating": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": "Remove Rating"
    },
    "screenDetails_button_liked": {
      "description": "Label of button to indicate to users that the current video title has been liked",
      "message": "Liked"
    },
    "screenDetails_button_dislike": {
      "description": "Label of button to allow users to dislike the current video title",
      "message": "Dislike"
    },
    "screenDetails_button_disliked": {
      "description": "Label of button to indicate to users that the current video title has been disliked",
      "message": "Disliked"
    },
    "screenDetails_button_notForMe": {
      "description": "Label of button to allow users to ignore the current video title",
      "message": "Not for me"
    },
    "screenDetails_button_likeDislike": {
      "description": "Label of unfocused button to allow users to like or dislike the current video title",
      "message": "Like or Dislike"
    },
    "screenDetails_button_sign_in_to_set_reminder": {
      "description": "Label of button to allow users to set the reminder to the current video title when the user is not signed in.",
      "message": "Sign In to Set Reminder"
    },
    "screenDetails_button_set_reminder": {
      "description": "Label of button to allow users to set the reminder to the current video title when the user is signed in.",
      "message": "Set Reminder"
    },
    "screenDetails_button_remove_reminder": {
      "description": "Label of button to indicate the users that reminder is set on the current video title",
      "message": "Remove Reminder"
    },
    "screenDetails_button_resume_playing": {
      "description": "Label of button to allow users to resume the current video title",
      "message": "Resume Playing"
    },
    "screenAgeVerification_network_issue": {
      "description": "An error message shown to users when they submit their birthdate, but there is an unexpected server or network error",
      "message": "Could not successfully send your birthdate to our servers."
    },
    "screenSignUpAgeVerification_sub_header_age": {
      "description": "A sub header message to direct users to enter their age",
      "message": "To continue, please verify your age"
    },
    "screenSignUpAgeVerification_request_age_prefix": {
      "description": "Label to ask user to enter their age. This part precedes the age provided",
      "message": "I'm"
    },
    "screenSignUpAgeVerification_request_age_postfix": {
      "description": "Label to ask user to enter their age. This part comes after the age provided",
      "message": "Years Old"
    },
    "screenSignUpAgeVerification_error_prompt_age": {
      "description": "A message informing the user that they entered an age that is not acceptable",
      "message": "Please enter a valid age"
    },
    "screenAgeVerification_header": {
      "description": "A header message on the Age required screen asking them to confirm their age",
      "message": "Confirm your age*"
    },
    "screenAgeVerification_sub_header": {
      "description": "A sub header message to direct users to enter their birth date",
      "message": "To continue, please verify your year of birth"
    },
    "screenAgeVerification_keypad_button": {
      "description": "A message on the button below the birth date keypad that users should select once done inserting their birth date",
      "message": "Start Watching"
    },
    "screenAgeVerification_year": {
      "description": "A label explaining that the 4 digits above the label signify the year that was input by the user",
      "message": "Year of Birth"
    },
    "screenAgeVerification_yyyy": {
      "description": "A label showing that the user should enter four digits for their birthdate year",
      "message": "YYYY"
    },
    "screenAgeVerification_warning_prompt": {
      "description": "A message informing the user that they entered a date that is not valid",
      "message": "Please be sure the information you entered is correct"
    },
    "screenAgeVerification_error_prompt": {
      "description": "A message informing the user that they entered a date that is not acceptable",
      "message": "Please enter a valid year of birth"
    },
    "metadata_fullscreen_countdown_plural": {
      "description": "label to indicate how many seconds it will take before the video player will automatically go fullscreen. This is the plural version but an attempt should be made to ensure the string is neither plural or singular by using a shorten form of seconds.",
      "message": "Fullscreen in {seconds} sec"
    },
    "metadata_fullscreen_countdown_no_seconds": {
      "description": "label to indicate how many seconds it will take before the video player will automatically go fullscreen. The word 'seconds' should NOT follow the number of seconds.",
      "message": "Fullscreen in {seconds}"
    },
    "metadata_watch_again": {
      "description": "label to indicate a watched video can be watched again",
      "message": "Watch again"
    },
    "metadata_expiresIn_plural": {
      "description": "label to indicate how long the user have to watch a video",
      "message": "Expires in {days} days"
    },
    "metadata_expiresIn_singular": {
      "description": "label to indicate the user has exactly 1 day to watch a video",
      "message": "Expires in 1 day"
    },
    "metadata_myStuff_empty_myList_title": {
      "description": "For an empty MyList container, this is the title that is displayed in the empty container",
      "message": "Your My List Is Empty"
    },
    "metadata_myStuff_empty_myList_description": {
      "description": "For an empty MyList container, this is the description/subtitle that is display in the empty container",
      "message": "Use the bookmark button to save favorite series and movies. They’ll show up here."
    },
    "metadata_myStuff_empty_continueWatching_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the empty container",
      "message": "You're All Caught Up!"
    },
    "metadata_myStuff_empty_continueWatching_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the empty container",
      "message": "Movies and series you haven’t finished will show up here."
    },
    "metadata_myStuff_empty_continueWatchingInfoPanel_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the InfoPanel when the empty container is in focus",
      "message": "Continue Watching"
    },
    "metadata_myStuff_myLikes_title": {
      "description": "The title of the My Likes container.",
      "message": "My Likes"
    },
    "metadata_myStuff_empty_myListInfoPanel_description": {
      "description": "For an empty myList container, this is the description/subtitle that is display in the InfoPanel when the empty container is in focus",
      "message": "Watch what you saved for later."
    },
    "metadata_myStuff_empty_myListInfoPanel_title": {
      "description": "For an empty myList container, this is the title that is display in the InfoPanel when the empty container is in focus",
      "message": "My List"
    },
    "metadata_myStuff_empty_continueWatchingInfoPanel_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the InfoPanel when the empty container is in focus",
      "message": "Pick up right where you left off."
    },
    "metadata_continueWatching_notSignedIn_title": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Sign Up to Save Your Progress"
    },
    "metadata_continueWatching_notSignedIn_description": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Pick up right where you left off next time you play a TV Series or a Movie. Available upon sign up."
    },
    "metadata_continueWatching_notSignedIn_container_description": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "No Subscription  •  No Credit Card  •  Free Forever"
    },
    "metadata_continueWatching_notSignedIn_container_button": {
      "description": "button text for when a non registered user focuses on the continue watching container",
      "message": "Sign Up to Save Progress - FREE"
    },
    "metadata_directed": {
      "description": "metadata label to indicate the directors of the current video title",
      "message": "Directed by"
    },
    "metadata_starring": {
      "description": "metadata label to indicate the actors of the current video title",
      "message": "Starring"
    },
    "metadata_hoursAndMinutes": {
      "description": "a duration listed in hours and minutes (abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "{hours} h {minutes} min"
    },
    "metadata_hours": {
      "description": "a duration listed in hours (abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "{hours} h"
    },
    "metadata_minutes": {
      "description": "a duration listed in minutes (abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "{minutes} min"
    },
    "metadata_seconds": {
      "description": "a duration listed in seconds (abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "{seconds} sec"
    },
    "metadata_seasons_plural": {
      "description": "Label of how many seasons of the current TV title",
      "message": "{seasons} Seasons"
    },
    "metadata_seasons_singular": {
      "description": "Label for when the current TV title has exactly one season",
      "message": "1 Season"
    },
    "metadata_series": {
      "description": "Label to indicate a title is a TV series",
      "message": "Series"
    },
    "sponsor_brought_by": {
      "description": "When content is sponsored by an advertizer, then this text proceeds the image of the sponsor. The text and the image should make a complete sentence.",
      "message": "Brought to you by"
    },
    "registration_signIn_recommended":{
      "description": "text appended to recommended row label to subtly remind users that they are signed out so that they understand that they need to sign-in to use Tubi at its fullest",
      "message":"Sign In for a more personalized experience"
    },
    "screenEndCard_startingIn": {
      "description": "indicator for how many seconds until next video will start playing (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "Starting in {seconds} s"
    },
    "videoPlayer_trailerTitle": {
      "description": "Label for the video preview associated with the current video title",
      "message": "Trailer ({title})"
    },
    "videoPlayer_adLoadingMessage": {
      "description": "Message to indicate ads will play before playing video content",
      "message": "Your program will begin after these messages..."
    },
    "videoPlayer_error_failed_description": {
      "description": "label for error messages to indicate 'failed'",
      "message": "FAILED"
    },
    "videoPlayer_error_invalidURL_description": {
      "description": "Error message to indicate that the video URL is invalid.",
      "message": "Video URL is not valid."
    },
    "videoPlayer_error_playback_description": {
      "description": "Error message when video could not play",
      "message": "There was an issue with video playback."
    },
    "videoPlayer_adHeadsUp": {
      "description": "Warning when the ad break is about to begin. (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "AD Break starts in {seconds} s"
    },
    "videoPlayer_toast_message": {
      "description": "Message to be displayed on Toast-message when user signed in.",
      "message": "You are now successfully signed in"
    },
    "linearVideoPlayer_buttonBack": {
      "description": "Label of a Button to go back",
      "message": "Back"
    },
    "linearVideoPlayer_buttonCaptions": {
      "description": "Label of a Button to display the closed captions",
      "message": "Captions"
    },
    "linearVideoPlayer_buttonCaptions2": {
      "description": "Label of a Button to display the closed captions",
      "message": "Subtitles"
    },
    "linearVideoPlayer_buttonGuide": {
      "description": "Label of a Button to view the channel guide",
      "message": "Guide"
    },
    "linearVideoPlayer_buttonGuide2": {
      "description": "Label of a Button to view the channel guide",
      "message": "Full TV Guide"
    },
    "linearVideoPlayer_buttonTvGuide": {
      "description": "Label of a Button to view the TV channel guide",
      "message": "TV Guide"
    },
    "linearVideoPlayer_buttonLanguage": {
      "description": "Label of a Button which is displayed on linear player screen to select language",
      "message": "Language"
    },
    "linearVideoPlayer_comingUp": {
      "description": "Label of a coming up program in linear video player",
      "message": "Coming up"
    },
    "linearVideoPlayer_comingUpAt": {
      "description": "Label of a coming up program with time in linear video player",
      "message": "Coming up at {time}"
    },
    "linearVideoPlayer_timeLeft": {
      "description": "Label to display time left in linear video player info panel",
      "message": "{time} left"
    },
    "channel_name": {
      "description": "This is the name of the app. This is not located in the app. It is displayed to the user in the Roku Channel Store",
      "message": "Tubi - Free Movies & TV"
    },
    "channel_description": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Channel Store",
      "message": "Enjoy the largest library of popular movies and TV shows, all for free!",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "channel_webDescription": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Web Channel Store",
      "message": "Watch thousands of hit movies and TV series for free. Tubi is 100% legal unlimited streaming, with no credit cards and no subscription required. Choose what you want to watch, when you want to watch it, with fewer ads than regular TV. Tubi is the largest free streaming service featuring award-winning movies and TV series. There is something for everybody; from comedy to drama, kids to classics, and niche favorites such as Korean dramas, anime, and British series. Download now and start streaming entertainment for free, today!",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "dialog_whoops_title": {
      "description": "A general whoops title for an dialog window",
      "message": "Whoops!"
    },
    "dialog_mylist_signIn_description": {
      "description": "Dialog description to say the user to signIn to view the My List",
      "message": "You must be logged in to view your list"
    },
    "dialog_mylist_empty_title": {
      "description": "A general empty My list title for an dialog window",
      "message": "Oh no! Your List is empty"
    },
    "dialog_mylist_empty_description": {
      "description": "Dialog description to say My List is empty",
      "message": "Find everything you add to My List here. To get started, select a TV Show or Movie and select the Add to My List button."
    },
    "dialog_button_register_signIn": {
      "description": "The label of the button in a dialog window that allows the user to register or signIn",
      "message": "Sign In or Register"
    },
    "why_ask_age_description": {
      "description": "The main message which explains why Tubi is asking for the users year of birth",
      "message": "*We process this information as described in Tubi's Privacy Policy and Terms of Use. For more information, see www.tubi.tv/privacy and www.tubi.tv/terms. Questions? Let us know at www.tubi.tv/support"
    },
    "signIn_screen_heading": {
      "description": "Title on the signIn screen",
      "message": "Sign In to Your Account"
    },
    "signIn_screen_enter_password": {
      "description": "enter password text",
      "message": "Enter your Tubi password"
    },
    "forgot_password_text": {
      "description": "forgot password text",
      "message": "Forgot password?"
    },
    "forgot_password_link": {
      "description": "forgot password link",
      "message": "Go to tubi.tv/forgot to reset"
    },
    "signIn_password_hint": {
      "description": "hint shown on signIn password textbox",
      "message": "password"
    },
    "signUp_password_hint": {
      "description": "hint shown on signUp password textbox",
      "message": "set a password"
    },
    "signUp_screen_heading": {
      "description": "Title on the signUp screen",
      "message": "Sign Up for a New Account"
    },
    "signUp_screen_password_validation": {
      "description": "sign up screen password validation text",
      "message": "Press OK on your remote and set a new password"
    },
    "already_having_account_text": {
      "description": "already having account text",
      "message": "Already have an account?"
    },
    "password_length_validation": {
      "description": "password length validation",
      "message": "Password must be 6-30 characters long"
    },
    "invalid_password_title": {
      "description": "invalid password title on modal",
      "message": "Invalid Password"
    },
    "invalid_oops_password_title": {
      "description": "invalid password title on modal",
      "message": "Oops, wrong Password"
    },
    "enter_password_dialog_description": {
      "description": "enter password dialog description",
      "message": "Please enter your Tubi password for the account"
    },
    "invalid_oops_password_description": {
      "description": "enter password dialog description",
      "message": "Let's try again or enter a different password for this account:"
    },
    "retry": {
      "description": "retry button text on modal",
      "message": "Retry"
    },
    "could_not_verify_email": {
      "description": "could not verify your email modal description",
      "message": "Could not verify your email"
    },
    "check_email_inbox": {
      "description": "Title on the email verification screen",
      "message": "Check Your Email Inbox"
    },
    "click_on_verification_link": {
      "description": "Message shown on the email verification screen about the verification link sent to email",
      "message": "Please click the verification link sent to your email:"
    },
    "screen_refresh_after_email_verification": {
      "description": "Message shown on the email verification to let the user know screen will refresh after the email verification",
      "message": "This screen will refresh once you have verified your email."
    },
    "rated_Label": {
      "description": "Label shown on video player when tv rating/descriptor is shown",
      "message": "RATED"
    },
    "skipIntro_Player":{
      "description": "Navigational instructions to users to skip the introduction section of the title. Usually the song or the beginning credits",
      "message": "Skip Intro"
    },
    "skipRecap_Player":{
      "description": "Navigational instructions to users to skip the section where the previous part of the show is recapped",
      "message": "Skip Recap"
    },
    "skipEarlyCredits_Player":{
      "description": "Navigational instructions to users to skip when the Credits are followed by a scene",
      "message": "Skip Early Credits"
    },
    "invalid_email_title": {
      "description": "Asking to enter a valid email on Email screen",
      "message": "Please enter a valid email"
    },
    "email_screen_heading": {
      "description": "Asking to enter a email on Email screen",
      "message": "Enter Email Address"
    },
    "screenAgeVerification_born_year": {
      "description": "Label to ask user to enter their year of birth",
      "message": "I was born in"
    },
    "signIn_screen_subheading": {
      "description": "Sub title on the signIn screen",
      "message": "Your email is already linked to an existing Tubi account"
    },
    "forgotPassword_screen_heading": {
      "description": "Title on the forgot password screen",
      "message": "Help is on the way!"
    },
    "forgotPassword_screen_instant_subheading": {
      "description": "Sub title on the forgot password screen - instant version",
      "message": "Go to this email inbox and click the instant sign-in link:"
    },
    "forgotPassword_screen_noInstant_subheading": {
      "description": "Sub title on the forgot password screen - no instant version",
      "message": "Go to this email inbox and click the password reset link:"
    },
    "forgotPassword_screen_instant_subheading2": {
      "description": "2nd Sub title on the forgot password screen - instant version",
      "message": "This screen will refresh once you have clicked the link in your email."
    },
    "forgotPassword_screen_noInstant_subheading2": {
      "description": "2nd Sub title on the forgot password screen - noInstant version",
      "message": "After your password is reset, click below to try signing in."
    },
    "forgotPassword_screen_btn_resend": {
      "description": "The button on the forgot password screen that corresponds to the action 'Resend Sign-in link",
      "message": "Resend Sign-In Link"
    },
    "forgotPassword_screen_btn_different_email": {
      "description": "The button on the forgot password screen that corresponds to the action 'Use Different Email",
      "message": "Use Different Email"
    },
    "search_hint": {
      "description": "Instructions to the user to use microphone icon on his/her remote to use voice enabled keyboard. Please note that a microphone icon will be placed immediately after the last word of this translation and the icon will be considered part of the sentence.",
      "message": "To use your voice enabled remote, press and hold"
    },
    "search_voice_hint": {
      "description": "Instructions to the user to use microphone icon on his/her remote to use voice enabled keyboard. Please note that a microphone icon will be placed at the beginning of the sentence.",
      "message": "To use your voice enabled remote, press and hold microphone button"
    },
    "dialog_button_signUp": {
      "description": "The label of the button in a dialog window that allows the user to sign up into the app.",
      "message": "Sign Up"
    },
    "screenSettings_parentalPassword_setup_new_password": {
      "description": "Directions for users who attempt to change the parental controls",
      "message": "To setup a new password"
    },
    "screenSettings_parentalPassword_visit_link": {
      "description": "Directions for users to setup the new password",
      "message": "visit tubi.tv/password"
    },
    "screenSettings_parentalPassword_visit_webBrowser": {
      "description": "Directions for users to setup the new password on browser",
      "message": "1. Please visit tubi.tv/password on a web browser"
    },
    "screenSettings_parentalPassword_email": {
      "description": "Directions to the user to enter his/her email to setup new password",
      "message": "2. Enter the email "
    },
    "screenSettings_parentalPassword_set_new_Password": {
      "description": "Directions to the user about email notification to setup new password",
      "message": "3. We’ll send you instructions to set a new password"
    },
    "screenSettings_parentalPassword_know_my_Password": {
      "description": "Directions to the user to enter his/her password if they know their password",
      "message": "I know my password. Let's go."
    },
    "registration_signup_button": {
      "description": "button text for when a non registered user focuses on details screen",
      "message": "Sign Up to Save Progress"
    },
    "registration_signup_button_free": {
      "description": "button text on top of background image next to sign up text for when a non registered user focuses on details screen",
      "message": "FREE"
    },
    "registration_signIn_to_play_button": {
      "description": "button text for when a non registered user focuses on details screen for sportsEvent",
      "message": "Sign In to Play"
    },
    "registration_signIn_to_play_R_rated": {
      "description": "Hint message why we have locked the content.",
      "message": "Sign in required to protect younger audiences. No credit card needed."
    },
    "registration_signIn_to_play_default": {
      "description": "Hint message why we have locked the content. This is the default message",
      "message": "Sign in required. No credit card needed."
    },
    "text_new":{
      "description": "simple text to use anywhere to indicate item is new",
      "message": "NEW"
    },
    "screenEmailVerification_resend_verification_link": {
      "description": "Label of button to allow users to resend the email verification link for sign in",
      "message": "Resend Verification Link"
    },
    "screenEmailVerification_use_different_email": {
      "description": "Label of button to allow users to use different email address for sign in",
      "message": "Use Different Email"
    },
    "next_button": {
      "description": "Button text displayed on onBoarding screens to proceed to next screens",
      "message": "Next"
    },
    "skip_button": {
      "description": "Button text displayed on onBoarding screens to skip the onboarding flow",
      "message": "Skip"
    },
    "getStarted_button": {
      "description": "Button text displayed on onBoarding screens, takes to landing screen",
      "message": "Get Started"
    },
    "registerOrSignIn_button": {
      "description": "Button text displayed on onBoarding screens takes to Roku Request for Information modal",
      "message": "Continue with Roku"
    },
    "continueAsGuest_button": {
      "description": "Button text displayed on onBoarding screens takes to Initial Content Type Selector Screen or Home Screen",
      "message": "Continue as Guest"
    },
    "onBoarding_landingScreen_addListLabel": {
      "description": "Label displayed on onBoarding Landing screen informing add to your list",
      "message": "Add to Your List"
    },
    "onBoarding_landingScreen_saveProgressLabel": {
      "description": "Label displayed on onBoarding Landing screen informing save your progress",
      "message": "Save Your Progress"
    },
    "onBoarding_landingScreen_saveProgressBody": {
      "description": "Body displayed on onBoarding Landing screen informing pickup where you left off",
      "message": "Pickup where you left off"
    },
    "dialog_got_it": {
      "description": "simple text to use anywhere to indicate dismiss action",
      "message": "Got it"
    },
    "reg_intro_title": {
      "description": "title displayed on registration welcome modal",
      "message": "Tubi is better when you sign in"
    },
    "reg_intro_sub_header":{
      "description": "sub header displayed on registraton welcome modal",
      "message": "No credit card. Free Forever."
    },
    "reg_first_line_sub_item": {
      "description": "first sub item to be displayed under reg_first_line_item to explain user about benifit of registration",
      "message": "Save now to watch later"
    },
    "reg_third_line_item":{
      "description": "third item to let know user about the benifit of registration",
      "message": "Unlock Picks Just for You"
    },
    "reg_third_line_sub_item":{
      "description": "third sub item to be displayed under reg_third_line_item to explain user about benifit of registration",
      "message": "Get better recommendations"
    },
    "reg_sign_in_button_title": {
      "description": "Button text to be displayed on first button of registration welcome modal",
      "message": "Continue to Sign In"
    },
    "reg_continue_as_guest_button_title": {
      "description": "Button text to be displayed on second button of registration welcome modal",
      "message": "Continue as Guest"
    },
    "ad": {
      "description": "This label used for badge overlaid on top of a thumbnail to indicate it is associated with an AD. The text needs to be very few characters.",
      "message": "AD"
    },
    "replay": {
      "description": "This label used for badge to indicate the content availability",
      "message": "Replay"
    },
    "info_panel_reminder_is_set": {
      "description": "Hint in the content metadata area informing the user that the reminder is set for this content",
      "message": "Reminder set"
    },
    "info_panel_available_in_4k": {
      "description": "Lets user know this content is available in 4k (although may not be available on their device)",
      "message": "Available in 4K"
    },
    "goBack_videoPlayer_ad": {
      "description": "Navigational instructions to users when pause Ad is displayed on video screen",
      "message": "Press any button to close the ad"
    },
    "cc_audio_overlay_subtitles": {
      "description": "Available closed caption tracks section header label.",
      "message": "Subtitles"
    },
    "cc_audio_overlay_audio": {
      "description": "Available audio tracks section header label.",
      "message": "Audio"
    },
    "consent_screen_heading": {
      "description": "Consent screen heading.",
      "message": "Your Privacy"
    },
    "consent_screen_subheading": {
      "description": "Consent screen sub heading.",
      "message": "Please take a moment to confirm your data privacy preferences"
    },
    "manage_preferences_button_label": {
      "description": "Manage preferences button label.",
      "message": "Manage Preferences"
    },
    "accept_all_button_label": {
      "description": "Accept button label.",
      "message": "Accept All"
    },
    "reject_all_button_label": {
      "description": "Reject button label.",
      "message": "Reject All"
    },
    "privacy_preferences_label": {
      "description": "privacy preferences screen title.",
      "message": "Privacy Settings"
    },
    "privacy_preferences_save_continue_button": {
      "description": "Save and Continue button on Consent Manage preferences",
      "message": "Save and Continue"
    },
    "privacy_preferences_privacy_section_heading": {
      "description": "Privacy section heading.",
      "message": "Privacy Policy"
    },
    "privacy_preferences_privacy_section_subheading": {
      "description": "Privacy section subheading.",
      "message": "To view Tubi's Privacy Policy, scan the QR code below with your mobile device or visit "
    },
    "privacy_preferences_tos_section_heading": {
      "description": "Terms of service section heading.",
      "message": "Terms of Use"
    },
    "privacy_preferences_tos_section_subheading": {
      "description": "Terms of service section subheading.",
      "message": "To view Tubi's Terms of Use, scan the QR code below with your mobile device or visit "
    },
    "privacy_preferences_qrcode_modal_subheading": {
      "description": "QR Code Selected Modal subheading.",
      "message": "Scan the QR Code on the previous screen with your mobile device to view the link."
    },
    "privacy_preferences_on": {
      "description": "Privacy preferences toggle text on",
      "message": "On"
    },
    "privacy_preferences_off": {
      "description": "Privacy preferences toggle text off",
      "message": "Off"
    },
    "privacy_preferences_required": {
      "description": "Privacy preferences required text",
      "message": "Required"
    },
    "required_preference_selected_toast_heading": {
      "description": "Toast header when required preference item is selected.",
      "message": "Setting Required"
    },
    "required_preference_selected_toast_message": {
      "description": "Toast message when required preference item is selected.",
      "message": "{preference} Functionality is necessary to continue."
    },
    "privacy_center_not_editable_mode_warning": {
      "description": "Warning label that will be displayed in privacy center whenever user is in kids mode or any parental controls mode.",
      "message": "Privacy settings can only be changed outside Tubi Kids. Only essential data is used within Tubi Kids."
    },
    "accept_now_button_label": {
      "description": "Button Label that will be used in consent screen accept button.",
      "message": "Accept Now"
    },
    "maybe_later_button_label": {
      "description": "Button Label that will be used in consent screen Maybe later button.",
      "message": "Maybe Later"
    },
    "roku_cw_consent_screen_heading": {
      "description": "Roku Continue Watching screen heading.",
      "message": "Get Back to What You Love Faster"
    },
    "roku_cw_consent_screen_sub_heading": {
      "description": "Roku Continue Watching screen sub heading.",
      "message": "Make it easier to jump back into what you were watching and get better recommendations on what to stream next.\n\nSelect “Accept Now” to give Tubi permission to share your video watch history with Roku.\n\nYou can change this any time in Settings."
    },
    "player_exit_prompt_signup_heading": {
      "description": "Video Player exit prompt signup header",
      "message": "Wait, don’t lose your progress!"
    },
    "player_exit_prompt_signup_sub_heading": {
      "description": "Video Player exit prompt signup sub header",
      "message": "Sign up to save your progress to pick up where you left off. No credit card required."
    },
    "player_exit_prompt_signup_later_button": {
      "description": "Video Player exit prompt signup later",
      "message": "Sign Up Later"
    },
    "trending_search_results_hint": {
      "description": "Trending Search Results hint which will be displayed in the search screen when we do not have enough search results.",
      "message": "Here are other trending searches you may like"
    },
    "search_results_no_matching_results": {
      "description": "No matching results message which will be displayed in search results screen.",
      "message": "We couldn't find any results for"
    },
    "privacy_center_save_restart": {
      "description": "Settings screen privacy center save and restart consent button label.",
      "message": "Save and Restart Tubi"
    },
    "gdpr_age_gate_error_dialog_heading": {
      "description": "GDPR age gate error dialog heading.",
      "message": "We're sorry"
    },
    "gdpr_age_gate_error_dialog_sub_heading": {
      "description": "GDPR age gate error dialog sub heading.",
      "message": "You are not eligible to continue."
    },
    "gdpr_age_gate_error_dialog_exit_tubi": {
      "description": "GDPR age gate error dialog exit tubi button label.",
      "message": "Exit Tubi"
    },
    "updated_terms_toast_message": {
      "description": "Message on the toast message informing the user of update ToS. Please keep style tags intact when translating.",
      "message": "<defaultStyle>We have updated our Terms of Use. By continuing to use Tubi, you agree to these updated terms. You can view our terms at </defaultStyle><urlStyle>https://tubitv.com/static/terms</urlStyle>"
    },
    "updated_terms_toast_header": {
      "description": "Header on the toast message informing the user of update ToS",
      "message": "Important"
    },
    "privacy_center_restart_channel": {
      "description": "Settings screen privacy center restart channel button label.",
      "message": "Restart"
    },
    "save_consent_dialog_heading": {
      "description": "Settings screen save consent dialog heading.",
      "message": "Privacy Preferences Updated"
    },
    "save_consent_dialog_sub_heading": {
      "description": "Settings screen save consent dialog sub heading.",
      "message": "You must restart Tubi for changes to take effect."
    },
    "privacy_center_view_privacy_settings_hint": {
      "description": "Settings screen privacy center view privacy settings hint.",
      "message": "You must save privacy setting changes and restart Tubi for changes to take effect."
    },
    "privacy_center_view_privacy_settings": {
      "description": "Settings screen privacy center launch preferences center button label.",
      "message": "View Privacy Settings"
    },
    "privacy_disclaimer": {
      "description": "Privacy disclaimer text displayed in Sign in and registration flow.",
      "message": "By registering or signing in, you agree that you have read and understood Tubi's Privacy Policy and agree to Tubi's Terms of Use. Learn more at {privacy_policy_url} and {terms_of_use_url}"
    },
    "dialog_gdpr_manage_privacy_settings_error_description": {
      "description": "Error dialog description shown due to one trust component library failure when clicking manage privacy settings.",
      "message": "Please try restarting Tubi to update the privacy settings. Please email support@tubi.tv if this keeps happening."
    },
    "live_on_date": {
      "description": "date label used in air date countdown timer",
      "message": "LIVE ON {month} {day}"
    },
    "live_on_date_today": {
      "description": "date label used in air date countdown timer",
      "message": "TODAY AT {time}"
    },
    "live_on_day": {
      "description": "day label used in air date countdown timer",
      "message": "{day} D"
    },
    "dialog_gdpr_manage_privacy_settings_error_description": {
      "description": "Error dialog description shown due to one trust component library failure when clicking manage privacy settings.",
      "message": "Please try restarting Tubi to update the privacy settings. Please email support@tubi.tv if this keeps happening."
    },
    "cc_audio_overlay_subtitles_mode": {
      "description": "Available modes displayed on closed caption overlay",
      "message": "Subtitles Mode"
    },
    "live_on_hour": {
      "description": "day label used in air date countdown timer",
      "message": "{hour} HR"
    },
    "live_on_minute": {
      "description": "day label used in air date countdown timer",
      "message": "{min} MIN"
    },
    "screenHome_button_sign_in_watch": {
      "description": "Sign in to watch live button label.",
      "message": "Sign In to Watch"
    },
    "available_at": {
      "description": "Sign in to watch live button label.",
      "message": "Available at {time}"
    },
    "watch_for_free": {
      "description": "Sign in to watch live button label.",
      "message": "Watch free on {date}."
    },
    "auth_refresh_welcome_message": {
      "description": "A message that let's the user know they've been signed in with the given email",
      "message": "Signed in as {email}"
    },
    "auth_refresh_welcome_header": {
      "description": "A header for the message that let's the user know they've been signed in with the given email",
      "message": "Welcome!"
    },
    "resolution_full_hd": {
      "description": "Title of the 1080p resolution label in the infopanel",
      "message": "FULL HD"
    },
    "available_at_toast_heading": {
      "description": "Toast message heading that is displayed when we click on a available at button",
      "message": "Content available at {time}"
    },
    "available_at_toast_subheading": {
      "description": "Toast message subheading that is displayed when we click on a available at button",
      "message": "We know you're excited. So are we!"
    },
    "sign_in_error_screen_heading": {
      "description": "Sign in error screen heading default error",
      "message": "We can't sign you in right now"
    },
    "sign_in_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favorite movies and TV shows as a guest."
    },
    "sign_in_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favorite movies and TV shows as a guest, including {major_event_name}!"
    },
    "sign_up_error_screen_heading": {
      "description": "Sign in error screen heading default error",
      "message": "We can't create an account for you right now"
    },
    "sign_up_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favorite movies and TV shows as a guest.\nWe'll send you an email to try again later."
    },
    "sign_up_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favorite movies and TV shows as a guest, including {major_event_name}!\nWe'll send you an email to try again later."
    },
    "mylist_disabled_message": {
      "description": "My List disabled toast message",
      "message": "My Stuff is currently unavailable."
    },
    "rating_disabled_message": {
      "description": "Like/Dislike disabled toast message",
      "message": "Rating is currently unavailable."
    },
    "continue_watching_disabled_message": {
      "description": "Continue watching disabled toast message",
      "message": "Continue Watching is currently unavailable."
    },
    "disaster_mode_toast_heading": {
      "description": "Heading of the toast that is shown on disaster mode UI.",
      "message": "We're having trouble connecting"
    },
    "disaster_mode_toast_subheading": {
      "description": "Subheading of the toast that is shown on disaster mode UI.",
      "message": "You can still watch {major_event_name}!"
    },
    "rating": {
      "description": "Like/Dislike feature",
      "message": "Rating"
    },
    "delayed_registration_message": {
      "description": "Message displayed when user tries to register and the registration is delayed",
      "message": "We'll try creating your account in the next 24 hours and if successful, we'll send you an email to finish setting up your account."
    },
    "game": {
      "description": "Fallback string to be used when major event name is not available in remote config",
      "message": "game"
    },
    "havent_received_email": {
      "description": "Message displayed in sign in screen during major event day",
      "message": "Haven't received an email? You can still continue as Guest."
    }
  }
End Function


' ::NOTE:: do not directly modify this function. Modify the strings found in Crowdin and then run the gulp download command described in the repo's readMe file.
' Return the associative array associated with the esMX locale
Function getTranslation_es_MX()
  return {
    "foxVideoPlayer_error_contentUnavailableMessage": {
      "description": "Used when the fox video player displays a dialog requiring the error_contentUnavailableMessage text string.",
      "message": "Nuestras disculpas, pero el contenido no está disponible en este momento. Por favor, inténtelo más tarde.\nSi continúa teniendo este problema, visita help.tubitv.com."
    },
    "foxVideoPlayer_error_generic": {
      "description": "Used when the fox video player displays a dialog requiring the error_generic text string.",
      "message": "Nuestras disculpas, pero el contenido no está disponible en este momento. Por favor, inténtelo más tarde.\nSi continúa teniendo este problema, visita help.tubitv.com."
    },
    "menu_signIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into app.",
      "message": "Iniciar Sesión"
    },
    "menu_goHome": {
      "description": "Menu option on the app's myStuff screen, Allows the user to  navigate to the home screen.",
      "message": "Ir a Inicio"
    },
    "menu_signedIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Shows that the user is signed in.",
      "message": "Hola {name}"
    },
    "menu_kids": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into kids mode.",
      "message": "Niños"
    },
    "menu_exitKids": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to exit kids mode.",
      "message": "Salir Niños"
    },
    "menu_search": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the search screen.",
      "message": "Buscar"
    },
    "menu_foryou": {
      "description": "Menu option on the app's top nav for pillshaped, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Para ti"
    },
    "component_library_failed": {
      "description": "Latest Version of Tubi app failed to load due to some error",
      "message": "{errCode}\nEl canal de Tubi no se cargó completamente. Es posible que falte alguna funcionalidad."
    },
    "epg_starts_at": {
      "description": "Program time Title when user selects a future program on EPG.",
      "message": "Comienza en"
    },
    "epg_started_at": {
      "description": "Program time Title for live program.",
      "message": "Comenzó a las"
    },
    "detail_screen_like_disLike_toast_header": {
      "description": "header text to be displayed on Toast-message when user like/dislike a title",
      "message": "Gracias por tus comentarios!"
    },
    "detail_screen_like_toast_message": {
      "description": "Message to be displayed on Toast-message when user liked a title",
      "message": "Sugeriremos más títulos como este en futuras recomendaciones."
    },
    "detail_screen_disLike_toast_message": {
      "description": "Message to be displayed on Toast-message when user disliked a title",
      "message": "Sugeriremos menos títulos como este en futuras recomendaciones."
    },
    "menu_home": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Inicio"
    },
    "menu_categories": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the categories screen.",
      "message": "Categorías"
    },
    "menu_channels": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the channels screen.",
      "message": "Canales"
    },
    "menu_networks": {
      "description": "Title for a container of channels tiles.",
      "message": "Canales"
    },
    "menu_movies": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the movies screen.",
      "message": "Películas"
    },
    "menu_tv": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the tv shows screen.",
      "message": "Series"
    },
    "menu_livetv": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the live TV screen.",
      "message": "TV En Vivo"
    },
    "menu_mystuff": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the my stuff screen.",
      "message": "Mis Cosas"
    },
    "menu_settings": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the settings screen.",
      "message": "Configuración"
    },
    "menu_exit": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to exit the app.",
      "message": "Salir"
    },
    "screenHome_item_showAllGames": {
      "description": "The text to display on Show All Games tile",
      "message": "Mostrar Todo"
    },
    "screenHome_button_spotlight_details": {
      "description": "On the home screen of the spotlight row, this is the text of a details button that allows the user to go to the details screen",
      "message": "Detalles"
    },
    "screenHome_button_spotlight_watch_live": {
      "description": "On the home screen of the spotlight row, this is the text of a watch live button that allows the user to start playing focused live content",
      "message": "Ver en Vivo"
    },
    "screenHome_button_spotlight_watch_now": {
      "description": "On the home screen of the spotlight row, this is the text of a watch now button that allows the user to start playing focused linear content",
      "message": "Ver Ahora"
    },
    "loadingIndicator": {
      "description": "When something is loading, this text appears so the user knows something is loading.",
      "message": "Cargando..."
    },
    "dialog_defaultError_title": {
      "description": "The default title of a popup error dialog",
      "message": "Algo salió mal"
    },
    "dialog_uidExpiraionError_title": {
      "description": "The title of a popup error dialog when link has been expired during signup process",
      "message": "Este enlace de verificación ha expirado"
    },
    "dialog_defaultError_description": {
      "description": "The default message of a popup error dialog",
      "message": "Disculpa la molestia. Para obtener ayuda, ponte en contacto con support@tubi.tv"
    },
    "dialog_magicLink_error_description": {
      "description": "The message of a popup error dialog when user magicLink API fails and user doesn't get verification link to their emial",
      "message": "Estamos teniendo problemas para procesar esta solicitud. Verifica tu conexión o vuelve a intentarlo haciendo clic en Reenviar enlace de Verificación"
    },
    "dialog_uidExpiraionError_description": {
      "description": "The description of a popup error dialog when link has been expired during signup process",
      "message": "Para obtener un nuevo enlace de verificación, haz clic nuevamente en el enlace Reenviar Verificación"
    },
    "dialog_errorMessageContact": {
      "description": "The contact info displayed in an error dialog",
      "message": "Por favor, ponte en contacto con: support@tubi.tv si esto sigue sucediendo."
    },
    "dialog_button_exit": {
      "description": "In a popup dialog that asks if the user if they wish to exit the app. This is the button that will confirm their exit.",
      "message": "Salir"
    },
    "dialog_button_signIn": {
      "description": "The label of the button in a dialog window that allows the user to sign into the app.",
      "message": "Iniciar Sesión"
    },
    "dialog_button_cancel": {
      "description": "Label of a dialog button to cancel out of the dialog",
      "message": "Cancelar"
    },
    "dialog_button_continue": {
      "description": "Label of a dialog button to continue to the next step that the dialog is saying",
      "message": "Continuar"
    },
    "dialog_button_forgot_password": {
      "description": "Label of a dialog button to take the user to the steps in case he/she has forgotten the account password. ",
      "message": "Olvidé Contraseña"
    },
    "dialog_button_submit": {
      "description": "Label of the dialog button to submit what the window is asking it to do.",
      "message": "Enviar"
    },
    "dialog_button_tryAgain": {
      "description": "Label of the dialog button to try again what the app had attempted to do.",
      "message": "Inténtalo de nuevo"
    },
    "dialog_button_close": {
      "description": "Label of the dialog button to close the dialog window",
      "message": "Cerrar"
    },
    "dialog_button_skip": {
      "description": "Label of the dialog button to skip what is being asked",
      "message": "Saltar"
    },
    "dialog_button_off": {
      "description": "Label of the dialog button to turn something off: i.e. turn off closed captions",
      "message": "Apagar"
    },
    "dialog_button_on": {
      "description": "Label of the dialog button to turn something on: i.e. turn on autoplay preview",
      "message": "Encender"
    },
    "dialog_button_settings": {
      "description": "Label of the dialog button to cause the app to go to the settings screen.",
      "message": "Ir a configuración"
    },
    "dialog_email_verification_email_already_sent": {
      "description": "The first line of the email verification description dialog",
      "message": "Ya se ha enviado un correo electrónico de verificación a"
    },
    "dialog_email_verification_check_spam": {
      "description": "The second line of the email verification description dialog",
      "message": "Por favor, recuerda revisar tu sección de spam"
    },
    "dialog_button_resend_verification_link": {
      "description": "Label of the dialog button to resend the email verification link",
      "message": "Sí, Reenviar correo clectrónico de verificación"
    },
    "dialog_button_attempts_title": {
      "description": "Title of the dialog after user selects resend verification link more than 3 times",
      "message": "Demasiados Intentos"
    },
    "dialog_button_multiple_emails_sent": {
      "description": "The first line of the too many attempts dialog",
      "message": "Ya se han enviado varios correos electrónicos de verificación a"
    },
    "dialog_errorOops_title": {
      "description": "A general error title for an error dialog window",
      "message": "¡Uy!"
    },
    "dialog_espanolDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav espanol menu item but the item has been disabled",
      "message": "Español desactivado"
    },
    "dialog_moviesDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav movies menu item but the item has been disabled",
      "message": "Películas desactivado"
    },
    "dialog_tvDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav TV menu item but the item has been disabled",
      "message": "TV Series Deshabilitados"
    },
    "dialog_linearEPGDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav Live TV menu item but the item has been disabled",
      "message": "TV en Vivo Deshabilitada"
    },
    "dialog_sideNavItemDisabled_description": {
      "description": "Message of a Dialog Window that is shown when the user clicked on a sidenav menu item but the item has been disabled",
      "message": "Por favor, sal de Tubi Niños para usar esta función."
    },
    "dialog_sideNavItemDisabled_Parental_description": {
      "description": "Message of a Dialog Window that is shown when the user clicked on a sidenav menu item but the item has been disabled due to parental set to Teens",
      "message": "Por favor, desactiva el control parental para utilizar esta función."
    },
    "dialog_contentNotAvailable_Parental_description": {
      "description": "Message of a Dialog Window that is shown when a deeplink content can not played because of user's parental control setting",
      "message": "Por favor, desactiva el control parental para utilizar esta función."
    },
    "error_connection_title": {
      "description": "title of error window when there is a connection error",
      "message": "Error de conexión"
    },
    "error_connection_description": {
      "description": "description of error window when there is a connection error",
      "message": "Puede haber un problema con tu conexión de red, o con el servidor de Tubi. Por favor, comprueba tu conexión de red e inténtalo de nuevo."
    },
    "dialog_updateVersion_title": {
      "description": "title of a dialog window that is shown when the user has an older version of the app",
      "message": "Por favor, actualiza el canal de Tubi"
    },
    "dialog_updateVersion_description": {
      "description": "message of a dialog window that is shown when the user has an older version of the app",
      "message": "Esta versión de Tubi ya no es compatible. Para actualizar, sal de la aplicación Tubi y ve a:\n\nConfiguración> Sistema> Actualización del sistema> Verificar ahora"
    },
    "dialog_fullSynopsis_title": {
      "description": "title of a dialog window that shows the full description of a video item",
      "message": "Sinopsis completa"
    },
    "dialog_parentalPassword_title": {
      "description": "title of the dialog window when guest user signs in and still needs to enter his/her password to change the parental controls",
      "message": "Ingresa tu contraseña"
    },
    "dialog_parentalPassword_description": {
      "description": "description of the dialog window when guest user signs in and still needs to enter his/her password to change the parental controls",
      "message": "Gracias por registrarse. Para actualizar los controles parentales a tu configuración deseada, ingresa tu contraseña."
    },
    "dialog_signIn_title": {
      "description": "title of a dialog window when it asks the user to sign in",
      "message": "Por favor, Iniciar Sesión"
    },
    "dialog_confirmCorrectAge_title": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct year",
      "message": "¿Naciste en {birthYear}?"
    },
    "dialog_confirmCorrectAge_title_age": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct age",
      "message": "¿Tienes {age} años?"
    },
    "dialog_confirmCorrectAge_description": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct year",
      "message": "Por favor confirma para continuar"
    },
    "dialog_confirmCorrectAge_confirm": {
      "description": "label of a dialog window button that will confirm app user's age is correct",
      "message": "Sí"
    },
    "dialog_confirmCorrectAge_edit": {
      "description": "label of a dialog window button that will let user edit their age again",
      "message": "Editar"
    },
    "dialog_kidsExit_title": {
      "description": "title of a dialog window when the user is attempting to exit kids Mode",
      "message": "Salir Niños"
    },
    "dialog_kidsExit_button_ok": {
      "description": "label of a dialog window button that will confirm app should exit kids mode",
      "message": "Salir Niños"
    },
    "dialog_kidsExitLimited_description": {
      "description": "description of a dialog window that describes what the user should do to exit kids mode",
      "message": "Para salir de Niños, actualiza los controles parentales en la configuración de la cuenta."
    },
    "dialog_kidsWelcome_title": {
      "description": "A message welcoming the user to Tubi Kids",
      "message": "Bienvenido a Tubi Niños"
    },
    "dialog_kidsWelcomeAgeGate_description": {
      "description": "A description informing users they cannot exit Tubi Kids for the next 24 hours",
      "message": "No puedes salir de Tubi Kids en este momento. Inténtelo de nuevo en 24 horas. Preguntas? Envíanos una línea a www.tubi.tv/support"
    },
    "dialog_cannotExitKidsMode_title": {
      "description": "Title for dialog telling the user they can not exit kids mode",
      "message": "No se pudo Salir del Modo Niños"
    },
    "dialog_cannotExitKidsMode_description": {
      "description": "Description for dialog telling the user they can not exit kids mode",
      "message": "Por favor, inténtelo de nuevo en 24 horas.\nPreguntas? Háganos saber en support@tubi.tv"
    },
    "dialog_exitApp_title": {
      "description": "Title of the dialog window that asks the user if they want to exit the app",
      "message": "¿Estás seguro?"
    },
    "dialog_exitApp_description": {
      "description": "description of the dialog window that asks the user if they want to exit the app",
      "message": "¿Seguro que quieres salir de Tubi?"
    },
    "error_noGetChannels_description": {
      "description": "description of the error dialog when channel content could not get received from the server.",
      "message": "No se pudo recuperar el contenido del canal."
    },
    "error_noGetChannelGuide_description": {
      "description": "description of the error dialog when channel guide content could not get received from the server.",
      "message": "No se pudo recuperar la guía de canales."
    },
    "error_noContent_description": {
      "description": "description of the error dialog when there was no content to be gathered from the server.",
      "message": "Esta página actualmente no tiene ningún contenido."
    },
    "error_mustBeSignedIn_description": {
      "description": "Description of the warning dialog when user needs to be signed in to view a video.",
      "message": "Para ver este video gratis, por favor, regístrate o inicia sesión."
    },
    "error_matureContent_title": {
      "description": "Title of the dialog window when user attempts to play mature content but they need to be signed in first",
      "message": "Contenido adulto"
    },
    "dialog_signOut_title": {
      "description": "Title of the dialog window that asks the user if they want to sign out of the app",
      "message": "¿Estás seguro?"
    },
    "dialog_signOut_description": {
      "description": "description of the dialog window that asks the user if they want to sign out of the app",
      "message": "Estás a punto de cerrar sesión en tu cuenta de Tubi."
    },
    "dialog_signOut_button_ok": {
      "description": "label of the confirmation button of the dialog window that asks the user if they want to sign out of the app",
      "message": "Cerrar Sesión"
    },
    "error_check_birthdate_description": {
      "description": "message letting the user know that they were not able to be signed in",
      "message": "Hubo un error al inciar la sesión. Por favor, ingresa al canal y inicia la sesión de nuevo."
    },
    "screenSearch_defaultLinearSearch": {
      "description": "Directions on the search page",
      "message": "Busca películas, series, TV en vivo, y personas"
    },
    "screenSearch_defaultSearch": {
      "description": "Directions on the search page",
      "message": "Busca películas, series y personas"
    },
    "screenSearch_trendingSearch": {
      "description": "A header message that shows on top of default search results in search screen",
      "message": "Búsquedas populares"
    },
    "screenSearch_kidsWarning": {
      "description": "More directions on the search screen to suggest switching to kids mode.  Should be limited to be around 40 characters or fewer.",
      "message": "Cambiar a Niños para resultados seguros"
    },
    "screenSearch_loading": {
      "description": "The label of the loading indictor on the search screen",
      "message": "Actualizando tus resultados..."
    },
    "screenSearch_noResults": {
      "description": "onscreen message when there are no search results.",
      "message": "No pudimos encontrar resultados para '{term}'\n Inténtalo de nuevo"
    },
    "screenSearch_results": {
      "description": "message after loading search results.",
      "message": "Resultados"
    },
    "screenSearch_matchingTitles": {
      "description": "text after number of search results for searchedString",
      "message": "títulos coinciden"
    },
    "screenSearch_liveText": {
      "description": "The label on the search results poster next to the live streaming icon",
      "message": "En Vivo"
    },
    "screenDetails_button_queue": {
      "description": "label of the button that will add the video title to the user's list",
      "message": "Agregar a Mi Lista"
    },
    "screenDetails_button_noQueue": {
      "description": "label of the button that will remove the video title from the user's list",
      "message": "Eliminar de Mi Lista"
    },
    "screenDetails_button_noHistory": {
      "description": "label of the button that will remove the video title from the user's viewing history",
      "message": "Eliminar del historial"
    },
    "screenDetails_button_changingRating": {
      "description": "label of the button when the user has clicked the button and the like/dislike state of the video title is changing",
      "message": "Cambiando Calificaciones..."
    },
    "screenDetails_button_queueNow": {
      "description": "label of the button when the user has clicked the button and the video title is being added to the user's list",
      "message": "Agregando..."
    },
    "screenDetails_button_removing": {
      "description": "label of the button when the user has clicked the button and the video title is being removed from the user's list or viewing history",
      "message": "Eliminando..."
    },
    "screenDetails_button_gotoChannel": {
      "description": "Label of the button that will take the user to the channel associated with the current video title",
      "message": "Ir a {channel}"
    },
    "screenDetails_error_addQueue_title": {
      "description": "Title of the warning dialog when user is attempting to add an item to their list but are not signed in",
      "message": "Se necesita cuenta"
    },
    "screenDetails_error_addQueueMovie_description": {
      "description": "Description of the warning dialog when user is attempting to add a movie to their list but are not signed in",
      "message": "Inicia sesión o regístrate en Tubi para agregar esta película a tu lista."
    },
    "screenDetails_error_addQueueSeries_description": {
      "description": "Description of the warning dialog when user is attempting to add a TV show/series to their list but are not signed in",
      "message": "Inicia sesión o regístrate en Tubi para agregar esta serie a tu lista."
    },
    "screenDetails_error_setReminderSports_description": {
      "description": "Description of the warning dialog when user is attempting to set reminder but are not signed in",
      "message": "Inicia sesión o regístrate para obtener una cuenta de Tubi y establecer un recordatorio."
    },
    "screenDetails_error_addQueueSports_description": {
      "description": "Description of the warning dialog when user is attempting to add a game to their list but are not signed in",
      "message": "Inicia sesión o regístrate en Tubi para agregar este juego a tu lista."
    },
    "screenDetails_error_getContent_description": {
      "description": "Description of error when app is not able to get content.",
      "message": "No se pudo recuperar la información del contenido del servidor."
    },
    "error_deeplink_content": {
      "description": "Error message when the app can not retrieve the deeplink content.",
      "message": "El título que has elegido no está disponible en este momento"
    },
    "error_deeplink_page": {
      "description": "Error message when the app can not retrieve the page requested through deeplink",
      "message": "El título que has elegido no está disponible en este momento"
    },
    "error_tryAgain_title": {
      "description": "Error message when the user has the option to try the operation again.",
      "message": "Intentémoslo de nuevo"
    },
    "screenDetails_queue_content_added_to_list_description": {
      "description": "Message when a content is added to the user's list after sign in.",
      "message": "Contenido"
    },
    "screenDetails_queue_added_to_list_description": {
      "description": "Message when a movie/series/replay game is added to the user's list after sign in.",
      "message": "{contentTitle} ha sido agregado a la lista."
    },
    "screenDetails_queue_added_to_reminder_list_description": {
      "description": "Message when a upcoming game is added to the user's reminder list after sign in.",
      "message": "{upcomingTitle} ha sido establecido en los recordatorios."
    },
    "screenDetails_error_queueMovie_description": {
      "description": "Error message when a movie is not added to the user's list.",
      "message": "No estamos seguros de lo que pasó, pero algo salió mal al tratar de agregar esta película a tu lista."
    },
    "screenDetails_error_queueSeries_description": {
      "description": "Error message when a tv show/series is not added to the user's list.",
      "message": "No estamos seguros de lo que pasó, pero algo salió mal al tratar de agregar esta serie a tu lista."
    },
    "screenDetails_error_noQueueMovie_description": {
      "description": "Error message when a movie is not removed from the user's list.",
      "message": "No estamos seguros de lo que pasó, pero algo salió mal al tratar de eliminar esta película de tu lista."
    },
    "screenDetails_error_noQueueSeries_description": {
      "description": "Error message when a tv show/series is not removed from the user's list.",
      "message": "No estamos seguros de lo que pasó, pero algo salió mal al tratar de eliminar esta serie de tu lista."
    },
    "screenDetails_error_noQueueUpcoming_description": {
      "description": "Error message when a upcoming game is not removed from the user's reminders list.",
      "message": "No estamos seguros de lo que sucedió, pero algo salió mal al intentar retirar el recordatorio."
    },
    "screenDetails_error_noQueueReplay_description": {
      "description": "Error message when a replay game is not removed from the user's list.",
      "message": "No estamos seguros de lo que pasó, pero algo salió mal al tratar de eliminar el evento deportivo de la lista."
    },
    "screenDetails_error_likeDislike_description": {
      "description": "Error message when a video title's like/dislike rating is not changed.",
      "message": "No estamos seguros de lo que sucedió, pero algo salió mal al intentar cambiar la calificación."
    },
    "screenDetails_error_noHistory_description": {
      "description": "Error message when video is not removed from the user's viewing history.",
      "message": "Algo salió mal al eliminar el contenido de tu historial."
    },
    "screenSettings_signIn_description": {
      "description": "Directions for the signin page",
      "message": "Inicia sesión en tu cuenta de Tubi en tu computadora o dispositivo móvil para ver las series y películas guardadas en Mi Lista, continuar viendo desde donde te quedaste, recibir recomendaciones personalizadas en sincronización con tu dispositivo móvil, televisor, tableta o computadora."
    },
    "screenSettings_signOut_description": {
      "description": "Description on SignIn page when user is signed in",
      "message": "Has iniciado sesión como {name}"
    },
    "screenSettings_signOut_description2": {
      "description": "More details on the SignIn page when user is signed in",
      "message": "Correo electrónico: {email}"
    },
    "screenSettings_fullDeviceID": {
      "description": "Text proceeding the full device ID",
      "message": "ID de dispositivo completo"
    },
    "screenSettings_about_title": {
      "description": "The title of the about screen",
      "message": "Acerca de Tubi"
    },
    "screenSettings_about_description": {
      "description": "The description on the about screen",
      "message": "Tubi es la aplicación más grande de series y películas gratuitas. Tenemos un catálogo de contenido con miles de películas y series con muchos menos anuncios que la televisión por cable."
    },
    "screenSettings_about_title2": {
      "description": "The subtitle on the about screen",
      "message": "¿Necesitas ayuda?"
    },
    "screenSettings_about_description2": {
      "description": "The 2nd description on the about screen",
      "message": "Visita {help_url}\n\nEnvía un correo electrónico a nuestro equipo de apoyo a support@tubi.tv\n\nPonte en contacto con nosotros en Facebook, Instagram, Twitter y en nuestra página web: \n{support_url} \n\nVersión {version}\nID de dispositivo corto: {id} (presiona OK para ver el ID de dispositivo completo)\n\n© {year} Tubi, Inc. todos los derechos reservados."
    },
    "screenSettings_menu_parentalControls": {
      "description": "The label for the parental controls",
      "message": "Controles parentales"
    },
    "screenSettings_menu_autoplayPreview": {
      "description": "The label for the autoplay preview",
      "message": "Avance de Video"
    },
    "screenSettings_menu_autoplayControls": {
      "description": "The Label for the autoplay controls to turn video preview and autoplay of the next video on or off.",
      "message": "Controles de Auto-Reproducir"
    },
    "screenSettings_menu_autoplayNextVideo": {
      "description": "The label for the autoplay next video",
      "message": "Auto-Reproducir Siguiente Video"
    },
    "screenSettings_parentalControls_group_LittleKids": {
      "description": "Little Kids of the parental controls",
      "message": "Niños Pequeños",
      "note": "This translation is used as screenSettings_parentalControls_group_LittleKids, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_OlderKids": {
      "description": "Older Kids of the parental controls",
      "message": "Niños Mayores",
      "note": "This translation is used as screenSettings_parentalControls_group_OlderKids, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_Teens": {
      "description": "Teens of the parental controls",
      "message": "Adolescentes",
      "note": "This translation is used as screenSettings_parentalControls_group_Teens, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_Adults": {
      "description": "Adults of the parental controls",
      "message": "Adultos",
      "note": "This translation is used as screenSettings_parentalControls_group_Adults, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_instructions": {
      "description": "Description of the parental controls screen",
      "message": "Elige la edad de visualización adecuada para Tubi. Tu selección determinará qué clasificaciones de películas y programas puedes ver en la aplicación. Si se modifica esta selección, pediremos que ingreses la contraseña de tu cuenta."
    },
    "screenSettings_autoplayPreview_instructions": {
      "description": "Description of the autoplay preview user choice screen",
      "message": "Puedes activar o desactivar la función de reproducción automática, que te permite ver el vídeo mientras navegas."
    },
    "screenSettings_autoplayTimer_instructions": {
      "description": "Description of the autoplay timer user choice screen",
      "message": "Contenido está configurado para Auto-Reproducir otro video cuando lo que estás viendo está por terminar."
    },
    "screenSettings_autoplayTimer_instructions_guest_users": {
      "description": "Description of the autoplay timer user choice screen for guest users",
      "message": "Contenido está configurado para Auto-Reproducir otro video cuando lo que estás viendo está por terminar. Debes iniciar sesión para usar esta función."
    },
    "screenSettings_autoplayPreview_featureDisabledMessage": {
      "description": "Message to display when the user has set Autoplay to false in Roku(not tubi) main settings.",
      "message": "Reproducción automática se controla desde la configuración de Roku. Para cambiarla, ve a Configuración de Roku -> Accesibilidad -> Reproducción automática de video."
    },
    "screenSettings_menu_about": {
      "description": "A menu Item for the Settings screen",
      "message": "Acerca de"
    },
    "screenSettings_menu_privacyPolicy": {
      "description": "A menu Item for the Settings screen",
      "message": "Política de privacidad"
    },
    "screenSettings_menu_tos": {
      "description": "A menu Item for the Settings screen",
      "message": "Términos de servicio"
    },
    "screenSettings_menu_yourPrivacyChoices": {
      "description": "A menu Item for the Settings screen",
      "message": "Sus Opciones de Privacidad"
    },
    "screenSettings_menu_PrivacyCenter": {
      "description": "A menu Item for the Settings screen",
      "message": "Centro de Privacidad"
    },
    "screenSettings_menu_signOut": {
      "description": "A menu Item for the Settings screen",
      "message": "Cerrar sesión"
    },
    "screenSettings_signInPanel_title": {
      "description": "The title of the Sign In Panel of the Settings screen",
      "message": "No has iniciado sesión"
    },
    "screenSettings_parentalPassword_title": {
      "description": "Directions for signed out users who attempt to change the parental controls",
      "message": "Ingresa contraseña para actualizar controles parentales"
    },
    "screenSettings_parentalPassword_button_hide": {
      "description": "Label of button on the password entry screen to hide the password",
      "message": "Ocultar contraseña"
    },
    "screenSettings_parentalPassword_button_show": {
      "description": "Label of button on the password entry screen to display the password",
      "message": "Mostrar contraseña"
    },
    "screenSettings_error_parentalFailedChange_title": {
      "description": "title of error screen when parental controls failed to update",
      "message": "Actualización falló"
    },
    "screenSettings_error_parentalFailedChange_description": {
      "description": "description of error screen when parental controls failed to update",
      "message": "Error al actualizar la configuración del control parental. Por favor, intenta volver a ingresar tu contraseña."
    },
    "screenSettings_error_parentalChanges": {
      "description": "title of dialog message when parental controls has changed",
      "message": "Cambio de configuración de controles parentales"
    },
    "screenSettings_error_parentalChanges_description_default": {
      "description": "description of dialog message when parental controls has changed",
      "message": "La configuración del control parental ha cambiado. Los controles parentales estarán protegidos con contraseña después de 5 minutos."
    },
    "screenSettings_error_parentalChanges_description_group0": {
      "description": "Success message when parental controls has changed to group 0",
      "message": "La configuración de los controles parentales ha cambiado a Niños pequeños. Los controles parentales estarán protegidos con contraseña después de 5 minutos.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group1": {
      "description": "Success message when parental controls has changed to group 1",
      "message": "La configuración de los controles parentales ha cambiado a Niños mayores. Los controles parentales estarán protegidos con contraseña después de 5 minutos.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group2": {
      "description": "Success message when parental controls has changed to group 2",
      "message": "La configuración de los controles parentales ha cambiado a Adolescentes. Los controles parentales estarán protegidos con contraseña después de 5 minutos.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group3": {
      "description": "Success message when parental controls has changed to group 3",
      "message": "La configuración de los controles parentales ha cambiado a Adultos. Los controles parentales estarán protegidos con contraseña después de 5 minutos.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_signInParental_description": {
      "description": "Description of message to let users know that they must be signed in to adjust the parental controls.",
      "message": "Debes iniciar sesión para ajustar los controles parentales"
    },
    "screenSettings_error_signInAutoplayPreview_description": {
      "description": "Description of message to let users know that they must be signed in to change the AutoplayPreview choice.",
      "message": "Debes iniciar sesión para cambiar las preferencias de reproducción automática."
    },
    "screenCategories_error_retrieve_message": {
      "description": "Onscreen message to indicate categories content could not be gathered",
      "message": "No se pudo recuperar el contenido de las categorías."
    },
    "screenHome_error_fetchCategories_description": {
      "description": "Onscreen message to indicate categories content could not be loaded",
      "message": "No se pudo cargar algunas categorías."
    },
    "screenHome_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate home content could not be loaded",
      "message": "No se pudo cargar la pantalla de inicio de Tubi."
    },
    "screenEspanol_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate espanol content could not be loaded",
      "message": "No se pudo cargar la pantalla de Tubi en Espanol."
    },
    "screenMovies_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate movies content could not be loaded",
      "message": "No se pudo cargar la pantalla de películas de Tubi."
    },
    "screenKids_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate kids home content could not be loaded",
      "message": "No se pudo cargar la pantalla de Tubi Niños."
    },
    "screenTv_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate TV content could not be loaded",
      "message": "No se pudo cargar la pantalla de series de Tubi."
    },
    "epg_minutes_left": {
      "description": "Indicate the number of minutes left. Use an abbreviation for minutes to save space and so we don't have to worry about plural and singular forms of the word minutes.",
      "message": "quedan {minutes} m"
    },
    "hour_mins_left": {
      "description": "Indicates time left in the format 'x hour y mins left'",
      "message": "{hour} horas {minutes} mins quedan"
    },
    "mins_left": {
      "description": "Indicates time left in the format 'y mins left'",
      "message": "{minutes} mins quedan"
    },
    "today": {
      "description": "Today",
      "message": "HOY"
    },
    "tomorrow": {
      "description": "Tomorrow",
      "message": "MAÑANA"
    },
    "onNow": {
      "description": "badge text to show program is not live but on now",
      "message": "AHORA"
    },
    "day_1": {
      "description": "shortened version Monday, formatted with , and a space",
      "message": "Lun, "
    },
    "day_2": {
      "description": "shortened version Tuesday, formatted with , and a space",
      "message": "Mar, "
    },
    "day_3": {
      "description": "shortened version Wednessday, formatted with , and a space",
      "message": "Mié, "
    },
    "day_4": {
      "description": "shortened version Thursday, formatted with , and a space",
      "message": "Jue, "
    },
    "day_5": {
      "description": "shortened version Friday, formatted with , and a space",
      "message": "Vie, "
    },
    "day_6": {
      "description": "shortened version Saturday, formatted with , and a space",
      "message": "Sáb, "
    },
    "day_7": {
      "description": "shortened version Sunday, formatted with , and a space",
      "message": "Dom, "
    },
    "short_version_date_format_1": {
      "description": "Shortened version of date format for the month of January",
      "message": "ene {day}, {year}"
    },
    "short_version_date_format_2": {
      "description": "Shortened version of date format for the month of February",
      "message": "feb {day}, {year}"
    },
    "short_version_date_format_3": {
      "description": "Shortened version of date format for the month of March",
      "message": "mar {day}, {year}"
    },
    "short_version_date_format_4": {
      "description": "Shortened version of date format for the month of April",
      "message": "abr {day}, {year}"
    },
    "short_version_date_format_5": {
      "description": "Shortened version of date format for the month of May",
      "message": "may {day}, {year}"
    },
    "short_version_date_format_6": {
      "description": "Shortened version of date format for the month of June",
      "message": "jun {day}, {year}"
    },
    "short_version_date_format_7": {
      "description": "Shortened version of date format for the month of July",
      "message": "jul {day}, {year}"
    },
    "short_version_date_format_8": {
      "description": "Shortened version of date format for the month of August",
      "message": "ago {day}, {year}"
    },
    "short_version_date_format_9": {
      "description": "Shortened version of date format for the month of September",
      "message": "sep {day}, {year}"
    },
    "short_version_date_format_10": {
      "description": "Shortened version of date format for the month of October",
      "message": "oct {day}, {year}"
    },
    "short_version_date_format_11": {
      "description": "Shortened version of date format for the month of November",
      "message": "nov {day}, {year}"
    },
    "short_version_date_format_12": {
      "description": "Shortened version of date format for the month of December",
      "message": "dic {day}, {year}"
    },
    "channelGuide_error_fetchContent_description": {
      "description": "Onscreen message to indicate channel Guide content could not be loaded",
      "message": "No se pudo cargar el guía de canales."
    },
    "screenMyStuff_signedOutUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "Haz Tubi Tuyo Gratis (Siempre)"
    },
    "screenMyStuff_signedOutUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Encuentra tus favoritos, continúa donde lo dejaste–todo en un solo lugar."
    },
    "screenMyStuff_signedOutUIBlurb": {
      "description": "The blurb of the MyStuff Screen for the guest user.",
      "message": "Y siempre gratis."
    },
    "screenMyStuff_signedOutUIButton": {
      "description": "The button of the MyStuff Screen for the guest user.",
      "message": "Desbloquear ahora"
    },
    "screenMyStuff_allEmptyUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "Mis Cosas esta Vacía"
    },
    "screenMyStuff_allEmptyUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Para añadir un título a Mi lista, utilice el icono de marcador."
    },
    "screenDetails_button_trailer": {
      "description": "Label of button to allow users to watch a preview of the current video title",
      "message": "Ver Tráiler"
    },
    "screenDetails_button_episodes": {
      "description": "Label of button to allow users to display the list of episodes/seasons of the current video title. Should be title case.",
      "message": "Todos Los Capítulos"
    },
    "screenDetails_button_episodes_more": {
      "description": "Label displayed over episodes list + YMAL on the details Screen.",
      "message": "Capítulos Y Más"
    },
    "screenDetails_relatedTitles": {
      "description": "Label of button to allow users to view other video titles related to the current video title",
      "message": "Puede que también te guste"
    },
    "screenDetails_button_play": {
      "description": "Label of button to allow users to play the current video title",
      "message": "Ver"
    },
    "screenDetails_button_startOver": {
      "description": "Label of button to allow users to start over and play the current video title",
      "message": "Ver desde el principio"
    },
    "screenDetails_button_like_instructions": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": " - Borrar Calificación"
    },
    "screenDetails_button_like": {
      "description": "Label of button to allow users to like the current video title",
      "message": "Me Gusta"
    },
    "screenDetails_button_likeIt": {
      "description": "Label of button to allow users to like the current video title",
      "message": "Me gusta"
    },
    "screenDetails_button_removeRating": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": "Borrar Calificación"
    },
    "screenDetails_button_liked": {
      "description": "Label of button to indicate to users that the current video title has been liked",
      "message": "Te Gustó"
    },
    "screenDetails_button_dislike": {
      "description": "Label of button to allow users to dislike the current video title",
      "message": "No Me Gusta"
    },
    "screenDetails_button_disliked": {
      "description": "Label of button to indicate to users that the current video title has been disliked",
      "message": "No Te Gustó"
    },
    "screenDetails_button_notForMe": {
      "description": "Label of button to allow users to ignore the current video title",
      "message": "No para mí"
    },
    "screenDetails_button_likeDislike": {
      "description": "Label of unfocused button to allow users to like or dislike the current video title",
      "message": "Me Gusta o No Me Gusta"
    },
    "screenDetails_button_sign_in_to_set_reminder": {
      "description": "Label of button to allow users to set the reminder to the current video title when the user is not signed in.",
      "message": "Inicia sesión para programar un Recordatorio"
    },
    "screenDetails_button_set_reminder": {
      "description": "Label of button to allow users to set the reminder to the current video title when the user is signed in.",
      "message": "Programar recordatorio"
    },
    "screenDetails_button_remove_reminder": {
      "description": "Label of button to indicate the users that reminder is set on the current video title",
      "message": "Eliminar Recordatorio"
    },
    "screenDetails_button_resume_playing": {
      "description": "Label of button to allow users to resume the current video title",
      "message": "Seguir viendo"
    },
    "screenAgeVerification_network_issue": {
      "description": "An error message shown to users when they submit their birthdate, but there is an unexpected server or network error",
      "message": "No pudimos mandar tu fecha de nacimiento a nuestros servidores con éxito."
    },
    "screenSignUpAgeVerification_sub_header_age": {
      "description": "A sub header message to direct users to enter their age",
      "message": "Para continuar, por favor verifica tu edad"
    },
    "screenSignUpAgeVerification_request_age_prefix": {
      "description": "Label to ask user to enter their age. This part precedes the age provided",
      "message": "Tengo"
    },
    "screenSignUpAgeVerification_request_age_postfix": {
      "description": "Label to ask user to enter their age. This part comes after the age provided",
      "message": "años de edad"
    },
    "screenSignUpAgeVerification_error_prompt_age": {
      "description": "A message informing the user that they entered an age that is not acceptable",
      "message": "Por favor, ingresa una edad válida"
    },
    "screenAgeVerification_header": {
      "description": "A header message on the Age required screen asking them to confirm their age",
      "message": "Confirma tu edad*"
    },
    "screenAgeVerification_sub_header": {
      "description": "A sub header message to direct users to enter their birth date",
      "message": "Para continuar, por favor confirma tu año de nacimiento"
    },
    "screenAgeVerification_keypad_button": {
      "description": "A message on the button below the birth date keypad that users should select once done inserting their birth date",
      "message": "Comienza a ver"
    },
    "screenAgeVerification_year": {
      "description": "A label explaining that the 4 digits above the label signify the year that was input by the user",
      "message": "Año de Nacimiento"
    },
    "screenAgeVerification_yyyy": {
      "description": "A label showing that the user should enter four digits for their birthdate year",
      "message": "AAAA"
    },
    "screenAgeVerification_warning_prompt": {
      "description": "A message informing the user that they entered a date that is not valid",
      "message": "Por favor, asegúrate de que la información que ingresaste sea correcta"
    },
    "screenAgeVerification_error_prompt": {
      "description": "A message informing the user that they entered a date that is not acceptable",
      "message": "Por favor, ingresa un año de nacimiento válido"
    },
    "metadata_fullscreen_countdown_plural": {
      "description": "label to indicate how many seconds it will take before the video player will automatically go fullscreen. This is the plural version but an attempt should be made to ensure the string is neither plural or singular by using a shorten form of seconds.",
      "message": "Pantalla completa en {seconds} s"
    },
    "metadata_fullscreen_countdown_no_seconds": {
      "description": "label to indicate how many seconds it will take before the video player will automatically go fullscreen. The word 'seconds' should NOT follow the number of seconds.",
      "message": "Pantalla completa en {seconds}"
    },
    "metadata_watch_again": {
      "description": "label to indicate a watched video can be watched again",
      "message": "Ver de nuevo"
    },
    "metadata_expiresIn_plural": {
      "description": "label to indicate how long the user have to watch a video",
      "message": "Expira en {days} días"
    },
    "metadata_expiresIn_singular": {
      "description": "label to indicate the user has exactly 1 day to watch a video",
      "message": "Expira en 1 día"
    },
    "metadata_myStuff_empty_myList_title": {
      "description": "For an empty MyList container, this is the title that is displayed in the empty container",
      "message": "Tu lista está vacía"
    },
    "metadata_myStuff_empty_myList_description": {
      "description": "For an empty MyList container, this is the description/subtitle that is display in the empty container",
      "message": "Use el marcador para guardar series y películas favoritas. Aparecerán aquí."
    },
    "metadata_myStuff_empty_continueWatching_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the empty container",
      "message": "Ya estas al día!"
    },
    "metadata_myStuff_empty_continueWatching_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the empty container",
      "message": "Películas y series que no hayas terminado de ver aparecerán aquí."
    },
    "metadata_myStuff_empty_continueWatchingInfoPanel_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the InfoPanel when the empty container is in focus",
      "message": "Seguir Viendo"
    },
    "metadata_myStuff_myLikes_title": {
      "description": "The title of the My Likes container.",
      "message": "Mis Gustos"
    },
    "metadata_myStuff_empty_myListInfoPanel_description": {
      "description": "For an empty myList container, this is the description/subtitle that is display in the InfoPanel when the empty container is in focus",
      "message": "Ver lo que guardaste para más tarde."
    },
    "metadata_myStuff_empty_myListInfoPanel_title": {
      "description": "For an empty myList container, this is the title that is display in the InfoPanel when the empty container is in focus",
      "message": "Mi Lista"
    },
    "metadata_myStuff_empty_continueWatchingInfoPanel_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the InfoPanel when the empty container is in focus",
      "message": "Recoge donde dejaste de ver."
    },
    "metadata_continueWatching_notSignedIn_title": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Regístrate para guardar tu progreso"
    },
    "metadata_continueWatching_notSignedIn_description": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Continúa justo donde dejaste de ver la próxima vez que veas una serie o película. Disponible al registrarte."
    },
    "metadata_continueWatching_notSignedIn_container_description": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Sin Suscripción  •  Sin Tarjeta de Crédito  •  Gratis Siempre"
    },
    "metadata_continueWatching_notSignedIn_container_button": {
      "description": "button text for when a non registered user focuses on the continue watching container",
      "message": "Regístrate para guardar tu progreso - GRATIS"
    },
    "metadata_directed": {
      "description": "metadata label to indicate the directors of the current video title",
      "message": "Dirigido por"
    },
    "metadata_starring": {
      "description": "metadata label to indicate the actors of the current video title",
      "message": "Protagonizado por"
    },
    "metadata_seasons_plural": {
      "description": "Label of how many seasons of the current TV title",
      "message": "{seasons} Temporadas"
    },
    "metadata_seasons_singular": {
      "description": "Label for when the current TV title has exactly one season",
      "message": "1 Temporada"
    },
    "sponsor_brought_by": {
      "description": "When content is sponsored by an advertizer, then this text proceeds the image of the sponsor. The text and the image should make a complete sentence.",
      "message": "Traído a ti por"
    },
    "registration_signIn_recommended": {
      "description": "text appended to recommended row label to subtly remind users that they are signed out so that they understand that they need to sign-in to use Tubi at its fullest",
      "message": "Inicia Sesión para una experiencia personalizada"
    },
    "screenEndCard_startingIn": {
      "description": "indicator for how many seconds until next video will start playing (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "Comenzando en {seconds} s"
    },
    "videoPlayer_trailerTitle": {
      "description": "Label for the video preview associated with the current video title",
      "message": "Traíler ({title})"
    },
    "videoPlayer_adLoadingMessage": {
      "description": "Message to indicate ads will play before playing video content",
      "message": "Tu título comenzará después de estos mensajes..."
    },
    "videoPlayer_error_failed_description": {
      "description": "label for error messages to indicate 'failed'",
      "message": "HA FALLADO"
    },
    "videoPlayer_error_invalidURL_description": {
      "description": "Error message to indicate that the video URL is invalid.",
      "message": "El URL del vídeo no es válido."
    },
    "videoPlayer_error_playback_description": {
      "description": "Error message when video could not play",
      "message": "Hubo un problema con la reproducción del video."
    },
    "videoPlayer_adHeadsUp": {
      "description": "Warning when the ad break is about to begin. (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "Pausa publicitaria comienza en {seconds} s"
    },
    "videoPlayer_toast_message": {
      "description": "Message to be displayed on Toast-message when user signed in.",
      "message": "Has iniciado sesión correctamente"
    },
    "linearVideoPlayer_buttonBack": {
      "description": "Label of a Button to go back",
      "message": "Atrás"
    },
    "linearVideoPlayer_buttonCaptions": {
      "description": "Label of a Button to display the closed captions",
      "message": "Subtítulos"
    },
    "linearVideoPlayer_buttonCaptions2": {
      "description": "Label of a Button to display the closed captions",
      "message": "Subtítulos"
    },
    "linearVideoPlayer_buttonGuide": {
      "description": "Label of a Button to view the channel guide",
      "message": "Guía"
    },
    "linearVideoPlayer_buttonGuide2": {
      "description": "Label of a Button to view the channel guide",
      "message": "Guía Completa de TV"
    },
    "linearVideoPlayer_buttonTvGuide": {
      "description": "Label of a Button to view the TV channel guide",
      "message": "Guía TV"
    },
    "linearVideoPlayer_buttonLanguage": {
      "description": "Label of a Button which is displayed on linear player screen to select language",
      "message": "Idioma"
    },
    "linearVideoPlayer_comingUp": {
      "description": "Label of a coming up program in linear video player",
      "message": "Próximamente"
    },
    "linearVideoPlayer_comingUpAt": {
      "description": "Label of a coming up program with time in linear video player",
      "message": "Próximamente en {time}"
    },
    "linearVideoPlayer_timeLeft": {
      "description": "Label to display time left in linear video player info panel",
      "message": "{time} quedan"
    },
    "channel_name": {
      "description": "This is the name of the app. This is not located in the app. It is displayed to the user in the Roku Channel Store",
      "message": "Tubi - Películas y Series Gratis"
    },
    "channel_description": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Channel Store",
      "message": "¡Disfruta del catálogo más grande de películas y series populares completamente Gratis!",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "channel_webDescription": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Web Channel Store",
      "message": "Ve miles de películas y series totalmente Gratis. En Tubi puedes ver contenido 100% legal y de forma ilimitada. No se requiere tarjeta de crédito o suscripción. Solo tienes que descargar la aplicación, elige lo que quieras ver en dónde tú quieras y disfruta del contenido con menos anuncios que el cable. Tubi es el servicio más grande de streaming Gratis que ofrece películas y series de televisión premiadas. Tenemos algo para todos: Comedias, dramas, familiares, clásicas, dramas coreanos, anime y más. ¡Descarga hoy y empieza el streaming de entretenimiento Gratis!",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "dialog_whoops_title": {
      "description": "A general whoops title for an dialog window",
      "message": "¡Uy!"
    },
    "dialog_mylist_signIn_description": {
      "description": "Dialog description to say the user to signIn to view the My List",
      "message": "Debes iniciar sesión para ver Mi Lista"
    },
    "dialog_mylist_empty_title": {
      "description": "A general empty My list title for an dialog window",
      "message": "¡Uy! Tu lista está vacía"
    },
    "dialog_mylist_empty_description": {
      "description": "Dialog description to say My List is empty",
      "message": "Encuentra todo lo que agregaste a Mi Lista aquí. Para empezar, elige una serie o película y haz clic en el botón Mi Lista."
    },
    "dialog_button_register_signIn": {
      "description": "The label of the button in a dialog window that allows the user to register or signIn",
      "message": "Iniciar Sesión o Regístrate"
    },
    "why_ask_age_description": {
      "description": "The main message which explains why Tubi is asking for the users year of birth",
      "message": "*Procesamos esta información como se describe en la Política de Privacidad y los Términos de Uso de Tubi. Para obtener más información, consulte www.tubi.tv/privacy y www.tubi.tv/terms ¿Preguntas? Háganos saber en www.tubi.tv/support"
    },
    "signIn_screen_heading": {
      "description": "Title on the signIn screen",
      "message": "Iniciar Sesión para acceder tu cuenta"
    },
    "signIn_screen_enter_password": {
      "description": "enter password text",
      "message": "Ingresa tu contraseña de Tubi"
    },
    "forgot_password_text": {
      "description": "forgot password text",
      "message": "¿Olvidaste tu contraseña?"
    },
    "forgot_password_link": {
      "description": "forgot password link",
      "message": "Ir a tubi.tv/forgot para restablecer"
    },
    "signIn_password_hint": {
      "description": "hint shown on signIn password textbox",
      "message": "contraseña"
    },
    "signUp_password_hint": {
      "description": "hint shown on signUp password textbox",
      "message": "establecer una contraseña"
    },
    "signUp_screen_heading": {
      "description": "Title on the signUp screen",
      "message": "Regístrate para una cuenta nueva"
    },
    "signUp_screen_password_validation": {
      "description": "sign up screen password validation text",
      "message": "Presiona OK en tu control y establece una contraseña nueva"
    },
    "already_having_account_text": {
      "description": "already having account text",
      "message": "¿Ya tienes una cuenta?"
    },
    "password_length_validation": {
      "description": "password length validation",
      "message": "Contraseña debe ser de 6-30 caracteres"
    },
    "invalid_password_title": {
      "description": "invalid password title on modal",
      "message": "Contraseña inválida"
    },
    "invalid_oops_password_title": {
      "description": "invalid password title on modal",
      "message": "Uyy, contraseña incorrecta"
    },
    "enter_password_dialog_description": {
      "description": "enter password dialog description",
      "message": "Por favor, ingresa la contraseña para tu cuenta de Tubi"
    },
    "invalid_oops_password_description": {
      "description": "enter password dialog description",
      "message": "Intentémoslo de nuevo o ingrese una contraseña diferente para esta cuenta:"
    },
    "retry": {
      "description": "retry button text on modal",
      "message": "Reintentar"
    },
    "could_not_verify_email": {
      "description": "could not verify your email modal description",
      "message": "No pudimos verificar tu correo electrónico"
    },
    "check_email_inbox": {
      "description": "Title on the email verification screen",
      "message": "Revisa tu correo electrónico"
    },
    "click_on_verification_link": {
      "description": "Message shown on the email verification screen about the verification link sent to email",
      "message": "Haz clic en el enlace de verificación enviado a tu correo electrónico:"
    },
    "screen_refresh_after_email_verification": {
      "description": "Message shown on the email verification to let the user know screen will refresh after the email verification",
      "message": "Esta pantalla se actualizará una vez que hayas verificado tu correo electrónico."
    },
    "rated_Label": {
      "description": "Label shown on video player when tv rating/descriptor is shown",
      "message": "CALIFICADO"
    },
    "skipIntro_Player": {
      "description": "Navigational instructions to users to skip the introduction section of the title. Usually the song or the beginning credits",
      "message": "Saltar Intro"
    },
    "skipRecap_Player": {
      "description": "Navigational instructions to users to skip the section where the previous part of the show is recapped",
      "message": "Saltar Recapitulación"
    },
    "skipEarlyCredits_Player": {
      "description": "Navigational instructions to users to skip when the Credits are followed by a scene",
      "message": "Saltar Créditos Iniciales"
    },
    "invalid_email_title": {
      "description": "Asking to enter a valid email on Email screen",
      "message": "Por favor, ingresa un correo electrónico válido"
    },
    "email_screen_heading": {
      "description": "Asking to enter a email on Email screen",
      "message": "Ingresa Correo Electrónico"
    },
    "screenAgeVerification_born_year": {
      "description": "Label to ask user to enter their year of birth",
      "message": "Nací en"
    },
    "signIn_screen_subheading": {
      "description": "Sub title on the signIn screen",
      "message": "Tu correo electrónico ya está vinculado a una cuenta de Tubi"
    },
    "forgotPassword_screen_heading": {
      "description": "Title on the forgot password screen",
      "message": "¡Ayuda está en camino!"
    },
    "forgotPassword_screen_instant_subheading": {
      "description": "Sub title on the forgot password screen - instant version",
      "message": "Ve a tu correo electrónico y haz clic en el enlace de inicio de sesión instantáneo:"
    },
    "forgotPassword_screen_noInstant_subheading": {
      "description": "Sub title on the forgot password screen - no instant version",
      "message": "Ve a tu correo electrónico y haz clic en el enlace de restablecimiento de contraseña:"
    },
    "forgotPassword_screen_instant_subheading2": {
      "description": "2nd Sub title on the forgot password screen - instant version",
      "message": "Esta pantalla se actualizará una vez que hagas clic en el enlace de tu correo electrónico."
    },
    "forgotPassword_screen_noInstant_subheading2": {
      "description": "2nd Sub title on the forgot password screen - noInstant version",
      "message": "Después de restablecer tu contraseña, haz clic aquí para intentar iniciar sesión."
    },
    "forgotPassword_screen_btn_resend": {
      "description": "The button on the forgot password screen that corresponds to the action 'Resend Sign-in link",
      "message": "Reenviar Enlace de Inicio de Sesión"
    },
    "forgotPassword_screen_btn_different_email": {
      "description": "The button on the forgot password screen that corresponds to the action 'Use Different Email",
      "message": "Usa correo electrónico diferente"
    },
    "search_hint": {
      "description": "Instructions to the user to use microphone icon on his/her remote to use voice enabled keyboard. Please note that a microphone icon will be placed immediately after the last word of this translation and the icon will be considered part of the sentence.",
      "message": "Para habilitar el control de voz, oprime y mantén"
    },
    "search_voice_hint": {
      "description": "Instructions to the user to use microphone icon on his/her remote to use voice enabled keyboard. Please note that a microphone icon will be placed at the beginning of the sentence.",
      "message": "Para habilitar el control de voz, oprime y mantén presionado el botón del micrófono en tu control"
    },
    "dialog_button_signUp": {
      "description": "The label of the button in a dialog window that allows the user to sign up into the app.",
      "message": "Inscríbete"
    },
    "screenSettings_parentalPassword_setup_new_password": {
      "description": "Directions for users who attempt to change the parental controls",
      "message": "Para crear una nueva contraseña"
    },
    "screenSettings_parentalPassword_visit_link": {
      "description": "Directions for users to setup the new password",
      "message": "visita tubi.tv/password"
    },
    "screenSettings_parentalPassword_visit_webBrowser": {
      "description": "Directions for users to setup the new password on browser",
      "message": "1. Por favor visita tubi.tv/password en un navegador de web"
    },
    "screenSettings_parentalPassword_email": {
      "description": "Directions to the user to enter his/her email to setup new password",
      "message": "2. Ingresa el correo electrónico "
    },
    "screenSettings_parentalPassword_set_new_Password": {
      "description": "Directions to the user about email notification to setup new password",
      "message": "3. Te enviaremos instrucciones para crear una contraseña nueva"
    },
    "screenSettings_parentalPassword_know_my_Password": {
      "description": "Directions to the user to enter his/her password if they know their password",
      "message": "Yo se mi contraseña. Vamos."
    },
    "registration_signup_button": {
      "description": "button text for when a non registered user focuses on details screen",
      "message": "Regístrate para Guardar Tu Progreso"
    },
    "registration_signup_button_free": {
      "description": "button text on top of background image next to sign up text for when a non registered user focuses on details screen",
      "message": "GRATIS"
    },
    "registration_signIn_to_play_button": {
      "description": "button text for when a non registered user focuses on details screen for sportsEvent",
      "message": "Inicia Sesión para Ver"
    },
    "registration_signIn_to_play_R_rated": {
      "description": "Hint message why we have locked the content.",
      "message": "Iniciar sesión requerido para proteger a audiencias jóvenes. No se necesita tarjeta de crédito."
    },
    "registration_signIn_to_play_default": {
      "description": "Hint message why we have locked the content. This is the default message",
      "message": "Iniciar sesión requerido. No se necesita tarjeta de crédito."
    },
    "text_new": {
      "description": "simple text to use anywhere to indicate item is new",
      "message": "NUEVO"
    },
    "screenEmailVerification_resend_verification_link": {
      "description": "Label of button to allow users to resend the email verification link for sign in",
      "message": "Reenviar Enlace de Verificación"
    },
    "screenEmailVerification_use_different_email": {
      "description": "Label of button to allow users to use different email address for sign in",
      "message": "Usar un correo electrónico diferente"
    },
    "next_button": {
      "description": "Button text displayed on onBoarding screens to proceed to next screens",
      "message": "Siguiente"
    },
    "skip_button": {
      "description": "Button text displayed on onBoarding screens to skip the onboarding flow",
      "message": "Saltar"
    },
    "getStarted_button": {
      "description": "Button text displayed on onBoarding screens, takes to landing screen",
      "message": "Comenzar"
    },
    "registerOrSignIn_button": {
      "description": "Button text displayed on onBoarding screens takes to Roku Request for Information modal",
      "message": "Continuar con Roku"
    },
    "continueAsGuest_button": {
      "description": "Button text displayed on onBoarding screens takes to Initial Content Type Selector Screen or Home Screen",
      "message": "Continuar como invitado"
    },
    "onBoarding_landingScreen_addListLabel": {
      "description": "Label displayed on onBoarding Landing screen informing add to your list",
      "message": "Agregar a Mi Lista"
    },
    "onBoarding_landingScreen_saveProgressLabel": {
      "description": "Label displayed on onBoarding Landing screen informing save your progress",
      "message": "Guarda tu progreso"
    },
    "onBoarding_landingScreen_saveProgressBody": {
      "description": "Body displayed on onBoarding Landing screen informing pickup where you left off",
      "message": "Continúa donde dejaste de ver"
    },
    "dialog_got_it": {
      "description": "simple text to use anywhere to indicate dismiss action",
      "message": "Lo entiendo"
    },
    "reg_intro_title": {
      "description": "title displayed on registration welcome modal",
      "message": "Tubi es mejor cuando Inicias Sesión"
    },
    "reg_intro_sub_header": {
      "description": "sub header displayed on registraton welcome modal",
      "message": "Sin Tarjeta de Crédito. Gratis Siempre."
    },
    "reg_first_line_sub_item": {
      "description": "first sub item to be displayed under reg_first_line_item to explain user about benifit of registration",
      "message": "Guardar Ahora, Ver Más Tarde"
    },
    "reg_third_line_item": {
      "description": "third item to let know user about the benifit of registration",
      "message": "Desbloquea títulos Solo para Ti"
    },
    "reg_third_line_sub_item": {
      "description": "third sub item to be displayed under reg_third_line_item to explain user about benifit of registration",
      "message": "Obtén mejores recomendaciones"
    },
    "reg_sign_in_button_title": {
      "description": "Button text to be displayed on first button of registration welcome modal",
      "message": "Continuar para Iniciar Sesión"
    },
    "reg_continue_as_guest_button_title": {
      "description": "Button text to be displayed on second button of registration welcome modal",
      "message": "Continuar como Invitado"
    },
    "replay": {
      "description": "This label used for badge to indicate the content availability",
      "message": "Repetición"
    },
    "info_panel_reminder_is_set": {
      "description": "Hint in the content metadata area informing the user that the reminder is set for this content",
      "message": "Recordatorio programado"
    },
    "info_panel_available_in_4k": {
      "description": "Lets user know this content is available in 4k (although may not be available on their device)",
      "message": "Disponible en 4K"
    },
    "goBack_videoPlayer_ad": {
      "description": "Navigational instructions to users when pause Ad is displayed on video screen",
      "message": "Presiona cualquier botón para cerrar el anuncio"
    },
    "cc_audio_overlay_subtitles": {
      "description": "Available closed caption tracks section header label.",
      "message": "Subtítulos"
    },
    "consent_screen_heading": {
      "description": "Consent screen heading.",
      "message": "Tu Privacidad"
    },
    "consent_screen_subheading": {
      "description": "Consent screen sub heading.",
      "message": "Tóma un momento para confirmar tus preferencias de privacidad de datos"
    },
    "manage_preferences_button_label": {
      "description": "Manage preferences button label.",
      "message": "Administra Preferencias"
    },
    "accept_all_button_label": {
      "description": "Accept button label.",
      "message": "Aceptar Todo"
    },
    "reject_all_button_label": {
      "description": "Reject button label.",
      "message": "Rechazar Todo"
    },
    "privacy_preferences_label": {
      "description": "privacy preferences screen title.",
      "message": "Configuración de Privacidad"
    },
    "privacy_preferences_save_continue_button": {
      "description": "Save and Continue button on Consent Manage preferences",
      "message": "Guardar y Continuar"
    },
    "privacy_preferences_privacy_section_heading": {
      "description": "Privacy section heading.",
      "message": "Política de Privacidad"
    },
    "privacy_preferences_privacy_section_subheading": {
      "description": "Privacy section subheading.",
      "message": "Para ver la Política de privacidad de Tubi, escanee el código QR a continuación con tu dispositivo móvil o visita "
    },
    "privacy_preferences_tos_section_heading": {
      "description": "Terms of service section heading.",
      "message": "Términos de Uso"
    },
    "privacy_preferences_tos_section_subheading": {
      "description": "Terms of service section subheading.",
      "message": "Para ver los Términos de uso de Tubi, escanee el código QR a continuación con tu dispositivo móvil o visita "
    },
    "privacy_preferences_qrcode_modal_subheading": {
      "description": "QR Code Selected Modal subheading.",
      "message": "Escanee el código QR en la pantalla con tu dispositivo móvil para ver el enlace."
    },
    "privacy_preferences_on": {
      "description": "Privacy preferences toggle text on",
      "message": "Encender"
    },
    "privacy_preferences_off": {
      "description": "Privacy preferences toggle text off",
      "message": "Apagar"
    },
    "privacy_preferences_required": {
      "description": "Privacy preferences required text",
      "message": "Requerido"
    },
    "required_preference_selected_toast_heading": {
      "description": "Toast header when required preference item is selected.",
      "message": "Ajuste Requerido"
    },
    "required_preference_selected_toast_message": {
      "description": "Toast message when required preference item is selected.",
      "message": "{preference} funcionalidad es necesaria para continuar."
    },
    "privacy_center_not_editable_mode_warning": {
      "description": "Warning label that will be displayed in privacy center whenever user is in kids mode or any parental controls mode.",
      "message": "Configuración de privacidad solo se puede cambiar fuera de Tubi Kids. Solo se utilizan datos esenciales dentro de Tubi Kids."
    },
    "accept_now_button_label": {
      "description": "Button Label that will be used in consent screen accept button.",
      "message": "Aceptar Ahora"
    },
    "maybe_later_button_label": {
      "description": "Button Label that will be used in consent screen Maybe later button.",
      "message": "Quizás más tarde"
    },
    "roku_cw_consent_screen_heading": {
      "description": "Roku Continue Watching screen heading.",
      "message": "Regresa a Lo Que Amas Más Rápido"
    },
    "roku_cw_consent_screen_sub_heading": {
      "description": "Roku Continue Watching screen sub heading.",
      "message": "Facilite volver a lo que estabas viendo y obtén mejores recomendaciones para stream a continuación.\n\nElige " + Chr(34) + "Aceptar ahora" + Chr(34) + " para dar permiso a Tubi para compartir tu historial de visualización de videos con Roku.\n\nPuedes cambiar esto en cualquier momento en Configuración."
    },
    "player_exit_prompt_signup_heading": {
      "description": "Video Player exit prompt signup header",
      "message": "Espera, no pierdas tu lugar!"
    },
    "player_exit_prompt_signup_sub_heading": {
      "description": "Video Player exit prompt signup sub header",
      "message": "Regístrate para guardar tu progreso y recogerlo donde lo dejaste. No se requiere tarjeta de crédito."
    },
    "player_exit_prompt_signup_later_button": {
      "description": "Video Player exit prompt signup later",
      "message": "Regístrate Más Tarde"
    },
    "trending_search_results_hint": {
      "description": "Trending Search Results hint which will be displayed in the search screen when we do not have enough search results.",
      "message": "Aquí hay otras búsquedas populares que te pueden gustar"
    },
    "search_results_no_matching_results": {
      "description": "No matching results message which will be displayed in search results screen.",
      "message": "No pudimos encontrar ningún resultado para"
    },
    "privacy_center_save_restart": {
      "description": "Settings screen privacy center save and restart consent button label.",
      "message": "Guardar y Reiniciar Tubi"
    },
    "gdpr_age_gate_error_dialog_heading": {
      "description": "GDPR age gate error dialog heading.",
      "message": "Lo Sentimos"
    },
    "gdpr_age_gate_error_dialog_sub_heading": {
      "description": "GDPR age gate error dialog sub heading.",
      "message": "No es elegible para continuar."
    },
    "gdpr_age_gate_error_dialog_exit_tubi": {
      "description": "GDPR age gate error dialog exit tubi button label.",
      "message": "Salir de Tubi"
    },
    "updated_terms_toast_message": {
      "description": "Message on the toast message informing the user of update ToS. Please keep style tags intact when translating.",
      "message": "<defaultStyle>Hemos actualizado nuestros Términos de uso. Al continuar utilizando Tubi, aceptas estos términos actualizados. Puede ver nuestros términos en </defaultStyle><urlStyle>https://tubitv.com/static/terms</urlStyle>"
    },
    "updated_terms_toast_header": {
      "description": "Header on the toast message informing the user of update ToS",
      "message": "Importante"
    },
    "privacy_center_restart_channel": {
      "description": "Settings screen privacy center restart channel button label.",
      "message": "Reiniciar"
    },
    "save_consent_dialog_heading": {
      "description": "Settings screen save consent dialog heading.",
      "message": "Configuración de Privacidad Actualizada"
    },
    "save_consent_dialog_sub_heading": {
      "description": "Settings screen save consent dialog sub heading.",
      "message": "Debes reiniciar Tubi para que los cambios surtan efecto."
    },
    "privacy_center_view_privacy_settings_hint": {
      "description": "Settings screen privacy center view privacy settings hint.",
      "message": "Debes guardar los cambios en configuración de privacidad y reiniciar Tubi para que los cambios surtan efecto."
    },
    "privacy_center_view_privacy_settings": {
      "description": "Settings screen privacy center launch preferences center button label.",
      "message": "Ver Configuración de Privacidad"
    },
    "privacy_disclaimer": {
      "description": "Privacy disclaimer text displayed in Sign in and registration flow.",
      "message": "Al regístrarte o inicia sesión, acceptas que has leido y entendido la Politica de Privacidade de Tubi y aceptas los Términos de Uso de Tubi. Obtenga más información en {privacy_policy_url} y {terms_of_use_url}"
    },
    "dialog_gdpr_manage_privacy_settings_error_description": {
      "description": "Error dialog description shown due to one trust component library failure when clicking manage privacy settings.",
      "message": "Reinicia Tubi para actualizar la configuración de privacidad. Por favor envíe un correo a support@tubi.tv si sigue pasando."
    },
    "live_on_date": {
      "description": "date label used in air date countdown timer",
      "message": "EN VIVO EN {month} {day}"
    },
    "live_on_date_today": {
      "description": "date label used in air date countdown timer",
      "message": "HOY A LAS {time}"
    },
    "live_on_day": {
      "description": "day label used in air date countdown timer",
      "message": "{day} D"
    },
    "cc_audio_overlay_subtitles_mode": {
      "description": "Available modes displayed on closed caption overlay",
      "message": "Modo Subtítulos"
    },
    "live_on_hour": {
      "description": "day label used in air date countdown timer",
      "message": "{hour} HR"
    },
    "live_on_minute": {
      "description": "day label used in air date countdown timer",
      "message": "{min} MIN"
    },
    "screenHome_button_sign_in_watch": {
      "description": "Sign in to watch live button label.",
      "message": "Inicia Sesión para Ver"
    },
    "available_at": {
      "description": "Sign in to watch live button label.",
      "message": "Disponible a las {time}"
    },
    "watch_for_free": {
      "description": "Sign in to watch live button label.",
      "message": "Ver gratis el {date}."
    },
    "auth_refresh_welcome_message": {
      "description": "A message that let's the user know they've been signed in with the given email",
      "message": "Iniciado sesión como {email}"
    },
    "auth_refresh_welcome_header": {
      "description": "A header for the message that let's the user know they've been signed in with the given email",
      "message": "¡Bienvenido!"
    },
    "resolution_full_hd": {
      "description": "Title of the 1080p resolution label in the infopanel",
      "message": "HD COMPLETO"
    },
    "available_at_toast_heading": {
      "description": "Toast message heading that is displayed when we click on a available at button",
      "message": "Contenido disponible a las {time}"
    },
    "available_at_toast_subheading": {
      "description": "Toast message subheading that is displayed when we click on a available at button",
      "message": "Sabemos que estás emocionado. ¡Nosotros también!"
    },
    "sign_in_error_screen_heading": {
      "description": "Sign in error screen heading default error",
      "message": "No podemos iniciar sesión en este momento"
    },
    "sign_in_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Aún puedes ver tus películas y series de TV favoritos como invitado."
    },
    "sign_in_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Aún puedes ver tus películas y series de TV favoritos como invitado, ¡incluido {major_event_name}!"
    },
    "sign_up_error_screen_heading": {
      "description": "Sign in error screen heading default error",
      "message": "No podemos crear tu cuenta en este momento"
    },
    "sign_up_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Aún puedes ver tus películas y series de TV favoritos como invitado. \nTe enviaremos un correo para que vuelvas a intentarlo más tarde."
    },
    "sign_up_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "¡Aún puedes ver tus películas y series de TV favoritos como invitado, ¡incluido {major_event_name}!\nTe enviaremos un correo para que vuelvas a intentarlo más tarde."
    },
    "mylist_disabled_message": {
      "description": "My List disabled toast message",
      "message": "Mis Cosas no están disponibles actualmente."
    },
    "rating_disabled_message": {
      "description": "Like/Dislike disabled toast message",
      "message": "Calificación no está disponible actualmente."
    },
    "continue_watching_disabled_message": {
      "description": "Continue watching disabled toast message",
      "message": "Seguir Viendo no está disponible actualmente."
    },
    "disaster_mode_toast_heading": {
      "description": "Heading of the toast that is shown on disaster mode UI.",
      "message": "Estamos teniendo problemas para conectarnos"
    },
    "disaster_mode_toast_subheading": {
      "description": "Subheading of the toast that is shown on disaster mode UI.",
      "message": "¡Aún puedes ver {major_event_name}!"
    },
    "rating": {
      "description": "Like/Dislike feature",
      "message": "Calificación"
    },
    "delayed_registration_message": {
      "description": "Message displayed when user tries to register and the registration is delayed",
      "message": "Intentaremos crear tu cuenta en las próximas 24 horas y, si tiene éxito, te enviaremos un correo para finalizar la configuración de tu cuenta."
    },
    "game": {
      "description": "Fallback string to be used when major event name is not available in remote config",
      "message": "juego"
    },
    "havent_received_email": {
      "description": "Message displayed in sign in screen during major event day",
      "message": "¿No has recibido un correo? Aún puedes continuar como Invitado."
    }
  }
End Function


Function getTranslation_fr_CA()
  return {
    "foxVideoPlayer_error_contentUnavailableMessage": {
      "description": "Used when the fox video player displays a dialog requiring the error_contentUnavailableMessage text string.",
      "message": "Toutes nos excuses, mais le contenu n'est pas disponible pour le moment. Veuillez réessayer plus tard.\nSi vous continuez à rencontrer ce problème, veuillez visiter help.tubitv.com."
    },
    "foxVideoPlayer_error_generic": {
      "description": "Used when the fox video player displays a dialog requiring the error_generic text string.",
      "message": "Toutes nos excuses, mais le contenu n'est pas disponible pour le moment. Veuillez réessayer plus tard.\nSi vous continuez à rencontrer ce problème, veuillez visiter help.tubitv.com."
    },
    "menu_signIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into app.",
      "message": "Connexion"
    },
    "menu_goHome": {
      "description": "Menu option on the app's myStuff screen, Allows the user to  navigate to the home screen.",
      "message": "Aller à l'accueil"
    },
    "menu_signedIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Shows that the user is signed in.",
      "message": "Bonjour {name}"
    },
    "menu_kids": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into kids mode.",
      "message": "Enfants"
    },
    "menu_exitKids": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to exit kids mode.",
      "message": "Quitter la section Enfants"
    },
    "menu_search": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the search screen.",
      "message": "Recherche"
    },
    "menu_foryou": {
      "description": "Menu option on the app's top nav for pillshaped, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Pour vous"
    },
    "component_library_failed": {
      "description": "Latest Version of Tubi app failed to load due to some error",
      "message": "{errCode}\nCanal du tubi n'a pas réussi à se charger complètement. Certaines fonctionnalités peuvent être manquantes."
    },
    "epg_starts_at": {
      "description": "Program time Title when user selects a future program on EPG.",
      "message": "Commence à"
    },
    "epg_started_at": {
      "description": "Program time Title for live program.",
      "message": "Commencé à"
    },
    "detail_screen_like_disLike_toast_header": {
      "description": "header text to be displayed on Toast-message when user like/dislike a title",
      "message": "Merci pour vos commentaires!"
    },
    "detail_screen_like_toast_message": {
      "description": "Message to be displayed on Toast-message when user liked a title",
      "message": "Nous proposerons plus de titres comme celui-ci dans les futures recommandations."
    },
    "detail_screen_disLike_toast_message": {
      "description": "Message to be displayed on Toast-message when user disliked a title",
      "message": "Nous vous proposerons moins de titres de ce type dans nos prochaines recommandations."
    },
    "menu_home": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Accueil"
    },
    "menu_categories": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the categories screen.",
      "message": "Catégories"
    },
    "menu_channels": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the channels screen.",
      "message": "Chaînes"
    },
    "menu_networks": {
      "description": "Title for a container of channels tiles.",
      "message": "Réseaux"
    },
    "menu_movies": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the movies screen.",
      "message": "Films"
    },
    "menu_tv": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the tv shows screen.",
      "message": "ProgrammesTV"
    },
    "menu_livetv": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the live TV screen.",
      "message": "TV en direct"
    },
    "menu_mystuff": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the my stuff screen.",
      "message": "Mes contenus"
    },
    "menu_settings": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the settings screen.",
      "message": "Paramètres"
    },
    "menu_exit": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to exit the app.",
      "message": "Quitter"
    },
    "screenHome_item_showAllGames": {
      "description": "The text to display on Show All Games tile",
      "message": "Montrer tout"
    },
    "screenHome_button_spotlight_details": {
      "description": "On the home screen of the spotlight row, this is the text of a details button that allows the user to go to the details screen",
      "message": "Détails"
    },
    "screenHome_button_spotlight_watch_live": {
      "description": "On the home screen of the spotlight row, this is the text of a watch live button that allows the user to start playing focused live content",
      "message": "Regarder direct"
    },
    "screenHome_button_spotlight_watch_now": {
      "description": "On the home screen of the spotlight row, this is the text of a watch now button that allows the user to start playing focused linear content",
      "message": "Regarder"
    },
    "loadingIndicator": {
      "description": "When something is loading, this text appears so the user knows something is loading.",
      "message": "Chargement..."
    },
    "dialog_errorPrefix": {
      "description": "When the user is displayed an error, this is the prefix of the error ID that is presented to them: i.e. Error 101",
      "message": "Erreur :"
    },
    "dialog_defaultError_title": {
      "description": "The default title of a popup error dialog",
      "message": "Un problème est survenu"
    },
    "dialog_uidExpiraionError_title": {
      "description": "The title of a popup error dialog when link has been expired during signup process",
      "message": "Le lien de vérification a expiré"
    },
    "dialog_defaultError_description": {
      "description": "The default message of a popup error dialog",
      "message": "Nous sommes désolés pour ce désagrément. Pour toute assistance, veuillez contacter support@tubi.tv"
    },
    "dialog_magicLink_error_description": {
      "description": "The message of a popup error dialog when user magicLink API fails and user doesn't get verification link to their emial",
      "message": "Nous avons des difficultés à traiter cette demande. Veuillez vérifier votre connexion Internet ou réessayer de cliquer sur " + Chr(34) + "Renvoyer le lien de vérification" + Chr(34) + "."
    },
    "dialog_uidExpiraionError_description": {
      "description": "The description of a popup error dialog when link has been expired during signup process",
      "message": "Pour obtenir un nouveau lien de vérification, veuillez cliquer à nouveau sur " + Chr(34) + "Renvoyer le lien de vérification" + Chr(34) + "."
    },
    "dialog_errorMessageContact": {
      "description": "The contact info displayed in an error dialog",
      "message": "Veuillez envoyer un e-mail à support@tubi.tv si ce problème persiste."
    },
    "dialog_button_exit": {
      "description": "In a popup dialog that asks if the user if they wish to exit the app. This is the button that will confirm their exit.",
      "message": "Quitter"
    },
    "dialog_button_signIn": {
      "description": "The label of the button in a dialog window that allows the user to sign into the app.",
      "message": "Connexion"
    },
    "dialog_button_cancel": {
      "description": "Label of a dialog button to cancel out of the dialog",
      "message": "Annuler"
    },
    "dialog_button_continue": {
      "description": "Label of a dialog button to continue to the next step that the dialog is saying",
      "message": "Continuer"
    },
    "dialog_button_forgot_password": {
      "description": "Label of a dialog button to take the user to the steps in case he/she has forgotten the account password. ",
      "message": "Mot de passe oublié"
    },
    "dialog_button_submit": {
      "description": "Label of the dialog button to submit what the window is asking it to do.",
      "message": "Envoyer"
    },
    "dialog_button_tryAgain": {
      "description": "Label of the dialog button to try again what the app had attempted to do.",
      "message": "Réessayer"
    },
    "dialog_button_close": {
      "description": "Label of the dialog button to close the dialog window",
      "message": "Fermer"
    },
    "dialog_button_skip": {
      "description": "Label of the dialog button to skip what is being asked",
      "message": "Passer"
    },
    "dialog_button_off": {
      "description": "Label of the dialog button to turn something off: i.e. turn off closed captions",
      "message": "Désactiver"
    },
    "dialog_button_on": {
      "description": "Label of the dialog button to turn something on: i.e. turn on autoplay preview",
      "message": "Activer"
    },
    "dialog_button_settings": {
      "description": "Label of the dialog button to cause the app to go to the settings screen.",
      "message": "Allez dans les " + Chr(34) + "Paramètres" + Chr(34) + "."
    },
    "dialog_email_verification_email_already_sent": {
      "description": "The first line of the email verification description dialog",
      "message": "Un e-mail de vérification a déjà été envoyé à"
    },
    "dialog_email_verification_check_spam": {
      "description": "The second line of the email verification description dialog",
      "message": "N'oubliez pas de vérifier votre dossier spam"
    },
    "dialog_button_resend_verification_link": {
      "description": "Label of the dialog button to resend the email verification link",
      "message": "Oui, renvoyer un e-mail de vérification"
    },
    "dialog_button_attempts_title": {
      "description": "Title of the dialog after user selects resend verification link more than 3 times",
      "message": "Trop de tentatives"
    },
    "dialog_button_multiple_emails_sent": {
      "description": "The first line of the too many attempts dialog",
      "message": "Plusieurs e-mails de vérification ont déjà été envoyés à"
    },
    "dialog_errorOops_title": {
      "description": "A general error title for an error dialog window",
      "message": "Oups !"
    },
    "dialog_espanolDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav espanol menu item but the item has been disabled",
      "message": "Espagnol désactivé"
    },
    "dialog_moviesDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav movies menu item but the item has been disabled",
      "message": "Films désactivés"
    },
    "dialog_tvDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav TV menu item but the item has been disabled",
      "message": "Série TV Désactivée"
    },
    "dialog_linearEPGDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav Live TV menu item but the item has been disabled",
      "message": "TV en DIRECT Désactivée"
    },
    "dialog_sideNavItemDisabled_description": {
      "description": "Message of a Dialog Window that is shown when the user clicked on a sidenav menu item but the item has been disabled",
      "message": "Veuillez quitter " + Chr(34) + "Tubi Enfants" + Chr(34) + " pour utiliser cette fonctionnalité."
    },
    "dialog_sideNavItemDisabled_Parental_description": {
      "description": "Message of a Dialog Window that is shown when the user clicked on a sidenav menu item but the item has been disabled due to parental set to Teens",
      "message": "Veuillez désactiver le contrôle parental pour utiliser cette fonctionnalité."
    },
    "dialog_contentNotAvailable_Parental_description": {
      "description": "Message of a Dialog Window that is shown when a deeplink content can not played because of user's parental control setting",
      "message": "Veuillez désactiver le contrôle parental pour regarder ce contenu."
    },
    "error_connection_title": {
      "description": "title of error window when there is a connection error",
      "message": "Erreur de connexion"
    },
    "error_connection_description": {
      "description": "description of error window when there is a connection error",
      "message": "Il peut y avoir un problème avec votre connexion réseau ou avec le serveur de Tubi. Veuillez vérifier votre connexion réseau et réessayer. "
    },
    "dialog_updateVersion_title": {
      "description": "title of a dialog window that is shown when the user has an older version of the app",
      "message": "Veuillez mettre à jour le chaîne Tubi"
    },
    "dialog_updateVersion_description": {
      "description": "message of a dialog window that is shown when the user has an older version of the app",
      "message": "Cette version de Tubi n'est plus prise en charge. Pour la mettre à jour, veuillez quitter l'application Tubi et aller dans :\n\nParamètres > Système > Mise à jour du système > Vérifier maintenant"
    },
    "dialog_fullSynopsis_title": {
      "description": "title of a dialog window that shows the full description of a video item",
      "message": "Synopsis complet"
    },
    "dialog_parentalPassword_title": {
      "description": "title of the dialog window when guest user signs in and still needs to enter his/her password to change the parental controls",
      "message": "Entrez votre mot de passe"
    },
    "dialog_parentalPassword_description": {
      "description": "description of the dialog window when guest user signs in and still needs to enter his/her password to change the parental controls",
      "message": "Merci de vous être connecté(e). Pour mettre à jour le contrôle parental selon les paramètres que vous souhaitez, veuillez saisir votre mot de passe."
    },
    "dialog_signIn_title": {
      "description": "title of a dialog window when it asks the user to sign in",
      "message": "Veuillez vous connecter"
    },
    "dialog_confirmCorrectAge_title": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct year",
      "message": "Êtes-vous né(e) en {birthYear} ?"
    },
    "dialog_confirmCorrectAge_title_age": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct age",
      "message": "Avez-vous {age} ans ?"
    },
    "dialog_confirmCorrectAge_description": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct year",
      "message": "Veuillez confirmer pour continuer"
    },
    "dialog_confirmCorrectAge_confirm": {
      "description": "label of a dialog window button that will confirm app user's age is correct",
      "message": "Oui"
    },
    "dialog_confirmCorrectAge_edit": {
      "description": "label of a dialog window button that will let user edit their age again",
      "message": "Modifier"
    },
    "dialog_kidsExit_title": {
      "description": "title of a dialog window when the user is attempting to exit kids Mode",
      "message": "Quitter la section Enfants"
    },
    "dialog_kidsExit_button_ok": {
      "description": "label of a dialog window button that will confirm app should exit kids mode",
      "message": "Quitter la section Enfants"
    },
    "dialog_kidsExitLimited_description": {
      "description": "description of a dialog window that describes what the user should do to exit kids mode",
      "message": "Pour quitter la section Enfants, veuillez mettre à jour votre contrôle parental dans les paramètres du compte."
    },
    "dialog_kidsWelcome_title": {
      "description": "A message welcoming the user to Tubi Kids",
      "message": "Bienvenue sur Tubi Enfants"
    },
    "dialog_kidsWelcomeAgeGate_description": {
      "description": "A description informing users they cannot exit Tubi Kids for the next 24 hours",
      "message": "Vous ne pouvez pas quitter Tubi Enfants pour le moment. Veuillez réessayer dans 24 heures. Vous avez des questions ? Écrivez-nous à www.tubi.tv/support"
    },
    "dialog_cannotExitKidsMode_title": {
      "description": "Title for dialog telling the user they can not exit kids mode",
      "message": "Impossible de quitter le mode Enfants"
    },
    "dialog_cannotExitKidsMode_description": {
      "description": "Description for dialog telling the user they can not exit kids mode",
      "message": "Veuillez réessayer dans 24 heures.\nVous avez des questions ? Envoyez-nous un e-mail à support@tubi.tv"
    },
    "dialog_exitApp_title": {
      "description": "Title of the dialog window that asks the user if they want to exit the app",
      "message": "Êtes-vous sûr(e) ?"
    },
    "dialog_exitApp_description": {
      "description": "description of the dialog window that asks the user if they want to exit the app",
      "message": "Voulez-vous vraiment quitter Tubi ?"
    },
    "error_noGetChannels_description": {
      "description": "description of the error dialog when channel content could not get received from the server.",
      "message": "Impossible de récupérer le contenu de la chaîne."
    },
    "error_noGetChannelGuide_description": {
      "description": "description of the error dialog when channel guide content could not get received from the server.",
      "message": "Impossible de récupérer le guide de la chaîne."
    },
    "error_noContent_description": {
      "description": "description of the error dialog when there was no content to be gathered from the server.",
      "message": "Cette page ne contient actuellement aucun contenu."
    },
    "error_mustBeSignedIn_description": {
      "description": "Description of the warning dialog when user needs to be signed in to view a video.",
      "message": "Pour regarder cette vidéo gratuitement, veuillez vous connecter ou vous inscrire."
    },
    "error_matureContent_title": {
      "description": "Title of the dialog window when user attempts to play mature content but they need to be signed in first",
      "message": "Contenu pour adultes"
    },
    "dialog_signOut_title": {
      "description": "Title of the dialog window that asks the user if they want to sign out of the app",
      "message": "Êtes-vous sûr(e) ?"
    },
    "dialog_signOut_description": {
      "description": "description of the dialog window that asks the user if they want to sign out of the app",
      "message": "Vous êtes sur le point de vous déconnecter de votre compte Tubi."
    },
    "dialog_signOut_button_ok": {
      "description": "label of the confirmation button of the dialog window that asks the user if they want to sign out of the app",
      "message": "Déconnexion"
    },
    "error_check_birthdate_description": {
      "description": "message letting the user know that they were not able to be signed in",
      "message": "Un problème est survenu lors de la tentative de connexion. Veuillez entrer dans la chaîne et vous connecter à nouveau."
    },
    "screenSearch_defaultLinearSearch": {
      "description": "Directions on the search page",
      "message": "Rechercher des films, TV, des programmes TV, du direct et des personnes"
    },
    "screenSearch_defaultSearch": {
      "description": "Directions on the search page",
      "message": "Rechercher des films, programmes TV et personnes"
    },
    "screenSearch_trendingSearch": {
      "description": "A header message that shows on top of default search results in search screen",
      "message": "Recherches populaires"
    },
    "screenSearch_kidsWarning": {
      "description": "More directions on the search screen to suggest switching to kids mode.  Should be limited to be around 40 characters or fewer.",
      "message": "Passer à Enfants pour des résultats sûrs"
    },
    "screenSearch_loading": {
      "description": "The label of the loading indictor on the search screen",
      "message": "Actualisation de vos résultats..."
    },
    "screenSearch_noResults": {
      "description": "onscreen message when there are no search results.",
      "message": "Nous n'avons pas trouvé de résultats pour '{term}'.\nVeuillez réessayer"
    },
    "screenSearch_results": {
      "description": "message after loading search results.",
      "message": "Résultats"
    },
    "screenSearch_matchingTitles": {
      "description": "text after number of search results for searchedString",
      "message": "titres correspondants"
    },
    "screenSearch_liveText": {
      "description": "The label on the search results poster next to the live streaming icon",
      "message": "Direct"
    },
    "screenDetails_button_queue": {
      "description": "label of the button that will add the video title to the user's list",
      "message": "Ajouter à ma liste"
    },
    "screenDetails_button_noQueue": {
      "description": "label of the button that will remove the video title from the user's list",
      "message": "Retirer de Ma liste"
    },
    "screenDetails_button_noHistory": {
      "description": "label of the button that will remove the video title from the user's viewing history",
      "message": "Retirer de l'historique"
    },
    "screenDetails_button_changingRating": {
      "description": "label of the button when the user has clicked the button and the like/dislike state of the video title is changing",
      "message": "Changement de notation..."
    },
    "screenDetails_button_queueNow": {
      "description": "label of the button when the user has clicked the button and the video title is being added to the user's list",
      "message": "Ajout en cours..."
    },
    "screenDetails_button_removing": {
      "description": "label of the button when the user has clicked the button and the video title is being removed from the user's list or viewing history",
      "message": "Retrait en cours..."
    },
    "screenDetails_button_gotoChannel": {
      "description": "Label of the button that will take the user to the channel associated with the current video title",
      "message": "Aller à {channel}"
    },
    "screenDetails_error_addQueue_title": {
      "description": "Title of the warning dialog when user is attempting to add an item to their list but are not signed in",
      "message": "Compte requis"
    },
    "screenDetails_error_addQueueMovie_description": {
      "description": "Description of the warning dialog when user is attempting to add a movie to their list but are not signed in",
      "message": "Se connecter ou s'inscrire à Tubi pour ajouter ce film à votre liste."
    },
    "screenDetails_error_addQueueSeries_description": {
      "description": "Description of the warning dialog when user is attempting to add a TV show/series to their list but are not signed in",
      "message": "Se connecter ou s'inscrire à Tubi pour ajouter ce programme TV à votre liste."
    },
    "screenDetails_error_setReminderSports_description": {
      "description": "Description of the warning dialog when user is attempting to set reminder but are not signed in",
      "message": "Se connecter ou s'inscrire à Tubi pour programmer un rappel."
    },
    "screenDetails_error_addQueueSports_description": {
      "description": "Description of the warning dialog when user is attempting to add a game to their list but are not signed in",
      "message": "Se connecter ou s'inscrire à Tubi pour ajouter ce jeu à votre Liste."
    },
    "screenDetails_error_getContent_description": {
      "description": "Description of error when app is not able to get content.",
      "message": "Impossible de récupérer les informations de contenu du serveur."
    },
    "error_deeplink_content": {
      "description": "Error message when the app can not retrieve the deeplink content.",
      "message": "Le titre que vous essayez de regarder n'est pas disponible actuellement."
    },
    "error_deeplink_page": {
      "description": "Error message when the app can not retrieve the page requested through deeplink",
      "message": "La page que vous recherchez n'est pas disponible actuellement."
    },
    "error_tryAgain_title": {
      "description": "Error message when the user has the option to try the operation again.",
      "message": "Réessayer"
    },
    "screenDetails_queue_content_added_to_list_description": {
      "description": "Message when a content is added to the user's list after sign in.",
      "message": "Contenu"
    },
    "screenDetails_queue_added_to_list_description": {
      "description": "Message when a movie/series/replay game is added to the user's list after sign in.",
      "message": "{contentTitle} a été ajouté à la liste."
    },
    "screenDetails_queue_added_to_reminder_list_description": {
      "description": "Message when a upcoming game is added to the user's reminder list after sign in.",
      "message": "{upcomingTitle} a été associé aux rappels."
    },
    "screenDetails_error_queueMovie_description": {
      "description": "Error message when a movie is not added to the user's list.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant d'ajouter ce film à votre Liste."
    },
    "screenDetails_error_queueSeries_description": {
      "description": "Error message when a tv show/series is not added to the user's list.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant d'ajouter ce programme TV à votre Liste."
    },
    "screenDetails_error_noQueueMovie_description": {
      "description": "Error message when a movie is not removed from the user's list.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant de retirer ce film de votre Liste."
    },
    "screenDetails_error_noQueueSeries_description": {
      "description": "Error message when a tv show/series is not removed from the user's list.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant de retirer ce programme TV de votre Liste."
    },
    "screenDetails_error_noQueueUpcoming_description": {
      "description": "Error message when a upcoming game is not removed from the user's reminders list.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant de supprimer ce rappel."
    },
    "screenDetails_error_noQueueReplay_description": {
      "description": "Error message when a replay game is not removed from the user's list.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant de retirer cet événement sportif de votre Liste."
    },
    "screenDetails_error_likeDislike_description": {
      "description": "Error message when a video title's like/dislike rating is not changed.",
      "message": "Nous ignorons ce qui s'est passé, mais un problème est survenu en essayant de changer la notation."
    },
    "screenDetails_error_noHistory_description": {
      "description": "Error message when video is not removed from the user's viewing history.",
      "message": "Un problème est survenu en retirant le contenu de votre Historique."
    },
    "screenSettings_signIn_description": {
      "description": "Directions for the signin page",
      "message": "Connectez-vous à votre compte Tubi sur votre ordinateur ou votre téléphone pour voir vos programmes TV et vos films sauvegardés dans Ma liste, pour continuer à regarder là où vous vous êtes arrêté et obtenir des recommandations personnelles synchronisées sur votre téléphone, votre TV, votre tablette ou votre ordinateur."
    },
    "screenSettings_signOut_description": {
      "description": "Description on SignIn page when user is signed in",
      "message": "Vous êtes connecté(e) en tant que {nom}"
    },
    "screenSettings_signOut_description2": {
      "description": "More details on the SignIn page when user is signed in",
      "message": "Email : {email}"
    },
    "screenSettings_fullDeviceID": {
      "description": "Text proceeding the full device ID",
      "message": "Numéro d'identification complet de l'appareil"
    },
    "screenSettings_about_title": {
      "description": "The title of the about screen",
      "message": "À propos de Tubi"
    },
    "screenSettings_about_description": {
      "description": "The description on the about screen",
      "message": "Tubi est l'application leader de streaming vidéo gratuite et premium. Nous disposons d'une collection de contenu vaste et diversifiée avec plusieurs milliers de titres et 3 fois moins de publicités que sur le câble TV."
    },
    "screenSettings_about_title2": {
      "description": "The subtitle on the about screen",
      "message": "Besoin d'assistance ?"
    },
    "screenSettings_about_description2": {
      "description": "The 2nd description on the about screen",
      "message": "Visitez {help_url} \n \n Envoyez un e-mail à notre équipe d'assistance support@tubi.tv \n \nContactez-nous sur Facebook, Instagram, Twitter et sur notre site Internet à : \n {support_url} \n \n Version {version} \n Numéro d'identification abrégé : {id} (appuyez sur OK pour voir le numéro complet de l'appareil) \n \n © {year} Tubi, Inc. tous droits réservés."
    },
    "screenSettings_menu_parentalControls": {
      "description": "The label for the parental controls",
      "message": "Contrôle parental"
    },
    "screenSettings_menu_autoplayPreview": {
      "description": "The label for the autoplay preview",
      "message": "Aperçus automatiques"
    },
    "screenSettings_menu_autoplayControls": {
      "description": "The Label for the autoplay controls to turn video preview and autoplay of the next video on or off.",
      "message": "Commandes Auto-Lecture"
    },
    "screenSettings_menu_autoplayNextVideo": {
      "description": "The label for the autoplay next video",
      "message": "Auto-Lecture Vidéo Suivante"
    },
    "screenSettings_parentalControls_group_LittleKids": {
      "description": "Little Kids of the parental controls",
      "message": "Jeunes enfants",
      "note": "This translation is used as screenSettings_parentalControls_group_LittleKids, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_OlderKids": {
      "description": "Older Kids of the parental controls",
      "message": "Enfants plus âgés",
      "note": "This translation is used as screenSettings_parentalControls_group_OlderKids, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_Teens": {
      "description": "Teens of the parental controls",
      "message": "Adolescents",
      "note": "This translation is used as screenSettings_parentalControls_group_Teens, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group_Adults": {
      "description": "Adults of the parental controls",
      "message": "Adultes",
      "note": "This translation is used as screenSettings_parentalControls_group_Adults, please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_instructions": {
      "description": "Description of the parental controls screen",
      "message": "Veuillez sélectionner l'âge approprié pour regarder Tubi TV. Votre sélection déterminera les classifications de films et d'émissions que vous pourrez consulter dans l'application. Si vous modifiez cette sélection, vous devrez entrer le mot de passe de votre compte."
    },
    "screenSettings_autoplayPreview_instructions": {
      "description": "Description of the autoplay preview user choice screen",
      "message": "Vous pouvez activer ou désactiver la fonction de lecture automatique qui vous permet de prévisualiser la vidéo pendant la navigation."
    },
    "screenSettings_autoplayTimer_instructions": {
      "description": "Description of the autoplay timer user choice screen",
      "message": "Contenu est configuré pour lire Auto-Lecture une autre vidéo lorsque vous regardez est sur le point de terminer."
    },
    "screenSettings_autoplayTimer_instructions_guest_users": {
      "description": "Description of the autoplay timer user choice screen for guest users",
      "message": "Contenu est configuré pour lire Auto-Lecture une autre vidéo lorsque vous regardez est sur le point de terminer. Vous devez vous connecter pour utiliser cette fonctionnalité."
    },
    "screenSettings_autoplayPreview_featureDisabledMessage": {
      "description": "Message to display when the user has set Autoplay to false in Roku(not tubi) main settings.",
      "message": "La lecture automatique est contrôlée dans les paramètres Roku. Pour la modifier, allez dans Paramètres Roku -> Accessibilité -> Lecture automatique de la vidéo."
    },
    "screenSettings_menu_about": {
      "description": "A menu Item for the Settings screen",
      "message": "À propos de"
    },
    "screenSettings_menu_privacyPolicy": {
      "description": "A menu Item for the Settings screen",
      "message": "Politique de confidentialité"
    },
    "screenSettings_menu_tos": {
      "description": "A menu Item for the Settings screen",
      "message": "Conditions d'utilisation"
    },
    "screenSettings_menu_yourPrivacyChoices": {
      "description": "A menu Item for the Settings screen",
      "message": "Vos choix en matière de confidentialité"
    },
    "screenSettings_menu_PrivacyCenter": {
      "description": "A menu Item for the Settings screen",
      "message": "Centre de Confidentialité"
    },
    "screenSettings_menu_signOut": {
      "description": "A menu Item for the Settings screen",
      "message": "Déconnexion"
    },
    "screenSettings_signInPanel_title": {
      "description": "The title of the Sign In Panel of the Settings screen",
      "message": "Vous n'êtes pas encore connecté(e)"
    },
    "screenSettings_parentalPassword_title": {
      "description": "Directions for signed out users who attempt to change the parental controls",
      "message": "Entrez le mot de passe pour mettre à jour Contrôle parental"
    },
    "screenSettings_parentalPassword_button_hide": {
      "description": "Label of button on the password entry screen to hide the password",
      "message": "Cacher le mot de passe"
    },
    "screenSettings_parentalPassword_button_show": {
      "description": "Label of button on the password entry screen to display the password",
      "message": "Montrer le mot de passe"
    },
    "screenSettings_error_parentalFailedChange_title": {
      "description": "title of error screen when parental controls failed to update",
      "message": "Échec de la mise à jour"
    },
    "screenSettings_error_parentalFailedChange_description": {
      "description": "description of error screen when parental controls failed to update",
      "message": "La mise à jour des paramètres du contrôle parental a échoué. Veuillez essayer de saisir à nouveau votre mot de passe."
    },
    "screenSettings_error_parentalChanges": {
      "description": "title of dialog message when parental controls has changed",
      "message": "Changement des paramètres du contrôle parental"
    },
    "screenSettings_error_parentalChanges_description_default": {
      "description": "description of dialog message when parental controls has changed",
      "message": "Les paramètres du contrôle parental ont été modifiés. Le contrôle parental sera protégé par un mot de passe après 5 minutes."
    },
    "screenSettings_error_parentalChanges_description_group0": {
      "description": "Success message when parental controls has changed to group 0",
      "message": "Les paramètres du contrôle parental pour les " + Chr(34) + "Jeunes enfants" + Chr(34) + " ont été modifiés. Le contrôle parental sera protégé par un mot de passe après 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group1": {
      "description": "Success message when parental controls has changed to group 1",
      "message": "Les paramètres du contrôle parental pour les " + Chr(34) + "Enfants plus âgés" + Chr(34) + " ont été modifiés. Le contrôle parental sera protégé par un mot de passe après 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group2": {
      "description": "Success message when parental controls has changed to group 2",
      "message": "Les paramètres du contrôle parental pour les " + Chr(34) + "Adolescents" + Chr(34) + " ont été modifiés. Le contrôle parental sera protégé par un mot de passe après 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_parentalChanges_description_group3": {
      "description": "Success message when parental controls has changed to group 3",
      "message": "Les paramètres du contrôle parental pour les " + Chr(34) + "Adultes" + Chr(34) + " ont été modifiés. Le contrôle parental sera protégé par un mot de passe après 5 minutes.",
      "note": "This translation is used as screenSettings_error_parentalChanges_description_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_error_signInParental_description": {
      "description": "Description of message to let users know that they must be signed in to adjust the parental controls.",
      "message": "Vous devez être connecté(e) pour configurer le contrôle parental"
    },
    "screenSettings_error_signInAutoplayPreview_description": {
      "description": "Description of message to let users know that they must be signed in to change the AutoplayPreview choice.",
      "message": "Vous devez être connecté(e) pour modifier les préférences de lecture automatique."
    },
    "screenCategories_error_retrieve_message": {
      "description": "Onscreen message to indicate categories content could not be gathered",
      "message": "Impossible de récupérer le contenu des catégories."
    },
    "screenHome_error_fetchCategories_description": {
      "description": "Onscreen message to indicate categories content could not be loaded",
      "message": "Impossible de charger certaines catégories."
    },
    "screenHome_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate home content could not be loaded",
      "message": "Impossible de charger l'écran d'accueil Tubi."
    },
    "screenEspanol_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate espanol content could not be loaded",
      "message": "Impossible de charger l'écran espagnol Tubi."
    },
    "screenMovies_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate movies content could not be loaded",
      "message": "Impossible de charger l'écran de films Tubi."
    },
    "screenKids_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate kids home content could not be loaded",
      "message": "Impossible de charger l'écran Enfants Tubi."
    },
    "screenTv_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate TV content could not be loaded",
      "message": "Impossible de charger l'écran des programmes TV Tubi."
    },
    "epg_minutes_left": {
      "description": "Indicate the number of minutes left. Use an abbreviation for minutes to save space and so we don't have to worry about plural and singular forms of the word minutes.",
      "message": "plus que {minutes} min"
    },
    "hour_mins_left": {
      "description": "Indicates time left in the format 'x hour y mins left'",
      "message": "{hour} heures {minutes} min restantes"
    },
    "mins_left": {
      "description": "Indicates time left in the format 'y mins left'",
      "message": "{minutes} min restantes"
    },
    "today": {
      "description": "Today",
      "message": "AUJOURD'HUI"
    },
    "tomorrow": {
      "description": "Tomorrow",
      "message": "DEMAIN"
    },
    "onNow": {
      "description": "badge text to show program is not live but on now",
      "message": "MAINTENANT"
    },
    "day_1": {
      "description": "shortened version Monday, formatted with , and a space",
      "message": "Lun "
    },
    "day_2": {
      "description": "shortened version Tuesday, formatted with , and a space",
      "message": "Mar "
    },
    "day_3": {
      "description": "shortened version Wednessday, formatted with , and a space",
      "message": "Mer "
    },
    "day_4": {
      "description": "shortened version Thursday, formatted with , and a space",
      "message": "Jeu "
    },
    "day_5": {
      "description": "shortened version Friday, formatted with , and a space",
      "message": "Ven "
    },
    "day_6": {
      "description": "shortened version Saturday, formatted with , and a space",
      "message": "Sam "
    },
    "day_7": {
      "description": "shortened version Sunday, formatted with , and a space",
      "message": "Dim "
    },
    "short_version_date_format_1": {
      "description": "Shortened version of date format for the month of January",
      "message": "{day} jan {year}"
    },
    "short_version_date_format_2": {
      "description": "Shortened version of date format for the month of February",
      "message": "{day} fév {year}"
    },
    "short_version_date_format_3": {
      "description": "Shortened version of date format for the month of March",
      "message": "{day} mar {year}"
    },
    "short_version_date_format_4": {
      "description": "Shortened version of date format for the month of April",
      "message": "{day} avr {year}"
    },
    "short_version_date_format_5": {
      "description": "Shortened version of date format for the month of May",
      "message": "{day} mai {year}"
    },
    "short_version_date_format_6": {
      "description": "Shortened version of date format for the month of June",
      "message": "{day} jui {year}"
    },
    "short_version_date_format_7": {
      "description": "Shortened version of date format for the month of July",
      "message": "{day} juil {year}"
    },
    "short_version_date_format_8": {
      "description": "Shortened version of date format for the month of August",
      "message": "{day} août {year}"
    },
    "short_version_date_format_9": {
      "description": "Shortened version of date format for the month of September",
      "message": "{day} sep {year}"
    },
    "short_version_date_format_10": {
      "description": "Shortened version of date format for the month of October",
      "message": "{day} oct {year}"
    },
    "short_version_date_format_11": {
      "description": "Shortened version of date format for the month of November",
      "message": "{day} nov {year}"
    },
    "short_version_date_format_12": {
      "description": "Shortened version of date format for the month of December",
      "message": "{day} déc {year}"
    },
    "channelGuide_error_fetchContent_description": {
      "description": "Onscreen message to indicate channel Guide content could not be loaded",
      "message": "Impossible de charger le guide des chaînes."
    },
    "screenMyStuff_signedOutUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "Faites de Tubi le Vôtre Gratuitement (pour toujours)"
    },
    "screenMyStuff_signedOutUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Trouvez vos favoris, reprenez où vous étiez á-le tout au même endroit."
    },
    "screenMyStuff_signedOutUIBlurb": {
      "description": "The blurb of the MyStuff Screen for the guest user.",
      "message": "Et toujours gratuit."
    },
    "screenMyStuff_signedOutUIButton": {
      "description": "The button of the MyStuff Screen for the guest user.",
      "message": "Déverrouillez Maintenant"
    },
    "screenMyStuff_allEmptyUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "Mes affaires sont vides"
    },
    "screenMyStuff_allEmptyUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Pour ajouter un titre à votre liste, utilisez l'icône marque-page."
    },
    "screenDetails_button_trailer": {
      "description": "Label of button to allow users to watch a preview of the current video title",
      "message": "Regarder la bande-annonce"
    },
    "screenDetails_button_episodes": {
      "description": "Label of button to allow users to display the list of episodes/seasons of the current video title. Should be title case.",
      "message": "Tous les épisodes"
    },
    "screenDetails_button_episodes_more": {
      "description": "Label displayed over episodes list + YMAL on the details Screen.",
      "message": "Épisodes et plus"
    },
    "screenDetails_relatedTitles": {
      "description": "Label of button to allow users to view other video titles related to the current video title",
      "message": "Vous pourriez aussi aimer"
    },
    "screenDetails_button_play": {
      "description": "Label of button to allow users to play the current video title",
      "message": "Lecture"
    },
    "screenDetails_button_startOver": {
      "description": "Label of button to allow users to start over and play the current video title",
      "message": "Lire depuis le début"
    },
    "screenDetails_button_like_instructions": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": " - Supprimer la notation"
    },
    "screenDetails_button_like": {
      "description": "Label of button to allow users to like the current video title",
      "message": "J'aime"
    },
    "screenDetails_button_likeIt": {
      "description": "Label of button to allow users to like the current video title",
      "message": "J'aime ça"
    },
    "screenDetails_button_removeRating": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": "Supprimer l'évaluation"
    },
    "screenDetails_button_liked": {
      "description": "Label of button to indicate to users that the current video title has been liked",
      "message": "Vous aimez"
    },
    "screenDetails_button_dislike": {
      "description": "Label of button to allow users to dislike the current video title",
      "message": "Je n'aime pas"
    },
    "screenDetails_button_disliked": {
      "description": "Label of button to indicate to users that the current video title has been disliked",
      "message": "Vous n'aimez pas"
    },
    "screenDetails_button_notForMe": {
      "description": "Label of button to allow users to ignore the current video title",
      "message": "Pas pour moi"
    },
    "screenDetails_button_likeDislike": {
      "description": "Label of unfocused button to allow users to like or dislike the current video title",
      "message": "J'aime ou Je n'aime pas"
    },
    "screenDetails_button_sign_in_to_set_reminder": {
      "description": "Label of button to allow users to set the reminder to the current video title when the user is not signed in.",
      "message": "Connectez-vous pour programmer un rappel"
    },
    "screenDetails_button_set_reminder": {
      "description": "Label of button to allow users to set the reminder to the current video title when the user is signed in.",
      "message": "Programmer un rappel"
    },
    "screenDetails_button_remove_reminder": {
      "description": "Label of button to indicate the users that reminder is set on the current video title",
      "message": "Supprimer le rappel"
    },
    "screenDetails_button_resume_playing": {
      "description": "Label of button to allow users to resume the current video title",
      "message": "Reprendre la lecture"
    },
    "screenAgeVerification_network_issue": {
      "description": "An error message shown to users when they submit their birthdate, but there is an unexpected server or network error",
      "message": "L'envoi de votre date de naissance à nos serveurs n'a pas abouti."
    },
    "screenSignUpAgeVerification_sub_header_age": {
      "description": "A sub header message to direct users to enter their age",
      "message": "Pour continuer, veuillez vérifier votre âge"
    },
    "screenSignUpAgeVerification_request_age_prefix": {
      "description": "Label to ask user to enter their age. This part precedes the age provided",
      "message": "J'ai"
    },
    "screenSignUpAgeVerification_request_age_postfix": {
      "description": "Label to ask user to enter their age. This part comes after the age provided",
      "message": "ans"
    },
    "screenSignUpAgeVerification_error_prompt_age": {
      "description": "A message informing the user that they entered an age that is not acceptable",
      "message": "Veuillez entrer un âge valide"
    },
    "screenAgeVerification_header": {
      "description": "A header message on the Age required screen asking them to confirm their age",
      "message": "Confirmez votre âge*"
    },
    "screenAgeVerification_sub_header": {
      "description": "A sub header message to direct users to enter their birth date",
      "message": "Pour continuer, veuillez vérifier votre année de naissance"
    },
    "screenAgeVerification_keypad_button": {
      "description": "A message on the button below the birth date keypad that users should select once done inserting their birth date",
      "message": "Commencer à regarder"
    },
    "screenAgeVerification_year": {
      "description": "A label explaining that the 4 digits above the label signify the year that was input by the user",
      "message": "Année de naissance"
    },
    "screenAgeVerification_yyyy": {
      "description": "A label showing that the user should enter four digits for their birthdate year",
      "message": "AAAA"
    },
    "screenAgeVerification_warning_prompt": {
      "description": "A message informing the user that they entered a date that is not valid",
      "message": "Veuillez vérifier que les informations saisies sont correctes"
    },
    "screenAgeVerification_error_prompt": {
      "description": "A message informing the user that they entered a date that is not acceptable",
      "message": "Veuillez entrer une année de naissance valide"
    },
    "metadata_fullscreen_countdown_plural": {
      "description": "label to indicate how many seconds it will take before the video player will automatically go fullscreen. This is the plural version but an attempt should be made to ensure the string is neither plural or singular by using a shorten form of seconds.",
      "message": "Plein écran dans {seconds} sec"
    },
    "metadata_fullscreen_countdown_no_seconds": {
      "description": "label to indicate how many seconds it will take before the video player will automatically go fullscreen. The word 'seconds' should NOT follow the number of seconds.",
      "message": "Plein écran dans {seconds}"
    },
    "metadata_watch_again": {
      "description": "label to indicate a watched video can be watched again",
      "message": "Regarde encore"
    },
    "metadata_expiresIn_plural": {
      "description": "label to indicate how long the user have to watch a video",
      "message": "Expire dans {days} jours"
    },
    "metadata_expiresIn_singular": {
      "description": "label to indicate the user has exactly 1 day to watch a video",
      "message": "Expire dans 1 jour"
    },
    "metadata_myStuff_empty_myList_title": {
      "description": "For an empty MyList container, this is the title that is displayed in the empty container",
      "message": "Votre liste est vide"
    },
    "metadata_myStuff_empty_myList_description": {
      "description": "For an empty MyList container, this is the description/subtitle that is display in the empty container",
      "message": "Utilisez bouton de signet pour enregistrer vos séries et films préférés. Ils montreront ici."
    },
    "metadata_myStuff_empty_continueWatching_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the empty container",
      "message": "Vous êtes à jour!"
    },
    "metadata_myStuff_empty_continueWatching_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the empty container",
      "message": "Les films et series que vous n'avez pas fini de regarder apparaissent ici."
    },
    "metadata_myStuff_empty_continueWatchingInfoPanel_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the InfoPanel when the empty container is in focus",
      "message": "Continuer à regarder"
    },
    "metadata_myStuff_myLikes_title": {
      "description": "The title of the My Likes container.",
      "message": "Mes goûts"
    },
    "metadata_myStuff_empty_myListInfoPanel_description": {
      "description": "For an empty myList container, this is the description/subtitle that is display in the InfoPanel when the empty container is in focus",
      "message": "Regardez ce que vous avez économisé pour plus tard."
    },
    "metadata_myStuff_empty_myListInfoPanel_title": {
      "description": "For an empty myList container, this is the title that is display in the InfoPanel when the empty container is in focus",
      "message": "Ma liste"
    },
    "metadata_myStuff_empty_continueWatchingInfoPanel_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the InfoPanel when the empty container is in focus",
      "message": "Reprendre là où vous en étiez."
    },
    "metadata_continueWatching_notSignedIn_title": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Inscrivez-vous pour sauvegarder votre progression"
    },
    "metadata_continueWatching_notSignedIn_description": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Reprenez là où vous vous êtes arrêté la prochaine fois que vous regarderez une série TV ou un film. Disponible après vous être inscrit(e)."
    },
    "metadata_continueWatching_notSignedIn_container_description": {
      "description": "tells non registered user what they need to do to see the continue watching container",
      "message": "Pas d'abonnement  •  Pas de carte de crédit  •  Gratuit pour toujours"
    },
    "metadata_continueWatching_notSignedIn_container_button": {
      "description": "button text for when a non registered user focuses on the continue watching container",
      "message": "Inscrivez-vous pour sauvegarder votre progression - GRATUIT"
    },
    "metadata_directed": {
      "description": "metadata label to indicate the directors of the current video title",
      "message": "Réalisé par"
    },
    "metadata_starring": {
      "description": "metadata label to indicate the actors of the current video title",
      "message": "Avec"
    },
    "metadata_seasons_plural": {
      "description": "Label of how many seasons of the current TV title",
      "message": "{seasons} saisons"
    },
    "metadata_seasons_singular": {
      "description": "Label for when the current TV title has exactly one season",
      "message": "1 saison"
    },
    "metadata_series": {
      "description": "Label to indicate a title is a TV series",
      "message": "Série"
    },
    "sponsor_brought_by": {
      "description": "When content is sponsored by an advertizer, then this text proceeds the image of the sponsor. The text and the image should make a complete sentence.",
      "message": "Proposé par"
    },
    "registration_signIn_recommended": {
      "description": "text appended to recommended row label to subtly remind users that they are signed out so that they understand that they need to sign-in to use Tubi at its fullest",
      "message": "Connectez-vous pour une expérience plus personnalisée"
    },
    "screenEndCard_startingIn": {
      "description": "indicator for how many seconds until next video will start playing (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "Commence dans {seconds} sec."
    },
    "videoPlayer_trailerTitle": {
      "description": "Label for the video preview associated with the current video title",
      "message": "Bande-annonce ({title})"
    },
    "videoPlayer_adLoadingMessage": {
      "description": "Message to indicate ads will play before playing video content",
      "message": "Votre programme va commencer après ces messages..."
    },
    "videoPlayer_error_failed_description": {
      "description": "label for error messages to indicate 'failed'",
      "message": "ÉCHEC"
    },
    "videoPlayer_error_invalidURL_description": {
      "description": "Error message to indicate that the video URL is invalid.",
      "message": "L'URL de la vidéo n'est pas valide."
    },
    "videoPlayer_error_playback_description": {
      "description": "Error message when video could not play",
      "message": "Il y a eu un problème avec la lecture de la vidéo."
    },
    "videoPlayer_adHeadsUp": {
      "description": "Warning when the ad break is about to begin. (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "La pause pub commence dans {seconds} sec."
    },
    "videoPlayer_toast_message": {
      "description": "Message to be displayed on Toast-message when user signed in.",
      "message": "Vous êtes maintenant connecté avec succès"
    },
    "linearVideoPlayer_buttonBack": {
      "description": "Label of a Button to go back",
      "message": "Retour"
    },
    "linearVideoPlayer_buttonCaptions": {
      "description": "Label of a Button to display the closed captions",
      "message": "Sous-titres"
    },
    "linearVideoPlayer_buttonCaptions2": {
      "description": "Label of a Button to display the closed captions",
      "message": "Sous-titres"
    },
    "linearVideoPlayer_buttonGuide2": {
      "description": "Label of a Button to view the channel guide",
      "message": "Guide TV complet"
    },
    "linearVideoPlayer_buttonTvGuide": {
      "description": "Label of a Button to view the TV channel guide",
      "message": "Guide TV"
    },
    "linearVideoPlayer_buttonLanguage": {
      "description": "Label of a Button which is displayed on linear player screen to select language",
      "message": "Langue"
    },
    "linearVideoPlayer_comingUp": {
      "description": "Label of a coming up program in linear video player",
      "message": "À venir"
    },
    "linearVideoPlayer_comingUpAt": {
      "description": "Label of a coming up program with time in linear video player",
      "message": "À venir à {time}"
    },
    "linearVideoPlayer_timeLeft": {
      "description": "Label to display time left in linear video player info panel",
      "message": "{time} restantes"
    },
    "channel_name": {
      "description": "This is the name of the app. This is not located in the app. It is displayed to the user in the Roku Channel Store",
      "message": "Tubi - Films et TV gratuits"
    },
    "channel_description": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Channel Store",
      "message": "Profitez de la plus grande collection de films et de programmes TV populaires. Tout est gratuit !",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "channel_webDescription": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Web Channel Store",
      "message": "Regardez gratuitement des milliers de films et de séries TV à succès. Tubi est un service de streaming illimité 100% légal, sans carte de crédit et sans abonnement. Choisissez ce que vous voulez regarder, quand vous voulez et avec moins de publicités que la TV ordinaire. Tubi est le plus grand service de streaming gratuit qui propose des films et des séries TV primés. Il y en a pour tous les goûts : des comédies aux drames, des films pour enfants aux classiques, en passant par les favoris de contenus ciblés comme les drames coréens, les animations et les séries britanniques. Téléchargez dès maintenant et commencez à regarder du divertissement en streaming gratuitement, dès aujourd'hui !",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "dialog_whoops_title": {
      "description": "A general whoops title for an dialog window",
      "message": "Oups !"
    },
    "dialog_mylist_signIn_description": {
      "description": "Dialog description to say the user to signIn to view the My List",
      "message": "Vous devez être connecté(e) pour voir votre Liste."
    },
    "dialog_mylist_empty_title": {
      "description": "A general empty My list title for an dialog window",
      "message": "Oh non ! Votre liste est vide."
    },
    "dialog_mylist_empty_description": {
      "description": "Dialog description to say My List is empty",
      "message": "Retrouvez ici tout ce que vous voulez ajouter à Ma liste. Pour commencer, sélectionnez un programme TV ou un film et cliquez sur le bouton Ajouter à ma Liste."
    },
    "dialog_button_register_signIn": {
      "description": "The label of the button in a dialog window that allows the user to register or signIn",
      "message": "Se connecter ou S'inscrire"
    },
    "why_ask_age_description": {
      "description": "The main message which explains why Tubi is asking for the users year of birth",
      "message": "*Nous traitons ces informations comme décrit dans la Politique de confidentialité et les Conditions d'utilisation de Tubi. Pour plus d'informations, voir www.tubi.tv/privacy et www.tubi.tv/terms Des questions? Faites-le nous savoir à www.tubi.tv/support"
    },
    "signIn_screen_heading": {
      "description": "Title on the signIn screen",
      "message": "Connectez-vous à votre compte"
    },
    "signIn_screen_enter_password": {
      "description": "enter password text",
      "message": "Entrez votre mot de passe Tubi"
    },
    "forgot_password_text": {
      "description": "forgot password text",
      "message": "Vous avez oublié votre mot de passe ?"
    },
    "forgot_password_link": {
      "description": "forgot password link",
      "message": "Allez sur tubi.tv/forgot pour réinitialiser"
    },
    "signIn_password_hint": {
      "description": "hint shown on signIn password textbox",
      "message": "mot de passe"
    },
    "signUp_password_hint": {
      "description": "hint shown on signUp password textbox",
      "message": "définir un mot de passe"
    },
    "signUp_screen_heading": {
      "description": "Title on the signUp screen",
      "message": "Créez un nouveau compte"
    },
    "signUp_screen_password_validation": {
      "description": "sign up screen password validation text",
      "message": "Appuyez sur OK sur votre télécommande et définissez un nouveau mot de passe."
    },
    "already_having_account_text": {
      "description": "already having account text",
      "message": "Vous avez déjà un compte ?"
    },
    "password_length_validation": {
      "description": "password length validation",
      "message": "Le mot de passe doit comporter de 6 à 30 caractères"
    },
    "invalid_password_title": {
      "description": "invalid password title on modal",
      "message": "Mot de passe invalide"
    },
    "invalid_oops_password_title": {
      "description": "invalid password title on modal",
      "message": "Oups, mauvais mot de passe"
    },
    "enter_password_dialog_description": {
      "description": "enter password dialog description",
      "message": "Veuillez entrer votre mot de passe Tubi pour ce compte"
    },
    "invalid_oops_password_description": {
      "description": "enter password dialog description",
      "message": "Réessayons ou saisissons un autre mot de passe pour ce compte:"
    },
    "retry": {
      "description": "retry button text on modal",
      "message": "Réessayer"
    },
    "could_not_verify_email": {
      "description": "could not verify your email modal description",
      "message": "Votre adresse e-mail n'a pas pu être vérifiée"
    },
    "check_email_inbox": {
      "description": "Title on the email verification screen",
      "message": "Vérifiez vos e-mails"
    },
    "click_on_verification_link": {
      "description": "Message shown on the email verification screen about the verification link sent to email",
      "message": "Veuillez cliquer sur le lien de vérification envoyé à votre adresse e-mail :"
    },
    "screen_refresh_after_email_verification": {
      "description": "Message shown on the email verification to let the user know screen will refresh after the email verification",
      "message": "Cet écran s'actualisera une fois que vous aurez vérifié votre e-mail."
    },
    "rated_Label": {
      "description": "Label shown on video player when tv rating/descriptor is shown",
      "message": "CLASSÉ"
    },
    "skipIntro_Player": {
      "description": "Navigational instructions to users to skip the introduction section of the title. Usually the song or the beginning credits",
      "message": "Passer l'intro"
    },
    "skipRecap_Player": {
      "description": "Navigational instructions to users to skip the section where the previous part of the show is recapped",
      "message": "Passer le résumé"
    },
    "skipEarlyCredits_Player": {
      "description": "Navigational instructions to users to skip when the Credits are followed by a scene",
      "message": "Passer le générique"
    },
    "invalid_email_title": {
      "description": "Asking to enter a valid email on Email screen",
      "message": "Veuillez entrer une adresse e-mail valide"
    },
    "email_screen_heading": {
      "description": "Asking to enter a email on Email screen",
      "message": "Entrez votre adresse e-mail"
    },
    "screenAgeVerification_born_year": {
      "description": "Label to ask user to enter their year of birth",
      "message": "Je suis né en"
    },
    "signIn_screen_subheading": {
      "description": "Sub title on the signIn screen",
      "message": "Votre adresse e-mail est déjà associée à un compte Tubi existant."
    },
    "forgotPassword_screen_heading": {
      "description": "Title on the forgot password screen",
      "message": "Une aide est en route!"
    },
    "forgotPassword_screen_instant_subheading": {
      "description": "Sub title on the forgot password screen - instant version",
      "message": "Allez dans cette boîte aux lettres électronique et cliquez sur le lien de connexion instantanée:"
    },
    "forgotPassword_screen_noInstant_subheading": {
      "description": "Sub title on the forgot password screen - no instant version",
      "message": "Allez dans cette boîte aux lettres électronique et cliquez sur le lien de réinitialisation du mot de passe:"
    },
    "forgotPassword_screen_instant_subheading2": {
      "description": "2nd Sub title on the forgot password screen - instant version",
      "message": "Cet écran s'actualisera une fois que vous aurez cliqué sur le lien figurant dans votre courrier électronique."
    },
    "forgotPassword_screen_noInstant_subheading2": {
      "description": "2nd Sub title on the forgot password screen - noInstant version",
      "message": "Une fois votre mot de passe réinitialisé, cliquez ci-dessous pour essayer de vous connecter."
    },
    "forgotPassword_screen_btn_resend": {
      "description": "The button on the forgot password screen that corresponds to the action 'Resend Sign-in link",
      "message": "Renvoyer le lien de connexion"
    },
    "forgotPassword_screen_btn_different_email": {
      "description": "The button on the forgot password screen that corresponds to the action 'Use Different Email",
      "message": "Utiliser un courriel différent"
    },
    "search_hint": {
      "description": "Instructions to the user to use microphone icon on his/her remote to use voice enabled keyboard. Please note that a microphone icon will be placed immediately after the last word of this translation and the icon will be considered part of the sentence.",
      "message": "Pour utiliser votre télécommande vocale, appuyez et maintenez"
    },
    "search_voice_hint": {
      "description": "Instructions to the user to use microphone icon on his/her remote to use voice enabled keyboard. Please note that a microphone icon will be placed at the beginning of the sentence.",
      "message": "Pour utiliser votre télécommande vocale, appuyez sur le bouton du micro et maintenez-le."
    },
    "dialog_button_signUp": {
      "description": "The label of the button in a dialog window that allows the user to sign up into the app.",
      "message": "S'inscrire"
    },
    "screenSettings_parentalPassword_setup_new_password": {
      "description": "Directions for users who attempt to change the parental controls",
      "message": "Pour créer un nouveau mot de passe"
    },
    "screenSettings_parentalPassword_visit_link": {
      "description": "Directions for users to setup the new password",
      "message": "visitez tubi.tv/password"
    },
    "screenSettings_parentalPassword_visit_webBrowser": {
      "description": "Directions for users to setup the new password on browser",
      "message": "1. Veuillez visiter tubi.tv/passwordsur un navigateur web"
    },
    "screenSettings_parentalPassword_email": {
      "description": "Directions to the user to enter his/her email to setup new password",
      "message": "2. Entrez votre email"
    },
    "screenSettings_parentalPassword_set_new_Password": {
      "description": "Directions to the user about email notification to setup new password",
      "message": "3. Nous vous enverrons les instructions pour créer un nouveau mot de passe."
    },
    "screenSettings_parentalPassword_know_my_Password": {
      "description": "Directions to the user to enter his/her password if they know their password",
      "message": "Je connais mon mot de passe. Allons-y."
    },
    "registration_signup_button": {
      "description": "button text for when a non registered user focuses on details screen",
      "message": "Inscrivez-vous pour sauvegarder votre progression"
    },
    "registration_signup_button_free": {
      "description": "button text on top of background image next to sign up text for when a non registered user focuses on details screen",
      "message": "GRATUIT"
    },
    "registration_signIn_to_play_button": {
      "description": "button text for when a non registered user focuses on details screen for sportsEvent",
      "message": "Se connecter"
    },
    "registration_signIn_to_play_R_rated": {
      "description": "Hint message why we have locked the content.",
      "message": "Connexion requise pour protéger les jeunes publics. Non carte de crédit nécessaire."
    },
    "registration_signIn_to_play_default": {
      "description": "Hint message why we have locked the content. This is the default message",
      "message": "Connexion requise. Aucune carte de crédit nécessaire."
    },
    "text_new": {
      "description": "simple text to use anywhere to indicate item is new",
      "message": "NOUVEAU"
    },
    "screenEmailVerification_resend_verification_link": {
      "description": "Label of button to allow users to resend the email verification link for sign in",
      "message": "Renvoyer le lien de vérification"
    },
    "screenEmailVerification_use_different_email": {
      "description": "Label of button to allow users to use different email address for sign in",
      "message": "Utiliser une autre adresse e-mail"
    },
    "next_button": {
      "description": "Button text displayed on onBoarding screens to proceed to next screens",
      "message": "Prochain"
    },
    "skip_button": {
      "description": "Button text displayed on onBoarding screens to skip the onboarding flow",
      "message": "Passer"
    },
    "getStarted_button": {
      "description": "Button text displayed on onBoarding screens, takes to landing screen",
      "message": "Commencer"
    },
    "registerOrSignIn_button": {
      "description": "Button text displayed on onBoarding screens takes to Roku Request for Information modal",
      "message": "Continuer avec Roku"
    },
    "continueAsGuest_button": {
      "description": "Button text displayed on onBoarding screens takes to Initial Content Type Selector Screen or Home Screen",
      "message": "Continuer en tant qu'invité"
    },
    "onBoarding_landingScreen_addListLabel": {
      "description": "Label displayed on onBoarding Landing screen informing add to your list",
      "message": "Ajouter à votre Liste"
    },
    "onBoarding_landingScreen_saveProgressLabel": {
      "description": "Label displayed on onBoarding Landing screen informing save your progress",
      "message": "Sauvegardez votre progression"
    },
    "onBoarding_landingScreen_saveProgressBody": {
      "description": "Body displayed on onBoarding Landing screen informing pickup where you left off",
      "message": "Reprenez là où vous vous êtes arrêté"
    },
    "dialog_got_it": {
      "description": "simple text to use anywhere to indicate dismiss action",
      "message": "J'ai compris"
    },
    "reg_intro_title": {
      "description": "title displayed on registration welcome modal",
      "message": "Tubi, c'est mieux quand vous vous connectez"
    },
    "reg_intro_sub_header": {
      "description": "sub header displayed on registraton welcome modal",
      "message": "Pas de carte de crédit. Gratuit pour toujours."
    },
    "reg_first_line_sub_item": {
      "description": "first sub item to be displayed under reg_first_line_item to explain user about benifit of registration",
      "message": "Enregistrez maintenant, regardez plus tard"
    },
    "reg_third_line_item": {
      "description": "third item to let know user about the benifit of registration",
      "message": "Débloquez des sélections rien que pour vous"
    },
    "reg_third_line_sub_item": {
      "description": "third sub item to be displayed under reg_third_line_item to explain user about benifit of registration",
      "message": "Obtenir de meilleures recommandations"
    },
    "reg_sign_in_button_title": {
      "description": "Button text to be displayed on first button of registration welcome modal",
      "message": "Continuer à s'identifier"
    },
    "reg_continue_as_guest_button_title": {
      "description": "Button text to be displayed on second button of registration welcome modal",
      "message": "Continuer en tant qu'invité"
    },
    "replay": {
      "description": "This label used for badge to indicate the content availability",
      "message": "Rediffusion"
    },
    "info_panel_reminder_is_set": {
      "description": "Hint in the content metadata area informing the user that the reminder is set for this content",
      "message": "Rappel programmé"
    },
    "info_panel_available_in_4k": {
      "description": "Lets user know this content is available in 4k (although may not be available on their device)",
      "message": "Disponible en 4K"
    },
    "goBack_videoPlayer_ad": {
      "description": "Navigational instructions to users when pause Ad is displayed on video screen",
      "message": "Appuyez sur n'importe quel bouton pour fermer l'annonce"
    },
    "cc_audio_overlay_subtitles": {
      "description": "Available closed caption tracks section header label.",
      "message": "Sous-titres"
    },
    "consent_screen_heading": {
      "description": "Consent screen heading.",
      "message": "Votre Vie Privée"
    },
    "consent_screen_subheading": {
      "description": "Consent screen sub heading.",
      "message": "Veuillez prendre un moment pour confirmer vos préférences en matière de confidentialité des données"
    },
    "manage_preferences_button_label": {
      "description": "Manage preferences button label.",
      "message": "Gérer les Préférences"
    },
    "accept_all_button_label": {
      "description": "Accept button label.",
      "message": "Tout Accepter"
    },
    "reject_all_button_label": {
      "description": "Reject button label.",
      "message": "Rejeter Tout"
    },
    "privacy_preferences_label": {
      "description": "privacy preferences screen title.",
      "message": "Paramètres de Confidentialité"
    },
    "privacy_preferences_save_continue_button": {
      "description": "Save and Continue button on Consent Manage preferences",
      "message": "Enregistrer et Continuer"
    },
    "privacy_preferences_privacy_section_heading": {
      "description": "Privacy section heading.",
      "message": "Politique de confidentialité"
    },
    "privacy_preferences_privacy_section_subheading": {
      "description": "Privacy section subheading.",
      "message": "Pour consulter la politique de confidentialité de Tubi, scannez le code QR ci-dessous avec votre appareil mobile ou visitez "
    },
    "privacy_preferences_tos_section_heading": {
      "description": "Terms of service section heading.",
      "message": "Conditions d'utilisation"
    },
    "privacy_preferences_tos_section_subheading": {
      "description": "Terms of service section subheading.",
      "message": "Pour consulter les conditions d'utilisation de Tubi, scannez le code QR ci-dessous avec votre appareil mobile ou visitez "
    },
    "privacy_preferences_qrcode_modal_subheading": {
      "description": "QR Code Selected Modal subheading.",
      "message": "Scannez le code QR sur l'écran précédent avec votre appareil mobile pour afficher le lien."
    },
    "privacy_preferences_on": {
      "description": "Privacy preferences toggle text on",
      "message": "Activer"
    },
    "privacy_preferences_off": {
      "description": "Privacy preferences toggle text off",
      "message": "Arrêt"
    },
    "privacy_preferences_required": {
      "description": "Privacy preferences required text",
      "message": "Obligatoire"
    },
    "required_preference_selected_toast_heading": {
      "description": "Toast header when required preference item is selected.",
      "message": "Réglage Requis"
    },
    "required_preference_selected_toast_message": {
      "description": "Toast message when required preference item is selected.",
      "message": "{preference} La fonctionnalité est nécessaire pour continuer."
    },
    "privacy_center_not_editable_mode_warning": {
      "description": "Warning label that will be displayed in privacy center whenever user is in kids mode or any parental controls mode.",
      "message": "Paramètres de confidentialité ne peuvent être modifiés qu'en dehors de Tubi Kids. Seules les données essentielles sont utilisées dans Tubi Enfants."
    },
    "accept_now_button_label": {
      "description": "Button Label that will be used in consent screen accept button.",
      "message": "Acceptez Maintenant"
    },
    "maybe_later_button_label": {
      "description": "Button Label that will be used in consent screen Maybe later button.",
      "message": "Peut-être plus tard"
    },
    "roku_cw_consent_screen_heading": {
      "description": "Roku Continue Watching screen heading.",
      "message": "Revenez Plus Vite à Ce Que Vous Aimez"
    },
    "roku_cw_consent_screen_sub_heading": {
      "description": "Roku Continue Watching screen sub heading.",
      "message": "Facilitez-vous la tâche pour revenir à ce que vous regardiez et obtenez de meilleures recommandations sur ce qu'il faut diffuser ensuite.\n\nChoisir " + Chr(34) + "Accepter maintenant" + Chr(34) + " pour autoriser Tubi à partager votre historique de visionnage de vidéos avec Roku.\n\nVous pouvez modifier cela à tout moment dans les paramètres."
    },
    "player_exit_prompt_signup_heading": {
      "description": "Video Player exit prompt signup header",
      "message": "Attendez, ne perds pas ta place!"
    },
    "player_exit_prompt_signup_sub_heading": {
      "description": "Video Player exit prompt signup sub header",
      "message": "Inscrivez pour sauvegarder vos progrès et reprendre. Aucune carte de crédit n'est requise."
    },
    "player_exit_prompt_signup_later_button": {
      "description": "Video Player exit prompt signup later",
      "message": "S'inscrire plus tard"
    },
    "trending_search_results_hint": {
      "description": "Trending Search Results hint which will be displayed in the search screen when we do not have enough search results.",
      "message": "Voici d'autres recherches populaires qui pourraient vous plaire"
    },
    "search_results_no_matching_results": {
      "description": "No matching results message which will be displayed in search results screen.",
      "message": "Nous n'avons trouvé aucun résultat pour"
    },
    "privacy_center_save_restart": {
      "description": "Settings screen privacy center save and restart consent button label.",
      "message": "Enregistrer et Redémarrer Tubi"
    },
    "gdpr_age_gate_error_dialog_heading": {
      "description": "GDPR age gate error dialog heading.",
      "message": "Nous sommes désolés"
    },
    "gdpr_age_gate_error_dialog_sub_heading": {
      "description": "GDPR age gate error dialog sub heading.",
      "message": "Désolé, vous n'êtes pas éligible pour continuer."
    },
    "gdpr_age_gate_error_dialog_exit_tubi": {
      "description": "GDPR age gate error dialog exit tubi button label.",
      "message": "Sortie Tubi"
    },
    "updated_terms_toast_message": {
      "description": "Message on the toast message informing the user of update ToS. Please keep style tags intact when translating.",
      "message": "<defaultStyle>Nous avons mis à jour nos Conditions d'utilisation. En continuant à utiliser Tubi, vous acceptez ces conditions mises à jour. Vous pouvez consulter nos conditions sur</defaultStyle><urlStyle>https://tubitv.com/static/terms</urlStyle>"
    },
    "privacy_center_restart_channel": {
      "description": "Settings screen privacy center restart channel button label.",
      "message": "Redémarrer"
    },
    "save_consent_dialog_heading": {
      "description": "Settings screen save consent dialog heading.",
      "message": "Paramètres De Confidentialité Mis à Jour"
    },
    "save_consent_dialog_sub_heading": {
      "description": "Settings screen save consent dialog sub heading.",
      "message": "Vous devez redémarrer Tubi pour que les modifications prennent effet."
    },
    "privacy_center_view_privacy_settings_hint": {
      "description": "Settings screen privacy center view privacy settings hint.",
      "message": "Vous devez enregistrer les modifications de confidentialité et redémarrer Tubi pour que les modifications prennent effet."
    },
    "privacy_center_view_privacy_settings": {
      "description": "Settings screen privacy center launch preferences center button label.",
      "message": "Afficher Paramètres de Confidentialité"
    },
    "privacy_disclaimer": {
      "description": "Privacy disclaimer text displayed in Sign in and registration flow.",
      "message": "En vous inscrivant ou en vous connectant, vous reconnaissez avoir lu et compris la Politique de confidentialité de Tubi et acceptez les Conditions d'utilisation de Tubi. En savoir plus sur {privacy_policy_url} et {terms_of_use_url}"
    },
    "dialog_gdpr_manage_privacy_settings_error_description": {
      "description": "Error dialog description shown due to one trust component library failure when clicking manage privacy settings.",
      "message": "Redémarrer Tubi pour mettre à jour les paramètres de confidentialité. S'il vous plaît email support@tubi.tv si ça continue."
    },
    "live_on_date": {
      "description": "date label used in air date countdown timer",
      "message": "EN DIRECT SUR {month} {day}"
    },
    "live_on_date_today": {
      "description": "date label used in air date countdown timer",
      "message": "AUJOURD'HUI À {time}"
    },
    "live_on_day": {
      "description": "day label used in air date countdown timer",
      "message": "{day} D"
    },
    "cc_audio_overlay_subtitles_mode": {
      "description": "Available modes displayed on closed caption overlay",
      "message": "Mode Sous-Titres"
    },
    "live_on_hour": {
      "description": "day label used in air date countdown timer",
      "message": "{hour} HR"
    },
    "live_on_minute": {
      "description": "day label used in air date countdown timer",
      "message": "{min} MIN"
    },
    "screenHome_button_sign_in_watch": {
      "description": "Sign in to watch live button label.",
      "message": "Connectez-vous pour regarder"
    },
    "available_at": {
      "description": "Sign in to watch live button label.",
      "message": "Disponible au {time}"
    },
    "watch_for_free": {
      "description": "Sign in to watch live button label.",
      "message": "Regardez gratuit sur {date}."
    },
    "auth_refresh_welcome_message": {
      "description": "A message that let's the user know they've been signed in with the given email",
      "message": "Connecté en tant que {email}"
    },
    "auth_refresh_welcome_header": {
      "description": "A header for the message that let's the user know they've been signed in with the given email",
      "message": "Bienvenue!"
    },
    "resolution_full_hd": {
      "description": "Title of the 1080p resolution label in the infopanel",
      "message": "PLEINE HD"
    },
    "available_at_toast_heading": {
      "description": "Toast message heading that is displayed when we click on a available at button",
      "message": "Contenu disponible sur {time}"
    },
    "available_at_toast_subheading": {
      "description": "Toast message subheading that is displayed when we click on a available at button",
      "message": "Nous savons que vous êtes excité. Nous aussi!"
    },
    "sign_in_error_screen_heading": {
      "description": "Sign in error screen heading default error",
      "message": "Nous ne pouvons pas vous connecter maintenant"
    },
    "sign_in_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Vous pouvez toujours regarder vos films et série de TV préférés en tant qu'invité."
    },
    "sign_in_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Vous pouvez toujours regarder vos films et série de TV préférés en tant qu'invité, y compris {major_event_name}!"
    },
    "sign_up_error_screen_heading": {
      "description": "Sign in error screen heading default error",
      "message": "Nous ne pouvons pas créer votre compte pour le moment"
    },
    "sign_up_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Vous pouvez toujours regarder vos films et série de TV préférés en tant qu'invité.\nNous vous enverrons un e-mail pour réessayer plus tard."
    },
    "sign_up_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "Vous pouvez toujours regarder vos films et série de TV préférés en tant qu'invité, y compris {major_event_name}!\nNous vous enverrons un e-mail pour réessayer plus tard."
    },
    "mylist_disabled_message": {
      "description": "My List disabled toast message",
      "message": "Mes affaires est actuellement indisponibles."
    },
    "rating_disabled_message": {
      "description": "Like/Dislike disabled toast message",
      "message": "Classement est actuellement indisponible."
    },
    "continue_watching_disabled_message": {
      "description": "Continue watching disabled toast message",
      "message": "Continuer à regarder est actuellement indisponible."
    },
    "disaster_mode_toast_heading": {
      "description": "Heading of the toast that is shown on disaster mode UI.",
      "message": "Nous avons des problèmes de connexion"
    },
    "disaster_mode_toast_subheading": {
      "description": "Subheading of the toast that is shown on disaster mode UI.",
      "message": "Vous pouvez toujours regarder {major_event_name}!"
    },
    "rating": {
      "description": "Like/Dislike feature",
      "message": "Classement"
    },
    "delayed_registration_message": {
      "description": "Message displayed when user tries to register and the registration is delayed",
      "message": "Nous essaierons de créer votre compte dans les prochaines 24 heures et en cas de succès, nous vous enverrons un e-mail pour terminer la configuration de votre compte."
    },
    "game": {
      "description": "Fallback string to be used when major event name is not available in remote config",
      "message": "jeu"
    },
    "havent_received_email": {
      "description": "Message displayed in sign in screen during major event day",
      "message": "Vous n'avez pas reçu d'e-mail? Vous pouvez toujours continuer en tant qu'invité."
    }
  }
End Function


Function getTranslation_en_GB()
  return {
    "screenSettings_about_description": {
      "description": "The description on the about screen",
      "message": "Tubi is the leading free, premium, video streaming app. We have a large and diverse library of content with many thousands of titles and 3x fewer adverts than other TV services."
    },
    "screenSettings_about_description2": {
      "description": "The 2nd description on the about screen",
      "message": "Visit {help_url}\n\nEmail our Support team at support@tubi.tv\n\nReach us on Facebook, Instagram, X, and on our website at:\n{support_url}\n\nVersion {version}\nShort Device ID: {id} (press OK to see full Device ID)\n\n© {year} Tubi, Inc. all rights reserved."
    },
    "screenSettings_parentalControls_instructions": {
      "description": "Description of the parental controls screen",
      "message": "Please select the appropriate viewing age for Tubi TV. Your selection will determine which film and show ratings you can view in the app. If this selection is changed, you will be required to enter your account password."
    },
    "screenSettings_autoplayTimer_instructions_guest_users": {
      "description": "Description of the autoplay timer user choice screen for guest users",
      "message": "Content is set up to automatically play another video when what you're watching is about to end. You need to sign in to use this feature."
    },
    "screenSettings_menu_PrivacyCenter": {
      "description": "A menu Item for the Settings screen",
      "message": "Privacy Centre"
    },
    "screenSettings_error_signInAutoplayPreview_description": {
      "description": "Description of message to let users know that they must be signed in to change the AutoplayPreview choice.",
      "message": "You must be signed in to change Auto-play Preview preferences."
    },
    "short_version_date_format_6": {
      "description": "Shortened version of date format for the month of June",
      "message": "June {day}, {year}"
    },
    "short_version_date_format_7": {
      "description": "Shortened version of date format for the month of July",
      "message": "July {day}, {year}"
    },
    "short_version_date_format_9": {
      "description": "Shortened version of date format for the month of September",
      "message": "Sept {day}, {year}"
    },
    "screenMyStuff_signedOutUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Find your favourites fast, pick up where you left off–all in one place."
    },
    "screenAgeVerification_network_issue": {
      "description": "An error message shown to users when they submit their birthdate, but there is an unexpected server or network error",
      "message": "Could not successfully send your date of birth to our servers."
    },
    "metadata_myStuff_empty_myList_description": {
      "description": "For an empty MyList container, this is the description/subtitle that is display in the empty container",
      "message": "Use the bookmark button to save favourite series and movies. They’ll show up here."
    },
    "registration_signIn_recommended": {
      "description": "text appended to recommended row label to subtly remind users that they are signed out so that they understand that they need to sign-in to use Tubi at its fullest",
      "message": "Sign in for a more personalised experience"
    },
    "videoPlayer_adLoadingMessage": {
      "description": "Message to indicate ads will play before playing video content",
      "message": "Your programme will begin after these messages..."
    },
    "videoPlayer_adHeadsUp": {
      "description": "Warning when the ad break is about to begin. (seconds is abbreviated for brevity and so singular and plural forms are irrelevant)",
      "message": "Adverts start in {seconds} s"
    },
    "channel_webDescription": {
      "description": "This is the description of the app. This is not located in the app. It is displayed to the user in the Roku Web Channel Store",
      "message": "Watch thousands of hit movies and TV series for free. Tubi is 100% legal unlimited streaming, with no credit cards and no subscription required. Choose what you want to watch, when you want to watch it, with fewer adverts than other TV services. Tubi is the largest free streaming service featuring award-winning films and TV series. There is something for everybody; from comedy to drama, kids to classics, and niche favourites such as Korean dramas, anime, and British series. Download now and start streaming entertainment for free, today!",
      "note": "This translation is used for channelStore, please double check that it is not needed before deleting"
    },
    "dialog_whoops_title": {
      "description": "A general whoops title for an dialog window",
      "message": "Oops!"
    },
    "goBack_videoPlayer_ad": {
      "description": "Navigational instructions to users when pause Ad is displayed on video screen",
      "message": "Press any button to close the advert"
    },
    "sign_in_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favourite movies and TV shows as a guest."
    },
    "sign_in_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favourite movies and TV shows as a guest, including {major_event_name}!"
    },
    "sign_up_error_screen__default_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favourite movies and TV shows as a guest.\nWe'll send you an email to try again later."
    },
    "sign_up_error_screen__purple_carpet_day_subheading": {
      "description": "Sign in error screen heading default error",
      "message": "You can still watch your favourite movies and TV shows as a guest, including {major_event_name}!\nWe'll send you an email to try again later."
    }
  }
End Function
