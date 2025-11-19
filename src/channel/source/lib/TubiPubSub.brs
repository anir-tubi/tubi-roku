' An instance of TubiPubSub is used to allow UI components (typically screens) to have fields updated
' when a value on the parent's (typically the contentController's) m. is updated. This could be used
' to pass uiMode to screens, or isLoggedIn to screens automatically when these values change.
'
' For items on the context's m. that act as publishers, please use the naming convention of prepending
' the string "pub_" to the m. property name. For instance, m.pub_uiMode. This will inform people that
' updates to this m. property need to be done via the publish() method on the TubiPubSub instance.

' @context: assocArray, the m context of the caller that wishes to create a TubiPubSub instance.
Function TubiPubSub(context)
  ' a publication can be thought of as a property on the context's m.
  if isAA(context)
    return {
      ' public
      context: context
      publish: tubiPubSub_publish
      subscribe: tubiPubSub_subscribe
      unsubscribe: tubiPubSub_unsubscribe
      unsubscribeFromAll: tubiPubSub_unsubscribeFromAll
      printPublication: tubiPubSub_printPublication
      printAllPublications: tubiPubSub_printAllPublications

      ' private
      ' publications will be an AA with each key containing an AA of component ids that are
      ' subscribed to a publication. An example data structure would look like the following
      ' with uiMode and deviceSettings being keys on the context's m.
      '
      ' publications: {
      '   uiMode: {
      '     uiMode: {
      '       homeScreen: uiMode
      '       detailScreen_03067: uiMode
      '     }
      '   }
      '   deviceSettings: {
      '     "deviceSettings.language": {
      '        videoPlayer: playbackLanguage
      '        linearVideoPlayer: playbackLanguage
      '     }
      '     "deviceSettings.fonts.color": {
      '       searchScreen: fontColor
      '     }
      '   }
      ' }
      publications: {}
      unsubscribeFromAllViaId: tubiPubSub_unsubscribeFromAllViaId
    }
  else
    return invalid
  end if
End Function


' Updates the value on the context's m. and updates the field on any components that are subscribed.
' For example if we pass ("uiMode", "latino"), then the context to which this module belongs will have
' m.uiMode = "latino" set upon it, and any components (like screens or side nav) which are subscribed to
' updates on m.uiMode will have the value "latino" set on the component's field that was specified
' at the time of setting up the subscription (the fieldName parameter in m.subsribe()).
'
' If we want to publish a change to m.deviceSetting.fontPreferences.size, publish the full deviceSettings
' and any component that is subscribed to any child of deviceSettings will be updated.
'
' @contextKey: string, a key/property on m. (ex. "uiMode" if we want to update m.uiMode = "latino").
' @value: any, (ex. "latino" if we want to update m.uiMode = "latino")
Function tubiPubSub_publish(contextKey, value)
  if isString(contextKey) = true
    ' update the context's m.
    m.context[contextKey] = value

    ' update any subscribers
    publication = m.publications[contextKey]

    if publication <> invalid
      for each path in publication ' path might be "uiMode" or "deviceSettings.fonts.colors"
        publishValue = invalid

        ' check if path exists on context's m.
        pathParts = path.split(".")
        pathTester = m.context

        for i = 0 to pathParts.count() - 1
          pathTester = pathTester[pathParts[i]]

          if pathTester = invalid
            exit for
          end if
        end for

        publishValue = pathTester

        ' set the value on each subscriber component's field
        if publishValue <> invalid
          for each subscriberId in publication[path]
            fieldName = publication[path][subscriberId]
            subscriber = m.context.top.findNode(subscriberId)

            if subscriber <> invalid
              if subscriber.hasField(fieldName) = true
                subscriber[fieldName] = publishValue
              end if
            else
              ' subscriber component cannot be found, so remove from all publications to prevent
              ' memory use from getting too large unnecessarily.
              m.unsubscribeFromAllViaId(subscriberId)
            end if
          end for
        end if
      end for
    end if
  end if
End Function


' Allows a child component to subscribe to state value stored on the parent's m. context.
'
' @publication: string, the property name on the contexts m. This can either be a string like "uiMode"
'                       if we want to subscribe to m.uiMode. Or it can be a string like
'                       "deviceSettings.fontPreferences.size". This example would be considered to
'                       have a depth of 3. The max depth allowed is 4.
' @component: roSGNode, the component that will be updated when the property on m. is updated.
'                       the component must have an id that is unique throughout the app
' @fieldName: string, the field on the passed in component that will be updated when property on m. is published
'
' Note: if the passed in component does not have a field with the name that is passed as fieldName,
' the component will not be subscribed to the publication.
Function tubiPubSub_subscribe(publication, component, fieldName)
  if isString(publication) = true AND isNode(component) = true AND isNonEmptyString(component.id) = true
    if m.publications = invalid
      ' added for safety, we should never have to enter this if block
      m.publications = {}
    end if

    publicationAsArray = publication.split(".")
    publicationHeadValue = publicationAsArray[0]

    if component.hasField(fieldName) = true AND m.context.doesExist(publicationHeadValue) = true AND publicationAsArray.count() < 5
      ' set up default publications data structure in case it doesn't exist yet
      if m.publications[publicationHeadValue] = invalid
        m.publications[publicationHeadValue] = {}
      end if

      if m.publications[publicationHeadValue][publication] = invalid
        m.publications[publicationHeadValue][publication] = {}
      end if

      m.publications[publicationHeadValue][publication][component.id] = fieldName
      return true
    end if
  end if

  return false
End Function


' @publicationPath: string, the property name on the context's m. Can be "uiMode" in the case of m.uiMode or
'                       can be "deviceSettings.fonts.color" in the case of m.deviceSettings.fonts.color
' @component: roSGNode, the component that will be updated when the property on m. is updated.
'                       the component must have an id that is unique throughout the app
Function tubiPubSub_unsubscribe(publicationPath, component)
  if isString(publicationPath) = true AND isNode(component) = true AND isNonEmptyString(component.id) = true
    pubPathAsArray = publicationPath.split(".")
    pubPathHeadValue = pubPathAsArray[0]

    publication = m.publications[pubPathHeadValue]

    if publication <> invalid
      subscribers = publication[publicationPath]

      if subscribers <> invalid
        subscribers.delete(component.id)

        if subscribers.count() = 0
          ' since there are no more subscriptions for the publication path
          ' we can remove the publication path from the publication for now
          ' (ie. remove "deviceSetings.language" from deviceSettings)
          publication.delete(publicationPath)

          if publication.count() = 0
            ' since there are no more publication paths for the publication path head
            ' we can remove the publication path head for now
            ' (ie. remove "deviceSettings" from publications)
            m.publications.delete(pubPathHeadValue)
          end if
        end if

        return true
      end if
    end if
  end if

  return false
End Function


' @component: roSGNode, the component that will be updated when the property on m. is updated.
'                       The component must have an id that is unique throughout the app
Function tubiPubSub_unsubscribeFromAll(component)
  if isNode(component) AND isNonEmptyString(component.id)
    return m.unsubscribeFromAllViaId(component.id)
  end if

  return false
End Function


' @componentId: string, the id of the component that will be updated when the property on m. is updated.
'                       The component id must be unique throughout the app.
Function tubiPubSub_unsubscribeFromAllViaId(componentId)
  if isNonEmptyString(componentId) = true
    for each pubPathHeadValue in m.publications
      publication = m.publications[pubPathHeadValue]

      if publication <> invalid
        for each publicationPath in publication
          subscribers = publication[publicationPath]

          if subscribers <> invalid
            for each subscriberId in subscribers
              if subscriberId = componentId
                subscribers.delete(subscriberId)

                if subscribers.count() = 0
                  ' since there are no more subscriptions for the publication path
                  ' we can remove the publication path from the publication for now
                  ' (ie. remove "deviceSetings.language" from deviceSettings)
                  publication.delete(publicationPath)

                  if publication.count() = 0
                    ' since there are no more publication paths for the publication path head
                    ' we can remove the publication path head for now
                    ' (ie. remove "deviceSettings" from publications)
                    m.publications.delete(pubPathHeadValue)
                  end if
                end if
              end if
            end for
          end if
        end for
      end if
    end for

    ' return true indicates that the component with the passed in id is no longer subscribed to any
    ' publications, not necessarily that we actively unsubscribed the component while calling this function.
    return true
  end if

  return false
End Function


' Prints a list of components that are subscribed to the publication
' @publication: string, the property name on the contexts m.
Function tubiPubSub_printPublication(publication)
  if isString(publication) = true
    publicationAsArray = publication.split(".")
    publicationHeadValue = publicationAsArray[0]

    if m.publications[publicationHeadValue] <> invalid
      subscribers = m.publications[publicationHeadValue][publication]

      if subscribers.count() > 0
        print "*** Subscriber Components on m."; publication; " ***"
        for each subscriber in subscribers
          print "  "; subscriber; "."; subscribers[subscriber]
        end for
      else
        print "!!!  No Subscibers on m."; publication; " !!!"
      end if
    end if
  end if
End Function


Function tubiPubSub_printAllPublications()
  if m.publications <> invalid AND m.publications.count() > 0
    for each publicationHeadValue in m.publications
      publicationPaths = m.publications[publicationHeadValue]
      for each publication in publicationPaths
        m.printPublication(publication)
      end for

    end for
  else
    print "!!! There are no publications on m. !!!"
  end if
End Function