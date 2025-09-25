import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Settings', function () {
  beforeEach(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeRowList', 'Timed out waiting for Rowlist to have focus');

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
    await testUtils.waitForElementToFullyShowOnScreen('fullDeviceMessage');

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

  // https://tubi.testrail.io/index.php?/cases/view/770140
  it('C770140- Privacy Policy Page - If Rokus autoplay setting = OFF, Autoplay Next Video should be accesible, @settings', async () => {

    // Start app with Roku's autoplay setting disabled
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, isAutoplayEnabled: false }); // This sets Roku system level autoplay to OFF

    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Verify we're on Settings screen
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToFullyShowOnScreen('AutoPlayControlsMenuItemFocused');

    // Get the autoplay instructions element using getNodeForElement
    const instructions = await testUtils.getNodeForElement('autoplayInstructions');
    expect(instructions.visible).to.equal(true);

    // Get the instructions text to verify it shows disabled message
    const instructionsText = instructions.text;
    expect(instructionsText).to.equals('Autoplay is currently controlled in Roku Settings. To change this setting, go to Roku Settings -> Accessibility -> Auto-play video.'); // Verify the feature disabled message is shown

    //As Autoplay video is disabled, focus should go to AutoPlay Next Video Menu when we press right.
    await ecp.sendKeypress(ecp.Key.Right);

    //Verify autoplayNextVideoMenu is visible
    const autoplayNextVideoMenu = await testUtils.getNodeForElement('autoplayNextVideoMenu');
    expect(autoplayNextVideoMenu.visible).to.equal(true);

    //Verify AutoPlay Next Video has focus and can browse throgh items
    await testUtils.waitForElementToFullyShowOnScreen('autoplayNextVideoMenu');
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Down);

  });

});

async function goToSettingsPageSelectAbout() {
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

