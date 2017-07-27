Function TubiMetadataFetch(constants, request, translate)
  return {
    request: request
    constants: constants
    translate: translate

    'public method
    liveTv: TubiMetadataFetch_liveTv

    'private methods
    getliveTvRequest: TubiMetadataFetch_getliveTvRequest
    organizeLiveTvContent: TubiMetadataFetch_organizeLiveTvContent
  }
End Function


Function TubiMetadataFetch_liveTv()
  request = m.getliveTvRequest()
  
  res = request.runSynchronous()
  if res <> invalid
    liveTvContentRes = ParseJson(res)
    organizedRes = m.organizeLiveTvContent(liveTvContentRes)
    return organizedRes
  else
    return invalid
  end if
End Function


'just a helper function to create the request object needed for to get the live tv metadata
Function TubiMetadataFetch_getliveTvRequest()
  url = m.constants.urls.liveTv.getAll
  name = "getLiveTv"
  options = {
    params: {
      platform: m.constants.platform
    }
  }
  request = m.request.createAsync(url, name, options)

  return request
End Function


'takes a server response that has been parsed from JSON and organizes it in a way we can feed to the translating function
'this function is tightly coupled to the API response format
'
'@liveTvResponse: assocArray, a JSON parsed response from the server to get the live tv metadata
Function TubiMetadataFetch_organizeLiveTvContent(liveTvResponse)
  channels = {
    liveTvCursor: [0,0,0]
    children: []
  }

  containers = liveTvResponse.containers
  contents = liveTvResponse.contents

  for i=0 to containers.count()-1
    channel = {
      id: ""
      title: ""
      children: []
      liveTvChannelType: "regular"
      slug: "default-slug"
    }

    container = containers[i]
    if container.id <> invalid
      channel.id = container.id

      'set the title
      if container.title <> invalid
        channel.title = container.title
      else
        channel.title = container.id
      end if

      if container.description <> invalid
        channel.description = container.description
      end if

      if container.type <> invalid then
        channel.liveTvChannelType = container.type
      end if

      if container.slug <> invalid
        channel.slug = container.slug
      end if

      'set the children
      for each id in container.children
        if contents[id] <> invalid
          child = contents[id]
          child.isLiveTV = true

          if child["type"] = "c"  'indicates "clip" or short form type
            child["type"] = "clip"   'need to change the type, since we already use type="c" to indicate categories
          end if
          channel.children.push(child)
        end if
      end for
    end if

    channels.children.push(channel)
  end for

  parent = CreateObject("roSGNode", "TubiContentNode")
  nodeCount = m.translate.translateRecursive(channels, parent)
  parent.liveTvCursor = channels.liveTvCursor

  'find the channel specified in costants
  for i=0 to parent.getChildCount()-1
    if parent.getChild(i).id = m.constants.ui.onNow.channelId
      parent.liveTvCursor = [i, parent.liveTvCursor[1], parent.liveTvCursor[2]]
      exit for
    end if
  end for

  return parent
End Function
