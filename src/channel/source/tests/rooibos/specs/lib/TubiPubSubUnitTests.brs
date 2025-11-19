'@TestSuite [TubiPubSub] TubiPubSub.brs

'@BeforeEach
Function tubiPubsub_tests_beforeEach()
  ' since the context is not a node, mock an m.top.findNode()
  m.top = {
    component: invalid
    findNode: Function(id = "")
      return m.component
    End Function
  }

  m.pubsub = TubiPubSub(m)
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiPubSub.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test unit tests tubiPubSub_subscribe
Function tubiPubSub_subscribe_test()
  subscriber = CreateObject("roSGnode", "ContentNode")
  subscriber.id = "the_subscriber"
  m.someString = "aaa"
  m.anotherString = "bbb"
  m.someAA = {}

  ' test subscribing to something not on m.
  success = m.pubsub.subscribe("notOnM", subscriber, "title")
  m.assertInvalid(m.pubsub.publications["notOnM"])
  m.assertEqual(m.pubsub.publications.count(), 0)
  m.assertFalse(success)

  ' test subscribing with a field that doesn't exist on the subscriber
  success = m.pubsub.subscribe("someString", subscriber, "nonExistentField")
  m.assertInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications.count(), 0)
  m.assertFalse(success)

  ' test subscribing when the subscriber doesn't exist
  fakeSubscriber = invalid
  success = m.pubsub.subscribe("someString", fakeSubscriber, "nonExistentField")
  m.assertInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications.count(), 0)
  m.assertFalse(success)

  ' test subscribing to something simple on m.
  success = m.pubsub.subscribe("someString", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertTrue(success)

  ' test subscribing to a 2nd simple thing on m.
  success = m.pubsub.subscribe("anotherString", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["anotherString"])
  m.assertNotInvalid(m.pubsub.publications["anotherString"]["anotherString"])
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 2)
  m.assertTrue(success)

  ' test subscribing to something nested on m.
  success = m.pubsub.subscribe("someAA.is.nested", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertNotInvalid(m.pubsub.publications["anotherString"])
  m.assertNotInvalid(m.pubsub.publications["anotherString"]["anotherString"])
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["anotherString"]["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 3)
  m.assertTrue(success)

  ' test subscribing to a 2nd nested thing on m.
  success = m.pubsub.subscribe("someAA.is.also.nested", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"]["the_subscriber"], "title")
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.also.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.also.nested"]["the_subscriber"], "title")
  m.assertNotInvalid(m.pubsub.publications["anotherString"])
  m.assertNotInvalid(m.pubsub.publications["anotherString"]["anotherString"])
  m.assertEqual(m.pubsub.publications["anotherString"]["anotherString"]["the_subscriber"], "title")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"]["the_subscriber"], "title")
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["anotherString"]["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someAA"].count(), 2)
  m.assertEqual(m.pubsub.publications.count(), 3)
  m.assertTrue(success)

  ' test subscribing a second component/field to an existing subscription
  secondSubscriber = CreateObject("roSGnode", "ContentNode")
  secondSubscriber.id = "second_subscriber"

  success = m.pubsub.subscribe("someString", secondSubscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"]["the_subscriber"], "title")
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.also.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.also.nested"]["the_subscriber"], "title")
  m.assertNotInvalid(m.pubsub.publications["anotherString"])
  m.assertNotInvalid(m.pubsub.publications["anotherString"]["anotherString"])
  m.assertEqual(m.pubsub.publications["anotherString"]["anotherString"]["the_subscriber"], "title")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"]["the_subscriber"], "title")
  m.assertEqual(m.pubsub.publications["someString"]["someString"]["second_subscriber"], "title")
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 2)
  m.assertEqual(m.pubsub.publications["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["anotherString"]["anotherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someAA"].count(), 2)
  m.assertEqual(m.pubsub.publications.count(), 3)
  m.assertTrue(success)
End Function


'@Test unit tests tubiPubSub_publish
Function tubiPubSub_publish_test()
  subscriber1 = CreateObject("roSGnode", "ContentNode")
  subscriber1.id = "the_subscriber1"
  m.top.component = subscriber1
  m.someString = "default"
  m.someAA = {}

  ' test that the field on the parent component's m. gets updated
  m.pubsub.publish("someInt", 12)
  m.assertEqual(m.someInt, 12)

  ' test that simple publications (like uiMode) update the appropriate subscriber fields
  m.pubsub.subscribe("someString", subscriber1, "title")
  m.pubsub.publish("someString", "aaaa")
  m.assertEqual(subscriber1.title, "aaaa")
  m.assertEqual(m.someString, "aaaa")

  ' test that nested publications (like deviceSettings.font.color) update the appropriate subsriber fields
  subscriber2 = CreateObject("roSGnode", "ContentNode")
  subscriber2.id = "the_subscriber2"
  subscriber2.description = "def"
  m.top.component = subscriber2

  m.pubsub.subscribe("someAA.is.nested", subscriber2, "title")
  m.pubsub.subscribe("someAA.is.not.existing", subscriber2, "description")
  someAA = {
    is: {
      nested: "absolutely"
      fancy: "maybe"
      worried: "never"
    }
  }
  m.pubsub.publish("someAA", someAA)
  m.assertEqual(subscriber2.title, "absolutely")
  m.assertEqual(subscriber2.description, "def") 'no change since we subscribed to a nested property that doesn't exist
  m.assertEqual(m.someAA.is.nested, "absolutely")
  m.assertEqual(m.someAA.is.fancy, "maybe")
  m.assertEqual(m.someAA.is.worried, "never")

  ' test that subscribers are removed if they cannot be found
  ' reset the pubsub
  m.pubsub = TubiPubSub(m)
  m.someString = "default"
  m.someAA = {}
  subscriber1 = CreateObject("roSGnode", "ContentNode")
  subscriber1.id = "the_subscriber1"
  subscriber2 = CreateObject("roSGnode", "ContentNode")
  subscriber2.id = "the_subscriber2"
  ' update the find node mock function to enforce that we can't find subscriber1 but can find subscriber2
  m.top.findNode = Function(id = "")
    if id = "the_subscriber2"
      return m.component
    else
      return invalid
    end if
  End Function

  m.pubsub.subscribe("someString", subscriber1, "title")
  m.pubsub.subscribe("someAA.is.nested", subscriber1, "description")
  m.pubsub.subscribe("someString", subscriber2, "title")
  m.pubsub.subscribe("someAA.is.nested", subscriber2, "description")
  m.top.component = subscriber2 'only subscriber2 will be found when we attempt to publish

  m.pubsub.publish("someString", "yyyy")
  m.assertInvalid(m.pubsub.publications["someString"]["someString"][subscriber1.id])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"][subscriber2.id])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertEqual(subscriber2.title, "yyyy")
  m.assertInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"][subscriber1.id])
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"][subscriber2.id])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 2)
End Function


'@Test unit tests tubiPubSub_unsubscribe
Function tubiPubSub_unsubscribe_test()
  subscriber = CreateObject("roSGnode", "ContentNode")
  subscriber.id = "the_subscriber"
  m.top.component = subscriber
  m.someString = "default"
  m.someOtherString = "initial"
  m.someAA = {}

  ' test unsubscribing from simple publication works (uiNode)
  ' set up a subscriber first
  subSuccess = m.pubsub.subscribe("someString", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertTrue(subSuccess)
  ' now test removing the subscriber (and publication since there are no subscribers on it)
  unsubSuccess = m.pubsub.unsubscribe("someString", subscriber)
  m.assertInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications.count(), 0)
  m.assertTrue(unsubSuccess)

  ' test unsubscribing from nested publication works (deviceSettings.font.color)
  ' set up a subscriber first
  subSuccess = m.pubsub.subscribe("someAA.is.nested", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertTrue(subSuccess)
  ' now test removing the subscriber (and publication since there are no subscribers on it)
  unsubSuccess = m.pubsub.unsubscribe("someAA.is.nested", subscriber)
  m.assertInvalid(m.pubsub.publications["someAA"])
  m.assertEqual(m.pubsub.publications.count(), 0)
  m.assertTrue(unsubSuccess)

  ' test unsubscribing when multiple subscribers exist
  ' set up multiple subscriptions
  m.pubsub.subscribe("someString", subscriber, "title")
  m.pubsub.subscribe("someOtherString", subscriber, "description")
  m.pubsub.subscribe("someAA.is.nested", subscriber, "actors")
  m.pubsub.subscribe("someAA.is.also.nested", subscriber, "directors")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someOtherString"]["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"]["someOtherString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 2)
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.also.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.also.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 3)
  ' now test removing one of the nested subscriptions
  unsubSuccess = m.pubsub.unsubscribe("someAA.is.nested", subscriber)
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someOtherString"]["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"]["someOtherString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 3)
  m.assertTrue(unsubSuccess)
  ' now test removing one of the simple subscriptions
  unsubSuccess = m.pubsub.unsubscribe("someString", subscriber)
  m.assertInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"].count(), 1)
  m.assertEqual(m.pubsub.publications["someOtherString"]["someOtherString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someOtherString"]["someOtherString"])
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.also.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.also.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 2)
  m.assertTrue(unsubSuccess)
  ' now test removing the other nested subscription
  unsubSuccess = m.pubsub.unsubscribe("someAA.is.also.nested", subscriber)
  m.assertInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someOtherString"]["someOtherString"])
  m.assertEqual(m.pubsub.publications["someOtherString"]["someOtherString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertTrue(unsubSuccess)
  ' now test removing the last simple subscription
  m.pubsub.unsubscribe("someOtherString", subscriber)
  m.assertInvalid(m.pubsub.publications["someOtherString"])
  m.assertEqual(m.pubsub.publications.count(), 0)
  m.assertTrue(unsubSuccess)

  ' test removing a simple subscription that doesn't exist
  subSuccess = m.pubsub.subscribe("someString", subscriber, "title")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertTrue(subSuccess)
  unsubSuccess = m.pubsub.unsubscribe("notExisting", subscriber)
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertFalse(unsubSuccess)

  ' test removing a simple subscription that doesn't exist
  subSuccess = m.pubsub.subscribe("someAA.is.nested", subscriber, "description")
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 2) ' someString is still in m.pubsub.publications from last test
  m.assertTrue(subSuccess)
  unsubSuccess = m.pubsub.unsubscribe("someAA.not.existing", subscriber)
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 2) ' someString is still in m.pubsub.publications from last test
  m.assertFalse(unsubSuccess)
End Function


'@Test unit tests tubiPubSub_unsubscribeFromAll
Function tubiPubSub_unsubscribeFromAll_test()
  subscriber1 = CreateObject("roSGnode", "ContentNode")
  subscriber1.id = "the_subscriber1"
  subscriber2 = CreateObject("roSGnode", "ContentNode")
  subscriber2.id = "the_subscriber2"
  m.top.component = subscriber1
  m.someString = "default"
  m.someAA = {}

  m.pubsub.subscribe("someString", subscriber1, "title")
  m.pubsub.subscribe("someAA.is.nested", subscriber1, "description")
  m.top.component = subscriber2
  m.pubsub.subscribe("someString", subscriber2, "title")
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertNotInvalid(m.pubsub.publications["someString"]["someString"])
  m.assertEqual(m.pubsub.publications["someString"]["someString"].count(), 2)
  m.assertNotInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someAA"]["someAA.is.nested"])
  m.assertEqual(m.pubsub.publications["someAA"].count(), 1)
  m.assertEqual(m.pubsub.publications["someAA"]["someAA.is.nested"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 2)

  m.top.component = subscriber1
  unsubSuccess = m.pubsub.unsubscribeFromAll(subscriber1)
  m.assertInvalid(m.pubsub.publications["someAA"])
  m.assertNotInvalid(m.pubsub.publications["someString"])
  m.assertEqual(m.pubsub.publications["someString"].count(), 1)
  m.assertEqual(m.pubsub.publications.count(), 1)
  m.assertTrue(unsubSuccess)
End Function

