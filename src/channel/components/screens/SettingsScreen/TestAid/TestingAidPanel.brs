Function init()
  m.constants = getConstantsFromGlobal()
  m.top.selectButtonMovesPanelForward = true
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("isLoading", "onIsLoading")

  m.ContentGroup = m.top.findNode("ContentGroup")
  m.infoArea = m.top.findNode("infoArea")
  m.Menu = m.top.findNode("testingAidMenu")
  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-fhd.9.png"
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focused
  end if
  m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-footprint-fhd.9.png"
  if m.constants.deviceInfo.scaledUi = true
    m.Menu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
    m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-footprint-hd.9.png"
  end if

  m.Menu.observeFieldScoped("itemSelected", "onTestingAidPanelItemSelected")
  m.Menu.observeFieldScoped("itemFocused", "onItemFocused")

  m.Spinner = m.top.findNode("Spinner")
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
  end if

End Function


Function onIsLoading()
  tubiLog("TestingAirPanel.onIsLoading")
  if m.top.isLoading = true
    m.Spinner.visible = true
    m.ContentGroup.visible = false
  else
    m.Spinner.visible = false
    m.ContentGroup.visible = true
  end if
End Function


Function onTestingAidPanelItemSelected(msg)
  tubiLog("TestingAirPanel.onTestingAidPanelItemSelected")
  itemSelected = msg.GetData()

  item = m.Menu.Content.getChild(itemSelected)
  if item.id="viewRegistry"
    showRegistryValues()
  else if item.id = "clearRegistry"
    clearRegistry()
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


Function showData(data = "")
  dialog = createObject("roSGNode", "ScrollingDialog")
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