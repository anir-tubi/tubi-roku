' Call createGridOverlay in the init() function of a screen to show a grid
' for helping with component placement and alignment on the screen
'
' createGridOverlay may break certain screens that require dynamic adding of components to
' the passed in screen node
Function createGridOverlay(screen, spacingX=10, spacingY=10)
  if m.global.constants.settings.mode = "dev" OR m.global.constants.settings.mode = "qa"

    boldColor = "0xC3C43FFF"
    graphColor = "0xAAAAAAFF"
    fontsize = 16
    width = 1920
    height = 1080

    di = CreateObject("roDeviceInfo")

    if UCase(di.GetUiResolution().name) = "FHD"
      lineSize = 1
      boldLineSize = 2
    else
      lineSize = 2
      boldLineSize = 4
    end if

    'create line containers
    allLines = CreateObject("roSGNode", "Group")
    allLines.id = "overlayGrid"
    vertLines = allLines.createChild("Group")
    horizLines = allLines.createChild("Group")

    'create vertical lines
    for x=0+spacingX to width step spacingX
      if width > x
        line = vertLines.createChild("Rectangle")
        line.translation = [x, 0]
        line.height = height

        if x MOD 100 = 0
          line.width = boldLineSize
          line.color = boldColor
          label = vertLines.createChild("Label")
          label.translation = [x-fontsize, 100-fontsize]
          label.text = x.ToStr()
          label.color = boldColor
          label.font.size = fontsize
        else
          line.width = lineSize
          line.color = graphColor
        end if
      end if
    end for

    'create horizontal lines
    for y=0+spacingY to height step spacingY
      if height > y
        line = horizLines.createChild("Rectangle")
        line.translation = [0, y]
        line.width = width

        if y MOD 100 = 0
          line.height = boldLineSize
          line.color = boldColor
          label = horizLines.createChild("Label")
          label.translation = [100-fontsize, y-fontsize]
          label.text = y.ToStr()
          label.color = boldColor
          label.font.size = fontsize
        else
          line.height = lineSize
          line.color = graphColor
        end if
      end if
    end for

    'attach nodes to screen
    screen.appendChild(allLines)
    return true
  else
    return false
  end if
End Function
