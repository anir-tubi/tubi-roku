Function init()
  m.constants = getConstantsFromGlobal()
  m.currentPoster = m.top.findNode("posterA")
  m.nextPoster = m.top.findNode("posterB")
  m.animation = m.top.findNode("animation")
  m.fadeOutInterpolator = m.top.findNode("fadeOutInterpolator")
  m.fadeInInterpolator = m.top.findNode("fadeInInterpolator")

  m.top.observeFieldScoped("uri", "onUriChanged")
End Function


Function onUriChanged(msg)
  uri = msg.getData()

  ' Allows not having to setup uri in brs just to be able to switch between hd and fhd or to have to use two uris
  uri = setImageUriSize(uri)

  if m.constants.deviceInfo.limitedUi = false
    m.animation.control = "finish"
  end if

  if m.nextPoster.uri = uri
    ' We're reusing the same image again. If we don't do this check then loadStatus would never change as the uri hasn't changed
    onLoadStatusChanged()
  else
    m.nextPoster.observeFieldScoped("loadStatus", "onLoadStatusChanged")
    ' Make sure to set after registering the observer. Don't ask me how I know :)
    m.nextPoster.uri = uri
  end if
End Function

Function onLoadStatusChanged()
  loadStatus = m.nextPoster.loadStatus

  if loadStatus = "ready" OR loadStatus = "failed"
    m.nextPoster.unobserveFieldScoped("loadStatus")
    m.nextPoster.visible = true
    if m.nextPoster.uri = ""
      ' Setting uri to an empty string does not make the image disappear so have to hide it ourselves
      m.nextPoster.visible = false
    end if

    if m.constants.deviceInfo.limitedUi = true
      m.currentPoster.opacity = 0
      m.nextPoster.opacity = 1
    else
      m.fadeOutInterpolator.fieldToInterp = m.currentPoster.id + ".opacity"
      m.fadeInInterpolator.fieldToInterp = m.nextPoster.id + ".opacity"

      m.animation.control = "start"
    end if

    ' Swap the poster for the next animation
    temp = m.nextPoster
    m.nextPoster = m.currentPoster
    m.currentPoster = temp
  end if

  m.top.loadStatus = loadStatus
End Function
