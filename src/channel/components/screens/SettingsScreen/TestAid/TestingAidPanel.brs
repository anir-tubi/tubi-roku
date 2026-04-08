Function init()
  m.constants = getConstantsFromGlobal()
  experimentsInfo = getExperimentsInfoFromGlobal()
  m.experiments = TubiExperiments(experimentsInfo)
  m.top.selectButtonMovesPanelForward = true
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("isLoading", "onIsLoading")

  m.ContentGroup = m.top.findNode("ContentGroup")
  m.infoArea = m.top.findNode("infoArea")
  m.Menu = m.top.findNode("testingAidMenu")
  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focusedColor
    m.focusedColor = theme.focusedColor
  end if
  ' Adding a transparent 1px image since leaving it empty causes roku to use it's default.
  ' We do not want to show unfocused background as per designs.
  m.Menu.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  title = m.top.findNode("title")
  title.text = "Testing Aid Config for: " + m.constants.settings.mode


  m.Menu.observeFieldScoped("itemSelected", "onTestingAidPanelItemSelected")
  m.Menu.observeFieldScoped("itemFocused", "onItemFocused")

  m.Spinner = m.top.findNode("Spinner")

  m.top.observeFieldScoped("statsigExperiments", "onStatsigExperimentsChanged")


  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.infoArea, typographyConstants.ids.bodyMedium)


End Function

Function onComponentFocus()
  if m.top.hasFocus() = true
    m.Menu.setFocus(true)
  end if
End Function


Function onItemFocused(msg)
  itemSelected = msg.GetData()

  item = m.Menu.Content.getChild(itemSelected)

  ' Hide features panel when navigating away from it
  if item.id <> "features" AND m.featuresPanel <> invalid AND m.featuresPanel.visible = true
    m.featuresPanel.visible = false
  end if

  ' Hide branch builds panel when navigating away from it
  if item.id <> "branchBuilds" AND m.branchBuildsPanel <> invalid AND m.branchBuildsPanel.visible = true
    m.branchBuildsPanel.visible = false
  end if

  ' Hide Ads list when navigating away from it
  if item.id <> "rokuAds" AND m.rokuAdsList <> invalid AND m.rokuAdsList.visible = true
    m.rokuAdsList.visible = false
  end if

  if item.id = "viewRegistry"
    m.infoArea.text = "Current Registry values are printed by each section. Press OK to see full registry."
  else if item.id = "clearRegistry"
    m.infoArea.text = "It will delete all the registry values and restart the app."
  else if item.id = "safeZone"
    m.infoArea.text = "It will overlay all the screens with safe zone guidelines."
  else if item.id = "overlay"
    m.infoArea.text = "It will overlay a Grid of 10 px over all of the screens. If you want better control, use devOverlay.brs"
  else if item.id = "addProxy"
    proxyInfo = "It will add/remove a proxy to the app and restart the app."

    if m.constants.settings.charlesProxyEnabled = true
      m.infoArea.text = proxyInfo + chr(10) + "Current Proxy: " + m.constants.settings.charlesProxyUrl
    else
      m.infoArea.text = proxyInfo + chr(10) + "Current Proxy: None"
    end if
  else if item.id = "mockServer"
    mockServerInfo = "Select a profile to enable mock server. Select Reset to disable. Requires app restart."

    registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
    currentProfile = registrySection.read("mockServerProfile")

    if currentProfile <> invalid AND currentProfile <> ""
      m.infoArea.text = mockServerInfo + chr(10) + "Status: Enabled" + chr(10) + "Phase: " + currentProfile
    else
      m.infoArea.text = mockServerInfo + chr(10) + "Status: Disabled"
    end if
  else if item.id = "changeCountry"
    m.infoArea.text = "Select the country. It will work for White listed IPs only. Contact CSS for whitelisting" + chr(10) + "Current Country: " + m.constants.deviceInfo.countryCode
  else if item.id = "changeLanguage"
    m.infoArea.text = "Select the language for testing." + chr(10) + "Current Locale: " + m.constants.deviceInfo.locale
  else if item.id = "playerStats"
    m.infoArea.text = "This toggles the display of player stats within the video player, helping QA and developers understand the current playback."
  else if item.id = "rokuAds"
    registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
    currentAdTypes = registrySection.read("mockServerAdTypes")
    rokuAdsInfo = "Toggle ad types to whitelist on the mock server. Selections are persisted across restarts."
    if currentAdTypes <> invalid AND currentAdTypes <> ""
      m.infoArea.text = rokuAdsInfo + chr(10) + "Active: " + currentAdTypes
    else
      m.infoArea.text = rokuAdsInfo + chr(10) + "Active: None"
    end if
  else if item.id = "branchBuilds"
    m.infoArea.text = "Select a remote component library from a feature branch. Changes require an app restart."
    if m.branchBuildsPanel = invalid
      showBranchBuildsPanel()
    else if m.branchBuildsPanel.visible = false
      m.branchBuildsPanel.visible = true
    end if
  else if item.id = "features"
    m.infoArea.text = "Override experiment variants for testing purposes. Select an experiment to view available variants. Changes require an app restart to take effect."
    if m.featuresPanel = invalid
      showFeaturesPanel()
    else if m.featuresPanel.visible = false
      m.featuresPanel.visible = true
    end if
  end if
  showCountryList(item.id = "changeCountry")
  showLanguageList(item.id = "changeLanguage")
  displayProxyKB(item.id = "addProxy")
  showMockServerProfileList(item.id = "mockServer")
  showRokuAdsList(item.id = "rokuAds")
