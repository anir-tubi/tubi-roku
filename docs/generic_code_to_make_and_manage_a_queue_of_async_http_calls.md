# tubiq: a queue of async http calls

=====

## Requirements

1. Marios Assiotis via email: 
> The "async request queue" is for making regular HTTP calls. By async, I mean that it shouldn't block any rendering threads. It doesn't necessarily have to be a queue, but you may find it advantageous to implement it as such as to not overload the device. For example, if you are prefetching content, you may fire 20-30 calls (one for each category), the response of each one you may need, but not right away. Similarly, as you pointed out, things like analytics do not necessarily require a response, so they can be fire & forget. This kind of infrastructure is fairly commonplace outside Roku, but if you guys think this is overkill, let me know. 
All that being said, you should assume that the backend fails from time to time and latency can fluctuate wildly. Therefore it is paramount that the http handling code is resilient despite variable latency and does not exhibit unpredictable behavior under failures."

2. From Scope of Work: 
> "There should be no Tubi TV specific parts in this work, at this point we should be able to open source the entire project as a starter­kit."

3. From Scope of Work: 
> "Generic code to make and manage a queue of async http calls""

4. Verbally
> "Roku silently drops HTTP requests at some max number [RAF requests]"


## Target Use cases

1. Ad tracking
    a. many requests are started quickly within the context of a single ad unit.  
    a. Context is video player message loop, so single MessagePort is used for all requests. 
    a. References to roUrlTransfer need to be tracked until requests are finished
    a. Responses aren't needed, except to verify success

2. CMS content
    a. Requests possibly started by multiple Screens or SceneGraph components
    b. Responses are needed by various Screens or Nodes to render content



## Technical Design

**Behavior**

- If a `maxSize` is non-zero for the queue, new incoming requests will not be added to the queue once it is full.
- If a `timeout` is non-zero (default 30s), longer running requests will be garbage collected in handleRequest, pushRequest, getResponse, and cancelRequest functions
- New requests are started as soon as they are added to the queue



### Coding standards

* Don't assume m is global AA from BrightScript, best not to use it at all.
* Don't use global settings through m, leave that as business logic at higher level.  If we need a global setting, pass it in as a parameter to the createHTTPRequestQueue object.

### Non-requirements

HTTP-specific features which should probably be separate from queue management, mainly because they are also needed for single requests as well.

- Retries (possibly with backoff algorithm)
- Interpretation of HTTP codes (4xx)

Business logic features which should be separate from queue managment

- caching of responses to be made available to the app globally for a long duration (metadata prefetches)
- parsing responses into Content Meta-data usable by SceneGraph or Screen components



## Public Interfaces

### Request.brs

```
''''''''''''''''''''''''
' createAsyncHTTPRequest() - helper to create an async reqeust
'
' url - The URL (with or without query params) to request
' name (optional) - a human readable name for the request, to track in logs
' options (optional) - options to tune the behavior of the request
'         valid Options:
'               method - HTTP method as string: GET, PUT, POST, or DELETE
'               params - assoc array of URL query params
'               body - PUT or POST body as string
'               headers - assoc array of headers and their values
'
Function createAsyncHTTPRequest(url as String, name = "" as String, options={} As Object) as Object
```

```
'''''''''''''''''''''''
' start - Prep the roUrlTransfer object and initiate the request
'   
' urltransfer_or_messageport - a roUrlTransfer or roMessagePort object; 
'
'     If roUrlTransfer is passed, the object is used to execute the request and events
'     send to the roMessagePort already associated with the roUrlTransfer object.
'
'     If roMessagePort is passed, a roUrlTransfer object is allocated and 
'     events will be sent to the roMessagePort provided.
'
Function tubihttp_start(urltransfer_or_messageport As Object) As Boolean
```

```
'''''''''''''''''''''''
' handleEvent - ingest a received message.  If the message is not
'               relevant to this request, return invalid.  If there is a
'               response available, it is returned. Requests will be
'               retried on failures.
'
' message - the roUrlEvent received on the caller's roMessagePort
'
Function tubihttp_handleEvent(message As Object) As Object
```



### RequestQueue.brs

```
'''''''''''''''''
' createHTTPRequestQueue - create and initialize a request queue
'
' port - the message port used by the caller's main loop, where roUrlTransfer objects will send events
' maxSize - the maximum depth of queue, or 0 if no limit
' timeout - seconds before expiring the request, default 30
'
Function createHTTPRequestQueue(port As Object, maxSize=0 As integer, timeout=30 As Integer) As Object
```

