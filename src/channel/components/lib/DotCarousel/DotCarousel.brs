Function init()
  m.dotGroup = m.top.findNode("dotGroup")
  m.top.observeField("totalDots", "onDrawDots")
End Function


''''''''''''''''''
' onDrawDots
Function onDrawDots()

  if m.top.totalDots <> invalid then
  
    totalDots = m.top.totalDots
    dotIndex = m.top.dotIndex
  
    for i = 0 to totalDots-1
      dot = m.dotGroup.createChild("Poster")
      dot.id = "dot_" + i.ToStr()
      if dotIndex = i
        dot.uri = "pkg:/images/dot_selected.png"
      else
        dot.uri = "pkg:/images/dot_unselected.png"  
      end if
    end for
    
  end if
End Function