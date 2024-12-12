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
  end if
  ' Adding a transparent 1px image since leaving it empty causes roku to use it's default.
  ' We do not want to show unfocused background as per designs.
  m.Menu.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  title = m.top.findNode("title")
  title.text = "Testing Aid Config for: " + m.constants.settings.mode


  m.Menu.observeFieldScoped("itemSelected", "onTestingAidPanelItemSelected")
  m.Menu.observeFieldScoped("itemFocused", "onItemFocused")

  m.Spinner = m.top.findNode("Spinner")


  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.infoArea, typographyConstants.ids.bodyMediumStrong)


End Function

Function onComponentFocus()
  if m.top.hasFocus() = true
    m.Menu.setFocus(true)
  end if
End Function


Function onItemFocused(msg)
  buttonFocused = msg.getData()
  if buttonFocused = 0
    m.infoArea.text = "Current Registry values are printed by each section. Press OK to see full registry."
  else if buttonFocused = 1
    m.infoArea.text = "It will delete all the registry values and restart the app."
  else if buttonFocused = 2
    currExperiments = getCurrentExperiments()
    m.infoArea.text = "Experiments enabled:" + chr(10) + chr(10) + currExperiments
  else if buttonFocused = 3
    m.infoArea.text = "It will overlay all the screens with safe zone guidelines."
  else if buttonFocused = 4
    m.infoArea.text = "It will overlay a Grid of 10 px over all of the screens. If you want better control, use devOverlay.brs"
  end if

End Function


Function onIsLoading()
  tubiLog("TestingAidPanel.onIsLoading")
  if m.top.isLoading = true
    m.Spinner.visible = true
    m.ContentGroup.visible = false
  else
    m.Spinner.visible = false
    m.ContentGroup.visible = true
  end if
End Function


Function onTestingAidPanelItemSelected(msg)
  tubiLog("TestingAidPanel.onTestingAidPanelItemSelected")
  itemSelected = msg.GetData()

  item = m.Menu.Content.getChild(itemSelected)
  if item.id="viewRegistry"
    showRegistryValues()
  else if item.id = "clearRegistry"
    clearRegistry()
  else if item.id = "showEnabledExp"
    showCurrentExperiments()
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


  end if

End Function


'This function shows registry value in a dialog and also prints to the console.
Function showRegistryValues()
  registry = CreateObject("roRegistry")
  regStr = ""
  sections = registry.GetSectionList()
  print "*******************Registry Values******************************"

  for each sectionName in sections
    section = CreateObject("roRegistrySection", sectionName)
    print "-------------------" + sectionName + "-----------------------"
    keys = section.GetKeyList()
    regStr = regStr + chr(10) + chr(10) + "<header>"+ sectionName + "</header>" + chr(10)
    for each k in keys
      value = section.Read(k)
      if value <> invalid
        regStr = regStr + "          " +  k + ": " + "<subTitle>" + value.toStr() + "</subTitle>" + chr(10)
        print "            " + k + ": " + value.toStr()
      else
        regStr = regStr + "          " +  k +  ": " + chr(10)
        print "            " + k + ": "
      end if
    end for
    print "-----------------------------------------------------------"
  end for

  showData(regStr)
End Function


Function getCurrentExperiments()

  enabledExperiments = "Enabled Experiments" + chr(10) + "--------------------------------------------------" + chr(10)
  notEnabledExperiments = chr(10) + chr(10) + "Not Enabled Experiments" + chr(10) + "--------------------------------------------------" + chr(10)
  for each expNamespace in m.experiments.defaultResources.keys()
    for each exp in m.experiments.defaultResources[expNamespace].keys()
      if m.experiments.defaultResources[expNamespace][exp].enabled = true
        enabledExperiments = enabledExperiments + exp + chr(10)
      else
        notEnabledExperiments =   notEnabledExperiments + exp + chr(10)
      end if
    end for
  end for


  return enabledExperiments + notEnabledExperiments
End Function


Function showCurrentExperiments()
  print "*******************Enabled Experiments******************************"
  currentExperiments = getCurrentExperiments()
  print currentExperiments
  print "-----------------------------------------------------------"
  showData(currentExperiments, "Current  Experiments")
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
    print sectionName + " is Deleted "
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
      res="FHD"
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
