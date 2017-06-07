'''''''''''
' NodePool
'
' A very simple implementation of a pool of nodes.  This
' can be used as a reusable set of nodes or simply a cache
' of precreated nodes that may be used once.
'
' The 'preCreateSize' determines how many are available at first,
' and the pool grows as items are needed.  
'
' NOTE!: The pool never shrinks in size unless the whole nodepool gets
'        garbage collected. Be sure to release nodes if they become unused
Function createNodePool(nodeType As String, preCreateSize As Integer)
  free = []
  for i=0 to preCreateSize-1
    free.push(CreateObject("roSGNode", nodeType))
  end for

  return {
    used: []
    free: free
    nodeType: nodeType
    get: nodePool_getNode
    release: nodePool_releaseNode
    printStats: nodePool_printStats
  }
End Function


' Find an unused node, or create one if necessary
Function nodePool_getNode() As Object
  if m.free.count() = 0 then
    m.free.push(CreateObject("roSGNode", m.nodeType))
  end if

  node = m.free.shift()
  m.used.push(node)
  'm.printStats("get")
  return node
End Function

' Release a used node back to the pool of unused nodes
Function nodePool_releaseNode(node As Object) As Void
  if node <> invalid then
    for i=0 to m.used.count()-1
      if m.used[i].isSameNode(node) then
        m.used.Delete(i)
        m.free.push(node)
        exit for
      end if
    end for
  end if
  'm.printStats("release")
End Function

Function nodePool_printStats(func as String)
  print "[NodePool:" + func + ":" + m.nodeType + "] " + stri(m.used.count()) + "/" + stri(m.used.count() + m.free.count()) 
End Function
