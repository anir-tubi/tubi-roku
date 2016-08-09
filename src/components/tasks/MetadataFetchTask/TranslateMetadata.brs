'See example metadata at "https://uapi.adrise.tv/cms/categories?app_id=tubitv&platform=roku&device_id=AABBCCDDEEFF&page_enabled=false"

''''''''''''''''''''''
' translateMetadata
'
' Translates content from server into format that roku understands
' contentToTranslate should be parsed from JSON before it hits this function
Function translateMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")

  if contentToTranslate <> invalid
    'expect a list of categories with one category filled with content or a list of contents
    if type(contentToTranslate) = "roArray"
      for each content in contentToTranslate
        translateRecursive(content, translated)
      end for

    'expect a single piece of content, or several (as an associative array)
    else if type(contentToTranslate) = "roAssociativeArray"
      for each id in contentToTranslate
        'the uapi/contents API might return a piece of content as invalid (chris: ?)
        if contentToTranslate[id] <> invalid
          translateRecursive(contentToTranslate[id], translated)
        end if
      end for
    end if
  end if

  return translated
end Function


'''''''''''''''''''''
' translateRecursive
'
' This is a recursive function that does the heavy lifting for translateContentFromServer
Function translateRecursive(contentFromServer, parent) As Void
  if contentFromServer = invalid then return

  translatedContent = parent.createChild("TubiContentNode")
  constants = m.constants

  typeVar = "type"
    if contentFromServer[typeVar] <> invalid
      if contentFromServer[typeVar] = "c"
        translatedContent[typeVar] = constants.ui.contentTypes.category
      else if contentFromServer[typeVar] = "v"
        translatedContent[typeVar] = constants.ui.contentTypes.video
      else if contentFromServer[typeVar] = "s"
        translatedContent[typeVar] = constants.ui.contentTypes.series
      else if contentFromServer[typeVar] = "a"
        translatedContent[typeVar] = constants.ui.contentTypes.season
      end if
    end if

    'record keeping needed for adding series to bookmarks and previously viewed
    ' if translatedContent.type = constants.ui.contentTypes.video and parent <> invalid and parent.parentType = constants.ui.contentTypes.series
    if parent.parentId <> invalid
      translatedContent.parentId = parent.parentId
    else
      translatedContent.parentId = parent.id
    end if

    if parent.parentType <> invalid
      translatedContent.parentType = parent.parentType
    else
      translatedContent.parentType = parent[typeVar]
    end if

    if parent.parentTitle <> invalid
      translatedContent.parentTitle = parent.parentTitle
    else
      translatedContent.parentTitle = parent.title
    end if
    
    'translate all the stuff from the server
    if contentFromServer.id <> invalid then translatedContent.id = contentFromServer.id
    if contentFromServer.title <> invalid then translatedContent.title = contentFromServer.title
    if contentFromServer.duration <> invalid then translatedContent.length = contentFromServer.duration
    if contentFromServer.actors <> invalid then translatedContent.actors = contentFromServer.actors 'array of actors
    if contentFromServer.tags <> invalid then 
      translatedContent.genres = contentFromServer.tags 'array of genres
      translatedContent.categories = contentFromServer.tags 'array of genres
    end if
    if contentFromServer.lang <> invalid then translatedContent.language = contentFromServer.lang
    if contentFromServer.publisher_id <> invalid then translatedContent.pubId = contentFromServer.publisher_id
    if contentFromServer.country <> invalid then translatedContent.country = contentFromServer.country
    if contentFromServer.year <> invalid and contentFromServer.year <> 0 then translatedContent.releaseDate = contentFromServer.year.ToStr()
    if contentFromServer.currentEpisodeId <> invalid then translatedContent.currentEpisodeId = contentFromServer.currentEpisodeId
    if contentFromServer.nowPos <> invalid then translatedContent.nowPos = contentFromServer.nowPos
    
    if contentFromServer.description <> invalid
      translatedContent.description = contentFromServer.description
      translatedContent.longDescription = contentFromServer.description
    end if
    
    if contentFromServer.directors <> invalid and contentFromServer.directors.count() > 0
      translatedContent.director = contentFromServer.directors[0]
    end if

    if contentFromServer.credit_cuepoints <> invalid
      if contentFromServer.credit_cuepoints.prologue <> invalid
        translatedContent.introCuepoint = contentFromServer.credit_cuepoints.prologue
      end if
      if contentFromServer.credit_cuepoints.postlude <> invalid
        translatedContent.creditsCuepoint = contentFromServer.credit_cuepoints.postlude
      end if
    end if

    if contentFromServer.thumbnails <> invalid and type(contentFromServer.thumbnails) = "roArray" and contentFromServer.thumbnails.count() > 0
      translatedContent.landscape = contentFromServer.thumbnails[0]
    end if

    if contentFromServer.posterarts <> invalid and type(contentFromServer.posterarts) = "roArray" and contentFromServer.posterarts.count() > 0
      translatedContent.portrait = contentFromServer.posterarts[0]
      translatedContent.HDGRIDPOSTERURL = contentFromServer.posterarts[0]
    end if

    if contentFromServer.hero_images <> invalid and type(contentFromServer.hero_images) = "roArray" and contentFromServer.hero_images.count() > 0
      translatedContent.heros = contentFromServer.hero_images
    end if

    if contentFromServer.ratings <> invalid and contentFromServer.ratings[0] <> invalid and contentFromServer.ratings[0].value <> invalid
      translatedContent.rating = contentFromServer.ratings[0].value
    end if

    if contentFromServer.url <> invalid
      translatedContent.streams = [{url: contentFromServer.url}]
      translatedContent.url = contentFromServer.url
      if contentFromServer.url.instr(1,".m3u8") > 0
        translatedContent.streamformat = "hls"
      else if contentFromServer.url.instr(1,".mp4") > 0
        translatedContent.streamformat = "mp4"
      end if
    end if

    'take care of any subtitles if they exist - should only happen on videos
    if contentFromServer.subtitles <> invalid and type(contentFromServer.subtitles) = "roArray" and contentFromServer.subtitles.count() > 0
      translatedContent.subtitles = {}
      translatedContent.subtitles.languages = []
      for each subtitle in contentFromServer.subtitles
        translatedContent.subtitles.languages.push({
          url: subtitle.url
          name: subtitle.lang
        })
      end for
      
      'set the default subtitles if there is only one set of subtitles
      if translatedContent.subtitles.languages.count() = 1
        translatedContent.subtitles.default = translatedContent.subtitles.languages[0].url
        translatedContent.subtitleUrl = translatedContent.subtitles.languages[0].url
      end if
    end if

    'set the inital subtitle on/off state for the video
    if translatedContent.type = "video"
      if constants.deviceInfo.captionsMode = "On"
        translatedContent.showSubtitles = true
      else
        translatedContent.showSubtitles = false
      end if
    end if

    'take care of any children the content might have
    if contentFromServer.children <> invalid and contentFromServer.children.count() > 0

      for each childContent in contentFromServer.children
        translatedChildContent = translateRecursive(childContent, translatedContent)
      end for

    end if
  
end Function