End Function


Function displayProxyKB(show = false)
  if show = true

    if m.proxyinputDialog = invalid
      m.proxyinputDialog = createObject("roSGNode", "ProxyInput")
      m.proxyinputDialog.observeFieldScoped("proxyAddress", "addProxy")
      m.proxyinputDialog.observeFieldScoped("removeProxy", "removeProxy")
      m.top.appendChild(m.proxyinputDialog)
    end if

    m.proxyinputDialog.visible = true
  else
    if m.proxyinputDialog <> invalid
      m.proxyinputDialog.visible = false
    end if
  end if
End Function


Function removeProxy(msg)
  if msg.getData() = true

    registry = CreateObject("roRegistry")
    sections = registry.GetSectionList()

    for each sectionName in sections
      if sectionName = m.constants.registrySectionIDs.settingsOverride
        registry.Delete(sectionName)
        registry.Flush()
        exit for
      end if
    end for

    'after registry been deleted restart the app.
    m.top.appRestartRequested = true
  end if
End Function


Function addProxy(msg)
  ipAddress = msg.getData()

  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride) ' Create a registry section object
  registrySection.write("charlesProxyEnabled", "true")
  registrySection.write("charlesProxyUrl", "http://" + ipAddress + ":8888")
  registrySection.flush()

  'after registry been updated restart the app.
  m.top.appRestartRequested = true
End Function


' Creates a standard MarkupList for test aid selection panels
Function createTestAidList(listId as String, selectionCallback as String, numRows = 10 as Integer, translation = "[350,81]" as String) as Object
  list = createObject("roSGNode", "markupList")
  list.update({
    id: listId
    numRows: numRows.toStr()
    itemSize: "[450,72]"
    itemSpacing: "[0,8]"
    itemComponentName: "CheckButton"
    vertFocusAnimationStyle: "fixedFocus"
    translation: translation
  }, true)
  list.focusBitmapBlendColor = m.focusedColor
  m.top.appendChild(list)
  list.observeFieldScoped("itemSelected", selectionCallback)
  return list
End Function


