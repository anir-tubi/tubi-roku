Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  topRef.observeFieldScoped("consents", "onConsentList")

  m.preferenceMenu = topRef.findNode("preferenceMenu")
  m.preferenceMenu.observeFieldScoped("itemSelected", "onPreferenceMenuItemSelected")
  m.preferenceMenu.observeFieldScoped("currFocusRow", "onPreferenceMenuItemCurrFocusRow")

  m.topGradient = topRef.findNode("topGradient")
  m.bottomGradient = topRef.findNode("bottomGradient")

  ' Holds true/false based on whether the focus indicator is in fixed position or can slide/float up and down the list.
  m.isFocusStyleFixed = false

  ' Holds the value of the direction up/down when the focus animation style changes from floating focus to fixed focus.
  ' Focus get fixed at the top or bottom based on the focused item position and direction.
  m.scrollDirectionWhenFocusStyleChanges = "down"

  ' Holds the value of the index of the focused item when the focus animation style changes from floating focus to fixed focus.
  ' Using 1 as the start position rather than zero for easier understandability.
  m.focusedIndexWhenFocusStyleChanges = 1
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.preferenceMenu.setFocus(true)
  end if
End Function


Function onConsentList(msg)
  consentList = msg.getData()
  contentNode = CreateObject("roSGNode", "ContentNode")
  contentNode.id = "consentItems"
  rowHeights = []

  ' Holds the value of the largest row height value.
  maxHeight = 0
  for each content in consentList
    preferenceItemContentNode = contentNode.createChild("ConsentPreferenceItemContentNode")
    preferenceItemContentNode.update(content)
    preferenceItemContentNode.subHeaderWidth = m.top.subHeaderWidth
    preferenceItemContentNode.totalWidth = m.top.totalWidth

    ' Creating a virtual component to find the height of the component so that we can dynamically set row heights.
    itemNode = CreateObject("roSGNode", "ConsentPreferenceItem")
    itemNode.itemContent = preferenceItemContentNode

    height = itemNode.boundingRect().height
    if maxHeight < height
      maxHeight = height
    end if
    rowHeights.push(height)
  end for
  rowHeights[0] = maxHeight

  ' Using the index so that we can calculate the height of the visible row items to place the bottom gradient.
  index = 0
  visibleItemsHeight = 0  
  for each height in rowHeights
    if index < 4
      visibleItemsHeight = visibleItemsHeight + height
    end if
    index = index + 1
  end for

  m.preferenceMenu.content = contentNode
  m.preferenceMenu.rowHeights = rowHeights
  width = m.preferenceMenu.itemSize[0]
  m.topGradient.width = width
  m.bottomGradient.width = width + 10
  m.bottomGradient.translation = [-5, visibleItemsHeight - 72]

  m.topGradient.opacity = 0
  
  ' Display gradient only if we have more than 4 items.
  if consentList.count() > 4
    m.bottomGradient.opacity = 1
  else
    m.bottomGradient.opacity = 0
  end if
End Function


Function onPreferenceMenuItemSelected(msg)
  index = msg.getData()
  itemSelected = m.preferenceMenu.content.getChild(index)

  if itemSelected.value <> "required"
    if itemSelected.value = "opted_out"
      itemSelected.value = "opted_in"
    else
      itemSelected.value = "opted_out"
    end if
  end if
  selectedConsent = {}
  selectedConsent[itemSelected.key] = itemSelected.value
  m.top.selectedConsent = selectedConsent
End Function


