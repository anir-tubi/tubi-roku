'use strict';
// This file provides some functions for running suitest tests and converting them over to our test format.
// This file may get removed if we fully move away from Suitest.

const prompts = require('prompts');

const {suitest, ecp, odc, device, utils} = require('roku-test-automation');
const fs = require('fs');
const clipboardy = require('clipboardy');

const testsFilePath = 'automated-tests-config/suitest-tests.json';
const allElementsPath = 'automated-tests-config/suitest-all-elements.json';
const xpathsToKeyPathsPath = 'automated-tests-config/converted-element-keypaths.json';

// Use to skip to starting at a particular test. Useful if a specific test is failing
// const startOffsetTestId = '3d313789-f0fc-4c80-8f9f-ce027382c302';
// const startOffsetTestId = '73e8a3b5-6df2-43f6-9ee2-4af3a806d054';
const startOffsetTestId = '61b87815-df1d-46f9-82c1-d8214ff71552';

const tags = [
  // Application Launch
  '@application_launch',

  //Details Page Movies
  '@mdp_1', '@mdp_2', '@mdp_3',

  // Details Page Series
  '@sdp_1', '@sdp_2',

  // EPG 1
  '@epg',

  // Homescreen Navigation
  '@homescreen',

  // Kids Mode Guests
  '@kidsmode_guest',

  // Kids Mode Open Tests
  '@kidsmode_open',

  // Kids Mode Registered
  '@kidsmode',

  // Kids Mode Toggle
  '@kids_toggle',

  // Linear Search
  '@linearsearch',

  // Live Sports
  '@livesports',

  // My List
  '@my_list',

  // Parental Controls
  '@parental_controls_1', '@parental_controls_2',

  // Playback 1
  '@playback_1',

  // Playback 2
  '@playback_2',

  // Playback 3
  '@playback_3',

  // Playback 4
  '@playback_4',

  // Programmatic Exit Tests
  '@exit',

  // Queue
  '@queue',

  // Registered User Reactions
  '@registeredreactions',

  // Registration Continue Watching Row
  '@continue_watching_signup',

  // Series Autoplay
  '@series_autoplay',

  // Settings Tests
  '@settings',

  // Side Navigation
  '@sidenavigation_1', '@sidenavigation_2',

  // Top Navigation
  '@topnav',

  // Tubi Espanol
  '@espanol',

  // Video Previews
  '@videopreview'
];

const excludedTestIds = [
  // ST API seems to return width as 214 but actual value should be 145
  '3d313789-f0fc-4c80-8f9f-ce027382c302',

  // Fails on ST due to us not waiting for detail page to load first
  '4ef98961-7808-4470-be6b-0e817c7bb62a',

  // Fails on ST
  '379a5104-2f03-4138-b5b3-e7fd58799a22',

  // Needs to navigate down further
  '562dd49e-edfe-4205-a9f8-91341484e51e',

  // Needs to navigate down further
  '9d5df9cc-1b3e-4a91-a682-89c4c26964c4',

  // Trailer playing in background
  '5c985aeb-c7c9-43d8-a02f-459e7c3ae5ab',

  // Trailer playing in background
  'c835be2e-7b23-4943-8cb5-313fa4402655',

  // Needs to verify video is playing before trying to fast forward
  'cbfcbac3-665d-4c07-9dc0-34646c0f2166',

  // CategoryDetailsScreen in xpath should be DetailsScreen
  'e04c3bb8-4d9d-429a-a74f-1a769f3e4e69',

  // Not sure why this one works in Suitest as the Label gets reparented as is no longer in a LayoutGroup so should be failing but it is not
  '560f51f7-2a1d-4686-9263-443620d70424',

  // Fails if ad plays before hand as we just check for playing not how long the item is like we do in some other tests
  '13922c9f-97b9-4cb2-8173-3bf54b68ee25',

  // Fails on Suitest as well
  '30d388b1-e002-42d0-b046-26c0280069bc',

  // Fails for the same reason as 560f51f7-2a1d-4686-9263-443620d70424
  '73e8a3b5-6df2-43f6-9ee2-4af3a806d054'
];


suitest.preOpenAppHook = async () => {
  // Try to clear out the registry
  try {
    const isActiveApp = await ecp.isActiveApp();
    if (isActiveApp) {
      await odc.deleteEntireRegistry({}, {timeout: 400});
      console.log(`Cleared registry out`);
    }
  } catch(e) {
    // continue on as normal
  }
};