Function showMockServerProfileList(show = false)
  if show = true
    if m.mockServerProfileList = invalid
      m.mockServerProfileList = createTestAidList("mockServerProfileList", "onMockServerProfileSelected", 6, "[350,185]")

      registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
      currentPhase = registrySection.read("mockServerProfile")
      profileListContent = createObject("roSGNode", "ContentNode")
      profileListContent.update({
        id: "mockServerProfileListContent"
        children: [
          { id: "resetMockServer", title: "Reset", checked: (currentPhase = invalid OR currentPhase = "") }
          { id: "30days", title: "Solar Bear - 30 Days", checked: (currentPhase = "30days") }
          { id: "5days", title: "Solar Bear - 5 Days", checked: (currentPhase = "5days") }
          { id: "2days", title: "Solar Bear - 2 Days", checked: (currentPhase = "2days") }
          { id: "today", title: "Solar Bear - Live (Today)", checked: (currentPhase = "today") }
          { id: "live", title: "Solar Bear - Live (2 min)", checked: (currentPhase = "live") }
          { id: "livenow", title: "Solar Bear - Live (Now)", checked: (currentPhase = "livenow") }
          { id: "postgame", title: "Solar Bear - Post Game", checked: (currentPhase = "postgame") }
          { id: "replay", title: "Solar Bear - Replay", checked: (currentPhase = "replay") }
        ]
      }, true)

      m.mockServerProfileList.content = profileListContent
    end if
    m.mockServerProfileList.visible = true
  else
    if m.mockServerProfileList <> invalid
      m.mockServerProfileList.visible = false
    end if
  end if
End Function


' Handles phase selection - selecting a phase enables mocking with the
' Roku profile and the chosen phase, selecting Reset clears only the phase.
' Uses syncDeviceWithMockServer to send a combined PUT with both phase and ad params.
Function onMockServerProfileSelected(msg) as Void
  itemSelected = msg.getData()
  if itemSelected = invalid OR itemSelected < 0 then return

  selectedItem = m.mockServerProfileList.content.getChild(itemSelected)
  if selectedItem = invalid then return

  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)

  if selectedItem.id = "resetMockServer"
    registrySection.delete("mockServerProfile")
  else
    registrySection.write("mockServerProfile", selectedItem.id)
  end if

  registrySection.flush()
  syncDeviceWithMockServer()
  m.top.appRestartRequested = true
End Function


' Syncs the device registration with the mock server using combined params from registry.
' Reads both mockServerProfile (phase) and mockServerAdTypes (ads) from registry
' and sends a single PUT with all params under one profile, or DELETE if both are cleared.
Function syncDeviceWithMockServer() as Void
  mockServerUrl = m.constants.settings.mockServerUrl
  if mockServerUrl = invalid OR mockServerUrl = "" then return

  deviceId = m.constants.deviceInfo.deviceId
  if deviceId = invalid OR deviceId = "" then return

  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
  phase = registrySection.read("mockServerProfile")
  adTypes = registrySection.read("mockServerAdTypes")

  hasPhase = isNonEmptyString(phase)
  hasAds = isNonEmptyString(adTypes)

  url = mockServerUrl + "api/devices/" + deviceId

  if hasPhase OR hasAds
    params = {}
    if hasPhase then params["phase"] = phase
    if hasAds then params["ads"] = adTypes

    body = {
      "profileName": "Roku"
      "params": params
    }

    reqInfo = {
      url: url
      requestType: m.constants.reqNames.registerMockDevice
      options: {
        "method": "PUT"
        "headers": { "Content-Type": "application/json" }
        "body": FormatJson(body)
      }
      silenceCallbackWarnings: true
    }
  else
    reqInfo = {
      url: url
      requestType: m.constants.reqNames.registerMockDevice
      options: {
        "method": "DELETE"
        "headers": { "Content-Type": "application/json" }
      }
      silenceCallbackWarnings: true
    }
  end if

  makeNetworkRequest(reqInfo)
End Function


