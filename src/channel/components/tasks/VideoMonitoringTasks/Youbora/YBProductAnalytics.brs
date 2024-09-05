function YBProductAnalytics(plugin as object) As Object

  ProductAnalyticsLog("Created YBProductAnalytics")
  this = CreateObject("roAssociativeArray")

  ' -------------------------------------------------------------------------------------------
  ' Attribute definition
  ' -------------------------------------------------------------------------------------------

  this._plugin = plugin
  this._initialized = false

  ' Settings

  this._productAnalyticsSettingsDefault = {
    "highlightContentAfter": 1,
    "enableStateTracking": false,
    "activeStateTimeout": 30,
    "activeStateDimension": 9,
  }

  this._productAnalyticsSettings = {}
  this._productAnalyticsSettings.Append(this._productAnalyticsSettingsDefault)

  ' Page

  this._page = ""

  ' Search

  this._searchQuery = invalid

  ' Content highlight

  this._contentHighlighted = invalid
  this._contentHighlightTimeout = CreateObject("roSGNode", "Timer")
  this._contentHighlightTimeout.setFields({"id": "timerHighlight", "duration": this._productAnalyticsSettings.highlightContentAfter, "repeat": false})
  this._contentHighlightTimeout.observeField("fire", this._plugin.port)
  
  this._pendingVideoEvents = []

  ' User state

  this._userStates = {
    active: "active",
    passive: "passive"
  }

  this._userStateTimeout = CreateObject("roSGNode", "Timer")
  this._userStateTimeout.setFields({"id": "timerUserState", "repeat": false})
  this._userStateDimension = ""
  this._userState = this._userStates.passive

  ' Test

  if this._plugin = invalid
    ProductAnalyticsLog("Plugin reference unset.")
  end if

  ' -------------------------------------------------------------------------------------------
  ' Method definition
  ' -------------------------------------------------------------------------------------------

  ' Initializes product analytics
  ' @param {String} Screen name
  ' @param {Object} productAnalyticsSettings product analytics settings
  ' @param {Object} [npawtmConfigValue] configuration settings

  this.initialize = sub(page, productAnalyticsSettings)

    ' Set screen name

    if ( Type(page) = "roString" )
      m._page = page
    else
      ProductAnalyticsLog("Page unset while initializing.")
    end if

    ' Load settings

    m._productAnalyticsSettings = {}
    m._productAnalyticsSettings.Append(m._productAnalyticsSettingsDefault)

    if ( Type(productAnalyticsSettings) = "roAssociativeArray")
      m._productAnalyticsSettings.Append(productAnalyticsSettings)
    end if

    ' Validate settings

    if ( getInterface(m._productAnalyticsSettings.highlightContentAfter, "ifInt") = invalid )
      m._productAnalyticsSettings.highlightContentAfter = m._productAnalyticsSettingsDefault["highlightContentAfter"]
    else if (m._productAnalyticsSettings.highlightContentAfter < 1)
      ProductAnalyticsLog("Invalid higlightContentAfter value. Using default value instead.")
      m._productAnalyticsSettings.highlightContentAfter = m._productAnalyticsSettingsDefault["highlightContentAfter"]
    end if

    if ( getInterface(m._productAnalyticsSettings.enableStateTracking, "ifBoolean") = invalid )
      m._productAnalyticsSettings.enableStateTracking = m._productAnalyticsSettingsDefault["enableStateTracking"]
    end if

    if ( getInterface(m._productAnalyticsSettings.activeStateTimeout, "ifInt") = invalid )
      m._productAnalyticsSettings.activeStateTimeout = m._productAnalyticsSettingsDefault["activeStateTimeout"]
    else if (m._productAnalyticsSettings.activeStateTimeout < 1)
      ProductAnalyticsLog("Invalid activeStateTimeout value. Using default value instead.")
      m._productAnalyticsSettings.activeStateTimeout = m._productAnalyticsSettingsDefault["activeStateTimeout"]
    end if

    if ( getInterface(m._productAnalyticsSettings.activeStateDimension, "ifInt") = invalid OR m._productAnalyticsSettings.activeStateDimension < 1 OR m._productAnalyticsSettings.activeStateDimension > 9)
      m._productAnalyticsSettings.activeStateDimension = m._productAnalyticsSettingsDefault["activeStateDimension"]
    end if

    ' Update highlight timer period
    
    m._contentHighlightTimeout.setField("duration", m._productAnalyticsSettings.highlightContentAfter)

    ' Update user state fields

    m._userStateTimeout.setField("duration", m._productAnalyticsSettings.activeStateTimeout)
    m._userStateTimeout.observeField("fire", m._plugin.port)
  
    m._userStateDimension = "content.customDimension." + StrI(m._productAnalyticsSettings.activeStateDimension, 10)

    ' Set as initialized

    m._initialized = true

  end sub

  ' -------------------------------------------------------------------------------------------
  ' ADAPTER
  ' -------------------------------------------------------------------------------------------

  ' Track adapter start
  ' @private

  this._adapterTrackStart = sub()

    if m._initialized
      m.trackPlayerInteraction("start", {}, {}, true)
    end if

  end sub

  ' Execute after adapter is set to plugin

  this.adapterAfterSet = sub()

  ' Start tracking user state

  m._userStateStart()

  end sub

  ' Execute before removing adapter from plugin

  this.adapterBeforeRemove = sub()

    ' Stop tracking user state

    m._userStateStop()

    ' Discard pending video events
    
    m._pendingVideoEvents = []

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' SESSION
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' New user session

  this.newSession = sub()

    if m._initialized = false
      ProductAnalyticsLog("Cannot start a new session since Product Analytics is uninitialized.")
    else if m._plugin = invalid
      ProductAnalyticsLog("Cannot start a new session since plugin is unavailable.")
    else
      m.endSession()
      m._plugin.eventHandler("sessionStart", {"page": m._page})
    end if

  end sub

  ' Ends user session

  this.endSession = sub()

    if m._initialized = false
      ProductAnalyticsLog("Cannot end session since Product Analytics is uninitialized.")
    else if m._plugin = invalid
      ProductAnalyticsLog("Cannot end session since plugin is unavailable.")
    else
      m._plugin.eventHandler("sessionStop", {})
    end if

  end sub

  ' Set user profile

  this.setUserProfile = sub(profileId, profileType, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot set user profile since Product Analytics is uninitialized.")
    else if m._plugin = invalid
      ProductAnalyticsLog("Cannot set user profile since plugin is unavailable.")
    else if (Type(profileId) <> "roString" OR profileId = "")
      ProductAnalyticsLog("Cannot set user profile since profileId is unset.")
    else
      m.endSession()
      m.newSession()

      dimensionsInternal = {
        "eventType": "UserSwitch",
        "profileId": profileId
      }

      if (Type(profileType) = "roString" AND profileType <> "")
        dimensionsInternal.profileType = profileType
      end if

      m._fireEvent("USER PROFILE SELECTION", dimensionsInternal, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' NAVIGATION
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Tracks navigation
  ' @param {string} page The unique name to identify a page of the application.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackNavByName = sub(page, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track navigation since Product Analytics is uninitialized.")
    else if m._plugin = invalid
      ProductAnalyticsLog("Cannot track navigation since plugin is unavailable.")
    else if (Type(page) <> "roString" OR page = "")
      ProductAnalyticsLog("Cannot track navigation since page has not been supplied.")
    else
      m._page = page

      m._plugin.eventHandler("sessionStart", {"page": m._page})

      ' Track the event

      ProductAnalyticsLog("[NAV] " + m._page)
      m._fireEvent("[NAV] " + m._page, {
        "eventType": "Navigation",
        "route": "",
        "routeDomain": "",
        "fullRoute": ""
      }, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' ATTRIBUTION
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Tracks attribution
  ' @param {string} utmSource The UTM Source parameter. It is commonly used to identify a search engine, newsletter, or other source (i.e., Google, Facebook, etc.).
  ' @param {string} utmMedium The UTM Medium parameter. It is commonly used to identify a medium such as email or cost-per-click (cpc).
  ' @param {string} utmCampaign The UTM Campaign parameter. It is commonly used for campaign analysis to identify a specific product promotion or strategic campaign (i.e., spring sale).
  ' @param {string} utmTerm The UTM Term parameter. It is commonly used with paid search to supply the keywords for ads (i.e., Customer, NonBuyer, etc.).
  ' @param {string} utmContent The UTM Content parameter. It is commonly used for A/B testing and content-targeted ads to differentiate ads or links that point to the same URL (i.e., Banner1, Banner2, etc.)
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track


  this.trackAttribution = sub(utmSource, utmMedium, utmCampaign, utmTerm, utmContent, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track attribution since Product Analytics is uninitialized.")
    else

      params = {}

      if (Type(utmSource) = "roString") params["utmSource"] = utmSource
      if (Type(utmMedium) = "roString") params["utmMedium"] = utmMedium
      if (Type(utmCampaign) = "roString") params["utmCampaign"] = utmCampaign
      if (Type(utmTerm) = "roString") params["utmTerm"] = utmTerm
      if (Type(utmContent) = "roString") params["utmContent"] = utmContent

      ' Track attribution

      if m._initialized = false

        ProductAnalyticsLog("Cannot track attribution since Product Analytics is uninitialized.")

      else if params.Count() > 0

        params.eventType = "Attribution"
        params.url = ""

        ProductAnalyticsLog("ATTRIBUTION")
        m._fireEvent("ATTRIBUTION", params, dimensions, metrics)

      end if
        
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' SECTION
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Section goes into viewport.
  ' @param {string} section The section title. It is commonly used to indicate the section title presented over a grid layout (e.g. Recommended Movies, Continue Watching, etc).
  ' @param {integer} sectionOrder The section order within the page.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackSectionIn = sub(section, sectionOrder, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track section-in since Product Analytics is uninitialized.")
    else if (Type(section) <> "roString" OR section = "")
      ProductAnalyticsLog("Cannot track section-in since no section has been supplied.")
    else if (Type(sectionOrder) <> "roInt" OR sectionOrder < 1)
      ProductAnalyticsLog("Cannot track section-in since sectionOrder is invalid.")
    else
      ProductAnalyticsLog("[SECTION] In")
      m._fireEvent("SECTION IN", {
        "eventType": "SectionVisibility",
        "sectionOrder": sectionOrder,
        "section": section
      }, dimensions, metrics)
    end if

  end sub

  ' Section goes out of viewport.
  ' @param {string} section The section title. It is commonly used to indicate the section title presented over a grid layout (e.g. Recommended Movies, Continue Watching, etc).
  ' @param {integer} sectionOrder The section order within the page.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackSectionOut = sub(section, sectionOrder, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track section-out since Product Analytics is uninitialized.")
    else if (Type(section) <> "roString" OR section = "")
      ProductAnalyticsLog("Cannot track section-out since no section has been supplied.")
    else if (Type(sectionOrder) <> "roInt" OR sectionOrder < 1)
      ProductAnalyticsLog("Cannot track section-out since sectionOrder is invalid.")
    else
      ProductAnalyticsLog("[SECTION] Out")
      m._fireEvent("SECTION OUT", {
        "eventType": "SectionVisibility",
        "sectionOrder": sectionOrder,
        "section": section
      }, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' CONTENT
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Sends a content highlight event if content is focused during, at least, highlightContentAfter s.
  ' @param {string} section The section title. It is commonly used to indicate the section title presented over a grid layout (e.g. Recommended Movies, Continue Watching, etc).
  ' @param {integer} sectionOrder The section order within the page.
  ' @param {integer} column Used to indicate the column number where content is placed in a grid layout The first column is number 1.
  ' @param {integer} row Used to indicate the row number where content is placed in a grid layout. The first row is number 1. In the case of a horizontal list instead of a grid, the row parameter should be set to 1.
  ' @param {string} contentID The unique content identifier of the content linked.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.contentFocusIn = sub(section, sectionOrder, column, row, contentID, dimensions, metrics)
    m.contentFocusOut()

    if m._initialized = false
      ProductAnalyticsLog("Cannot track content highlight since Product Analytics is uninitialized.")
    else if (Type(section) <> "roString" OR section = "")
      ProductAnalyticsLog("Cannot track content highlight since no section has been supplied.")
    else if (Type(sectionOrder) <> "roInt" OR sectionOrder < 1)
      ProductAnalyticsLog("Cannot track content highlight since sectionOrder is invalid.")
    else if (Type(column) <> "roInt" OR column < 1)
      ProductAnalyticsLog("Cannot track content highlight since column is invalid.")
    else if (Type(row) <> "roInt" OR row < 1)
      ProductAnalyticsLog("Cannot track content highlight since row is invalid.")
    else if (Type(contentID) <> "roString" OR contentID = "")
      ProductAnalyticsLog("Cannot track content highlight since no contentID has been supplied.")
    else
      m._contentHighlighted = { "sectionOrder": sectionOrder, "section": section, "column": column, "row": row, "contentID": contentID, "dimensions": dimensions, "metrics": metrics }
      m._contentHighlightTimeout.control = "start"
    end if

  end sub

  ' Content loses focus
  ' @private

  this.contentFocusOut = sub()

    m._contentHighlighted = invalid
    m._contentHighlightTimeout.control = "stop"

  end sub

  ' Sends a content highlight event using selected content info
  ' @private

  this.trackContentHighlight = sub()

    if ( m._contentHighlighted = invalid )

      ProductAnalyticsLog("Cannot highlight content since no content is selected")

    else

      ProductAnalyticsLog("CONTENT HIGHLIGHT")

      m._fireEvent("CONTENT HIGHLIGHT", {
        "eventType": "ContentHighlight",
        "sectionOrder": m._contentHighlighted["sectionOrder"],
        "section": m._contentHighlighted["section"],
        "column": m._contentHighlighted["column"],
        "row": m._contentHighlighted["row"],
        "contentId": m._contentHighlighted["contentID"]
      }, m._contentHighlighted["dimensions"], m._contentHighlighted["metrics"])

      m._contentHighlighted = invalid
      
    end if

  end sub


  ' Tracks the location of user clicks.
  ' @param {string} section The section title. It is commonly used to indicate the section title presented over a grid layout (e.g. Recommended Movies, Continue Watching, etc).
  ' @param {integer} sectionOrder The section order within the page.
  ' @param {integer} column Used to indicate the column number where content is placed in a grid layout The first column is number 1.
  ' @param {integer} row Used to indicate the row number where content is placed in a grid layout. The first row is number 1. In the case of a horizontal list instead of a grid, the row parameter should be set to 1.
  ' @param {string} contentID The unique content identifier of the content linked.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackContentClick = sub(section, sectionOrder, column, row, contentID, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track content click since Product Analytics is uninitialized.")
    else if (Type(section) <> "roString" or section = "")
      ProductAnalyticsLog("Cannot track content click since no section has been supplied.")
    else if (Type(sectionOrder) <> "roInt" or sectionOrder < 1)
      ProductAnalyticsLog("Cannot track content click since sectionOrder is invalid.")
    else if (Type(column) <> "roInt" or column < 1)
      ProductAnalyticsLog("Cannot track content click since column is invalid.")
    else if (Type(row) <> "roInt" or row < 1)
      ProductAnalyticsLog("Cannot track content click since row is invalid.")
    else if (Type(contentID) <> "roString" or contentID = "")
      ProductAnalyticsLog("Cannot track content click since no contentID has been supplied.")
    else
      ProductAnalyticsLog("CONTENT CLICK")
      m._fireEvent("CONTENT CLICK", {
        "eventType": "ContentClick",
        "sectionOrder": sectionOrder,
        "section": section,
        "column": column,
        "row": row,
        "contentId": contentID
      }, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' CONTENT PLAYBACK
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Tracks when a content starts playing be it automatically or through a user interaction.
  ' @param {string} contentID The unique content identifier of the content being played.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackPlay = sub(contentID, dimensions, metrics)

    eventName = "Play"
    startEvent = false

    if m._initialized = false
      ProductAnalyticsLog("Cannot track play since Product Analytics is uninitialized.")
    else if (Type(contentID) <> "roString" OR contentID = "")
      ProductAnalyticsLog("Cannot track play since no contentID has been supplied.")
    else if (m._plugin.isStarted = false)
      m._pendingVideoEvents.push({ "eventName": eventName, "contentID": contentID, "dimensions": dimensions, "metrics": metrics, "startEvent": startEvent })
    else
      m._trackPlayerEventsPending()
      m._trackPlayerEvent(eventName, contentID, dimensions, metrics, startEvent)
    end if

  end sub

  ' Tracks content watching events.
  ' TODO: add (2nd) argument to tell whether user state must be updated or not
  ' @param {string} eventName The name of the interaction (i.e., Pause, Seek, Skip Intro, Skip Ads, Switch Language, etc.).
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track
  ' @param {boolean} [startEvent] Internal param informing that current interaction is responsible of first player start

  this.trackPlayerInteraction = sub(eventName, dimensions, metrics, startEvent)

    contentID = invalid

    if Type(startEvent) <> "roBoolean"
      startEvent = false
    end if

    if m._initialized = false
      ProductAnalyticsLog("Cannot track player interaction since Product Analytics is uninitialized.")
    else if (Type(eventName) <> "roString" OR eventName = "")
      ProductAnalyticsLog("Cannot track player interaction since no interaction name has been supplied.")
    else if ( m._plugin.isStarted = false )
      m._pendingVideoEvents.push({ "eventName": eventName, "contentID": contentID, "dimensions": dimensions, "metrics": metrics, "startEvent": startEvent })
    else
      m._trackPlayerEventsPending()
      m._trackPlayerEvent(eventName, contentID, dimensions, metrics, startEvent)
    end if

  end sub

  ' Track player pending events

  this._trackPlayerEventsPending = sub()

    for each event In m._pendingVideoEvents
      m._trackPlayerEvent(event["eventName"], event["contentID"], event["dimensions"], event["metrics"], event["startEvent"])
    next

    m._pendingVideoEvents = []

  end sub

  ' Track player event
  ' @param {*} eventName
  ' @param {*} contentID
  ' @param {*} dimensions
  ' @param {*} metrics
  ' @param {*} startEvent

  this._trackPlayerEvent = sub(eventName as string, contentID, dimensions, metrics, startEvent as boolean)
    ' Log message

    ProductAnalyticsLog("[PLAYER] " + eventName)

    ' Prepare dimensions

    dimensionsInternal = {
      "eventType": "ContentPlayback"
    }

    if (contentID <> invalid)
      dimensionsInternal["contentId"] = contentID
    end if

    ' Fire event

    m._fireEventVideo("[PLAYER] " + eventName, dimensionsInternal, dimensions, metrics)

    ' Transition state to active

    if ( startEvent = false )
      m._setActive(eventName)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' CONTENT SEARCH
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Tracks search query events.
  ' @param {string} searchQuery The search term entered by the user.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackSearchQuery = sub(searchQuery, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track search query since Product Analytics is uninitialized.")
    else if (Type(searchQuery) <> "roString" OR searchQuery = "")
      ProductAnalyticsLog("Cannot track search query since no searchQuery has been supplied.")
    else
      ProductAnalyticsLog("[SEARCH] Query " + searchQuery)
      m._searchQuery = searchQuery
      m._fireEvent("[SEARCH] Query", {
        "eventType": "ContentSearch",
        "query": m._searchQuery
      }, dimensions, metrics)
    end if

  end sub

  ' Tracks search result events.
  ' @param {integer} resultCount The number of search results returned by a search query.
  ' @param {String} [searchQuery] The search term entered by the user.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackSearchResult = sub(resultCount, searchQuery, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track search result since Product Analytics is uninitialized.")
    else if (Type(resultCount) <> "roInt" OR resultCount < 0)
      ProductAnalyticsLog("Cannot track search result since resultCount is invalid.")
    else

      if (Type(searchQuery) <> "roString" OR searchQuery = "")
        query = m._searchQuery
      else
        query = searchQuery
      end if

      ProductAnalyticsLog("[SEARCH] Results " + StrI(resultCount, 10))
      m._fireEvent("[SEARCH] Results", {
        "eventType": "ContentSearch",
        "query": query,
        "resultCount": resultCount
      }, dimensions, metrics)

    end if

  end sub

  ' Tracks user interactions with search results.
  ' @param {string} section The section title. It is commonly used to indicate the section title presented over a grid layout (e.g. Recommended Movies, Continue Watching, etc).
  ' @param {integer} sectionOrder The section order within the page.
  ' @param {integer} column The content placement column. It is commonly used to indicate the column number where content is placed in a grid layout (i.e.1, 2, etc..).
  ' @param {integer} row The content placement row. It is commonly used to indicate the row number where content is placed in a grid layout (i.e.1, 2, etc..).
  ' @param {string} contentID The content identifier. It is used for internal content unequivocally identification (i.e., AAA000111222).
  ' @param {String} [searchQuery] The search term entered by the user.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackSearchClick = sub(section, sectionOrder, column, row, contentID, searchQuery, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track search click since Product Analytics is uninitialized.")
    else if (Type(column) <> "roInt" OR column < 1)
      ProductAnalyticsLog("Cannot track search click since column is invalid.")
    else if (Type(row) <> "roInt" OR row < 1)
      ProductAnalyticsLog("Cannot track search click since row is invalid.")
    else if (Type(contentID) <> "roString" OR contentID = "")
      ProductAnalyticsLog("Cannot track search click since no contentID has been supplied.")
    else

      if (Type(searchQuery) <> "roString" OR searchQuery = "")
        query = m._searchQuery
      else
        query = searchQuery
      end if

      if (Type(section) <> "roString" OR section = "")
        section = "Search"
      end if

      if (Type(sectionOrder) <> "roInt" OR sectionOrder < 1)
        sectionOrder = 1
      end if

      ProductAnalyticsLog("[SEARCH] Result Click")

      m._fireEvent("[SEARCH] Result Click", {
        "eventType": "ContentSearch",
        "sectionOrder": sectionOrder,
        "section": section,
        "query": query,
        "column": column,
        "row": row,
        "contentId": contentID
      }, dimensions, metrics)

    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' EXTERNAL APPLICATIONS
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Tracks external app start events.
  ' @param {string} appName The name of the application being used to deliver the content to the end-user (i.e., Netflix).
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackExternalAppLaunch = sub(appName, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track external application launch since Product Analytics is uninitialized.")
    else if (Type(appName) <> "roString" OR appName = "")
      ProductAnalyticsLog("Cannot track external application launch since no appName has been supplied.")
    else
      ProductAnalyticsLog("APP LAUNCH " + appName)
      m._fireEvent("APP LAUNCH", {
        "eventType": "ExternalApplications",
        "appName": appName
      }, dimensions, metrics)
    end if

  end sub

  ' Tracks external app stop events.
  ' @param {string} appName The name of the application being used to deliver the content to the end-user (i.e., Netflix).
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackExternalAppExit = sub(appName, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track external application exit since Product Analytics is uninitialized.")
    else if (Type(appName) <> "roString" OR appName = "")
      ProductAnalyticsLog("Cannot track external application exit since no appName has been supplied.")
    else
      ProductAnalyticsLog("APP EXIT " + appName)
      m._fireEvent("APP EXIT", {
        "eventType": "ExternalApplications",
        "appName": appName
      }, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' ENGAGEMENT
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Tracks engagement events.
  ' @param {string} eventName The name of the engagement event (i.e., Share, Save, Rate, etc.).
  ' @param {string} contentID The unique content identifier of the content the user is engaging with.
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackEngagementEvent = sub(eventName, contentID, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track engagement event since Product Analytics is uninitialized.")
    else if (Type(eventName) <> "roString" OR eventName = "")
      ProductAnalyticsLog("Cannot track engagement event since no eventName has been supplied.")
    else if (Type(contentID) <> "roString" OR contentID = "")
      ProductAnalyticsLog("Cannot track engagement event since no contentID has been supplied.")
    else
      ProductAnalyticsLog(eventName)
      m._fireEvent(eventName, {
        "eventType": "Engagement",
        "contentId": contentID
      }, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' CUSTOM EVENT
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Track custom event
  ' @param {string} eventName Name of the event to track
  ' @param {Object} [dimensions] Dimensions to track
  ' @param {Object} [metrics] Metrics to track

  this.trackEvent = sub(eventName, dimensions, metrics)

    if m._initialized = false
      ProductAnalyticsLog("Cannot track event since Product Analytics is uninitialized.")
    else if (Type(eventName) <> "roString" OR eventName = "")
      ProductAnalyticsLog("Event cannot be tracked since no eventName has been supplied.")
    else
      ProductAnalyticsLog(eventName)
      m._fireEvent(eventName, {
        "eventType": "CustomEvent"
      }, dimensions, metrics)
    end if

  end sub

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' STATE MANAGEMENT
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Start tracking user state

  this._userStateStart = sub()

    if m._initialized AND m._productAnalyticsSettings.enableStateTracking
      m._storeUserState(m._userStates.passive)
    end if
    
  end sub

  ' Stop tracking user state

  this._userStateStop = sub()

    if m._initialized AND m._productAnalyticsSettings.enableStateTracking
      m._userStateTimeout.state = "stop"
      m._userState = m._userStates.passive
    end if

  end sub

  ' Set active state
  ' @param {string} eventName
  ' @param {boolean} playerStarted

  this._setActive = sub(eventName as string)

    if m._initialized AND m._productAnalyticsSettings.enableStateTracking

      state = m._userStates.active

      if (m._userState <> state)
        m._fireEventState(state, eventName)
        m._storeUserState(state)
      end if

      m._userStateTimeout.control = "stop"
      m._userStateTimeout.control = "start"

    end if

  end sub

  ' Set user state as passive after a timeout

  this.setPassive = sub()

    if m._initialized AND m._productAnalyticsSettings.enableStateTracking

      state = m._userStates.passive

      m._fireEventState(state, "timer")
      m._storeUserState(state)

    end if

  end sub

  ' Fire switch state event
  ' @private

  this._fireEventState = sub(state as string, eventName as string)

    ProductAnalyticsLog("User changing from state " + m._userState + " to " + state)

    dimensions = {
      "eventType": "ContentPlayback",
      "newState": state,
      "triggerEvent": eventName,
      "stateFromTo": m._userState + " to " + state
    }

    ' Fire the event

    if ( state = m._userStates.active )
      m._fireEventVideo("[PLAYBACK STATE] Switch to Active", dimensions, invalid, invalid)
    else if ( state = m._userStates.passive )
      m._fireEventVideo("[PLAYBACK STATE] Switch to Passive", dimensions, invalid, invalid)
    end if

  end sub

  ' Store state
  ' @param {string} state
  ' @private

  this._storeUserState = sub(state as string)

    if m._plugin = invalid OR m._plugin.infoManager = invalid OR m._plugin.infoManager.options = invalid
      ProductAnalyticsLog("Cannot track user state since plugin options are unavailable.")
    else
      m._userState = state
      m._plugin.infoManager.options.Append(m.getOptions())
    end if

  end sub

  ' Get options

  this.getOptions = function() as object

    options = {}

    if ( m._initialized AND m._productAnalyticsSettings.enableStateTracking )
      options[m._userStateDimension] = m._userState
    end if

    return options

  end function

  ' ------------------------------------------------------------------------------------------------------------------------------
  ' INTERNAL
  ' ------------------------------------------------------------------------------------------------------------------------------

  ' Fires an event
  ' @param {string} eventName Name of the event to be fired
  ' @param {Object} dimensionsInternal Dimensions supplied by user
  ' @param {Object} dimensionsUser Specific event dimensions
  ' @param {Object} metrics Metrics to track
  ' @private

  this._fireEvent = sub(eventName as string, dimensionsInternal, dimensionsUser, metrics)

    ' Extract top level dimensions from custom dimensions

    dimensions = m._buildDimensions(dimensionsInternal, dimensionsUser)

    ' Track event

    if (m._plugin = invalid)
      ProductAnalyticsLog("Cannot fire " + eventName + " since plugin is unavailable.")
    else

      params = {
          "name": eventName,
          "dimensions": dimensions["custom"],
          "values": metrics
        }

      params.Append(dimensions["top"])

      m._plugin.eventHandler("sessionEvent", params)

    end if

  end sub

  ' Fires a video event (in case it is available)
  ' @param {string} eventName Event name
  ' @param {Object} dimensionsInternal Dimensions supplied by user
  ' @param {Object} dimensionsUser Specific event dimensions
  ' @param {Object} metrics Metrics to track
  ' @private

  this._fireEventVideo = sub(eventName as string, dimensionsInternal as object, dimensionsUser as object, metrics as object)

    dimensions = m._buildDimensions(dimensionsInternal, dimensionsUser)

    if ( m._plugin = invalid )

      ProductAnalyticsLog("Cannot fire " + eventName + " video event since plugin is unavailable.")

    else

      params = { 
          "name": eventName,
          "dimensions": dimensions.custom, 
          "values": metrics
        }
      params.Append(dimensions.top)

      m._plugin.eventHandler("event", params)

    end if

  end sub

  ' Builds a list of top level and custom dimensions
  ' @param {Object} dimensionsInternal Object containing list of internal dimensions
  ' @param {Object} dimensionsUser Object containing list of custom dimensions
  ' @private

  this._buildDimensions = function(dimensionsInternal as object, dimensionsUser as object)

    ' Build custom event dimensions

    dimensionsCustom = {"page": m._page}

    if ( dimensionsInternal <> invalid )
      dimensionsCustom.Append(dimensionsInternal)
    end if

    if ( dimensionsUser <> invalid )
      dimensionsCustom.Append(dimensionsUser)
    end if

    dimensionsCustom.Append({"eventSource": "Product Analytics"})

    ' List of Top Level Dimension keys

    topKeys = ["contentid", "contentId", "contentID", "utmSource", "utmMedium", "utmCampaign", "utmTerm", "utmContent", "profileId", "profile_id"]
    topKeysDelete = ["contentid", "contentId", "contentID", "profileId", "profile_id"]

    ' Create object with top level dimensions

    dimensionsTopLevel = {}

    for each key in dimensionsCustom
      if (m._contained(topKeys, key))
        dimensionsTopLevel[key] = dimensionsCustom[key]
      end if
    next

    ' Remove top level dimensions from custom dimensions list

    for each key in topKeysDelete
      dimensionsCustom.Delete(key)
    next

    return {"custom": dimensionsCustom, "top": dimensionsTopLevel}

  end function

  ' String is contained in array

  this._contained = function(arr as Object, str as String) as Boolean

    For Each item In arr
        If item = str Then 
            Return True
        End If
    End For
    Return False

  end function
 
  return this

end function

function ProductAnalyticsLog(message)

  YouboraLog(message, "Product Analytics")

end function