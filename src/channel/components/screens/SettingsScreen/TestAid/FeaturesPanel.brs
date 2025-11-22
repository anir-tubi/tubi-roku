' Initialize the FeaturesPanel component
'
' Sets up the experiments grid, focus styling, observers, and theme
' Caches node references and applies initial theme colors
Function init() as Void
  topRef = m.top
  topRef.observeFieldScoped("experimentsData", "onExperimentsDataChanged")
  topRef.observeFieldScoped("focusedChild", "onFocusedChildChange")

  ' Cache node reference
  m.experimentsGrid = topRef.findNode("ExperimentsGrid")

  ' Set focus bitmaps
  m.experimentsGrid.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.experimentsGrid.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  ' Observe item focus to track which experiment is focused
  m.experimentsGrid.observeFieldScoped("itemFocused", "onExperimentFocused")

  ' Set up theme observer and apply initial theme
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handle focus changes on the panel
'
' Ensures the experiments grid receives focus when the panel gains focus
' through explicit user action (right/OK key press)
Function onFocusedChildChange() as Void
  ' When panel gets focus via explicit user action (right/OK key), ensure the experiments grid has it
  if m.top.hasFocus() = true AND m.experimentsGrid <> invalid
    m.experimentsGrid.setFocus(true)
  end if
End Function


' Handle theme changes and update focus colors
'
' @param msg (optional) Message object containing the new theme, or invalid to fetch current theme
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.experimentsGrid.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


' Handle experiments data changes
'
' Processes the experiments data response and displays experiments in the grid
' Handles error states by hiding the grid
'
' @param msg Message object containing the experiments data
Function onExperimentsDataChanged(msg) as Void
  experimentsData = msg.getData()

  if experimentsData = invalid OR experimentsData.error = true
    m.experimentsGrid.visible = false
    return
  end if

  ' Process and display experiments
  displayExperiments(experimentsData)
End Function


' Display experiments in the grid
'
' Handles different response structures (data, experiments, or direct array)
' Creates content nodes for each experiment and populates the grid
' Uses appendChildren for efficient bulk addition
'
' @param experimentsData Experiments data object or array from API response
Function displayExperiments(experimentsData) as Void
  ' Handle different response structures
  if isNonEmptyArray(experimentsData.data) = false
    return
  end if

  experiments = experimentsData.data

  ' Create content for the list
  content = createObject("roSGNode", "ContentNode")
  items = []

  for each experiment in experiments
    item = createObject("roSGNode", "ContentNode")

    ' Set experiment data
    item.update({
      title: experiment.name
      id: experiment.id
      layerId: experiment.layerID
      groups: experiment.groups
    }, true)

    items.push(item)
  end for

  content.appendChildren(items)
  m.experimentsGrid.content = content
End Function


' Handle experiment focus changes in the grid
'
' Stores the focused experiment index and shows the detail panel for the
' focused experiment without moving focus to it
'
' @param msg Message object containing the focused item index
Function onExperimentFocused(msg) as Void
  focusedIndex = msg.getData()

  ' Show detail panel for the focused experiment (but don't move focus to it)
  if m.experimentsGrid.content = invalid then return

  focusedItem = m.experimentsGrid.content.getChild(focusedIndex)
  if focusedItem <> invalid
    showExperimentDetail(focusedItem)
  end if
End Function


' Show or update the experiment detail panel
'
' Creates the ExperimentDetailPanel on first call and sets up observers
' Updates the panel with experiment data and makes it visible
' Focus remains on the experiments grid
'
' @param experimentItem ContentNode containing experiment data (title, id, layerId, groups)
Function showExperimentDetail(experimentItem) as Void
  ' Create and show ExperimentDetailPanel
  if m.detailPanel = invalid
    m.detailPanel = createObject("roSGNode", "ExperimentDetailPanel")
    m.detailPanel.translation = "[550, 0]"
    m.detailPanel.observeFieldScoped("closePanel", "onDetailPanelClose")
    m.detailPanel.observeFieldScoped("groupSelected", "onGroupSelected")
    m.top.appendChild(m.detailPanel)
  end if

  ' Pass experiment data to detail panel
  experimentData = {
    title: experimentItem.title
    id: experimentItem.id
    layerId: experimentItem.layerId
    groups: experimentItem.groups
  }
  m.detailPanel.experimentData = experimentData

  m.detailPanel.visible = true
End Function


' Handle experiment group selection from detail panel
'
' Bubbles up the selection event to parent (TestingAidPanel/SettingsScreen)
' for further processing and storage
'
' @param msg Message object containing the selection data (experimentId and group info)
Function onGroupSelected(msg) as Void
  selectionData = msg.getData()
  ' Bubble up the selection to parent (TestingAidPanel/SettingsScreen)
  m.top.experimentGroupSelected = selectionData
End Function


' Handle detail panel close request
'
' Hides the detail panel and returns focus to the experiments grid
Function onDetailPanelClose() as Void
  if m.detailPanel <> invalid
    m.detailPanel.visible = false
    m.experimentsGrid.setFocus(true)
  end if
End Function


' Check if detail panel is currently visible
'
' @return Boolean True if detail panel exists and is visible
Function isDetailPanelVisible() as Boolean
  return m.detailPanel <> invalid AND m.detailPanel.visible = true
End Function


' Check if detail panel has focus
'
' @return Boolean True if detail panel is visible and in focus chain
Function isDetailPanelFocused() as Boolean
  return isDetailPanelVisible() AND m.detailPanel.isInFocusChain()
End Function


' Check if experiments grid has focus
'
' @return Boolean True if experiments grid exists and is in focus chain
Function isExperimentsGridFocused() as Boolean
  return m.experimentsGrid <> invalid AND m.experimentsGrid.isInFocusChain()
End Function


' Move focus to the detail panel's groups grid
'
' @return Boolean True if focus was successfully moved
Function focusDetailPanel() as Boolean
  if isDetailPanelVisible() = false then return false

  detailGrid = m.detailPanel.findNode("groupsGrid")
  if detailGrid <> invalid
    detailGrid.setFocus(true)
  else
    m.detailPanel.setFocus(true)
  end if
  return true
End Function


' Handle key events for panel navigation
'
' Manages focus transitions between experiments grid and detail panel
' Handles navigation keys (right, left, back, OK) based on current focus state
'
' Key behaviors:
' - Right/OK: Move focus from experiments grid to detail panel (if visible)
' - Left: Move focus from detail panel back to grid, or close panel if grid has focus
' - Back: Move focus to grid if detail panel focused, otherwise close panel
'
' @param key The key that was pressed
' @param press True if key was pressed, false if released
' @return Boolean True if the event was handled, false otherwise
Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press <> true then return false

  ' Handle right/OK: Move from experiments grid to detail panel
  if key = "right" OR key = "OK"
    if isExperimentsGridFocused() AND focusDetailPanel()
      return true
    end if
  end if

  ' Handle left/back: Navigate back or close panel
  if key = "left" OR key = "back"
    if isDetailPanelFocused()
      m.experimentsGrid.setFocus(true)
      return true
    end if

    ' For "left", only close if experiments grid has focus
    ' For "back", always close
    if key = "back" OR isExperimentsGridFocused()
      m.top.closePanel = true
      return true
    end if
  end if

  return false
End Function