' Shows the Ads multi-select list with ad type options.
' Restores previously persisted selections from registry.
Function showRokuAdsList(show = false)
  if show = true
    if m.rokuAdsList = invalid
      m.rokuAdsList = createTestAidList("rokuAdsList", "onRokuAdsItemSelected", 7, "[350,185]")

      registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
      savedAdTypes = registrySection.read("mockServerAdTypes")
      savedMap = {}
      if savedAdTypes <> invalid AND savedAdTypes <> ""
        parts = savedAdTypes.split(",")
        for each part in parts
          savedMap[part] = true
        end for
      end if

      rokuAdsContent = createObject("roSGNode", "ContentNode")
      rokuAdsContent.update({
        id: "rokuAdsContent"
        children: [
          { id: "hdc_carousel", title: "Carousel", checked: savedMap.doesExist("hdc_carousel") }
          { id: "hdc_spotlight", title: "Spotlight", checked: savedMap.doesExist("hdc_spotlight") }
          { id: "wrapper", title: "Wrapper", checked: savedMap.doesExist("wrapper") }
          { id: "sponsored_container", title: "SponsoredContainer", checked: savedMap.doesExist("sponsored_container") }
          { id: "sponsored_hero", title: "SponsoredHero", checked: savedMap.doesExist("sponsored_hero") }
          { id: "sponsored_hub", title: "SponsoredHub", checked: savedMap.doesExist("sponsored_hub") }
          { id: "restartApp", title: "Restart App", checked: false }
        ]
      }, true)

      m.rokuAdsList.content = rokuAdsContent
    end if
    m.rokuAdsList.visible = true
  else
    if m.rokuAdsList <> invalid
      m.rokuAdsList.visible = false
    end if
  end if
End Function


' Handles toggling ad types on/off in the Ads list
' Selecting whitelists the ad type, unselecting sends a DELETE to remove the device
Function onRokuAdsItemSelected(msg) as Void
  itemSelectedIndex = msg.getData()
  if itemSelectedIndex = invalid OR itemSelectedIndex < 0 then return

  selectedItem = m.rokuAdsList.content.getChild(itemSelectedIndex)
  if selectedItem = invalid then return

  if selectedItem.id = "restartApp"
    m.top.appRestartRequested = true
    return
  end if

  selectedItem.checked = not selectedItem.checked

  if selectedItem.checked = true
    whitelistRokuAdTypes()
  else
    hasChecked = false
    for i = 0 to m.rokuAdsList.content.getChildCount() - 1
      child = m.rokuAdsList.content.getChild(i)
      if child.checked = true
        hasChecked = true
        exit for
      end if
    end for

    if hasChecked = true
      whitelistRokuAdTypes()
    else
      unwhitelistRokuAds()
    end if
  end if
End Function


' Persists selected ad types to registry and syncs combined state with the mock server
Function whitelistRokuAdTypes() as Void
  selectedTypes = []
  for i = 0 to m.rokuAdsList.content.getChildCount() - 1
    child = m.rokuAdsList.content.getChild(i)
    if child.checked = true AND child.id <> "restartApp"
      selectedTypes.push(child.id)
    end if
  end for

  adsParam = selectedTypes.join(",")
  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
  registrySection.write("mockServerAdTypes", adsParam)
  registrySection.flush()

  syncDeviceWithMockServer()
End Function


