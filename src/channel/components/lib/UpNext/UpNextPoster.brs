Function init()
  tubiLog("UpNextPoster.init")
  m.top.observeField("currRect", "onRectChange")
  m.top.observeField("itemContent", "onContentChange")
  m.Poster = m.top.findNode("Poster")
End Function

Function onRectChange()
  m.Poster.width = m.top.currRect.width
  m.Poster.height = m.top.currRect.height
  setLockIconPosition()
End Function

Function onContentChange()
  tubiLog("UpNextPoster.onContentChange")
  item = m.top.itemContent
  if item <> invalid then
    ' If series content, we show a 16:9 poster, otherwise a DVD-aspect poster
    sURI = ""
    if item.seriesId <> invalid and item.seriesId <> ""
      sURI = item.landscape
    else
      if getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true
        sURI = item.landscape
      else
        sURI = item.hdgridposterurl
      end if
    end if

    m.poster.uri = sURI


    if item.needsLogin = true
      setLockIcon()
    else
      removeLockIcon()
    end if

  end if
End Function

Function setLockIcon()
  tubiLog("UpNextPoster.setLockIcon")
  if m.lockIcon = invalid
    m.lockIcon = m.top.createChild("Poster")
    m.lockIcon.opacity = 0.0
    m.lockIcon.width = 21
    m.lockIcon.height = 24
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.top.observeFieldscoped("focusPercent", "onFocusPercent")
  end if
  setLockIconPosition()
End Function


Function setLockIconPosition()
  if m.lockIcon <> invalid
    m.lockIcon.translation = [m.Poster.width - (m.lockIcon.width * 2), 8]
  end if
End Function


Function removeLockIcon()
  tubiLog("UpNextPoster.removeLockIcon")
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
    m.top.unObserveFieldscoped("focusPercent")
  end if
End Function


Function onFocusPercent(msg)
  if  m.lockIcon <> invalid
    m.lockIcon.opacity = msg.getData()
  end if
End Function