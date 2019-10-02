Function init()
 m.SettingsMenu = m.top.findNode("SettingsMenu")
 m.top.list = m.SettingsMenu

 m.SettingsMenu.focusBitmapUri = "pkg:/images/menu-focus-fhd.9.png"
 m.SettingsMenu.focusBitmapBlendColor = m.global.theme.focused
 m.SettingsMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-fhd.9.png"
 if m.global.constants.deviceInfo.scaledUi = true
   m.SettingsMenu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
   m.SettingsMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-hd.9.png"
 end if
 m.SignInOutButtonContent = m.top.findNode("SignInOutButton")
 m.top.observeField("focusedChild", "onComponentFocus")
 m.top.observeField("signedIn", "onSignedInChange")
 setSignInOutText()
end Function

Function setSignInOutText()
  if m.top.signedIn = true
    m.SignInOutButtonContent.title = "Sign Out"
  else
    m.SignInOutButtonContent.title = "Sign In"
  end if
End Function

Function onSignedInChange()
  setSignInOutText()
End Function

Function onComponentFocus()
  if m.top.isInFocusChain() = true
    m.top.opacity = 1.0
    if m.top.hasFocus() = true
      m.SettingsMenu.setFocus(true)
    end if
  else
    m.top.opacity = 0.3
  end if
End Function
