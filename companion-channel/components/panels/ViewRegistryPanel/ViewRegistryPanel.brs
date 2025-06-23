Function init()
  m.scrollableText = m.top.findNode("scrollableText")
  m.lastFocusedNode = m.scrollableText

  registryContents = ""

  registry = createObject("roRegistry")
  sections = registry.getSectionList()
  for each section in sections
    registryContents += "Section: " + section + chr(10)
    sectionKeys = regReadAll(section)
    for each sectionKey in sectionKeys
      registryContents += sectionKey + ": " + sectionKeys[sectionKey] + chr(10)
    end for
    registryContents += chr(10)
  end for

  m.scrollableText.text = registryContents
End Function
