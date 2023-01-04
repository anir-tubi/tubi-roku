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
  if sTranslatedString = "" AND locale <> defaultLocale
    '//If no translation was found, then use the default locale
    sTranslatedString = getTranslationBasedOnLocale(sID, defaultLocale)
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

  if locale = "en_us"
    translationSet = getTranslation_en_US()
  else if Left(locale, 2) = "es"
    'es_MX and es_ES
    translationSet = getTranslation_es_MX()
  else if locale = "en_gb"
  else if locale = "fr_ca"
  else if locale = "de_de"
  else if locale = "it_it"
  else if locale = "pt_br"
  end if

  return translationSet
End Function

'//::NOTE:: Below this line are functions to get associative arrays for various locales. The associative arrays within the functions
'//are generated by a script that downloads the translations from https://crowdin.com/project/tubiapps.
'//If you wish to add/delete/modify a static string, do NOT edit the associative arrays below. Instead modify the
'//en_US.json file located in the locale folder and upload the json file to the crowdin to be translated.

' Return the associative array associated with the enUS locale
Function getTranslation_en_US()
  return {
    "menu_signIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into app.",
      "message": "Sign In"
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
    "menu_recommended": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Recommended"
    },
    "menu_epg_all":{
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the all EPG screen.",
      "message": "All"
    },
    "menu_epg_sports":{
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the Sports EPG screen.",
      "message": "Sports"
    },
    "menu_epg_news":{
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the News EPG screen.",
      "message": "News"
    },
    "menu_epg_entertainment":{
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the Entertainment EPG screen.",
      "message": "Entertainment"
    },
    "epg_starts_at": {
      "description": "Program time Title when user selects a future program on EPG.",
      "message": "Starts at"
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
    "menu_movies_and_tv": {
      "description": "Menu option on the app's navigation, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Movies & TV"
    },
    "menu_mylist": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the mylist/queue screen.",
      "message": "My List"
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
    "dialog_channelsDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav channels menu item but the item has been disabled",
      "message": "Channels Disabled"
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
      "message": "TV Disabled"
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
      "message": "Were you born in {birthYear}"
    },
    "dialog_confirmCorrectAge_title_age": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct age",
      "message": "Are you {age} years old"
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
    "screenSearch_defaultSearch": {
      "description": "Directions on the search page",
      "message": "Search for movies, TV shows, and people"
    },
    "screenSearch_defaultLinearSearch": {
      "description": "Directions on the search page",
      "message": "Search for movies, TV shows, Live TV, and people"
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
      "message": " You're signed in as {name}"
    },
    "screenSettings_signOut_description2": {
      "description": "More details on the SignIn page when user is signed in",
      "message": " Email: {email}"
    },
    "screenSettings_fullDeviceID": {
      "description": "Text proceeding the full device ID",
      "message": " Full Device ID"
    },
    "screenSettings_about_title": {
      "description": "The title of the about screen",
      "message": " About Tubi"
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
      "message": "Visit {help_url} \n \n Email our Support team at support@tubi.tv \n \n Reach us on Facebook, Instagram, Twitter, and on our website at: \n {support_url} \n \n Version {version} \n Short Device ID: {id} (press OK to see full Device ID) \n \n © {year} Tubi, Inc. all rights reserved."
    },
    "screenSettings_menu_parentalControls": {
      "description": "The label for the parental controls",
      "message": "Parental Controls"
    },
    "screenSettings_menu_autoplayPreview": {
      "description": "The label for the autoplay preview",
      "message": "Autoplay Previews"
    },
    "screenSettings_parentalControls_group0": {
      "description": "Group 0 of the parental controls",
      "message": "Little Kids",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group1": {
      "description": "Group 1 of the parental controls",
      "message": "Older Kids",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group2": {
      "description": "Group 2 of the parental controls",
      "message": "Teens",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group3": {
      "description": "Group 3 of the parental controls",
      "message": "Adults",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_instructions": {
      "description": "Description of the parental controls screen",
      "message": "Please select the appropriate viewing age for Tubi TV. Your selection will determine which movie and show ratings you can view in the app. If this selection is changed, you will be required to enter your account password."
    },
    "screenSettings_autoplayPreview_instructions": {
      "description": "Description of the autoplay preview user choice screen",
      "message": "You can turn the autoplay functionality on or off, which allows you to preview the video while browsing."
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
      "message": "Enter Password to update"
    },
    "screenSettings_parentalPassword_subtitle": {
      "description": "Directions 2nd line for signed out users who attempt to change the parental controls",
      "message": "parental controls"
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
    "screenChannels_error_retrieve_message": {
      "description": "Onscreen message to indicate channel content could not be gathered",
      "message": "Could not retrieve channels content."
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
    "screenTournament_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate Tournament content could not be loaded",
      "message": "Unable to load the Tubi Tournament screen."
    },
    "epg_minutes_left": {
      "description": "Indicate the number of minutes left. Use an abbreviation for minutes to save space and so we don't have to worry about plural and singular forms of the word minutes.",
      "message": "{minutes}m left"
    },
    "today":{
      "description": "Today",
      "message": "TODAY"
    },
    "tomorrow":{
      "description": "Tomorrow",
      "message": "TOMORROW"
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
    "screenMyStuff_title": {
      "description": "The title of the MyStuff Screen which contains the continueWatching and queue/myList channels.",
      "message": "My Stuff"
    },
    "screenMyStuff_signedOutUITitle": {
      "description": "The title of the MyStuff Screen for the guest user.",
      "message": "Make Tubi Yours, For Free"
    },
    "screenMyStuff_signedOutUISubtitle": {
      "description": "The subtitle of the MyStuff Screen for the guest user.",
      "message": "Save all your favorites, pick up where you left off - all in one place"
    },
    "screenMyStuff_signedOutUIBlurb": {
      "description": "The blurb of the MyStuff Screen for the guest user.",
      "message": "No credit card required • Free forever"
    },
    "screenDetails_button_trailer": {
      "description": "Label of button to allow users to watch a preview of the current video title",
      "message": "Watch Trailer"
    },
    "screenDetails_button_episodes": {
      "description": "Label of button to allow users to display the list of episodes/seasons of the current video title",
      "message": "Episodes list"
    },
    "screenDetails_relatedTitles": {
      "description": "Label of button to allow users to view other video titles related to the current video title",
      "message": "You Might Also Like"
    },
    "screenDetails_button_play": {
      "description": "Label of button to allow users to play the current video title",
      "message": "Play"
    },
    "screenDetails_button_like_instructions": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": " - Remove Rating"
    },
    "screenDetails_button_like": {
      "description": "Label of button to allow users to like the current video title",
      "message": "Like"
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
    "screenDetails_button_likeDislike": {
      "description": "Label of unfocused button to allow users to like or dislike the current video title",
      "message": "Like or Dislike"
    },
    "screenDetails_button_see_all_games": {
      "description": "Label of button to allow users to a new page where they can see all the games related to the current sports title",
      "message": "See All Matches"
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
    "screenDetails_button_resume": {
      "description": "Label of button to allow users to resume the current video title",
      "message": "Resume"
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
      "message": "My List"
    },
    "metadata_myStuff_empty_myList_description": {
      "description": "For an empty MyList container, this is the description/subtitle that is display in the empty container",
      "message": "Movies and TV shows added\nto your list will appear here"
    },
    "metadata_myStuff_empty_continueWatching_title": {
      "description": "For an empty continueWatching container, this is the title that is display in the empty container",
      "message": "Continue Watching"
    },
    "metadata_myStuff_empty_continueWatching_description": {
      "description": "For an empty continueWatching container, this is the description/subtitle that is display in the empty container",
      "message": "Movies and TV shows you haven’t finished\nwatching will appear here"
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
    "linearVideoPlayer_channelGuideTitle": {
      "description": "The title displayed above a list of live TV channels",
      "message": "Channel Guide"
    },
    "goBack_categories": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK FOR CATEGORIES"
    },
    "goBack_channels": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK FOR CHANNELS"
    },
    "goBack_default": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK TO GO BACK"
    },
    "goBack_videoPlayer_upNext": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "BACK TO DISMISS"
    },
    "goBack_videoPlayer_controls": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK TO HIDE"
    },
    "goBack_menu": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK FOR MENU"
    },
    "goBack_home": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK FOR HOME"
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
      "message": "*We use this information to confirm that you're meeting the age requirements set out in our Terms of Use and to personalize you experience. Read Terms of Use at: www.tubitv.com/terms Questions? Let us know at: support@tubi.tv"
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
    "enter_password_dialog_description": {
      "description": "enter password dialog description",
      "message": "Please enter your Tubi password for the account"
    },
    "re-enter_password_button": {
      "description": "re-enter password button text on modal",
      "message": "Re-enter Password"
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
    "goBack_signIn": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESS BACK FOR SIGNIN"
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
    "new_password_text": {
      "description": "new password text",
      "message": "To setup a new password,"
    },
    "new_password_link": {
      "description": "forgot password link",
      "message": "visit tubi.tv/password"
    },
    "signIn_screen_subheading": {
      "description": "Sub title on the signIn screen",
      "message": "Your email is already linked to an existing Tubi account"
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
    "registration_signIn_to_play_hint": {
      "description": "hint text next to the Sign In to Play button when a non registered user focuses on details screen for sportsEvent",
      "message": "Sign in to watch free. No subscription or credit card required."
    },
    "text_new":{
      "description": "simple text to use anywhere to indicate item is new",
      "message" : "NEW"
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
    "onBoarding_welcomeScreen_heading": {
      "description": "Label displayed on onBoarding welcome screen",
      "message": "Welcome to unlimited movies,\nTV shows and Live TV"
    },
    "onBoarding_welcomeScreen_description": {
      "description": "Description displayed on onBoarding welcome screen",
      "message": "For all your Entertainment, News, and Sports needs.\nAlways free. No subscription. 100% legal."
    },
    "onBoarding_freeForeverScreen_heading": {
      "description": "Label displayed on onBoarding Free Forever screen",
      "message": "FREE Forever with Fewer\nAds than Cable"
    },
    "onBoarding_freeForeverScreen_description": {
      "description": "Description displayed on onBoarding Free Forever screen",
      "message": "3x more content and 3x less ads. None of the costs. $0/month.\nNo paywalls, no bundles."
    },
    "onBoarding_availableDeviceScreen_heading": {
      "description": "Label displayed on onBoarding Available Device screen",
      "message": "Available on all\nyour devices"
    },
    "onBoarding_availableDeviceScreen_description": {
      "description": "Description displayed on onBoarding Available Device screen",
      "message": "Watch on your phone, television, tablet\nor computer."
    },
    "onBoarding_landingScreen_heading": {
      "description": "Label displayed on onBoarding Landing screen",
      "message": "Tubi is better when\nyou sign up"
    },
    "onBoarding_landingScreen_description": {
      "description": "Description displayed on onBoarding Landing screen",
      "message": "No credit card required • Free Forever"
    },
    "onBoarding_landingScreen_addListLabel": {
      "description": "Label displayed on onBoarding Landing screen informing add to your list",
      "message": "Add to Your List"
    },
    "onBoarding_landingScreen_addListBody": {
      "description": "Body displayed on onBoarding Landing screen informing save now and watch later",
      "message": "Save Now, Watch Later"
    },
    "onBoarding_landingScreen_saveProgressLabel": {
      "description": "Label displayed on onBoarding Landing screen informing save your progress",
      "message": "Save Your Progress"
    },
    "onBoarding_landingScreen_saveProgressBody": {
      "description": "Body displayed on onBoarding Landing screen informing pickup where you left off",
      "message": "Pickup where you left off"
    },
    "onBoarding_landingScreen_madeForYouLabel": {
      "description": "Label displayed on onBoarding Landing screen informing made for you",
      "message": "Made For You"
    },
    "onBoarding_landingScreen_madeForYouBody": {
      "description": "Body displayed on onBoarding Landing screen informing better recommendations",
      "message": "Unlock better recommendations"
    },
    "dialog_got_it": {
      "description": "button display on fifa intro modal",
      "message": "Got it"
    },
    "dialog_explore_fifa": {
      "description": "button display on fifa intro modal",
      "message": "Explore FIFA 2022"
    },
    "explore_fifa_description": {
      "description": "description displayed on fifa intro modal",
      "message": "Tubi has full replays of all 64 World Cup matches available for free. Sign up to stream every match on your favorite device. No subscription or credit card required."
    },
    "replay": {
      "description": "This label used for badge to indicate the content availability",
      "message": "Replay"
    },
    "show_all_games_gameInfo": {
      "description": "Text displayed on Fifa World Cup 2022 infopanel second line when Show all games is focused",
      "message": "Nov 20, 2022 - Dec 18, 2022"
    },
    "show_all_games_description": {
      "description": "Description displayed on Fifa World Cup 2022 infopanel when Show all games is focused",
      "message": "Taking place every four years, the FIFA Men's World Cup sees 32 nations compete against each other for the prize."
    },
    "info_panel_reminder_is_set": {
      "description": "Hint in the content metadata area informing the user that the reminder is set for this content",
      "message": "Reminder set"
    }
  }
End Function


' ::NOTE:: do not directly modify this function. Modify the strings found in Crowdin and then run the gulp download command described in the repo's readMe file.
' Return the associative array associated with the esMX locale
Function getTranslation_es_MX()
  return {
    "menu_signIn": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to sign into app.",
      "message": "Iniciar Sesión"
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
    "menu_recommended": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Recomendado"
    },
    "menu_epg_all": {
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the all EPG screen.",
      "message": "Todo"
    },
    "menu_epg_sports": {
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the Sports EPG screen.",
      "message": "Deportes"
    },
    "menu_epg_news": {
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the News EPG screen.",
      "message": "Noticias"
    },
    "menu_epg_entertainment": {
      "description": "Menu option on the app's top nav, (length of text should not be too long). Allows the user to display the Entertainment EPG screen.",
      "message": "Entretenimiento"
    },
    "epg_starts_at": {
      "description": "Program time Title when user selects a future program on EPG.",
      "message": "Comienza en"
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
    "menu_movies_and_tv": {
      "description": "Menu option on the app's navigation, (length of text should not be too long). Allows the user to display the home screen.",
      "message": "Películas & Series"
    },
    "menu_mylist": {
      "description": "Menu option on the app's side nav, (length of text should not be too long). Allows the user to display the mylist/queue screen.",
      "message": "Mi Lista"
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
      "message": "Mostrar Todos Los Partidos"
    },
    "loadingIndicator": {
      "description": "When something is loading, this text appears so the user knows something is loading.",
      "message": "Cargando..."
    },
    "dialog_errorPrefix": {
      "description": "When the user is displayed an error, this is the prefix of the error ID that is presented to them: i.e. Error 101",
      "message": "Error: "
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
    "dialog_button_ok": {
      "description": "Label of the dialog button to confirm the action the dialog is asking",
      "message": "OK"
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
    "dialog_channelsDisabled_title": {
      "description": "Title of a Dialog Window that is shown when the user clicked the sidenav channels menu item but the item has been disabled",
      "message": "Canales desactivado"
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
      "message": "Series desactivado"
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
      "message": "Naciste en {birthYear}"
    },
    "dialog_confirmCorrectAge_title_age": {
      "description": "title of a dialog window when the user is attempting to set their age but are less than 13 years old so we want to confirm they set the correct age",
      "message": "Tienes {age} años"
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
    "screenSearch_defaultSearch": {
      "description": "Directions on the search page",
      "message": "Busca películas, series y personas"
    },
    "screenSearch_defaultLinearSearch": {
      "description": "Directions on the search page",
      "message": "Busca películas, series, TV en vivo, y personas"
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
    "screenInitialContent_title": {
      "description": "Title of the initial content screen",
      "message": "¿Qué quieres ver?"
    },
    "screenInitialContent_subtitle_signedOut": {
      "description": "subTitle of the initial content screen when user is signed out",
      "message": "¡Comienza a ver Gratis! ¡Sin iniciar sesión!"
    },
    "screenInitialContent_subtitle_signedIn": {
      "description": "subTitle of the initial content screen when user is signed in",
      "message": "Elige algo para ver"
    },
    "screenInitialContent_show_everything_title": {
      "description": "title for button a user clicks to skip selecting a content experience",
      "message": "Muestrame Todo"
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
      "message": " Has iniciado sesión como {name}"
    },
    "screenSettings_signOut_description2": {
      "description": "More details on the SignIn page when user is signed in",
      "message": " Correo electrónico: {email}"
    },
    "screenSettings_fullDeviceID": {
      "description": "Text proceeding the full device ID",
      "message": " ID de dispositivo completo"
    },
    "screenSettings_about_title": {
      "description": "The title of the about screen",
      "message": " Acerca de Tubi"
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
    "screenSettings_parentalControls_group0": {
      "description": "Group 0 of the parental controls",
      "message": "Niños pequeños",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group1": {
      "description": "Group 1 of the parental controls",
      "message": "Niños mayores",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group2": {
      "description": "Group 2 of the parental controls",
      "message": "Adolescentes",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_group3": {
      "description": "Group 3 of the parental controls",
      "message": "Adultos",
      "note": "This translation is used as screenSettings_parentalControls_group[variable], please double check that it is not needed before deleting"
    },
    "screenSettings_parentalControls_instructions": {
      "description": "Description of the parental controls screen",
      "message": "Elige la edad de visualización adecuada para Tubi. Tu selección determinará qué clasificaciones de películas y programas puedes ver en la aplicación. Si se modifica esta selección, pediremos que ingreses la contraseña de tu cuenta."
    },
    "screenSettings_autoplayPreview_instructions": {
      "description": "Description of the autoplay preview user choice screen",
      "message": "Puedes activar o desactivar la función de reproducción automática, que te permite ver el vídeo mientras navegas."
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
      "message": "Ingresa tu contraseña"
    },
    "screenSettings_parentalPassword_subtitle": {
      "description": "Directions 2nd line for signed out users who attempt to change the parental controls",
      "message": "controles parentales"
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
    "screenChannels_error_retrieve_message": {
      "description": "Onscreen message to indicate channel content could not be gathered",
      "message": "No se pudo recuperar el contenido de los canales."
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
    "screenTournament_error_fetchScreenContent_description": {
      "description": "Onscreen message to indicate Tournament content could not be loaded",
      "message": "No se puede cargar la pantalla del Torneo en Tubi."
    },
    "epg_minutes_left": {
      "description": "Indicate the number of minutes left. Use an abbreviation for minutes to save space and so we don't have to worry about plural and singular forms of the word minutes.",
      "message": "quedan {minutes} m"
    },
    "today": {
      "description": "Today",
      "message": "HOY"
    },
    "tomorrow": {
      "description": "Tomorrow",
      "message": "MAÑANA"
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
    "screenDetails_button_trailer": {
      "description": "Label of button to allow users to watch a preview of the current video title",
      "message": "Ver Tráiler"
    },
    "screenDetails_button_episodes": {
      "description": "Label of button to allow users to display the list of episodes/seasons of the current video title",
      "message": "Lista de Capítulos"
    },
    "screenDetails_relatedTitles": {
      "description": "Label of button to allow users to view other video titles related to the current video title",
      "message": "Puede que también te guste"
    },
    "screenDetails_button_play": {
      "description": "Label of button to allow users to play the current video title",
      "message": "Ver"
    },
    "screenDetails_button_like_instructions": {
      "description": "text to be place AFTER the text that indicates that the user 'liked' or 'disliked' the current video title. This appears once the button gains focus",
      "message": " - Borrar Calificación"
    },
    "screenDetails_button_like": {
      "description": "Label of button to allow users to like the current video title",
      "message": "Me Gusta"
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
    "screenDetails_button_likeDislike": {
      "description": "Label of unfocused button to allow users to like or dislike the current video title",
      "message": "Me Gusta o No Me Gusta"
    },
    "screenDetails_button_see_all_games": {
      "description": "Label of button to allow users to a new page where they can see all the games related to the current sports title",
      "message": "Ver Todos Los Partidos"
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
    "screenDetails_button_resume": {
      "description": "Label of button to allow users to resume the current video title",
      "message": "Reanudar"
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
    "metadata_expiresIn_plural": {
      "description": "label to indicate how long the user have to watch a video",
      "message": "Expira en {days} días"
    },
    "metadata_expiresIn_singular": {
      "description": "label to indicate the user has exactly 1 day to watch a video",
      "message": "Expira en 1 día"
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
      "message": "Sin suscripción • Sin tarjeta de crédito • Gratis siempre"
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
      "message": "{seasons} Temporadas"
    },
    "metadata_seasons_singular": {
      "description": "Label for when the current TV title has exactly one season",
      "message": "1 Temporada"
    },
    "metadata_series": {
      "description": "Label to indicate a title is a TV series",
      "message": "Series"
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
    "linearVideoPlayer_channelGuideTitle": {
      "description": "The title displayed above a list of live TV channels",
      "message": "Guía de Canales"
    },
    "goBack_categories": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA VOLVER A LAS CATEGORÍAS"
    },
    "goBack_channels": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA VOLVER A LOS CANALES"
    },
    "goBack_default": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA REGRESAR"
    },
    "goBack_videoPlayer_upNext": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "ATRÁS PARA DESCARTAR"
    },
    "goBack_videoPlayer_controls": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA ESCONDER"
    },
    "goBack_menu": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA VOLVER AL MENÚ"
    },
    "goBack_home": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA VOLVER A INICIO"
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
      "message": "*Usamos esta información para confirmar si satisfaces los requerimientos de edad presentados en nuestros Términos de uso y para personalizar tu experiencia. Lee los Términos de uso en: www.tubitv.com/terms ¿Preguntas? Haznos saber a: support@tubi.tv"
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
    "enter_password_dialog_description": {
      "description": "enter password dialog description",
      "message": "Por favor, ingresa la contraseña para tu cuenta de Tubi"
    },
    "re-enter_password_button": {
      "description": "re-enter password button text on modal",
      "message": "Ingresa tu contraseña"
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
    "goBack_signIn": {
      "description": "Navigational instructions to users on what the back button does on the current page",
      "message": "PRESIONA ATRÁS PARA VOLVER A INICIAR SESIÓN"
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
    "new_password_text": {
      "description": "new password text",
      "message": "Para establecer una contraseña nueva,"
    },
    "new_password_link": {
      "description": "forgot password link",
      "message": "visita tubi.tv/password"
    },
    "signIn_screen_subheading": {
      "description": "Sub title on the signIn screen",
      "message": "Tu correo electrónico ya está vinculado a una cuenta de Tubi"
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
      "message": "Inicia sesión para Ver"
    },
    "registration_signIn_to_play_hint": {
      "description": "hint text next to the Sign In to Play button when a non registered user focuses on details screen for sportsEvent",
      "message": "Inicia sesión para ver gratis. No se requiere tarjeta de crédito."
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
    "onBoarding_welcomeScreen_heading": {
      "description": "Label displayed on onBoarding welcome screen",
      "message": "Bienvenido a películas ilimitadas,\nSeries y TV en Vivo"
    },
    "onBoarding_welcomeScreen_description": {
      "description": "Description displayed on onBoarding welcome screen",
      "message": "Para todas tus necesidades de entretenimiento, Noticias y Deportes.\nSiempre gratis. Sin suscripción. 100% legal."
    },
    "onBoarding_freeForeverScreen_heading": {
      "description": "Label displayed on onBoarding Free Forever screen",
      "message": "Gratis Siempre con Menos\nAnuncios que el Cable"
    },
    "onBoarding_freeForeverScreen_description": {
      "description": "Description displayed on onBoarding Free Forever screen",
      "message": "3 veces más contenido y 3 veces menos anuncios. Sin costos. $0/mes.\nSin muros de pago, sin paquetes."
    },
    "onBoarding_availableDeviceScreen_heading": {
      "description": "Label displayed on onBoarding Available Device screen",
      "message": "Disponible en todos\ntus dispositivos"
    },
    "onBoarding_availableDeviceScreen_description": {
      "description": "Description displayed on onBoarding Available Device screen",
      "message": "Ver en tu teléfono, televisión, tableta\no computadora."
    },
    "onBoarding_landingScreen_heading": {
      "description": "Label displayed on onBoarding Landing screen",
      "message": "Tubi es mejor cuando\nte inscribes"
    },
    "onBoarding_landingScreen_description": {
      "description": "Description displayed on onBoarding Landing screen",
      "message": "Tarjeta de Crédito No Requerida • Gratis Siempre"
    },
    "onBoarding_landingScreen_addListLabel": {
      "description": "Label displayed on onBoarding Landing screen informing add to your list",
      "message": "Agregar a Mi Lista"
    },
    "onBoarding_landingScreen_addListBody": {
      "description": "Body displayed on onBoarding Landing screen informing save now and watch later",
      "message": "Guardar Ahora, Ver Más Tarde"
    },
    "onBoarding_landingScreen_saveProgressLabel": {
      "description": "Label displayed on onBoarding Landing screen informing save your progress",
      "message": "Guarda tu progreso"
    },
    "onBoarding_landingScreen_saveProgressBody": {
      "description": "Body displayed on onBoarding Landing screen informing pickup where you left off",
      "message": "Continúa donde dejaste de ver"
    },
    "onBoarding_landingScreen_madeForYouLabel": {
      "description": "Label displayed on onBoarding Landing screen informing made for you",
      "message": "Hecho para ti"
    },
    "onBoarding_landingScreen_madeForYouBody": {
      "description": "Body displayed on onBoarding Landing screen informing better recommendations",
      "message": "Desbloquea mejores recomendaciones"
    },
    "dialog_got_it": {
      "description": "button display on fifa intro modal",
      "message": "Lo entiendo"
    },
    "dialog_explore_fifa": {
      "description": "button display on fifa intro modal",
      "message": "Descubre FIFA 2022"
    },
    "explore_fifa_description": {
      "description": "description displayed on fifa intro modal",
      "message": "Llamando a todos los aficionados del fútbol! Ver el Mundial de la FIFA 2022 gratis en Tubi. Crea una cuenta para acceder a todos los partidos. No se requiere tarjeta de crédito. Sin suscripciones."
    },
    "replay": {
      "description": "This label used for badge to indicate the content availability",
      "message": "Repetición"
    },
    "show_all_games_gameInfo": {
      "description": "Text displayed on Fifa World Cup 2022 infopanel second line when Show all games is focused",
      "message": "20 de nov, de 2022 - 18 de dic, de 2022"
    },
    "show_all_games_description": {
      "description": "Description displayed on Fifa World Cup 2022 infopanel when Show all games is focused",
      "message": "La Copa Mundial de la FIFA, que se celebra cada cuatro años, cuenta con la participación de 32 naciones que compiten por el título."
    },
    "info_panel_reminder_is_set": {
      "description": "Hint in the content metadata area informing the user that the reminder is set for this content",
      "message": "Recordatorio programado"
    }
  }
End Function
