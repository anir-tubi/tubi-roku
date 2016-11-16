Function ToString(variable As Dynamic) As String
    If Type(variable) = "Integer" or Type(variable) = "roInt" Or Type(variable) = "roInteger" Or Type(variable) = "roFloat" Or Type(variable) = "Float" Then
        Return Str(variable).Trim() + " (" + Type(variable) + ")"
    Else If Type(variable) = "roBoolean" Or Type(variable) = "Boolean" Then
        If variable = True Then
            Return "True"
        End If
        Return "False"
    Else If Type(variable) = "roString" Or Type(variable) = "String" Then
        Return variable
    Else
        Return Type(variable)
    End If
End Function

Function ShowVariable (obj, name, depth)
  if Type(obj) = "roAssociativeArray"
   printWithDepth("(object)", name, depth)
   For Each n In obj
        ShowVariable(obj[n], n, depth +1)
    End For
  else if Type(obj) = "roArray" or Type(obj) = "roList"
   obj.reset()
   count = 0
   printWithDepth("(array)", name, depth)
   while obj.isNext()
       ShowVariable(obj.next(), "[" + Str(count) + "]", depth+1)
       count = count + 1
   End while
  else
    printWithDepth(obj, name, depth)
  end if
End Function

Function ShowVariableOneLevel (obj, name, depth)
  if Type(obj) = "roAssociativeArray"
   printWithDepth("(object)", name, depth)
  else if Type(obj) = "roArray" or Type(obj) = "roList"
   printWithDepth("(array)", name, depth)
  else
    printWithDepth(obj, name, depth)
  end if
End Function



Function printWithDepth (obj, name, depth)
    s = ""
    for x = 0 To depth
        s = s + " "
    end for

    if len(name) > 0
        s = s + name + ": "
    end if
    s = s + ToString(obj)

    if s.len() > 185
        s = left(s, 183) + "..."
    end if
    print s
End Function


Function BuildVarOutputArray (outArray, obj, name, depth)
    if Type(obj) = "roAssociativeArray"
       printToArray(outArray, "(object)", name, depth)
       for each n in obj
         BuildVarOutputArray(outArray, obj[n], n, depth+1)
       end for
    else if Type(obj) = "roArray"  or Type(obj) = "roList"
       obj.reset()
       count = 0
       printToArray(outArray, "(array)", name, depth)
       while obj.isNext()
         BuildVarOutputArray(outArray, obj.next(), "[" + Str(count) + "]", depth+1)
         count = count + 1
       End while
    else
        printToArray(outArray, obj, name, depth)
    end if
End Function

Function printToArray (outArray, obj, name, depth)
    s = ""
    if len(name) > 0
        s = s + name + ": "
    end if
    s = s + ToString(obj)

    if s.len() > 155
        s = left(s, 155) + "..."
    end if
    outArray.push([s, depth])
End Function


Function ShowVarSimple (varToShow, name="")
    ShowVariable(varToShow, name, 0)
end function

Function ShowVar (varToShow)
    ShowVariable(varToShow, invalid, 0)
end function

Function doNothing1 (a)
End Function

Function doNothing2 (a, b)
End Function

Function filterActions(which)
   if m.filters[val] = 0
     return {
            show: doNothing2
            showOnScreen: doNothing1
        }
   else
     return m
    end if
end Function

function Dev()
	return {
	    f: filterActions,
	    filters: [1,1,0,1,1,1,1,1,1,1,1,1]
		show: ShowVarSimple
		showOnScreen: showVarOnScreen
	}
end function

Sub showVarOnScreen (varToShow, y=40)
    o = []
    startY = y
    deviceInfo = CreateObject("roDeviceInfo")
		displaySize = deviceInfo.GetDisplaySize()
    BuildVarOutputArray(o, varToShow, "", 0)

    canvasItems = []

    if m.devFont = invalid
        fontReg = CreateObject("roFontRegistry")
        fontReg.Register("pkg:/fonts/LCDMono.ttf")
        m.devFont = fontReg.Get("Default", 14, 50, false)
    end if

    while o.isNext()
        item = o.next()
        canvasItems.push ({
            Text: item[0]
            TextAttrs:{
                Color:"#FFFFFF00"
                Font:m.devFont
                HAlign:"Left"
                VAlign:"VCenter"
                Direction:"LeftToRight"
            }
            TargetRect: {x: 40 + (item[1]*12), y: y, w: 2000, h: 22}
        })
        y = y + 14
    End while

   canvas = CreateObject("roImageCanvas")
   port = CreateObject("roMessagePort")
   canvas.SetMessagePort(port)
   canvas.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
   canvas.SetLayer(1, canvasItems)
   canvas.AddButton(1, "exit object viewer")
   canvas.AddButton(2, "page up")
   canvas.AddButton(3, "page down")
   canvas.Show()
   while(true)
		 msg = wait(0,port)
		 if type(msg) = "roImageCanvasEvent" then
			if msg.isButtonPressed()
				button = msg.GetIndex()
				if (button = 1)
					return
				else if (button = 2)
					showVarOnScreen(varToShow, startY+(displaySize.h-50))
					return
				else if (button = 3)
					showVarOnScreen(varToShow, startY-(displaySize.h-50))
					return
				end if
			end if
		 end if
   end while
End Sub

'returns the current time in seconds since UNIX epoch
function getCurrentTime()
  currentTime = CreateObject("roDateTime")
  currentTime.Mark()
  return currentTime.AsSeconds()
end function
