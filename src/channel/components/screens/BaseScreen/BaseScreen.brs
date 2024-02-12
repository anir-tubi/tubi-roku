Function init()
  m.audioGuide = CreateObject("roAudioGuide")
  m.defaultBackgroundUri = ""
End Function


Function determineBackgroundImage(content)
  if isNode(content) = true AND isNonEmptyArray(content.backgrounds) = true then
    return content.backgrounds
  else
    if isNonEmptyString(m.defaultBackgroundUri) = true
      return [m.defaultBackgroundUri]
    else
      return []
    end if
  end if
End Function


'This function will tell you whether audioGuide enabled or not.
'AudioGuide supported devices:  Roku Streaming Stick (3600X), Roku Express (3700X) and Express+ (3710X),
'Roku Premiere (4620X) and Premiere+ (4630X), Roku Ultra (4640X), and any Roku TV running Roku OS version 7.5 and late
Function isRokuAudioGuideEnabled()
  deviceInfo = CreateObject("roDeviceInfo")

  return deviceInfo.isAudioGuideEnabled()
End Function


'This function will read the passing text to be spoken.
'@textToRead: String, The string to be spoken.
'@isFlush: boolean, set to true to make the screen reader immediately stop speaking any other speech before speaking, otherwise set to false
'@isRepeat: boolean, set to true will ignore reading the same text, otherwise set to false.
Function readAudioGuideText(textToRead as string, isFlush = true as boolean, isRepeat = true as boolean)
  if isRokuAudioGuideEnabled() = true AND m.audioGuide <> invalid
    m.audioGuide.say(textToRead, isFlush, isRepeat)
  end if
End Function
