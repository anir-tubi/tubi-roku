Function init()
  m.waitingForUpdatedAuthInfo = false ' flag to indicate if we are waiting for updated auth info before we can proceed with some operation
End Function


' When it is discovered that we need updated auth, use this function to start the process to retrieve it. If called multiple times it will only trigger the process once if the updated auth request is still in progress.
Function getUpdatedAuth(port = invalid)
  tubiLog("BaseTaskNeedungAuth.getUpdatedAuth")
  ' If we are already requesting updated auth info, then don't do it again
  if m.waitingForUpdatedAuthInfo = false then
    m.waitingForUpdatedAuthInfo = true

    if port = invalid then
      port = m.port
    end if

    if port = invalid then
      tubiLog("m.port not set but is required for getUpdatedAuth")
    else
      m.top.observeFieldScoped("authUpdated", port)
    end if

    m.top.updateAuth = true
  end if
End Function


' Since tasks run in a loop, this function is needed to check if we have received updated auth info and if so trigger the appropriate callback either onAuthUpdatedFailure or onAuthUpdatedSuccess. Will return true if the message passed in was an authUpdated message else false.
Function conditionallyProcessAuthUpdatedMessage(msg)
  if type(msg) = "roSGNodeEvent" then
    if msg.getField() = "authUpdated" then
      m.waitingForUpdatedAuthInfo = false
      m.top.unobserveFieldScoped("authUpdated")

      if m.auth <> invalid then
        authInfo = m.auth.getAuthInfoNoUpdate()
        if authInfo = invalid OR m.auth.checkIfAuthExpired(authInfo) = true then
          onAuthUpdatedFailure()
        else
          onAuthUpdatedSuccess()
        end if
      else
        tubiLog("m.auth not set but is required for conditionallyProcessAuthUpdatedMessage")
      end if

      return true
    end if
  end if

  return false
End Function


Function onAuthUpdatedSuccess()
  ' This function is called when the authUpdated message is received and the auth info is deemed to be valid.
  ' Those extending can override this to be notified when this happens.
End Function


Function onAuthUpdatedFailure()
  ' This function is called when the authUpdated message is received and the auth info is deemed to not be valid.
  ' Those extending can override this to be notified when this happens.
End Function
