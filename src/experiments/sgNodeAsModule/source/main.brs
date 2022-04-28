Function Main(startupArgs)
  ' this version of constants will be the constants that are part of the submitted build (or the side loaded build)
  ' and only exist in the main brightscript thread.
  ' constants will be reset in remote components for scene graph
  m.appStartTime = UpTime(0)
  m.startupArgs = startupArgs

  tfl = testFunctionLib()

  someThings = {
    a: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    b: 18790765
    c: {}
    e: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    f: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    g: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    h: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    i: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    j: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
    k: "adfssssssssssffdfdafsafasfsafasdfsafsafsafsfdasafdsafsafsafsadfdsaf"
  }

  counter = 50000
  testTimer = createObject("roTimespan")

  ' ////////////////////////////////////////////////////////////////////////////////////
  ' pass no values, return invalid
  for i = 0 to counter
    tubi_testFunction1()
  end for
  basicTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " basic function calls passing no values, returning invalid"; basicTime; ";  ms/call: "; basicTime/counter


  for i = 0 to counter
    tfl.testFunction1()
  end for
  aaTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " aa function calls passing no values, returning invalid"; aaTime; ";  ms/call: "; aaTime/counter


  tfn = CreateObject("roSGNode", "TesterNode")
  for i = 0 to counter
    tfn.callFunc("tubi_testFunction1")
  end for
  nodeTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " node function calls passing no values, returning invalid"; nodeTime; ";  ms/call: "; nodeTime/counter
  print ""


  ' ////////////////////////////////////////////////////////////////////////////////////
  ' pass an AA, return invalid
  for i = 0 to counter
    tubi_testFunction2(someThings)
  end for
  basicTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " basic function calls passing an AA, returning invalid"; basicTime; ";  ms/call: "; basicTime/counter


  for i = 0 to counter
    tfl.testFunction2(someThings)
  end for
  aaTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " aa function calls passing an AA, returning invalid"; aaTime; ";  ms/call: "; aaTime/counter


  tfn = CreateObject("roSGNode", "TesterNode")
  for i = 0 to counter
    tfn.callFunc("tubi_testFunction2", someThings)
  end for
  nodeTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " node function calls passing an AA, returning invalid"; nodeTime; ";  ms/call: "; nodeTime/counter
  print ""

  ' ////////////////////////////////////////////////////////////////////////////////////
  ' pass an AA, return an AA
  for i = 0 to counter
    aa = tubi_testFunction3(someThings)
  end for
  basicTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " basic function calls passing an AA, returning an AA"; basicTime; ";  ms/call: "; basicTime/counter


  for i = 0 to counter
    aa = tfl.testFunction3(someThings)
  end for
  aaTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " aa function calls passing an AA, returning an AA"; aaTime; ";  ms/call: "; aaTime/counter


  tfn = CreateObject("roSGNode", "TesterNode")
  for i = 0 to counter
    aa = tfn.callFunc("tubi_testFunction3", someThings)
  end for
  nodeTime = testTimer.totalMilliseconds()
  testTimer.mark()

  print "Time (in ms) for "; counter " node function calls passing an AA, returning an AA"; nodeTime; ";  ms/call: "; nodeTime/counter
End Function