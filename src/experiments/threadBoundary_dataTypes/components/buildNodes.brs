'AA is an Associative Array that should be the parsed JSON response to the matrix/homescreen API endpoint.
'threadName is the name of the thread (task or render), that is calling the buildNodes() function
Function buildNodes(AA as Object, threadName as String)
  timer = CreateObject("roTimespan")
  allContentNode = CreateObject("roSGNode", "ContentNode")

  allCategories = buildCategories(AA)
  categoryCount = allCategories.count()
  contentCount = 0

  for i=0 to allCategories.count()-1
    category = allCategories[i]
    categoryNode = CreateObject("roSGNode", "ContentNode")
    contentCount = contentCount + category.children.count()
    categoryNode.update(category)
    allContentNode.appendChild(categoryNode)
  end for

  time = timer.TotalMilliseconds()
  print "Time to build "; categoryCount; " categories and "; contentCount; " contents in "; threadName; " thread (ms): "; time

  return allContentNode
End Function


'AA is an Associative Array that should be the parsed JSON response to the matrix/homescreen API endpoint.
'Returns an array of category associative arrays
Function buildCategories(response)
  containers = response.containers
  contents = response.contents

  allCategories = []
  for i=0 to containers.count()-1
    container = containers[i]
    if container.type = "regular"
      categoryAA = {
        id: container.id
        title: container.title
        children: CreateObject("roArray", container.children.count(), false)
      }
      if container.children <> invalid
        for j = 0 to container.children.count()-1
          content = contents[container.children[j]]
          contentAA = {
            id: content.id
            title: content.title
            description: content.description
            length: content.duration
            subtype: "ContentNode"
          }
          categoryAA.children.push(contentAA)
        end for
      end if
      categoryAA.rating = FormatJson(categoryAA)
      allCategories.push(categoryAA)
    end if
  end for

  return allCategories
End Function
