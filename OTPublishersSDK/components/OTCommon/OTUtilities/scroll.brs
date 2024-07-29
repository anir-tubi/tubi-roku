function ScrollInitialize(this, originalLayoutHeight, scrollLayoutHeigt) as object
    m.this = this
    m.originalLayoutHeight = originalLayoutHeight
    m.scrollLayoutHeigt = scrollLayoutHeigt
end function

function scrollHeight()
    m.this.scrollThumb.visible = false
    ThumbHeight = 0
    m.this.scrollJump = 0
    ViewportHeight = m.originalLayoutHeight.height
    ContentHeight = m.scrollLayoutHeigt.boundingRect().height
    scrolltextH = ContentHeight - ViewportHeight
    if scrolltextH >= 0
        m.this.scrollThumb.visible = true
        scrollacc = scrolltextH / 60
        ThumbHeight = ViewportHeight - (scrollacc * 60)
        m.this.scrollJump = 60
        if ThumbHeight <= 100
            ThumbHeight = 100
            scrollThumbSpace = viewportHeight - ThumbHeight
            m.this.scrollJump = scrollThumbSpace / scrollacc
        end if
    end if
    return ThumbHeight
end function

function isScrollable(key)
    originalLayoutH =  m.originalLayoutHeight.height
    layoutH = m.scrollLayoutHeigt.boundingRect().height
    if key = "down"
        return layoutH > originalLayoutH and (-m.scrollLayoutHeigt.translation[1] + originalLayoutH) < layoutH
    else
        return layoutH > originalLayoutH and m.scrollLayoutHeigt.translation[1] <> 0
    end if
end function

function scroll(direction)
    if direction = "up"
        m.scrollLayoutHeigt.translation = [m.scrollLayoutHeigt.translation[0], m.scrollLayoutHeigt.translation[1] + 60]
        m.this.scrollThumb.translation = [m.this.scrollThumb.translation[0], m.this.scrollThumb.translation[1] - m.this.scrollJump]
    else
        m.scrollLayoutHeigt.translation = [m.scrollLayoutHeigt.translation[0], m.scrollLayoutHeigt.translation[1] - 60]
        m.this.scrollThumb.translation = [m.this.scrollThumb.translation[0], m.this.scrollThumb.translation[1] + m.this.scrollJump]
    end if
end function

function resetScroll()
    m.this.scrollThumb.opacity = "0.3"
    m.scrollLayoutHeigt.translation = [m.scrollLayoutHeigt.translation[0], 0]
    m.scrollThumb.translation = [m.scrollThumb.translation[0], 0]
end function

function setScrollFocus()
    m.this.scrollThumb.opacity = "1"
    m.scrollLayoutHeigt.setFocus(true)
end function