' BranchBuildsPanel - Panel for selecting remote component library branch builds
'
' Fetches the branch manifest from CDN, displays available builds in a grid,
' and writes the selected build URL to the configurationOverrides registry.
Function init() as Void
  m.constants = getConstantsFromGlobal()
  topRef = m.top
  topRef.observeFieldScoped("focusedChild", "onFocusedChildChange")

  m.branchBuildsGrid = topRef.findNode("branchBuildsGrid")
  m.statusLabel = topRef.findNode("statusLabel")

  m.detailGroup = topRef.findNode("detailGroup")
  m.detailTitle = topRef.findNode("detailTitle")
  m.detailBranch = topRef.findNode("detailBranch")
  m.detailPR = topRef.findNode("detailPR")
  m.detailAuthor = topRef.findNode("detailAuthor")
  m.detailCommit = topRef.findNode("detailCommit")
  m.detailTimestamp = topRef.findNode("detailTimestamp")
  m.detailLib = topRef.findNode("detailLib")
  m.detailUrl = topRef.findNode("detailUrl")

  m.branchBuildsGrid.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.branchBuildsGrid.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  m.branchBuildsGrid.observeFieldScoped("itemSelected", "onBranchBuildSelected")
  m.branchBuildsGrid.observeFieldScoped("itemFocused", "onBranchBuildFocused")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.statusLabel, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailTitle, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.detailBranch, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailPR, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailAuthor, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailCommit, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailTimestamp, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailLib, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.detailUrl, typographyConstants.ids.bodyExtraSmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  fetchBranchManifest()
End Function


' Handles theme changes and applies colors to UI elements
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.branchBuildsGrid.focusBitmapBlendColor = theme.focusedColor
    m.statusLabel.color = theme.secondaryTextColor
    m.detailTitle.color = theme.primaryTextColor
    m.detailBranch.color = theme.secondaryTextColor
    m.detailPR.color = theme.secondaryTextColor
    m.detailAuthor.color = theme.secondaryTextColor
    m.detailCommit.color = theme.secondaryTextColor
    m.detailTimestamp.color = theme.secondaryTextColor
    m.detailLib.color = theme.secondaryTextColor
    m.detailUrl.color = theme.secondaryTextColor
  end if
End Function


' Handle focus changes on the panel
Function onFocusedChildChange() as Void
  if m.top.hasFocus() = true AND m.branchBuildsGrid <> invalid AND m.branchBuildsGrid.visible = true
    m.branchBuildsGrid.setFocus(true)
  end if
End Function


' Fetches the branch builds manifest.json from S3/CDN using the network helper.
Function fetchBranchManifest() as Void
  m.statusLabel.text = "Loading branch builds..."
  m.statusLabel.visible = true

  reqInfo = {
    url: m.constants.urls.branchBuildsManifest
    requestType: m.constants.reqNames.getBranchManifest
    responseType: "array"
    successCallback: onFetchBranchManifestSuccess
    errorCallback: onFetchBranchManifestError
  }

  makeNetworkRequest(reqInfo)
End Function


' Handles successful branch manifest fetch
' @param response - Parsed manifest data from CDN
Function onFetchBranchManifestSuccess(response) as Void
  if isNonEmptyArray(response) = false
    m.statusLabel.text = "No branch builds available."
    return
  end if

  m.statusLabel.visible = false
  m.branchManifestData = response
  createBranchBuildsUI(response)
End Function


' Handles branch manifest fetch error
' @param error - Error object from the network request
Function onFetchBranchManifestError(error) as Void
  m.statusLabel.text = "Failed to fetch branch builds manifest."
End Function


