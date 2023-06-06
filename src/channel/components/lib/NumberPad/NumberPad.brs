Function init()
  m.constants = getConstantsFromGlobal()
  theme = getThemeFromGlobal()

  m.keyboard = m.top.findNode("keyboard")
  textEditBox = m.keyboard.textEditBox
  textEditBox.visible = false
  textEditBox.voiceEntryType = "generic" ' numeric seems like it would be a better fit but if a user says two thousand thirteen it comes through as 213 with numeric

  keyGrid = m.keyboard.keyGrid
  keyGrid.keyDefinitionUri = "pkg:/components/data/NumberPadKDF.json"

  'This will save the last focused key of the keyboard used to enable the roku default audioguide after screen components read.
  m.keyFocused = ""

  if theme <> invalid
    palette = createObject("roSGNode", "RSGPalette")
    palette.colors = {
      "FocusColor": theme.focusedColor
      "FocusItemColor": theme.keyboardFocusedTextColor
    }
    keyGrid.palette = palette
  end if

  m.top.observeFieldScoped("focusedChild", "onTopFocusedChildChange")
  ' Need to observe textEditBox focusedChild as well to avoid voice input bug where voice input does not work properly after we have setFocus in the callback from m.top.focusedChild. m.keyboard.textEditBox.focusedChild gets called later which seems to fix it.
  m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onTextEditBoxFocusedChildChange")

  'This will disable the default roku screen reader for customKeyboard to read screen heading which are not read by roku default screen reader.
  m.keyboard.muteAudioGuide = true
  m.keyboard.observeFieldScoped("keyGrid", "onKeyGridChange")
  m.top.observeFieldScoped("moveFocusToDelete", "onMoveFocusToDelete")
  m.top.observeFieldScoped("text", "onTextChange")
End Function


Function onTopFocusedChildChange()
  if m.top.hasFocus()
    m.keyboard.textEditBox.voiceEnabled = true
    m.keyboard.keyGrid.setFocus(true)
  else if m.top.isInFocusChain() = false
    m.keyboard.textEditBox.voiceEnabled = false
  end if
End Function

Function onTextEditBoxFocusedChildChange()
  ' Don't allow textEditBox to take focus since we're not showing it
  if m.keyboard.textEditBox.hasFocus()
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onMoveFocusToDelete()
  if m.top.moveFocusToDelete = true
    m.keyboard.keyGrid.jumpToKey = [0, 3, 1]
  end if
End Function


Function onTextChange()
  ' Since we steal focus away once the user puts in a correct year,
  ' the keyGrid doesn't set its opacity back to 1 after dictation finishes so we set it any time the text changes
  m.keyboard.keyGrid.opacity = 1
End Function


'This function is to read the first focused key in the keyboard as we disable the default screen reader for keyboard initially
'to read the screen components and later we enable roku default screen reader for keyboard.
'NOTE: hardcoded values are to match the default keyboard.
Function onKeyGridChange(msg)
  keyGrid = msg.getData()
  if isNonEmptyString(m.keyFocused) = true AND m.keyboard.muteAudioGuide = true

    audioGuideText = keyGrid.keyFocused + " " + m.constants.audioGuideHints.buttonHint
    m.top.audioGuideText = audioGuideText

    'This is to read the screen text and suspend the keyboard default audio guide until focus moved to next key.
    if m.keyFocused <> keyGrid.keyFocused
      m.keyboard.muteAudioGuide = false
      m.keyboard.unObserveFieldScoped("keyGrid")
    end if
  end if

  m.keyFocused = keyGrid.keyFocused
End Function