' Clears persisted ad types from registry and syncs combined state with the mock server
Function unwhitelistRokuAds() as Void
  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
  registrySection.delete("mockServerAdTypes")
  registrySection.flush()

  syncDeviceWithMockServer()
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press = true
    if key = "left"
      if m.proxyinputDialog <> invalid AND m.proxyinputDialog.isInFocusChain() = true
        m.Menu.setfocus(true)
        handled = true
      else if m.mockServerProfileList <> invalid AND m.mockServerProfileList.isInFocusChain() = true
        m.Menu.setFocus(true)
        handled = true
      else if m.rokuAdsList <> invalid AND m.rokuAdsList.isInFocusChain() = true
        m.Menu.setFocus(true)
        handled = true
      else if m.countryListMenu <> invalid AND m.countryListMenu.isInFocusChain() = true
        m.Menu.setFocus(true)
        handled = true
      else if m.languageListMenu <> invalid AND m.languageListMenu.isInFocusChain() = true
        m.Menu.setFocus(true)
        handled = true
      else if m.branchBuildsPanel <> invalid AND m.branchBuildsPanel.isInFocusChain() = true
        m.Menu.setFocus(true)
        handled = true
      else if m.featuresPanel <> invalid AND m.featuresPanel.isInFocusChain() = true
        m.Menu.setFocus(true)
        handled = true
      end if
    else if key = "right"
      if m.Menu.hasFocus() = true
        if m.proxyinputDialog <> invalid AND m.proxyinputDialog.visible = true
          m.proxyinputDialog.setFocus(true)
          handled = true
        else if m.rokuAdsList <> invalid AND m.rokuAdsList.visible = true
          m.rokuAdsList.setFocus(true)
          handled = true
        else if m.mockServerProfileList <> invalid AND m.mockServerProfileList.visible = true
          m.mockServerProfileList.setFocus(true)
          handled = true
        else if m.countryListMenu <> invalid AND m.countryListMenu.visible = true
          m.countryListMenu.setFocus(true)
          handled = true
        else if m.languageListMenu <> invalid AND m.languageListMenu.visible = true
          m.languageListMenu.setFocus(true)
          handled = true
        else if m.branchBuildsPanel <> invalid
          isBranchBuildsVisible = m.branchBuildsPanel.visible
          isBranchBuildsItemFocused = isMenuItemFocused("branchBuilds")
          if isBranchBuildsVisible = true OR isBranchBuildsItemFocused = true
            if m.branchBuildsPanel.visible = false
              m.branchBuildsPanel.visible = true
            end if
            m.branchBuildsPanel.setFocus(true)
            branchBuildsGrid = m.branchBuildsPanel.findNode("branchBuildsGrid")
            if branchBuildsGrid <> invalid
              branchBuildsGrid.setFocus(true)
            end if
            handled = true
          end if
        end if
        if handled = false AND m.featuresPanel <> invalid
          isFeaturesVisible = m.featuresPanel.visible
          isFeaturesItemFocused = isMenuItemFocused("features")
          if isFeaturesVisible = true OR isFeaturesItemFocused = true
            ' Show features panel if it's hidden, then move focus to it
            if m.featuresPanel.visible = false
              m.featuresPanel.visible = true
            end if
            m.featuresPanel.setFocus(true)
            ' Also directly set focus to the experiments grid
            experimentsGrid = m.featuresPanel.findNode("ExperimentsGrid")
            if experimentsGrid <> invalid
              experimentsGrid.setFocus(true)
            end if
            handled = true
          end if
        end if
      end if
    end if
  end if
  return handled

End Function


Function onIsLoading()
  if m.top.isLoading = true
    m.Spinner.visible = true
    m.ContentGroup.visible = false
  else
    m.Spinner.visible = false
    m.ContentGroup.visible = true
  end if
End Function


