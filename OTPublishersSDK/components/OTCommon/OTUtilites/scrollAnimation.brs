Function ScrollInitialize(this, originalLayoutHeight, scrollLayoutHeigt) as Object
  m.this = this
  m.originalLayoutHeight = originalLayoutHeight
  m.scrollLayoutHeigt = scrollLayoutHeigt
End Function

Function scrollHeight()
  m.this.scrollThumb.visible = false
  m.originalLayoutHeight.clippingRect = [0, 0, m.originalLayoutHeight.width, m.originalLayoutHeight.height]
  ThumbHeight = 0
  m.this.scrollJump = 0
  ViewportHeight = m.originalLayoutHeight.height
  m.ContentHeight = m.scrollLayoutHeigt.boundingRect().height
  scrolltextH = m.ContentHeight - ViewportHeight
  if scrolltextH > 0 AND ViewportHeight > 0 AND m.ContentHeight > 0
    m.this.scrollThumb.visible = true
    scrollacc = scrolltextH / 1
    ThumbHeight = ViewportHeight - (scrollacc * 1)
    m.this.scrollJump = 1
    if ThumbHeight <= 100
      ThumbHeight = 100
      scrollThumbSpace = viewportHeight - ThumbHeight
      m.this.scrollJump = scrollThumbSpace / scrollacc
    end if
  end if
  return ThumbHeight
End Function

Function isScrollable(key, nextvalue = invalid)
  originalLayoutH = m.originalLayoutHeight.height
  layoutH = m.scrollLayoutHeigt.boundingRect().height
  scrollBtn = false
  _isScrollable = false
  if key = "down"
    if nextvalue <> invalid AND nextvalue.key = m.navConstant.scrollTextButton AND nextvalue.value.visible then scrollBtn = nextvalue.value.translation[1] + m.scrollLayoutHeigt.translation[1] < originalLayoutH - 100
    _isScrollable = layoutH > originalLayoutH AND getScrollLayoutH(key, originalLayoutH) < layoutH
  else
    if nextvalue <> invalid AND nextvalue.key = m.navConstant.scrollTextButton AND nextvalue.value.visible then scrollBtn = nextvalue.value.translation[1] + m.scrollLayoutHeigt.translation[1] > 0
    _isScrollable = layoutH > originalLayoutH AND getScrollLayoutH(key, originalLayoutH) < 0
  end if
  return _isScrollable AND not scrollBtn
End Function

Function getScrollLayoutH(key, originalLayoutH)
  if key = "down"
    return originalLayoutH - m.scrollLayoutHeigt.translation[1]
  else
    return cint(m.scrollLayoutHeigt.translation[1])
  end if
End Function

Function scroll(direction)
  if direction = "up"
    ' m.scrollLayoutHeigt.translation = [m.scrollLayoutHeigt.translation[0], m.scrollLayoutHeigt.translation[1] + 60]
    processLongKeyPress(true)
    ' m.this.scrollThumb.translation = [m.this.scrollThumb.translation[0], m.this.scrollThumb.translation[1] - m.this.scrollJump]
  else
    ' m.scrollLayoutHeigt.translation = [m.scrollLayoutHeigt.translation[0], m.scrollLayoutHeigt.translation[1] - 60]
    processLongKeyPress(true)
    ' m.this.scrollThumb.translation = [m.this.scrollThumb.translation[0], m.this.scrollThumb.translation[1] + m.this.scrollJump]
  end if
End Function

Function scrollAnimation(offsetY as Dynamic)
  ' yItemSpacing = m.top.itemSpacings[1]
  height = getScrollLayoutH(m.key, m.originalLayoutHeight.height)
  m.ContentHeight = m.scrollLayoutHeigt.boundingRect().height
  if m.key = "down" AND m.ContentHeight - height < offsetY then offsetY = m.ContentHeight - height
  if m.key = "up" AND -height < offsetY then offsetY = -height

  m.gridScrollAnimation.duration = m.scrollTimer.duration
  m.gridScrollThumbAnimation.duration = m.scrollTimer.duration
  offsettY = m.this.scrollJump * offsetY
  if (m.key = "up") offsetY = -offsetY
  if (m.key <> "up") offsettY = -offsettY
  nextTranslation = [0, m.lastTranslation[1] - offsetY]
  nextThumbTranslation = [m.scrollThumb.translation[0], m.lastThumbTranslation[1] - offsettY]

  m.gridScrollAnimationInterpolator.keyValue = [m.scrollLayoutHeigt.translation, nextTranslation]
  m.gridScrollThumbAnimationInterpolator.keyValue = [m.scrollThumb.translation, nextThumbTranslation]

  m.gridScrollAnimation.control = "start"
  m.gridScrollThumbAnimation.control = "start"

  m.lastTranslation = nextTranslation
  m.lastThumbTranslation = nextThumbTranslation
  'm.lastReverse = reverse
End Function

Function setScrollFocus()
  m.this.scrollThumb.opacity = "1"
  m.scrollLayoutHeigt.setFocus(true)
End Function