Function init()
  m.notificationBorder = m.top.findNode("notificationBorder")
  m.notificationTitle = m.top.findNode("notificationTitle")
  m.notificationTitle.observeFieldScoped("text", "onNotificationTextChanged")
End Function


Function onNotificationTextChanged()
  calculatedTextWidth = m.notificationTitle.boundingRect().width
  screenWidth = 1920
  textPadding = 16
  rightPadding = 56
  widthOfNotification = 2 * textPadding + rightPadding
  xTranslation = screenWidth - (calculatedTextWidth + widthOfNotification)
  yTranslation = 984
  m.top.translation = [xTranslation, yTranslation]
  m.notificationBorder.width = calculatedTextWidth + 32
  m.notificationTitle.width = calculatedTextWidth
End Function