' Creates the grid content for selecting a branch build.
' Includes "Reset to Default" as the first option, followed by each build from the manifest.
'
' @param manifest - Array of build entries from manifest.json
Function createBranchBuildsUI(manifest) as Void
  registrySection = createObject("roRegistrySection", "configurationOverrides")
  currentOverrides = registrySection.ReadMulti(["remoteComponentsUrl", "remoteComponentLibProvided"])
  activeUrl = ""
  if currentOverrides <> invalid AND currentOverrides.remoteComponentsUrl <> invalid
    activeUrl = currentOverrides.remoteComponentsUrl
  end if

  content = createObject("roSGNode", "ContentNode")
  items = []

  resetItem = createObject("roSGNode", "ContentNode")
  resetItem.update({
    id: "resetDefault"
    title: "Reset to Default"
    checked: (activeUrl = "")
  }, true)
  items.push(resetItem)

  for each entry in manifest
    if entry.displayName = invalid OR entry.prNumber = invalid then continue for

    item = createObject("roSGNode", "ContentNode")
    displayTitle = entry.displayName
    if entry.author <> invalid
      displayTitle = displayTitle + " (PR #" + entry.prNumber.toStr() + " " + entry.author + ")"
    end if
    item.update({
      id: "branch_" + entry.prNumber.toStr()
      title: displayTitle
      checked: (activeUrl = entry.url)
    }, true)
    items.push(item)
  end for

  content.appendChildren(items)
  m.branchBuildsGrid.content = content
  m.branchBuildsGrid.visible = true
End Function


' Handles focus change on a branch build grid item.
' Displays the full manifest entry details in the detail panel.
'
' @param msg - Message containing the focused item index
Function onBranchBuildFocused(msg) as Void
  focusedIndex = msg.getData()
  if focusedIndex = invalid OR focusedIndex < 0 then return

  if focusedIndex = 0
    m.detailGroup.visible = false
    return
  end if

  manifestIndex = focusedIndex - 1
  if m.branchManifestData = invalid OR manifestIndex >= m.branchManifestData.count()
    m.detailGroup.visible = false
    return
  end if

  entry = m.branchManifestData[manifestIndex]

  m.detailTitle.text = "Unknown"
  if entry.displayName <> invalid then m.detailTitle.text = entry.displayName

  m.detailBranch.text = "Branch: N/A"
  if entry.branch <> invalid then m.detailBranch.text = "Branch: " + entry.branch

  m.detailPR.text = "PR: #?"
  if entry.prNumber <> invalid then m.detailPR.text = "PR: #" + entry.prNumber.toStr()

  m.detailAuthor.text = "Author: N/A"
  if entry.author <> invalid then m.detailAuthor.text = "Author: " + entry.author

  m.detailCommit.text = "Commit: N/A"
  if entry.commitSha <> invalid then m.detailCommit.text = "Commit: " + left(entry.commitSha, 8)

  m.detailTimestamp.text = "Updated: N/A"
  if entry.timestamp <> invalid then m.detailTimestamp.text = "Updated: " + entry.timestamp

  m.detailLib.text = "Lib: N/A"
  if entry.libProvided <> invalid then m.detailLib.text = "Lib: " + entry.libProvided

  m.detailUrl.text = ""
  if entry.url <> invalid then m.detailUrl.text = entry.url

  m.detailGroup.visible = true
End Function


' Handles selection of a branch build from the grid.
' Writes the selected URL and lib name to the configurationOverrides registry section,
' or clears them for "Reset to Default".
'
' @param msg - Message containing the selected item index
Function onBranchBuildSelected(msg) as Void
  itemSelected = msg.getData()
  if itemSelected = invalid OR itemSelected < 0 then return

  selectedItem = m.branchBuildsGrid.content.getChild(itemSelected)
  registrySection = createObject("roRegistrySection", "configurationOverrides")

  if selectedItem.id = "resetDefault"
    registrySection.delete("remoteComponentsUrl")
    registrySection.delete("remoteComponentLibProvided")
  else
    prNumberStr = selectedItem.id.replace("branch_", "")
    prNumber = prNumberStr.toInt()

    for each entry in m.branchManifestData
      if entry.prNumber = prNumber
        registrySection.write("remoteComponentsUrl", entry.url)
        registrySection.write("remoteComponentLibProvided", entry.libProvided)
        exit for
      end if
    end for
  end if

  registrySection.flush()
  m.top.appRestartRequested = true
End Function


' Handle key events for panel navigation
'
' @param key The key that was pressed
' @param press True if key was pressed, false if released
' @return Boolean True if the event was handled
Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press <> true then return false

  if key = "left" OR key = "back"
    m.top.closePanel = true
    return true
  end if

  return false
End Function
