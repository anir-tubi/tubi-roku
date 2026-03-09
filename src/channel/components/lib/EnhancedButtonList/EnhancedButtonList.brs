' Initializes the EnhancedButtonList component
' Sets up node helpers, constants, observers, and theme
Function init() as Void
  m.nodeHelpers = TubiNodeHelpers()
  m.constants = getConstantsFromGlobal()
  m.buttons = []

  topRef = m.top
  topRef.observeFieldScoped("buttons", "onButtonsChange")
  topRef.observeFieldScoped("buttonSpacing", "onButtonSpacingChange")
  topRef.observeFieldScoped("buttonBackgroundBlendColor", "onButtonBackgroundBlendColorChange")
  topRef.observeFieldScoped("focusedChild", "onButtonListFocusChange")
  topRef.observeFieldScoped("focusedIndex", "onFocusedIndexChange")
  m.originalTranslation = topRef.translation

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and caches color values
' @param msg - Optional message object containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.secondaryTextColor = theme.secondaryTextColor
    m.focusedColor = theme.focusedColor
    m.unfocusedColor = theme.unfocusedColor
  end if
End Function


' Handles focus changes for the button list
' Updates inactive focus state when list loses focus and showInactiveFocusState is enabled
' @param _msg - Message object containing focus change data (unused)
Function onButtonListFocusChange(_msg as Object) as Void
  if m.top.showInactiveFocusState = true
    updateInactiveFocusState()
  end if
End Function


' Handles buttons array changes
' Clears existing buttons and creates new ones from the provided button data
' @param msg - Message object containing buttons array
Function onButtonsChange(msg as Object) as Void
  buttons = msg.getData()

  m.nodeHelpers.removeAllChildren(m.top)

  buttonList = []

  if isNonEmptyArray(buttons) = true
    for each info in buttons
      button = createButton(info)
      buttonList.push(button)
    end for
  end if

  if isNonEmptyArray(buttonList) = true
    m.top.appendChildren(buttonList)
    ' Cache reference to button nodes for later use
    m.buttons = buttonList
  else
    m.buttons = []
  end if

  if m.top.showInactiveFocusState = true
    updateInactiveFocusState()
  end if
End Function


' Creates an EnhancedButton node from button data
' Configures button properties, content, and sets up event observers
' @param buttonData - AssocArray containing button configuration (id, title, height, etc.)
' @return roSGNode - Configured EnhancedButton node
Function createButton(buttonData as Object) as Object
  button = CreateObject("roSGNode", "EnhancedButton")
  button.id = buttonData.id
  button.backgroundUri = m.top.buttonBackgroundUri
  if isNonEmptyString(m.top.buttonBackgroundBlendColor)
    button.backgroundBlendColor = m.top.buttonBackgroundBlendColor
  end if
  button.padding = m.top.padding

  if buttonData.height <> invalid
    button.height = buttonData.height
  else
    button.height = m.top.buttonHeight
  end if

  itemContent = CreateObject("roSGNode", "ContentNode")
  itemContent.update(buttonData, true)
  button.itemContent = itemContent

  ' Set up selection and focus handlers
  button.observeFieldScoped("wasSelected", "onButtonSelected")
  button.observeFieldScoped("wasFocused", "onButtonFocused")

  return button
End Function


' Handles button selection events
' Propagates button selection data (id, title, button node) to parent
' @param msg - Message object from button selection event
Function onButtonSelected(msg as Object) as Void
  button = msg.getRoSGNode()
  buttonData = button.itemContent

  if buttonData = invalid then return

  m.top.buttonSelected = {
    id: buttonData.id
    title: buttonData.title
    button: button
  }
End Function


' Handles button focus events
' Tracks focused and unfocused button states for navigation analytics
' @param msg - Message object from button focus event
Function onButtonFocused(msg as Object) as Void
  button = msg.getRoSGNode()
  wasFocused = msg.getData()
  buttonData = button.itemContent

  if buttonData = invalid OR wasFocused = false then return

  m.top.buttonUnFocused = m.top.buttonFocused
  m.top.buttonFocused = {
    id: buttonData.id
    title: buttonData.title
    button: button
  }

  m.top.trackingContext = buttonData.trackingContext
End Function


' Handles button spacing changes
' Updates the layout group's itemSpacings based on buttonSpacing field
' @param msg - Message object containing spacing array
Function onButtonSpacingChange(msg as Object) as Void
  m.top.itemSpacings = msg.getData()
End Function


' Handles buttonBackgroundBlendColor changes
' Updates all existing buttons' backgroundBlendColor when the field changes
' @param msg - Message object containing blend color string
Function onButtonBackgroundBlendColorChange(msg as Object) as Void
  blendColor = msg.getData()
  if isNonEmptyArray(m.buttons)
    for each button in m.buttons
      button.backgroundBlendColor = blendColor
    end for
  end if
End Function


' Updates inactive focus state for buttons
' Shows focus footprint only on the currently focused button when list is not in focus chain
Function updateInactiveFocusState() as Void
  if not isNonEmptyArray(m.buttons) then return

  focusedIndex = m.top.focusedIndex
  if focusedIndex = -1
    focusedIndex = 0
  end if

  for i = 0 to m.buttons.count() - 1
    button = m.buttons[i]
    button.hideFocusFootprint = (i <> focusedIndex)
  end for
End Function


' Handles focused index changes
' Updates the layout group's focused index
' @param msg - Message object containing focused index
Function onFocusedIndexChange(msg as Object) as Void
  topRef = m.top
  index = msg.getData()

  animated = false

  if topRef.pressedKey = "right"
    nextChild = topRef.getChild(index)
    if nextChild <> invalid AND nextChild.renderTracking <> "full"
      adjustTranslationForComponent(nextChild, -1, adjustForPartiallyRenderedButton)
      animated = true
    end if
  else if topRef.pressedKey = "left"
    if index - 1 = 0
      slideTo(topRef, m.originalTranslation, 0.15, 0.0, adjustForPartiallyRenderedButton)
      animated = true
    else
      previousChild = topRef.getChild(index - 1)
      if previousChild <> invalid AND previousChild.renderTracking <> "full"
        adjustTranslationForComponent(previousChild, 1, adjustForPartiallyRenderedButton)
        animated = true
      end if
    end if
  end if

  if animated = false
    adjustForPartiallyRenderedButton()
  end if
End Function


' Checks if the focused button is partially rendered and adjusts translation.
' Called after scroll animation completes, or immediately if no animation was triggered.
Function adjustForPartiallyRenderedButton() as Void
  topRef = m.top
  componentGainingFocus = topRef.componentGainingFocus
  if componentGainingFocus <> invalid AND componentGainingFocus.renderTracking = "partial"
    direction = -1
    if topRef.pressedKey = "left" then direction = 1
    adjustTranslationForComponent(componentGainingFocus, direction)
  end if
End Function


' Animates the list translation to account for the given component's width
' @param component - The button node whose width determines the offset
' @param direction - -1 to shift left (scrolling forward), 1 to shift right (scrolling back)
' @param callback - Optional function to call when animation completes
Function adjustTranslationForComponent(component as Object, direction as Integer, callback = invalid) as Void
  topRef = m.top
  translation = topRef.translation
  offset = component.boundingRect().width + (topRef.buttonSpacing[0] * 2)
  destination = [translation[0] + (direction * offset), translation[1]]
  slideTo(topRef, destination, 0.15, 0.0, callback)
End Function
