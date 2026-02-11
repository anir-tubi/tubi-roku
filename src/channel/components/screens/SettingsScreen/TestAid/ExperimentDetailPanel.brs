' Initialize the ExperimentDetailPanel component
'
' Sets up the groups grid, focus styling, and observers for experiment data changes.
' Also initializes the Statsig experiments interface for querying current variant info.
Function init() as Void
  topRef = m.top
  topRef.observeFieldScoped("experimentData", "onExperimentDataChanged")

  ' Cache node references
  m.experimentTitle = topRef.findNode("experimentTitle")
  m.variantsLabel = topRef.findNode("variantsLabel")
  m.groupsGrid = topRef.findNode("groupsGrid")
  m.groupsGrid.observeFieldScoped("itemSelected", "onGroupSelected")

  ' Set focus bitmaps
  m.groupsGrid.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.groupsGrid.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  ' Set typography for labels once
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.experimentTitle, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.variantsLabel, typographyConstants.ids.bodySmallStrong)

  m.currentExperimentId = invalid

  ' Initialize experiments interface once for reuse
  experimentsInfo = getStatsigExperimentsInfoFromGlobal()
  m.experiments = StatsigExperimentsInterface(experimentsInfo)

  ' Set the component to be focusable so onKeyEvent gets called
  topRef.focusable = true

  ' Set up theme observer and apply initial theme
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handle theme change events and update colors
'
' @param msg (optional) Message object containing the new theme, or invalid to fetch current theme
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.groupsGrid.focusBitmapBlendColor = theme.focusedColor
    m.experimentTitle.color = theme.primaryTextColor
    m.variantsLabel.color = theme.secondaryTextColor
  end if
End Function


' Handle experiment data changes
'
' When new experiment data is provided, stores the experiment ID, determines the
' current active variant, and displays all available groups/variants for selection.
'
' @param msg Message object containing the experiment data
Function onExperimentDataChanged(msg) as Void
  experimentData = msg.getData()
  if experimentData = invalid then return

  ' Display experiment name
  if experimentData.title <> invalid
    m.experimentTitle.text = experimentData.title
  end if

  ' Store the experiment ID for later use when a group is selected
  if experimentData.id <> invalid
    m.currentExperimentId = experimentData.id
  end if

  ' Get the current variant for this experiment
  m.currentVariant = getCurrentVariant(experimentData)

  ' Display groups
  if isNonEmptyArray(experimentData.groups)
    displayGroups(experimentData.groups)
  end if
End Function


' Get the current variant the user is in for this experiment
'
' Queries the Statsig experiments interface to determine which group/variant
' is currently active for the given experiment.
'
' @param experimentData Experiment data object containing layerId and id
' @return String The name of the current variant/group, or invalid if not found
Function getCurrentVariant(experimentData) as Dynamic
  ' Early return for invalid input or uninitialized experiments interface
  if experimentData = invalid OR experimentData.id = invalid OR m.experiments = invalid
    return invalid
  end if

  layerId = experimentData.layerId
  if layerId = invalid
    layerId = ""
  end if

  ' Get the experiment tracking info to find the group name
  trackingInfo = m.experiments.getExperimentTracking(layerId, experimentData.id)

  if trackingInfo = invalid OR trackingInfo.group = invalid
    return invalid
  end if

  return trackingInfo.group
End Function


' Display experiment groups/variants in the grid
'
' Creates content nodes for each group and marks the currently active variant
' with a checkmark. Uses appendChildren for efficient bulk addition.
'
' @param groups Array of group objects containing name, id, size, etc.
Function displayGroups(groups) as Void
  currentVariant = m.currentVariant
  content = createObject("roSGNode", "ContentNode")
  items = []

  ' Create content nodes for all groups
  for each group in groups
    item = createObject("roSGNode", "ContentNode")

    ' Check if this group is the current variant (comparing group name)
    isCurrentVariant = (currentVariant <> invalid AND currentVariant = group.name)

    ' Set all group data including parameterValues for selection
    item.update({
      title: group.name
      groupId: group.id
      size: group.size
      description: group.description
      parameterValues: group.parameterValues
      disabled: group.disabled
      foreignGroupID: group.foreignGroupID
      checked: isCurrentVariant
    }, true)

    items.push(item)
  end for

  ' Add all items at once for better performance
  content.appendChildren(items)

  m.groupsGrid.content = content
  m.groupsGrid.visible = true
End Function


' Handle group/variant selection by the user
'
' When a user selects a group, creates a selection data object containing
' the experiment ID and all group details, then exposes it to the parent
' component for storage and processing.
'
' @param msg Message object containing the selected item index
Function onGroupSelected(msg) as Void
  selectedIndex = msg.getData()

  ' Early returns for invalid state
  if m.groupsGrid.content = invalid then return

  selectedItem = m.groupsGrid.content.getChild(selectedIndex)
  if selectedItem = invalid OR m.currentExperimentId = invalid then return

  ' Create selection data with experiment ID and group info
  selectionData = {
    experimentId: m.currentExperimentId
    group: {
      name: selectedItem.title
      id: selectedItem.groupId
      size: selectedItem.size
      description: selectedItem.description
      parameterValues: selectedItem.parameterValues
      disabled: selectedItem.disabled
      foreignGroupID: selectedItem.foreignGroupID
    }
  }

  ' Expose the selection to parent
  m.top.groupSelected = selectionData
End Function


' Handle key events for panel navigation
'
' Closes the panel when the user presses back or left key.
'
' @param key The key that was pressed
' @param press True if key was pressed, false if released
' @return Boolean True if the event was handled, false otherwise
Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press <> true then return false

  if key = "back" OR key = "left"
    m.top.closePanel = true
    return true
  end if

  return false
End Function

