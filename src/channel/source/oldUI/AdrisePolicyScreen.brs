Function AdrisePolicyScreen(utils, settings)

  return{
    utils: utils
    settings: settings

    show: adrisePolicyScreen_show
    getPolicy: adrisePolicyScreen_getPolicy
  }
End Function


Function adrisePolicyScreen_show()
  policy = m.getPolicy()
  screen = CreateObject("roTextScreen")
  policyPort = CreateObject("roMessagePort")
  screen.setMessagePort(policyPort)
  screen.SetHeaderText("Privacy")
  screen.SetText(policy)
  screen.AddButton(0, "Ok")
  screen.Show()

  while true
    msg = wait(0, policyPort)

    if type(msg) = "roTextScreenEvent"
      if msg.isButtonPressed() and msg.getIndex() = 0
        screen.Close()
        exit while

      else if msg.isScreenClosed()
        exit while
      end if

    end if

  end while

End Function



Function adrisePolicyScreen_getPolicy()
  policy = m.utils.getTextFile(m.settings.policyUrl, "getPrivacyPolicy")
  return policy
End Function