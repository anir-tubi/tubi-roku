Function init()
  m.SponsorFooter = m.top.findNode("Footer")
  m.top.observeFieldScoped("uri", "onURIChange")
  m.FadingGroup = m.top.findNode("FadingGroup")

  m.FadeInURL = "" '//When a new footer needs to replace an existing one, the existing background is faded and this variable is used to remember the URL of the background that needs to be faded in
End Function


Function onURIChange(msg)
  sCurrentBground = m.SponsorFooter.uri
  url = msg.getData()

  if (sCurrentBground <> url OR m.FadingGroup.opacity < 1) AND m.FadeInURL <> url
    m.FadeInURL = url
    stopObservingFadeOutAnimation()
    if sCurrentBground <> "" AND m.FadingGroup.opacity > 0
      '//fade out the existing background. When the fadeOut animation is complete then fade in the new url
      m.animationFadeOut = fade(m.FadingGroup, "out", .25)
      if m.animationFadeOut <> invalid
        m.animationFadeOut.observeFieldScoped("state", "onAnimationStateChange")
      end if
    else
      '//if no existing background, then fade new background
      fadeInBackground()
    end if
  else
    '//if the current and new backgrounds are the same (and the background is at full opacity), then do nothing
  end if
End Function


Function stopObservingFadeOutAnimation()
  if m.animationFadeOut <> invalid
    m.animationFadeOut.unobserveFieldScoped("state")
  end if
End Function


Function onAnimationStateChange(msg)
  state = msg.getData()
  if m.FadingGroup.opacity = 0 AND state = "stopped"
    '//The fading group has completely faded out, now fade in the desired URL
    fadeInBackground()
  end if
End Function


Function fadeInBackground()
  stopObservingFadeOutAnimation()
  m.SponsorFooter.uri = m.FadeInURL
  if m.FadeInURL <> ""
    fade(m.FadingGroup, "in", .25)
  end if
End Function