Function componentTestHelper_TabNavigation(runTests, transition)
  tabs = [
    {
      id: "PosterA"
      uri: "pkg:/source/tests/assets/6f22da66-9be2-4027-907d-6a4e4f5d5c6d.jpg"
      subtype: "NavigationGroupTestPoster"
      translation: [0, 0]
    }
    {
      id: "PosterB"
      uri: "pkg:/source/tests/assets/09ee1277-50c7-4ce9-ba68-8833b1122b28.jpg"
      subtype: "NavigationGroupTestPoster"
      translation: [0, 0]
    }
    {
      id: "PosterC"
      uri: "pkg:/source/tests/assets/12648f7a-725b-4570-babc-41cb0f16bd0b.jpg"
      subtype: "NavigationGroupTestPoster"
      translation: [0, 0]
    }
    {
      id: "PosterD"
      uri: "pkg:/source/tests/assets/7739ea01-6f13-4564-a10f-29bcd2cd6657.jpg"
      subtype: "NavigationGroupTestPoster"
      translation: [0, 0]
    }
  ]
  nodes = []
  for each t in tabs
    node = CreateObject("roSGNode", "NavigationGroupTestPoster")
    node.setFields(t)
    nodes.push(node)
  end for

  data = [{
    "mode": "tab"
    "transition":  transition
    "viewIds": [
      "PosterA"
      "PosterB"
      "PosterC"
      "PosterD"
    ]
  }]
  for each t in nodes
    data.push({"addView": t})
  end for
  data.push({"show": "PosterA"})
  runTests("NavigationGroupTest", data, ["currentViewId"])
End Function

Function componentTest_TabNavigationGroupTest(screen, runTests)
  componentTestHelper_TabNavigation(runTests, "visible")
End Function

Function componentTest_TabNavigationGroupTest_fade(screen, runTests)
  componentTestHelper_TabNavigation(runTests, "fade")
End Function

Function componentTest_TabNavigationGroupTest_cascade(screen, runTests)
  componentTestHelper_TabNavigation(runTests, "cascade")
End Function



'''''''''''''''''''
' Stack Naviation
'''''''''''''''''''
Function componentTestHelper_StackNavigation(runTests, transition)
  posters = [
    {
      id: "PosterA"
      uri: "pkg:/source/tests/assets/6f22da66-9be2-4027-907d-6a4e4f5d5c6d.jpg"
      translation: [0, 0]
    }
    {
      id: "PosterB"
      uri: "pkg:/source/tests/assets/09ee1277-50c7-4ce9-ba68-8833b1122b28.jpg"
      translation: [0, 0]
    }
    {
      id: "PosterC"
      uri: "pkg:/source/tests/assets/12648f7a-725b-4570-babc-41cb0f16bd0b.jpg"
      translation: [0, 0]
    }
    {
      id: "PosterD"
      uri: "pkg:/source/tests/assets/7739ea01-6f13-4564-a10f-29bcd2cd6657.jpg"
      translation: [0, 0]
    }
  ]
  nodes = []
  for each p in posters
    node = CreateObject("roSGNode", "NavigationGroupTestPoster")
    node.setFields(p)
    nodes.push(node)
  end for

  data = {
    "mode": "stack"
    "transition": transition
    "backToPop": true
    "stackTemplates": posters
  }
  runTests("NavigationGroupTest", data, ["currentViewId"])
End Function

Function componentTest_StackNavigationGroupTest(screen, runTests)
  componentTestHelper_StackNavigation(runTests, "visible")
End Function

Function componentTest_StackNavigationGroupTest_fade(screen, runTests)
  componentTestHelper_StackNavigation(runTests, "fade")
End Function

Function componentTest_StackNavigationGroupTest_cascade(screen, runTests)
  componentTestHelper_StackNavigation(runTests, "cascade")
End Function