Function onTestingAidPanelItemSelected(msg)
  itemSelected = msg.GetData()

  item = m.Menu.Content.getChild(itemSelected)
  if item.id = "viewRegistry"
    showRegistryValues()
  else if item.id = "clearRegistry"
    clearRegistry()
  else if item.id = "safeZone"

    safeZone = getSafeZone()

    if safeZone = invalid
      item.title = "Hide Safe Zone Image"
      showSafeZoneImage(safeZone)
    else
      item.title = "Show Safe Zone Image"
      hideSafeZoneImage(safeZone)
    end if
  else if item.id = "overlay"
    overlay = getOverlay()

    if overlay = invalid
      item.title = "Hide Grid Overlay"
      'create new grid over the scene and append as a child 'overlayGrid'
      createGridOverlay(m.top.getScene())
    else
      item.title = "Show Grid Overlay"
      hideDevOverlay(overlay)
    end if
  else if item.id = "addProxy"
    if m.proxyinputDialog <> invalid
      m.proxyinputDialog.setFocus(true)
    else
      displayProxyKB(true)
    end if
  else if item.id = "mockServer"
    showMockServerProfileList(true)
  else if item.id = "playerStats"
    showPlayerStats = getPlayerStats()

    if showPlayerStats = false
      item.title = "Hide Player Stats"
      m.global.showPlayerStats = true
    else
      item.title = "Show Player Stats"
      m.global.showPlayerStats = false
    end if
  else if item.id = "branchBuilds"
    showBranchBuildsPanel()
  else if item.id = "features"
    showFeaturesPanel()
  end if

End Function


Function getPlayerStats()
  playerStats = false
  if m.global <> invalid AND m.global.showPlayerStats <> invalid
    playerStats = m.global.showPlayerStats
  end if
  return playerStats
End Function


'This function shows registry value in a dialog and also prints to the console.
Function showRegistryValues()
  registry = CreateObject("roRegistry")
  regStr = ""
  sections = registry.GetSectionList()

  for each sectionName in sections
    section = CreateObject("roRegistrySection", sectionName)
    keys = section.GetKeyList()
    regStr = regStr + chr(10) + chr(10) + "<header>" + sectionName + "</header>" + chr(10)
    for each k in keys
      value = section.Read(k)
      if value <> invalid
        regStr = regStr + "          " + k + ": " + "<subTitle>" + value.toStr() + "</subTitle>" + chr(10)
      else
        regStr = regStr + "          " + k + ": " + chr(10)
      end if
    end for
  end for

  showData(regStr)
End Function


Function showData(data = "", title = "")
  dialog = createObject("roSGNode", "ScrollingDialog")
  dialog.title = title
  dialog.text = data
  '// TODO: WHEN SCROLLABLE MULTISTYLE TEXT IS AVAILABLE, REMOVE SCROLLINGDIALOG FROM THE CODEBASE AND USE TUBI'S SHOWMODAL() WITH MULTISTYLE TEXT
  m.top.getScene().dialog = dialog

End Function


Function clearRegistry()
  registry = CreateObject("roRegistry")
  sections = registry.GetSectionList()
  for each sectionName in sections
    registry.Delete(sectionName)
  end for
  registry.Flush()
  'after registry been deleted restart the app.
  m.top.appRestartRequested = true
End Function


'this function will return the safeZone node if it is already present as a child to the Scene.
'else it will return invalid.
Function getSafeZone()
  safeZone = invalid

  for each child in m.top.getScene().getChildren(-1, 0)
    if child.id = "safeZoneImage"
      safeZone = child
      exit for
    end if
  end for

  return safeZone
End Function


'this function will return the overlay node if it is already present as a child to the Scene.
'else it will return invalid.
Function getOverlay()
  overlay = invalid

  for each child in m.top.getScene().getChildren(-1, 0)
    if child.id = "overlayGrid"
      overlay = child
      exit for
    end if
  end for

  return overlay
End Function


Function showSafeZoneImage(safeZone)

  if safeZone = invalid
    safeZone = createObject("roSGNode", "Poster")

    'CDN image has HD/FHD - all caps and $$RES$$ resolves to 'hd/fhd' - all small.
    'so use ScaleUi Constant value to determine the correct images.
    if m.constants.deviceInfo.scaledUi = true
      res = "HD"
    else
      res = "FHD"
    end if

    safeZone.uri = "https://mcdn.tubitv.com/image/roku_support_images/Outline-Roku-Safe-Zones-" + res + ".png"
    safeZone.translation = "[0,0]"
    safeZone.id = "safeZoneImage"
  end if

  m.top.getScene().appendChild(safeZone)

