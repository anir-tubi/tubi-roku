function BL_Overlay ( creative as Object, canvas as Object, context = {} as Object ) as Object
  this = {
    ' properties
    className:                     "[ BL_Overlay ]"
    creative:                      creative
    canvas:                        canvas
    context:                       context
    displayMode:                   "HD"
    currentState:                  invalid
    defaultLayerIndex:             10
    usedLayerIndexes:              {}
    keys:                          BL_getRemoteKeys()
    ' methods
    initialize:                    BL__overlayInitialize
    drawState:                     BL__overlayDrawState
    clear:                         BL__overlayClear
    doAction:                      BL__overlayDoAction
    onKeyPressed:                  BL__overlayOnKeyPressed
    onVideoPlayerPlaybackPosition: BL__overlayOnVideoPlayerPlaybackPosition
  }

  canvasRect = this.canvas.GetCanvasRect()

  if canvasRect.w <= 720 then
    this.displayMode = "SD"
  end if

  print this.className; " > "; this.displayMode

  this.initialize()

  return this
end function



' DO NOT CALL THE BELOW METHODS DIRECTLY



' need creative to have the following properties:
'   states
'   actions
'   initialState
sub BL__overlayInitialize ()
  if type(m.creative) = "roAssociativeArray" and m.creative.states <> invalid and m.creative.actions <> invalid and m.creative.initialState <> invalid then
    m.states       = m.creative.states
    m.actions      = m.creative.actions
    m.initialState = m.creative.initialState

    if m.creative.timeline <> invalid then
      m.timeline   = m.creative.timeline
    end if

    m.drawState( m.initialState )
  else
    print m.className; " > INITIALIZE ERROR"
  end if
end sub

sub BL__overlayDrawState ( stateName )
  if m.states[stateName] <> invalid then
    ' hd or sd
    if m.displayMode = "HD" then
      layerMode = "hdLayers"
    else
      layerMode = "sdLayers"
    end if

    layers = m.states[stateName][layerMode]

    if layers <> invalid then
      ' set current state
      m.currentState = stateName

      layerIndex = invalid

      m.canvas.AllowUpdates(false)

      for each layer in layers
        if type(layer.content) = "roArray" then
          layerIndex = m.defaultLayerIndex
          if layer.index <> invalid then
            layerIndex = layer.index
          end if

          m.usedLayerIndexes[ Stri(layerIndex) ] = layerIndex
          m.canvas.SetLayer( layerIndex, layer.content )

        end if
      end for

      m.canvas.AllowUpdates(true)
    end if
  end if
end sub

sub BL__overlayClear ()
  for each i in m.usedLayerIndexes
    m.canvas.ClearLayer( m.usedLayerIndexes[i] )
  end for

  m.usedLayerIndexes.Clear()
end sub

sub BL__overlayOnKeyPressed ( keyCode as Integer )
  key = m.keys[ keyCode ]
  
  if key <> invalid and (key = "up" or key = "back")
    stateActionsExit = {
      up: "exit"
      back: "exit"
    }
    m.states[m.currentState].actions.append(stateActionsExit)

    m.actions.exit = {
      type: "exit"
      target: invalid
    }
  end if

  ' print "BL__overlayOnKeyPressed "; key

  if key <> invalid and m.currentState <> invalid and m.states[ m.currentState ] <> invalid then
    currentState = m.states[ m.currentState ]
    if currentState.actions <> invalid and currentState.actions[ key ] <> invalid then
      m.doAction( currentState.actions[ key ] ) 
    end if
  end if
end sub

sub BL__overlayDoAction ( actionName as Object )
  ' print "BL__overlayDoAction "; actionName

  action = m.actions[ actionName ]

  if action <> invalid and action.type <> invalid then
    if action.type = "changeState" and action.target <> invalid then
      m.drawState( action.target )

    else if action.type = "launchMicrosite" and action.target <> invalid then
      if m.context.launchMicrosite <> invalid then
        m.context.launchMicrosite( action.target )
      end if

    else if action.type = "exit" then
      m.context.onVideoPlayerPartialResult( false )
      m.context.videoPlayer.Stop()
      m.context.close()
    end if
  end if
end sub

sub BL__overlayOnVideoPlayerPlaybackPosition ( videoPosition as Integer )
  if type(m.timeline) = "roArray" then
    for each tl in m.timeline
      if type(tl) = "roAssociativeArray" and tl.ts = videoPosition then
        m.drawState( tl.state )
      end if
    end for
  end if
end sub