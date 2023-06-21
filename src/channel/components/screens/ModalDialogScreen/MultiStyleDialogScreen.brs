Function init()
  m.buttonList = m.top.findNode("ButtonList")
  m.dialogBox = m.top.findNode("DialogBox")
  m.shade = m.top.findNode("Shade") ' background rectangle to dim the currentScreen
  m.Header = m.top.findNode("Header")
  m.subHeader = m.top.findNode("subHeader")
  m.multiStyleLayout = m.top.findNode("multiStyleLayout")
  m.mask = m.top.findNode("mask")

  m.top.observeFieldScoped("buttons", "formatDialog")
  m.top.observeFieldScoped("multiStyleMessage", "formatDialog")
  m.top.observeFieldScoped("multiStyleImageUrl", "formatDialog")
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")

  m.constants = getConstantsFromGlobal()
  m.top.screenLevel = m.constants.ui.screenLevels.modalDialogScreen


  '//::TODO::colors - Design will eventually add this black color to all themes but until then, hardcode this with the default shadeColor regardless of theme.
  '//   when Design adds the color to all themes, then set this color within the onThemeChange() observer using the new theme specific color
  m.shade.color = m.constants.ui.themes.default.shadeColor

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)

  if msg <> invalid
    m.theme = msg.getData()
  else
    m.theme = getThemeFromGlobal()
  end if

  if m.theme <> invalid
    m.Header.color = m.theme.primaryTextColor
    m.subHeader.color = m.theme.secondaryTextColor
    m.dialogBox.color = m.constants.ui.themes.extended.brandPurple
  end if

End Function


Function onFocusedChildChange()
  ' If we do not set focus 4670X was forcing device reboot :|
  if m.top.hasFocus() = true then
    m.buttonList.setFocus(true)
  end if

  'if modal loses focus (mainly because videoplayer gains focus or homescreen gains focus), Just close the modal
  if m.top.isInFocusChain() = false
    m.top.exitButton = "back"
  end if

End Function


Function formatDialog()
  ' buttons
  if m.top.buttons = invalid then
    m.buttonList.content = invalid
  else if m.buttonList.content = invalid OR m.buttonList.content.getChildCount() = 0
    newContent = CreateObject("roSGNode", "ContentNode")
    nWidestWidth = 0

    for each btnText in m.top.buttons
      buttonContent = newContent.createChild("ContentNode")
      buttonContent.update({
        title: btnText
        id: btnText
        fontSize: 24
      }, true)
      '//   Temporarily create ModalListItem for each button text to find the largest width necessary for the set of buttons,
      '//   in order to determine how wide m.buttonList should be.
      '//   Different languages may make the text wider than usual so we need to ensure the button displays the full text
      listItem = CreateObject("roSGNode", "ListItemButtonWithBg")
      listContent = CreateObject("roSGNode", "ContentNode")
      listContent.title = btnText
      listItem.itemContent = listContent

      if listItem.calculatedWidth > nWidestWidth
        nWidestWidth = listItem.calculatedWidth
      end if

    end for

    'Keeping the default width of 285 for each button and if the text length is greater than 285 then we are
    'determining the width based on the text length.
    if nWidestWidth > m.buttonList.itemSize[0]
      m.buttonList.itemSize = [nWidestWidth, m.buttonList.itemSize[1]]
    end if

    numButtons = m.top.buttons.Count()
    m.buttonList.numColumns = numButtons
    m.buttonList.content = newContent
    m.dialogBox.width = (nWidestWidth * numButtons) + (32 * (numButtons - 1)) + 96 'space between buttons = 32;  right padding = 48 ; left padding = 48
    dialogBoxTranslationX = 1920 - m.dialogBox.width - 51
    m.dialogBox.translation = [dialogBoxTranslationX, m.dialogBox.translation[1]]
    m.mask.width = m.dialogBox.width
    m.subHeader.width = m.dialogBox.width - 96
    m.header.width = m.dialogBox.width - 96
  end if

  if m.top.multiStyleMessage <> invalid AND m.top.multiStyleMessage.Count() > 0 AND m.multiStyleLayout.getChildCount() = 0
    m.multiStyleLayout.visible = true

    for each multiMsg in m.top.multiStyleMessage
      multiStyleMsgGroup = CreateObject("roSGNode", "IconTitleSubtitleGroup")
      multiStyleMsgGroup.header = multiMsg.header
      multiStyleMsgGroup.subHeader = multiMsg.subHeader

      if m.theme <> invalid
        multiStyleMsgGroup.headerColor = m.theme.primaryTextColor
        multiStyleMsgGroup.subHeaderColor = m.theme.secondaryTextColor
      end if

      multiStyleMsgGroup.sideIcon = multiMsg.iconUri
      m.dialogBox.height = m.dialogBox.height + 140 'each group is 80 height + 60 gap between next item

      m.multiStyleLayout.appendChild(multiStyleMsgGroup)
    end for
  else if isNonEmptyString(m.top.multiStyleImageUrl) = true AND m.multiStyleLayout.getChildCount() = 0
    m.multiStyleLayout.visible = true
    posterImg = CreateObject("roSGNode", "Poster")
    posterImg.id = "posterImg"
    posterImg.uri = m.top.multiStyleImageUrl
    posterImg.height = 352
    posterImg.width = 582
    posterImg.loadHeight = 352
    posterImg.loadwidth = 582
    posterImg.loadDisplayMode = "scaleToFit"

    m.multiStyleLayout.appendChild(posterImg)
  end if

End Function


Function onKeyEvent(key As string, press As boolean) As boolean
  if press
    ' removed alias from xml and setting buttonSelected interface value here, to play default Roku positive audio sound when user press "OK" on any dialog modal button
    if key = "OK" AND m.buttonList.hasFocus() = true
      m.top.buttonSelected = m.buttonList.itemSelected
    end if

    if key = "back" OR key = "options" then
      m.top.exitButton = key
    end if

    return true
  end if

  return false
End Function