suitest.postOpenAppHook = async () => {
  // Have to give time for application to boot up
  await utils.sleep(5000);
};


exports.retrieveSuitestTests = async function(done) {
  await suitest.retrieveAllTestsForAppVersion();
  await suitest.writeOutTestsToFile(testsFilePath);
  done();
};


exports.runSuitestTests = async function(done) {
  await suitest.readInTestsFromFile(testsFilePath);
  const allElements = fs.readFileSync(allElementsPath, 'utf-8');
  suitest.allElements = JSON.parse(allElements);

  await suitest.runTests(tags, {
    excludedTestIds: excludedTestIds,
    startOffsetTestId: startOffsetTestId
  });
  done();
};


exports.convertXpathsToKeyPaths = async function (done) {
  // Read in our Suitest info
  const allElements = fs.readFileSync(allElementsPath, 'utf-8');
  suitest.allElements = JSON.parse(allElements);

  const keyPathsForElements = {};
  const skippedElements = {};
  const failedElements = {};
  const notUsedElements = {};

  // Look to make sure the elements are actually used in a test
  for (const key in suitest.allElements) {
    const element = suitest.allElements[key];
    if (element['tests'].length === 0) {
      notUsedElements[key] = element;
      delete suitest.allElements[key];
    }
  }
  console.log('not used elements', Object.keys(notUsedElements).length);

  // First launch the application
  await device.deploy({
    rootDir: 'build/local',
    files: [
      '**/*'
    ]
  });

  // Serves as a list of spots where we will try to retrieve key paths in various parts of the application
  const scenarios = [];

  // First an empty one for starting homescreen
  scenarios.push(async () => {});

  // Next one for the DetailScreen
  scenarios.push(async () => {
    await ecp.sendKeypress(ecp.Key.Ok);
  });

  // Next one for the VideoScreen
  scenarios.push(async () => {
    await ecp.sendKeypress(ecp.Key.Ok);
  });

  // Next one for the SettingsScreen
  scenarios.push(async () => {
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Down, {count: 5});
    await ecp.sendKeypress(ecp.Key.Ok);
  });

  // Next one for the SearchScreen
  scenarios.push(async () => {
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
  });

  // Next one for the LinearVideoPlayerScreen
  scenarios.push(async () => {
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Right, {count: 3});
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(4000);
    await ecp.sendKeypress(ecp.Key.Ok);
  });

  // Next one for the Kids Mode
  scenarios.push(async () => {
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
  });

  for (const scenario of scenarios) {
    await scenario();
    await waitForNodeCountStability();

    const {rootTree, flatTree} = await odc.storeNodeReferences({
      includeArrayGridChildren: true
    });

    for (const key in suitest.allElements) {
      // If we already captured this keypath then we can skip it
      if(keyPathsForElements[key]) {
        continue;
      }

      const element = suitest.allElements[key];

      if (!element.platforms.roku) {
        delete suitest.allElements[key];
        continue;
      }
      const xpath = element.platforms.roku.selectors.xpath?.val;

      if (!xpath) {
        // console.log(`Skipping ${elementId} as does not include xpath selector`);
        skippedElements[key] = element;
        delete suitest.allElements[key];
        continue;
      }

      try {
        const result = await suitest.findMatchingNode(rootTree, xpath.split('/'), flatTree);
        keyPathsForElements[key] = result.keyPath;
        delete failedElements[key];
      } catch (e) {
        failedElements[key] = element;
      }
    }


  }
  console.log('total possible xpaths', Object.keys(suitest.allElements).length);
  console.log('skipped elements', Object.keys(skippedElements).length);
  console.log('failed xpaths', Object.keys(failedElements).length);

  for (const key in failedElements) {
    const element = suitest.allElements[key];
    console.log({
      elementId: key,
      name: element['name'],
      xpath: element.platforms.roku.selectors.xpath.val
    });
  }

  console.log('found key paths', Object.keys(keyPathsForElements).length);
  const output = {};
  for (const key in keyPathsForElements) {
    const element = suitest.allElements[key];
    output[element['name']] = {
      elementId: key,
      name: element['name'],
      xpath: element.platforms.roku.selectors.xpath.val,
      keyPath: keyPathsForElements[key]
    };
  }
  fs.writeFileSync(xpathsToKeyPathsPath, JSON.stringify(output, undefined, 2));

  console.log(`Saved found key paths to ${xpathsToKeyPathsPath}`);
};


