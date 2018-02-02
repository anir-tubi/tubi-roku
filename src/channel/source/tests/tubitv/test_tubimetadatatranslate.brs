Function testTranslateTypes(t As Object)
  constants = getConstants()
  serverContentTypes = {
    "c": constants.ui.contentTypes.category
    "clip": constants.ui.contentTypes.video
    "v": constants.ui.contentTypes.video
    "s": constants.ui.contentTypes.series
    "a": constants.ui.contentTypes.season
  }

  source = {
    id: "12345"
    type: ""
  } 
  translate = TubiMetadataTranslate(constants)

  for each contentType in serverContentTypes
    dest = CreateObject("roSGNode", "TubiContentNode")
    source.type = contentType
    translate.translateRecursive(source, dest)
    if contentType = "s" or contentType = "a"
      t.assertEqual("0" + source.id, dest.id)
    else
      t.assertEqual(source.id, dest.id)
    end if
    t.assertEqual(dest.type, serverContentTypes[contentType])
  end for
  ' check invalid types too
  source.type = ""
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertEqual(dest.type, "")
End Function


Function testParentTypes(t As Object)
  constants = getConstants()
  parentContentTypes = [
    ' valid parent types
    constants.ui.contentTypes.series
    constants.ui.contentTypes.season
    ' missing or unrecognized parent types
    invalid
    ""
    "SomeInvalidType"
  ]

  source = {
    id: "12345"
    type: "v"
  } 
  translate = TubiMetadataTranslate(constants)

  for each contentType in parentContentTypes
    parent = CreateObject("roSGNode", "TubiContentNode")
    parent.id = "parent"
    parent.type = contentType
    child = parent.createChild("TubiContentNode")
    translate.translateRecursive(source, child)
    if contentType = constants.ui.contentTypes.series or contentType = constants.ui.contentTypes.season
      t.assertEqual(child.parentId, parent.id)
    else
      t.assertEqual(child.parentId, "")
    end if
  end for
End Function

Function testCreditsCuepoints(t As Object)
  constants = getConstants()
  translate = TubiMetadataTranslate(constants)

  ' normal cuepoint
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 550
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 600)
  t.assertTrue(dest.creditsCuepoint = 550)

  ' default cuepoint
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 0
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 600)
  t.assertTrue(dest.creditsCuepoint = 560)

  ' missing cuepoints
  source = {
    id: "12345"
    type: "v"
    duration: 600
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 600)
  t.assertTrue(dest.creditsCuepoint = 560)

  ' cuepoint too close to the end
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 595
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 600)
  t.assertTrue(dest.creditsCuepoint = 560)

  ' no cuepoint or length given
  source = {
    id: "12345"
    type: "v"
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 0)
  t.assertTrue(dest.creditsCuepoint = 0)

  ' title isn't long enough for default cuepoint placement (no cuepoints)
  source = {
    id: "12345"
    type: "v"
    duration: 10
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 10)
  t.assertTrue(dest.creditsCuepoint = 0)

  ' title isn't long enough for default cuepoint placement (no cuepoints)
  source = {
    id: "12345"
    type: "v"
    duration: 10
    credit_cuepoints: {
      prologue: 0
      postlude: 8
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(source, dest)
  t.assertTrue(dest.length = 10)
  t.assertTrue(dest.creditsCuepoint = 0)
End Function
