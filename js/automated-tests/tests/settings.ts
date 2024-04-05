import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Settings', function () {
  beforeEach(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeRowList','Timed out waiting for Rowlist to have focus');

  });

  // https://tubi.testrail.io/index.php?/cases/view/21250
  it('C21250 - About Page - When user chooses the About Page then About page is open, @settings', async () => {

    // Go to Settings Page, highlight about
    await goToSettingsPageSelectAbout();

  });

  // https://tubi.testrail.io/index.php?/cases/view/21252
  // Need to add another test for GDPR - this is obsolete
  /*
  it('C21252 - Terms of Service, @settings', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Go to Settings Page
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Is left nav open?
    await testUtils.retryWithTimeOut(async () => {
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      expect(leftNavHomeButton.visible).to.be.true;
    });


    // Down to Settings
    await ecp.sendKeypress(ecp.Key.Down, { count: 5 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000); // Improvement

    // Select Privacy Center
    await testUtils.retryWithTimeOut(async () => {
      const settingsScreen = await testUtils.getNodeForElement('settingsScreen');
      expect(settingsScreen.visible).to.be.true;
    });

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });


    // Is the Privacy page Open?
    // Check if we are on Privacy page
    await waitForCurrentScreenToEqual()
  });*/


  // https://tubi.testrail.io/index.php?/cases/view/32370
  it('C32370 - About Page - When user chooses the About Page and presses OK then Full Device ID is displayed, @settings', async () => {
   

    // Go to Settings Page
    await goToSettingsPageSelectAbout();


    // Full Device ID modal present?
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('dialogBoxContentAreaDeviceID');
    const fullDeviceID = await testUtils.getNodeForElement('fullDeviceID');
    const fullDeviceMessage = await testUtils.getNodeForElement('fullDeviceMessage');
    await testUtils.elementHasFocus('fullDeviceID');
    expect(fullDeviceID.text).to.equal('Full Device ID');
  });

  // https://tubi.testrail.io/index.php?/cases/view/32371
  it('C32371 - About Page - When user chooses the About Page and checks Need Help label then Need Help should be present, @settings', async () => {
    

    // Go to Settings Page and higlight About
    await goToSettingsPageSelectAbout();


    // Does the help link exist?
    const helpLinkText = await testUtils.getNodeForElement('helpLinkText');
    expect(helpLinkText.text).to.equal('Visit http://help.tubitv.com');
  });

  // https://tubi.testrail.io/index.php?/cases/view/32372
  it('C32372- Privacy Policy Page - When user chooses the Privacy Policy Page then Privacy Policy page should be displayed, @settings', async () => {


    // Go to Settings Page
    await testUtils.goToPage('settings');

    // Select Privacy Policy
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });

    // Is the Privacy Policy Page Open?
    await testUtils.waitForElementToFullyShowOnScreen('privacyPolicyHeader');
    const privacyPolicyHeader = await testUtils.getNodeForElement('privacyPolicyHeader');
    expect(await privacyPolicyHeader.text).to.equal('Privacy Center');

  });
});

async function goToSettingsPageSelectAbout(){
  // Go to Settings Page
  await testUtils.goToPage('settings');
  await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

  // Select About
  await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
  
  // Is the About Page Open?
  const settingsScreenHeader = await testUtils.getNodeForElement('settingsScreenHeader');
  await testUtils.waitForElementToFullyShowOnScreen('settingsScreenHeader');
  expect(settingsScreenHeader.text).to.equal('About Tubi');

}