// Was trying to import TypeScript copy from PerformanceTestUtils but ran into issues so just copying function over
async function waitForNodeCountStability() {
  let lastNodeCount = 0;
  let numberOfTimesNodeCountMatched = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const result = await odc.getAllCount();
    if (lastNodeCount === result.totalNodes) {
      numberOfTimesNodeCountMatched++;
      if (numberOfTimesNodeCountMatched === 8) {
        return result;
      }
    } else {
      numberOfTimesNodeCountMatched = 0;
    }
    await utils.sleep(250);
    lastNodeCount = result.totalNodes;
  }
}


// We don't handle a good deal of Suitest testLine types so we just spit out the json from Suitest side to serve as some info on what we might do there to replace that functionality
// @testLine - object - Contains info about the current line in the test to be executed. This is pulled from automated-tests-config/suitest-tests.json
function addFallbackForTestLine(testLine, convertedTestLines) {
  convertedTestLines.push(`/* ${JSON.stringify(testLine, undefined, 2)} */`);
}


// Converts the current testLine into our RTA test output
// @testLine - object - Contains info about the current line in the test to be executed. This is pulled from automated-tests-config/suitest-tests.json
function convertSuitestTestLine(testLine, convertedTestLines) {
  if (testLine.excluded) {
    return;
  }

  switch (testLine.type) {
    case 'openApp':
      // Do nothing for this
      break;
    case 'sleep':
      convertedTestLines.push(`await utils.sleep(${testLine.timeout});`);
      break;
    case 'button':
      if (testLine.condition) {
        addFallbackForTestLine(testLine, convertedTestLines);
        break;
      }

      const buttonIdToKeyMap = {
        LEFT: 'ecp.Key.Left',
        RIGHT: 'ecp.Key.Right',
        UP: 'ecp.Key.Up',
        DOWN: 'ecp.Key.Down',
        ENTER: 'ecp.Key.Ok',
        BACK: 'ecp.Key.Back',
        FAST_FWD: 'ecp.Key.Forward',
        REWIND: 'ecp.Key.Rewind',
        PLAY_PAUSE: 'ecp.Key.Play',
        EXIT: 'ecp.Key.Home'
      };

      for (const id of testLine.ids) {
        const key = buttonIdToKeyMap[id];
        if (testLine?.count > 1) {
          convertedTestLines.push(`await ecp.sendKeypress(${key}, {count: ${testLine.count}});`);
        } else {
          convertedTestLines.push(`await ecp.sendKeypress(${key});`);
        }
      }
      break;
    case 'runSnippet':
      const test = suitest.testsByTestId[testLine.val];
      convertedTestLines.push('');
      convertedTestLines.push(`// START ${test.title}`);
      for (const snippetLine of test.definition) {
        convertSuitestTestLine(snippetLine, convertedTestLines);
      }
      convertedTestLines.push(`// END ${test.title}`);
      convertedTestLines.push('');
      break;
    case 'sendText':
      convertedTestLines.push(`await ecp.sendText('${testLine.val}');`);
      break;
    case 'comment':
      convertedTestLines.push(`// ${testLine.val}`);
      break;
    default:
      addFallbackForTestLine(testLine, convertedTestLines);
      break;
  }
}


// Tries to convert the supplied suitest test over to our own test format
exports.convertSuitestTest = async function (done) {
  // Read in our Suitest info
  await suitest.readInTestsFromFile(testsFilePath);
  const allElements = fs.readFileSync(allElementsPath, 'utf-8');
  suitest.allElements = JSON.parse(allElements);

  let {testIdOrUrl} = await prompts({
    type: 'text',
    name: 'testIdOrUrl',
    message: 'Enter the testId or url of the test you would like to convert'
  });

  const matches = testIdOrUrl.match(/testId=([^&]*)/);
  if (matches) {
    testIdOrUrl = matches[1];
  }

  const test = suitest.testsByTestId[testIdOrUrl];
  if (!test) {
    throw new Error(`Could not find test for testId ${testIdOrUrl}`);
  }

  const testName = test.title + ' ' + test.tags.join(',');

  const convertedTestLines = [`it('${testName}', async () => {`];
  for (const testLine of test.definition) {
    convertSuitestTestLine(testLine, convertedTestLines);
  }

  const output = `${convertedTestLines.join('\n  ')}
});`;

  console.log('---------------------------------------------------');
  console.log(output);
  console.log('---------------------------------------------------');
  clipboardy.writeSync(output);
  console.log('test copied to clipboard');
};