Function onPreferenceMenuItemCurrFocusRow(msg)
  ' Roku exposes 3 values none,up,down.
  vertFocusDirection = m.preferenceMenu.vertFocusDirection

  ' maximum visible items at any given point of time.
  totalVisibleItemCount = m.preferenceMenu.numRows

  ' currFocus value based on the direction of scroll goes upward or downward.
  ' moving up from 1 item to 2 item. values will increase from 1 to 2. ex: 1.05, 1.15 .... 1
  ' moving down from 2 item to 1 item. values will decrease from 2 to 1. ex: 2.95, 2.85 .... 2
  currFocus = msg.getData()

  ' For easier debugging considering the start position as 1 rather than default roku way of zero.
  ' Getting the fraction value, So if the currfocus row values is 2.5. Then 2.5 - 2 = 0.5, where 2 is the rounded down value of 2.5
  fraction = currFocus - roundDown(currFocus)

  ' Based on the direction of scroll if currfocus value is 3.5. Next focused item will be either 4 or 3.
  ' Plus one added here is just to convert the focused index to be starting from 1 instead of zero.
  itemFocused = roundUp(currFocus) + 1

  ' If the user is moving up then subtracting the 1 from itemfocused.
  if vertFocusDirection = "up" AND fraction > 0
    itemFocused = itemFocused - 1
  end if

  totalItems = m.preferenceMenu.content.getChildCount()

  ' Below is used to determine if the focus animation style is fixed and if fixed what was the index when it changed to fixed.

  ' When the focus style is floating and we reach top or bottom of the grid column.
  ' First condition check if the focus style is floating and second check if we reached bottom and third checks if we reached top.
  if m.isFocusStyleFixed = false AND (m.focusedIndexWhenFocusStyleChanges + totalVisibleItemCount = itemFocused OR m.focusedIndexWhenFocusStyleChanges - totalVisibleItemCount = itemFocused)
    m.focusedIndexWhenFocusStyleChanges = itemFocused
    m.isFocusStyleFixed = true
    m.scrollDirectionWhenFocusStyleChanges = vertFocusDirection
  else if m.isFocusStyleFixed = true AND vertFocusDirection = "up" AND m.scrollDirectionWhenFocusStyleChanges = "down"

    ' This logic is triggered when focus style was fixed and we pressed up and roku changes the focus style to floating to move the focus until it reaches top of grid column.
    m.isFocusStyleFixed = false
  else if m.isFocusStyleFixed = true AND vertFocusDirection = "down" AND m.scrollDirectionWhenFocusStyleChanges = "up"

    ' This logic is triggered when focus style was fixed and we pressed down and roku changes the focus style to floating to move the focus until it reaches down of grid column.
    m.isFocusStyleFixed = false
  else if m.isFocusStyleFixed = true

    ' This condition will be executed when the animation style is fixed and the scroll direction is the same as the previous scroll direction.
    ' In this logic we are just updating the focusedIndexWhenFocusStyleChanges to the latest index where the focus style is fixed.
    m.focusedIndexWhenFocusStyleChanges = itemFocused
  end if

  ' None is returned when list recieves focus from another component.
  if vertFocusDirection <> "none"
    indexOfTheLastVisibleItem = m.focusedIndexWhenFocusStyleChanges + (totalVisibleItemCount - 1)

    if m.scrollDirectionWhenFocusStyleChanges = "down"
      if m.isFocusStyleFixed = false

        ' Checks if the last visible position in the visible area gets focused.
        ' Checking if we have reached the end of the grid.
        if indexOfTheLastVisibleItem = itemFocused OR (m.focusedIndexWhenFocusStyleChanges = itemFocused AND m.focusedIndexWhenFocusStyleChanges > 1) OR indexOfTheLastVisibleItem > totalItems

          ' Making sure we only fade out if it is visible.
          if m.bottomGradient.opacity <> 0
            fadeOutBottomGradient(fraction, vertFocusDirection)
          end if
        else
          if m.bottomGradient.opacity <> 1
            if vertFocusDirection = "down" AND fraction > 0
              m.bottomGradient.opacity = fraction
            else
              m.bottomGradient.opacity = 1 - fraction
            end if
          end if
        end if

        ' When we reach top of the grid when focus style is floating.
        ' Below logic gets executed when user scrolled down past visible items and focus style changed to fixed, but then user scrolls up,
        ' when that happens focus style changes to floating and we are making sure when they reach top we hide the top gradient.
        ' ex: focus changed to fixed at position 5 considering we are displaying 4 items. So when we reach 2 we need to hide the top gradient. 5 - (4-1) = 2.
        if m.focusedIndexWhenFocusStyleChanges - (totalVisibleItemCount - 1) = itemFocused
          fadeOutTopGradient(fraction, vertFocusDirection)
        else if m.focusedIndexWhenFocusStyleChanges > 1

          ' When the focus style is floating and user is not in first set of items showing top gradient, when happens after focus style changed to fixed and user starts scrolling up and down.
          fadeInTopGradient(fraction)
        end if
      else if m.isFocusStyleFixed = true

        ' When the scroll direction is downwards and we have reached the bottom of the grid and focus style is fixed.
        ' Displaying the top gradient.
        fadeInTopGradient(fraction)
      end if
    else

      ' Same Logic as below but handles upward movement.
      if m.isFocusStyleFixed = false

        ' When we reach top of the grid hiding the top gradient. So that we do not display gradient on top of focused item.
        if m.focusedIndexWhenFocusStyleChanges = itemFocused
          if m.topGradient.opacity  <> 0
            fadeOutTopGradient(fraction, vertFocusDirection)
          end if
        else if m.focusedIndexWhenFocusStyleChanges < itemFocused AND m.focusedIndexWhenFocusStyleChanges > 1
          fadeInTopGradient(fraction)
        end if

        ' When we reach bottom after the focus style changed to fixed at top and user starts scrolling down.
        if indexOfTheLastVisibleItem = itemFocused
          fadeOutBottomGradient(fraction, vertFocusDirection)
        else
          fadeInBottomGradient(fraction, vertFocusDirection)
        end if
      else if m.isFocusStyleFixed = true

        ' Any time the focus is fixed style and at the top bottom gradient will be fixed.
        ' ex:  if we have 7 items and 4 are visible when they reach 3 the focus style becomes fixed and we have more items at the bottom so we display bottom gradient.
        fadeInBottomGradient(fraction, vertFocusDirection)
      end if

    end if

  end if
End Function


Function fadeInTopGradient(fraction)
  if m.topGradient.opacity <> 1 AND fraction > 0
    m.topGradient.opacity = fraction
  else
    m.topGradient.opacity = 1
  end if
End Function


Function fadeOutTopGradient(fraction, direction)
  if direction = "up"
    m.topGradient.opacity = fraction
  else if fraction > 0
    m.topGradient.opacity = 1 - fraction
  end if
End Function


Function fadeInBottomGradient(fraction, direction)
  if m.bottomGradient.opacity <> 1 AND fraction > 0
    if direction = "up"
      m.bottomGradient.opacity = 1 - fraction
    else
      m.bottomGradient.opacity = fraction
    end if
  else
    m.bottomGradient.opacity = 1
  end if
End Function


Function fadeOutBottomGradient(fraction, direction)
  if direction = "up"
    m.bottomGradient.opacity = fraction
  else if fraction > 0
    m.bottomGradient.opacity = 1 - fraction
  else
    m.bottomGradient.opacity = 0
  end if
End Function
