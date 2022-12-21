Function init()
  m.dotGroup = m.top.findNode("dotGroup")
  m.top.observeField("carouselIndex", "onDrawDots")
End Function


Function onDrawDots()
  if m.top.totalDots <> invalid then
    totalDots = m.top.totalDots
    carouselIndex = m.top.carouselIndex

    for i = 0 to totalDots-1
      dot = m.dotGroup.createChild("Poster")
      dot.id = "dot_" + i.ToStr()
      dot.uri = "pkg:/images/dot-carousel.webp"
      if carouselIndex = i
        dot.blendColor = ""
      else
        dot.blendColor = "0xFFFFFF1A"
      end if
    end for

  end if
End Function