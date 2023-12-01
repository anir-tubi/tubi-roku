import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Settings', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

  });

  // https://tubi.testrail.io/index.php?/cases/view/21250
  it('C21250 - About Page - When user chooses the About Page then About page is open, @settings', async () => {

    await testUtils.waitForAppLaunchBeaconToFire();

    // Go to Settings Page
    await ecp.sendKeyPress(ecp.Key.Back, { count: 2 });

    // Is left nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Down to Settings
    await ecp.sendKeyPress(ecp.Key.Down, { count: 5 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Select About
    await ecp.sendKeyPress(ecp.Key.Down, { count: 2 });

    // Is the About Page Open?
    const settingsScreenHeader = await testUtils.getNodeForElement('settingsScreenHeader');
    expect(settingsScreenHeader.text).to.equal('About Tubi');
  });

  // https://tubi.testrail.io/index.php?/cases/view/21252
  // Need to add another test for GDPR - this is obsolete
  /*
  it('C21252 - Terms of Service, @settings', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Go to Settings Page
    await ecp.sendKeyPress(ecp.Key.Back, { count: 2 });

    // Is left nav open?
    await testUtils.retryWithTimeOut(async () => {
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      expect(leftNavHomeButton.visible).to.be.true;
    });


    // Down to Settings
    await ecp.sendKeyPress(ecp.Key.Down, { count: 5 });
    await utils.sleep(2000);
    await ecp.sendKeyPress(ecp.Key.Ok);
    await utils.sleep(3000); // Improvement

    // Select Privacy Center
    await testUtils.retryWithTimeOut(async () => {
      const settingsScreen = await testUtils.getNodeForElement('settingsScreen');
      expect(settingsScreen.visible).to.be.true;
    });

    await ecp.sendKeyPress(ecp.Key.Down, { count: 3 });


    // Is the Privacy page Open?
    // Check if we are on Privacy page
    await waitForCurrentScreenToEqual()
  });*/


  // https://tubi.testrail.io/index.php?/cases/view/32370
  it('C32370 - About Page - When user chooses the About Page and presses OK then Full Device ID is displayed, @settings', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Go to Settings Page
    await ecp.sendKeyPress(ecp.Key.Back, { count: 2 });

    // Is left nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Down to Settings
    await ecp.sendKeyPress(ecp.Key.Down, { count: 5 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Select About
    await ecp.sendKeyPress(ecp.Key.Down, { count: 2 });
    await testUtils.elementHasFocus('aboutMenuItem');
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Full Device ID modal present?
    await utils.sleep(3000);
    const dialogBoxContentAreaDeviceID = testUtils.getNodeForElement('dialogBoxContentAreaDeviceID');
    await dialogBoxContentAreaDeviceID;
    const fullDeviceID = await testUtils.getNodeForElement('fullDeviceID');
    const fullDeviceMessage = await testUtils.getNodeForElement('fullDeviceMessage');
    await testUtils.elementHasFocus('fullDeviceID');
    expect(fullDeviceID.text).to.equal('Full Device ID');
    expect(fullDeviceMessage.visible).to.equal(true);
  });

  // https://tubi.testrail.io/index.php?/cases/view/32371
  it('C32371 - About Page - When user chooses the About Page and checks Need Help label then Need Help should be present, @settings', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Go to Settings Page
    await ecp.sendKeyPress(ecp.Key.Back, { count: 2 });

    // Is left nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Down to Settings
    await ecp.sendKeyPress(ecp.Key.Down, { count: 5 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Select About
    await ecp.sendKeyPress(ecp.Key.Down, { count: 2 });

    // Is the About Page Open and does the help link exist?
    const settingsScreenHeader = await testUtils.getNodeForElement('settingsScreenHeader');
    const helpPageText = await testUtils.getNodeForElement('helpPageText');
    expect(settingsScreenHeader.text).to.equal('About Tubi');
    expect(helpPageText.text).to.contain('Visit http://help.tubitv.com');
  });

  // https://tubi.testrail.io/index.php?/cases/view/32372
  it('C32372- Privacy Policy Page - When user chooses the Privacy Policy Page then Privacy Policy page should be displayed, @settings', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Go to Settings Page
    await ecp.sendKeyPress(ecp.Key.Back, { count: 2 });

    // Is left nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Down to Settings
    await ecp.sendKeyPress(ecp.Key.Down, { count: 5 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Select Privacy Policy
    await ecp.sendKeyPress(ecp.Key.Down, { count: 3 });
    await utils.sleep(1000);
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Is the Privacy Policy Page Open?
    const privacyPolicyHeader = await testUtils.getNodeForElement('privacyPolicyHeader');
    expect(await privacyPolicyHeader.text).to.equal('Privacy Center');

  });
});
