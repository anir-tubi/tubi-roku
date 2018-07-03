'*********************************************************************
'** (c) 2016-2017 Roku, Inc.  All content herein is protected by U.S.
'** copyright and other applicable intellectual property laws and may
'** not be copied without the express permission of Roku, Inc., which
'** reserves all rights.  Reuse of any of this content for any purpose
'** without the permission of Roku, Inc. is strictly prohibited.
'*********************************************************************

sub init()
    'we use a simple LabelList for a menu
    m.list = m.top.FindNode("list")
    m.list.observeField("itemSelected", "onItemSelected")
    m.list.SetFocus(true)

    'descriptor for the menu items
    itemList = [
        {
            title: "Baseline: Roku ad server (default server URL, single pre-roll)"
            url: "" 'point to your own ad server if doing "inventory split" revenue share
        }
        {
            ' notificationInterval, cuepoint, visibility, control thread
            title: "A: 0.5s, 00:05, true, task"
            ' From https://developers.google.com/interactive-media-ads/docs/sdks/html5/tags
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 0.5
            video_node_visible: true
            relay_position: false
        }
        {
            title: "B: 1.0s, 00:05, true, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 1.0
            video_node_visible: true
            relay_position: false
        }
        {
            title: "C: 0.5s, 00:05.5, true, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 0.5
            video_node_visible: true
            relay_position: false
        }
        {
            title: "D: 1.0s, 00:05.5, true, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 1.0
            video_node_visible: true
            relay_position: false
        }
        {
            title: "E: 0.5s, 00:05, false, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 0.5
            video_node_visible: false
            relay_position: false
        }
        {
            title: "F: 1.0s, 00:05, false, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 1.0
            video_node_visible: false
            relay_position: false
        }
        {
            title: "G: 0.5s, 00:05.5, false, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 0.5
            video_node_visible: false
            relay_position: false
        }
        {
            title: "H: 1.0s, 00:05.5, false, task"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 1.0
            video_node_visible: false
            relay_position: false
        }
        
        {
            title: "I: 0.5s, 00:05, true, render"
            ' From https://developers.google.com/interactive-media-ads/docs/sdks/html5/tags
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 0.5
            video_node_visible: true
            relay_position: true
        }
        {
            title: "J: 1.0s, 00:05, true, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 1.0
            video_node_visible: true
            relay_position: true
        }
        {
            title: "K: 0.5s, 00:05.5, true, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 0.5
            video_node_visible: true
            relay_position: true
        }
        {
            title: "L: 1.0s, 00:05.5, true, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 1.0
            video_node_visible: true
            relay_position: true
        }
        {
            title: "M: 0.5s, 00:05, false, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 0.5
            video_node_visible: false
            relay_position: true
        }
        {
            title: "N: 1.0s, 00:05, false, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_integer: 5
            notification_interval: 1.0
            video_node_visible: false
            relay_position: true
        }
        {
            title: "O: 0.5s, 00:05.5, false, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 0.5
            video_node_visible: false
            relay_position: true
        }
        {
            title: "P: 1.0s, 00:05.5, false, render"
            url: "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
            midroll_position_float: 5.5
            notification_interval: 1.0
            video_node_visible: false
            relay_position: true
        }
    ]

    ' compile into a ContentNode structure
    listNode = CreateObject("roSGNode", "ContentNode")
    for each item in itemList:
        nod = CreateObject("roSGNode", "ContentNode")
        nod.addField("midroll_position_float", "float", false)
        nod.addField("midroll_position_integer", "integer", false)
        nod.addField("notification_interval", "float", false)
        nod.addField("relay_position", "float", false)
        nod.addField("video_node_visible", "boolean", false)
        nod.setFields(item)
        listNode.appendChild(nod)
    next
    m.list.content = listNode

end sub

sub onItemSelected()
    m.list.SetFocus(false) ' un-set focus to avoid creating multiple players on user tapping twice
    menuItem = m.list.content.getChild(m.list.itemSelected)

    videoContent = {

        streamFormat: "mp4",
        titleSeason: "Art21 Season 3",
        title: "Place",
        url: "https://s3.amazonaws.com/veeta-test-media/stmpte-bars-timestamp.mp4"

        'used for raf.setContentGenre(). For ads provided by the Roku ad service, see docs on 'Roku Genre Tags'
        categories: ["Documentary"]

        'Roku mandates that all channels enable Nielsen DAR
        nielsen_app_id: "P2871BBFF-1A28-44AA-AF68-C7DE4B148C32" 'required, put "P2871BBFF-1A28-44AA-AF68-C7DE4B148C32", Roku's default appId if not having ID from Nielsen
        nielsen_genre: "DO" 'required, put "GV" if dynamic genre or special circumstances (e.g. games)
        nielsen_program_id: "Art21" 'movie title or series name
        length: 3220 'in seconds;

    }
    ' compile into a VideoContent node
    content = CreateObject("roSGNode", "VideoContent")
    content.setFields(videoContent)
    content.ad_url = menuItem.url
    if menuItem.midroll_position_integer <> invalid
      content.midroll_position_integer  = menuItem.midroll_position_integer
    end if
    if menuItem.midroll_position_float <> invalid
      content.midroll_position_float  = menuItem.midroll_position_float
    end if
    if menuItem.relay_position <> invalid
      content.relay_position = menuItem.relay_position
    end if
    if menuItem.notification_interval <> invalid
      content.notification_interval = menuItem.notification_interval
    end if

    if m.Player = invalid:
        m.Player = m.top.CreateChild("Player")
        m.Player.observeField("state", "PlayerStateChanged")
    end if

    'start the player
    m.Player.content = content
    m.Player.visible = true
    m.Player.control = "play"
end sub

sub PlayerStateChanged()
    print "EntryScene: PlayerStateChanged(), state = "; m.Player.state
    if m.Player.state = "done" or m.Player.state = "stop"
        m.Player.visible = false
        m.list.setFocus(true) 'NB. the player took the focus away, so get it back
    end if
end sub
