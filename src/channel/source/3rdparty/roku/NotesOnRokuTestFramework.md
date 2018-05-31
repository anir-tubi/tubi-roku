1. Tubi implementation only uses single underscores as opposed to the default double underscores in the documentation. For example:
  - Tubi: TestSuite_xxx
  - Docs: TestSuite__xxx

2. Tubi implementation does not place the files in the locations specified by the documentation.
  - Non SG Tests are in src/channel/source/tests/rokuUnits
  - SG Tests are in src/channel/components/tests

3. As of 5/31/18 using the Set Up and Tear Down functionality does not work in SG Tests.

4. AssertEqual can be used on arrays and assocArrays. This is not necessarily clear from the documentation.