```
''''''''''''''''
' pushRequest - add a request to the queue and start the request
'  
' request - a request created by createAsyncHTTPRequest
'     
Function tubiq_pushRequest(request As Object) As Object

```

```
'''''''''''''''''
' handleEvent - Handle a roUrlEvent received by the message port, returns the request id which had changed.
'
' event - an event received on the message port assigned to this queue; events besides roUrlEvent will
'         be ignored
'
Function tubiq_handleEvent(event As Object) As Object
```


```
'''''''''''''''''
' count - Return the number of requests currently in the queue
'
Function tubiq_count()
```

```
'''''''''''''''''
' clear - Cancel all outstanding requests
'
Function tubiq_clear()
```



## Usage Examples
	
### Asynchronous use case - screen port

	port = CreateObject(“roMessagePort”)
	request = createHTTPRequest(...)
    request.start(port)
	while true
		msg = wait(0, port)
		if type(msg) = "roUrlEvent" then ' optional check
            response = request.handleEvent(msg)
			if response <> invalid then
			    print "Got Response  + response.data
			end if
		end if
	end while

### Asynchronouse use case - many requests, not using a request queue

	port = CreateObject(“roMessagePort”)	
	requests = {
		first: createHTTPRequest(…)
		second: createHTTPRequest(…)
	}
	requests.first.start(port)
	requests.second.start(port)
	while true
		msg = wait(0, port)
		if type(msg) = "roUrlEvent" then
			for each r in requests
				response = requests[r].handleEvent(msg)
				if response <> invalid then
					print "Received response for " + r
				end if
			end for
	end while

### Request Queue use case
	q = createHTTPRequestQueue(…)
	port = CreateObject(“roMessagePort”)
	q.setPort(port)

	r = createHTTPRequest(…)
	reqid = q.pushRequest(r)
	q.start()
	msg = wait(0, port)
	respid = q.handleEvent(msg)
	response = q.getResponse(respid)
	


## HTTP Requests Reference

Categoriation of HTTP calls made by the existing Tubi TV channel

| Category | Example URLs<br>extracted from current code |
| -------- | ------------------------------------------- |
| Roku ECP | “http://"+ipAddr+":8060/query/apps”<br>”http://"+ipAddr+":8060/launch/11?contentID="+contentID<br>"http://"+ipAddr+":8060/launch/"+contentID |
| Ads | "http://ads.adrise.tv/?platform=roku…”<br>"http://ads.adrise.tv/cue-points/?format=json&pubid=" |
| CMS |	"http://cms.adrise.com/v3/livetv?cid=roku..."<br>"http://cms.adrise.com/v2/app.php?&id=…”<br>"http://cms.adrise.com/v2/videos.php?…”<br>"http://cms.adrise.com/v2/app.php?id=…”<br>"http://cms.adrise.com/v2/videos.php?…” |
| DEPRECATED VEZO LINKING | "http://vezo.tv//authenticateVezoApp?deviceId=roku_"<br>"http://vezo.tv//linkToVezo?deviceId=roku_….” |
| Tubi Analytics/Events | “http://cms.adrise.com/extEvent?events=“ (non-ad events) |
| Ad tracking (urls from inside ad units) | skippable ads tracking: “send the appropriate amount of tracking pixels depending on the XML structure”<br>clickable ads<br>	adUnit.clickTrack<br>adUnit.impTrack<br>adUnit.viewthru[percentage] |
| Tubi UAPI (authenticated) | "https://uapi.adrise.tv/user_device/logout"<br>"https://uapi.adrise.tv/user_device/login/refresh”<br>"https://uapi.adrise.tv/user_device/login/migrate”<br>"https://uapi.adrise.tv/user_device/queues”<br>"https://uapi.adrise.tv/user_device/histories"<br>"https://uapi.adrise.tv/user_device/code/sms/generate”<br>"https://uapi.adrise.tv/user_device/code/generate”<br>"https://uapi.adrise.tv/user_device/code/status<br>"https://uapi.adrise.tv/cms/contents?platform=…”<br>“https://uapi.adrise.tv/cms/contents?platform=…” |
| PPV event tracking |	"http://ads.adrise.tv/track/ppv.php?cid=“ |
| Hot patches |	"http://cdn.adrise.com/hotpatches/roku/11.brs" |