End Function



Function hideDevOverlay(overlay)
  if overlay <> invalid
    m.top.getScene().removeChild(overlay)
    overlay = invalid
  end if

End Function


Function hideSafeZoneImage(safeZone)

  if safeZone <> invalid
    m.top.getScene().removeChild(safeZone)
  end if

End Function


Function showCountryList(show = false)
  if show = true
    if m.countryListMenu = invalid
      m.countryListMenu = createTestAidList("countryListMenu", "onCountryListMenuChanged")

      countryList = createObject("roSGNode", "ContentNode")
      countryList.update({
        id: "countryList"
        children: [
          { id: "US", title: "United States" }
          { id: "GB", title: "United Kingdom" }
          { id: "AU", title: "Australia" }
          { id: "CA", title: "Canada" }
          { id: "NZ", title: "New Zealand" }
          { id: "MX", title: "Mexico" }
          { id: "CR", title: "Costa Rica" }
          { id: "GT", title: "Guatemala" }
          { id: "EC", title: "Ecuador" }
          { id: "PA", title: "Panama" }
          { id: "SV", title: "El Salvador" }
          { id: "OTHER", title: "Other" }
        ]
      }, true)

      m.countryListMenu.content = countryList
    end if
    m.countryListMenu.visible = true
  else
    if m.countryListMenu <> invalid
      m.countryListMenu.visible = false
    end if
  end if
End Function


Function onCountryListMenuChanged(msg)
  itemSelected = msg.getData()
  if itemSelected <> invalid AND itemSelected >= 0
    selectedCountry = m.countryListMenu.content.getChild(itemSelected).id
  else
    selectedCountry = "US"
  end if


  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride) ' Create a registry section object
  registrySection.write("sudoCountry", selectedCountry)
  registrySection.flush()
  'after registry been updated restart the app.
  m.top.appRestartRequested = true

End Function


Function showLanguageList(show = false)
  if show = true
    if m.languageListMenu = invalid
      m.languageListMenu = createTestAidList("languageListMenu", "onLanguageListMenuChanged")

      currentLocale = m.constants.deviceInfo.locale
      languageList = createObject("roSGNode", "ContentNode")
      languageList.update({
        id: "languageList"
        children: [
          { id: "resetDefault", title: "Reset to Default" }
          { id: "en_US", title: "English (US)", checked: currentLocale = "en_US" }
          { id: "en_GB", title: "English (UK)", checked: currentLocale = "en_GB" }
          { id: "es_MX", title: "Spanish", checked: currentLocale = "es_MX" }
          { id: "fr_CA", title: "French", checked: currentLocale = "fr_CA" }
        ]
      }, true)

      m.languageListMenu.content = languageList
    end if
    m.languageListMenu.visible = true
  else
    if m.languageListMenu <> invalid
      m.languageListMenu.visible = false
    end if
  end if
End Function


Function onLanguageListMenuChanged(msg)
  itemSelected = msg.getData()
  if itemSelected <> invalid AND itemSelected >= 0
    selectedLocale = m.languageListMenu.content.getChild(itemSelected).id
  else
    selectedLocale = "en_US"
  end if

  registrySection = CreateObject("roRegistrySection", m.constants.registrySectionIDs.settingsOverride)
  if selectedLocale = "resetDefault"
    registrySection.delete("sudoLocale")
  else
    registrySection.write("sudoLocale", selectedLocale)
  end if
  registrySection.flush()
  m.top.appRestartRequested = true
End Function


