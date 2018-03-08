' LICENSE: Permission is hereby granted, free of charge, to any person obtaining
' LICENSE: a copy of this software and associated documentation files (the
' LICENSE: "Software"), to deal in the Software without restriction, including
' LICENSE: without limitation the rights to use, copy, modify, merge, publish,
' LICENSE: distribute, sublicense, and/or sell copies of the Software, and to
' LICENSE: permit persons to whom the Software is furnished to do so, subject to
' LICENSE: the following conditions:
' LICENSE: 
' LICENSE: The above copyright notice and this permission notice shall be
' LICENSE: included in all copies or substantial portions of the Software.
' LICENSE: 
' LICENSE: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
' LICENSE: EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
' LICENSE: MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
' LICENSE: NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
' LICENSE: LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
' LICENSE: OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
' LICENSE: WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


' This is intended for simple components to be verified visually, including
' keypress handling.
Function ComponentTest(componentTestName)
  testFunctionName = "componentTest_" + componentTestName
  print "*** Running component test "; testFunctionName
  testFunctionNameType = "nothing"
  Eval("testFunctionNameType = type(" + testFunctionName + ")")
  if testFunctionNameType <> "Function"
    print "Component test function not found: "; testFunctionName
  else
    result = Eval(testFunctionName + "(componentTest_testComponent)")
    if type(result) = "roList"
      print "Errors ";
      for i=0 to result.count()-1
        print "  ["; i; "] "; result[i]
      end for
    ' &hFC==ERR_NORMAL_END
    ' &hE2==ERR_VALUE_RETURN 
    else if result <> &hFC and result <> &hE2
      print "Eval error "; result
      compileErrors = GetLastRunCompileError()
      if type(compileErrors) = "roList"
        print "Compile Errors: "
        for each error in compileErrors
          print error
        end for
      end if
    end if
  end if
  END
End Function


''''''''''''''''
' testComponent()
'
' Component development support.  
'
' - Launch an empty scene with child of type 'componentName'
' - set component input fields from 'dataFields'
' - observe roSGNodeEvents from 'observeFields'
' - Scene captures "back" and "ok" events to remove and restore target component focus
'
Function componentTest_testComponent(componentName, dataFields={}, observeFields=[])
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  scene = screen.CreateScene("TestScene")
  scene.id = "ComponentTestScene"
  screen.SetMessagePort(port)
  screen.show()
  scene.observeField("keypress", port)
  scene.backgroundUri = ""  ' get rid of the grey default poster
  ' Set a very visible red background for the component under test
  boundaries = scene.createChild("Rectangle")
  boundaries.color = "0x990000FF"
  ' focused component
  target = scene.createChild(componentName)
  for each field in observeFields
    target.observeField(field, port)
  end for
  if type(dataFields) = "roAssociativeArray"
    print "Settings fields: "; dataFields.keys().join(",")
    target.setFields(dataFields)
  else if type(dataFields) = "roArray"
    ' Expect array of assocarrays
    for each fieldSet in dataFields
      print "Settings fields: "; fieldSet.keys().join(",")
      target.setFields(fieldSet)
    end for
  else
    print "Unexpected type '"; type(dataFields); "' for data fields"
  end if
  target.setFocus(true)
  while true
    msg = wait(100, port)
    if type(msg) = "Invalid"
      ' Constantly resize, in case any internal processing or user input changes the dimensions
      rect = target.sceneBoundingRect()
      boundaries.translation = [rect.x, rect.y]
      boundaries.width = rect.width
      boundaries.height = rect.height
    else
      print "Got " + type(msg) + " message"
      if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
        print "playVideo: isScreenClosed"
        END  ' exit the app
      else if type(msg) = "roSGNodeEvent" then
        print "roSGNodeEvent from field "; msg.getField()
        if msg.getRoSGNode().isSameNode(scene)
          if msg.getField() = "keypress"
            if msg.getData() = "back" and target.isInFocusChain()
              print "Removing focus from target component"
              target.setFocus(false)
              scene.setFocus(true)
            else if msg.getData() = "OK" and not target.isInFocusChain()
              print "Setting focus on target component"
              target.setFocus(true)
            end if
          end if
        else if msg.getRoSGNode().isSameNode(target)
          print "Field '"; msg.getField(); "' = '"; msg.getData(); "'"
        end if
      end if
    end if
  end while
End Function