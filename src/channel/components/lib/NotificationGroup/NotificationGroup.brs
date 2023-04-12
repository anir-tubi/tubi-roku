Function init()
  m.notificationBorder = m.top.findNode("notificationBorder")
  m.notificationTitle = m.top.findNode("notificationTitle")
  m.asteriskIcon = m.top.findNode("asteriskIcon")
  m.notificationTitle.observeFieldScoped("text", "onNotificationTextChanged")
End Function


Function onNotificationTextChanged()
  calculatedTextWidth = m.notificationTitle.boundingRect().width
  screenWidth = 1920
  textPadding = 18
  rightPadding = 87
  widthOfNotification = 2 * textPadding + rightPadding
  asteriskIconWidth = m.asteriskIcon.boundingRect().width
  xTranslation = screenWidth - (calculatedTextWidth + widthOfNotification + asteriskIconWidth)
  yTranslation = 984
  m.top.translation = [xTranslation, yTranslation]
  m.notificationBorder.width = calculatedTextWidth + 72
  m.notificationTitle.width = calculatedTextWidth
End Function