' Show or create the features panel for experiment overrides
'
' Creates the FeaturesPanel on first call and sets up observers for close and selection events.
' Fetches experiments data from Statsig if not already available.
' Makes panel visible but does not auto-focus (user must press right key to focus it).
Function showFeaturesPanel() as Void
  ' Request to fetch experiments only if not already available
  if m.top.statsigExperiments = invalid
    m.top.fetchStatsigExperiments = true
  end if

  ' Create and show FeaturesPanel
  if m.featuresPanel = invalid
    m.featuresPanel = createObject("roSGNode", "FeaturesPanel")
    m.featuresPanel.translation = [350, 81]
    m.featuresPanel.observeFieldScoped("closePanel", "onFeaturesPanelClose")
    m.featuresPanel.observeFieldScoped("experimentGroupSelected", "onExperimentGroupSelected")
    m.top.appendChild(m.featuresPanel)
  end if

  ' Pass experiments data if available
  if m.top.statsigExperiments <> invalid
    m.featuresPanel.experimentsData = m.top.statsigExperiments
  end if

  m.featuresPanel.visible = true
  ' Don't auto-focus - let user explicitly move focus with right key
End Function


' Handle experiment group selection from features panel
'
' Bubbles up the selection event to SettingsScreen for processing and storage.
' Selection data contains experiment ID and selected group/variant information.
'
' @param msg Message object containing the selection data (experimentId and group info)
Function onExperimentGroupSelected(msg) as Void
  selectionData = msg.getData()
  ' Bubble up the selection to SettingsScreen
  m.top.experimentGroupSelected = selectionData
End Function


' Handle Statsig experiments data changes
'
' Updates the FeaturesPanel with new experiments data when it becomes available.
' Called when experiments are fetched from Statsig API.
'
' @param msg Message object containing the experiments data
Function onStatsigExperimentsChanged(msg) as Void
  experimentsData = msg.getData()

  ' Pass data to FeaturesPanel if it exists
  if m.featuresPanel <> invalid
    m.featuresPanel.experimentsData = experimentsData
  end if
End Function


' Handle features panel close event
'
' Hides the features panel and returns focus to the Testing Aid menu.
' Called when user presses back/left from experiments grid.
Function onFeaturesPanelClose() as Void
  if m.featuresPanel <> invalid
    m.featuresPanel.visible = false
    m.Menu.setFocus(true)
  end if
End Function


' Check if a specific menu item is currently focused by its id
'
' @param itemId - String, the id of the menu item to check
' @return Boolean True if the menu item with the given id is focused
Function isMenuItemFocused(itemId as String) as Boolean
  if m.Menu <> invalid AND m.Menu.content <> invalid
    focusedIndex = m.Menu.itemFocused
    if focusedIndex >= 0
      focusedItem = m.Menu.content.getChild(focusedIndex)
      if focusedItem <> invalid
        if focusedItem.id = itemId
          return true
        end if
      end if
    end if
  end if
  return false
End Function


' Show or create the branch builds panel
'
' Creates the BranchBuildsPanel on first call and sets up observers for close and restart events.
' Makes panel visible but does not auto-focus (user must press right key to focus it).
Function showBranchBuildsPanel() as Void
  if m.branchBuildsPanel = invalid
    m.branchBuildsPanel = createObject("roSGNode", "BranchBuildsPanel")
    m.branchBuildsPanel.translation = [350, 81]
    m.branchBuildsPanel.observeFieldScoped("closePanel", "onBranchBuildsPanelClose")
    m.branchBuildsPanel.observeFieldScoped("appRestartRequested", "onBranchBuildsAppRestart")
    m.top.appendChild(m.branchBuildsPanel)
  end if

  m.branchBuildsPanel.visible = true
End Function


' Handle branch builds panel close event
'
' Hides the panel and returns focus to the Testing Aid menu.
Function onBranchBuildsPanelClose() as Void
  if m.branchBuildsPanel <> invalid
    m.branchBuildsPanel.visible = false
    m.Menu.setFocus(true)
  end if
End Function


' Handle app restart request from branch builds panel
Function onBranchBuildsAppRestart() as Void
  m.top.appRestartRequested = true
End Function
