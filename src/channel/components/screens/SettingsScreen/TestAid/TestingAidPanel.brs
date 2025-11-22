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
  else if item.id = "changeCountry"
    m.infoArea.text = "Select the country. It will work for White listed IPs only. Contact CSS for whitelisting" + chr(10) + "Current Country: " + m.constants.deviceInfo.countryCode
  else if item.id = "playerStats"
    m.infoArea.text = "This toggles the display of player stats within the video player, helping QA and developers understand the current playback."
  else if item.id = "features"
    m.infoArea.text = "Override experiment variants for testing purposes. Select an experiment to view available variants. Changes require an app restart to take effect."
    ' Show features panel on focus (similar to proxy and country list)
    if m.featuresPanel = invalid
      showFeaturesPanel()
    else if m.featuresPanel.visible = false
      ' Only auto-show if panel was never created or explicitly hidden by navigating away
      ' Don't auto-show if user just closed it with left key
      m.featuresPanel.visible = true
    end if
  end if
  showCountryList(item.id = "changeCountry")
  displayProxyKB(item.id = "addProxy")
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


Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press = true
    if key = "left"
      if m.proxyinputDialog <> invalid AND m.proxyinputDialog.isInFocusChain() = true
        m.Menu.setfocus(true)
        handled = true
      else if m.countryListMenu <> invalid AND m.countryListMenu.isInFocusChain() = true
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
        else if m.countryListMenu <> invalid AND m.countryListMenu.visible = true
          m.countryListMenu.setFocus(true)
          handled = true
        else if m.featuresPanel <> invalid
          isFeaturesVisible = m.featuresPanel.visible
          isFeaturesItemFocused = isFeaturesMenuItemFocused()
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
  else if item.id = "playerStats"
    showPlayerStats = getPlayerStats()

    if showPlayerStats = false
      item.title = "Hide Player Stats"
      m.global.showPlayerStats = true
    else
      item.title = "Show Player Stats"
      m.global.showPlayerStats = false
    end if
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
      m.countryListMenu = createObject("roSGNode", "markupList")
      m.countryListMenu.numRows = "5"
      m.countryListMenu.itemSize = "[585,72]"
      m.countryListMenu.itemSpacing = "[0,8]"
      m.countryListMenu.focusBitmapBlendColor = m.focusedColor
      m.countryListMenu.itemComponentName = "CheckButton"
      m.countryListMenu.vertFocusAnimationStyle = "floatingFocus"
      m.countryListMenu.translation = "[700,200]"
      m.countryListMenu.id = "countryListMenu"
      countryList = createObject("roSGNode", "ContentNode")
      countryList.id = "countryList"
      item = createObject("roSGNode", "ContentNode")
      item.id = "US"
      item.title = "United States"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "GB"
      item.title = "United Kingdom"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "AU"
      item.title = "Australia"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "CA"
      item.title = "Canada"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "NZ"
      item.title = "New Zealand"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "MX"
      item.title = "Mexico"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "CR"
      item.title = "Costa Rica"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "GT"
      item.title = "Guatemala"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "EC"
      item.title = "Ecuador"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "PA"
      item.title = "Panama"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "SV"
      item.title = "El Salvador"
      countryList.appendChild(item)

      item = createObject("roSGNode", "ContentNode")
      item.id = "OTHER"
      item.title = "Other"
      countryList.appendChild(item)

      m.countryListMenu.content = countryList

      m.top.appendChild(m.countryListMenu)
      m.countryListMenu.observeFieldScoped("itemSelected", "onCountryListMenuChanged")
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


' Check if the features menu item is currently focused
'
' Traverses the menu structure to determine if the "features" item has focus.
' Used to handle right key press to show/focus the features panel.
'
' @return Boolean True if features menu item is focused, false otherwise
Function isFeaturesMenuItemFocused() as Boolean
  if m.Menu <> invalid AND m.Menu.content <> invalid
    focusedIndex = m.Menu.itemFocused
    if focusedIndex >= 0
      focusedItem = m.Menu.content.getChild(focusedIndex)
      if focusedItem <> invalid
        if focusedItem.id = "features"
          return true
        end if
      end if
    end if
  end if
  return false
End Function
