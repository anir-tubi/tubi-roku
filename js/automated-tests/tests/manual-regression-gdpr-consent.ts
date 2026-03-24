import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';
import {
  safeResumeProxy,
  goToPrivacyCenter
} from './manual-regression-helpers';

/**
 * GDPR/Consent Regression Tests
 * Tests for OneTrust consent, privacy settings, and UK region restrictions
 */

describe('GDPR/Consent Regression Tests', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  afterEach(async () => {
    try {
      await proxy.pause();
    } catch (e) {
      // proxy may already be paused (e.g. paused mid-test)
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672515
  it('C672515 - New User - App Open - Verify user cannot exit Initial Consent screen @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Connected to VPN in UK
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest
     * 2. From Initial Consent screen, attempt to exit the page using remote button except for Home button on remote (background app)
     * 
     * Expected:
     * - User sees Initial Consent screen
     * - User Cannot exit Initial Consent screen
     */

    // Mock the remote_config/roku endpoint to enable OneTrust consent
    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with fresh device/user to trigger consent screen
    await safeResumeProxy();

    // Launch app with cleared registry (simulates new device/user)
    // Don't use startApplicationAtPage as it tries to navigate, which won't work if consent screen blocks
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy callback to complete
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for otBanner (OneTrust consent banner) to show on screen
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 10000);

    // Verify otBanner is visible with full opacity
    let otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Back button - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Up - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Down - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Left - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Right - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672520
  it('C672520 - New User - App Open - Verify there are not Parental Control settings @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. Accept OneTrust consent if present
     * 3. Navigate to Settings
     * 4. Check for Parental Control settings
     * 
     * Expected:
     * - User should not see any Parental Control settings option in the UK region
     */

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Check if OneTrust consent screen appears and accept it if present
    try {
      await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 5000);

      // Accept OneTrust consent by pressing OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
    } catch (error) {
      // Consent screen didn't appear, continue with test
      console.log('OneTrust consent screen did not appear, continuing...');
    }

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Settings using helper
    await testHelpers.openSettings();
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

    // Get all menu items from Settings
    const settingsMenuItems = await testUtils.getAllRowListItemsContent('settingsMenu');

    // Verify Parental Controls is NOT in the menu
    const hasParentalControlsOption = settingsMenuItems.some((item: any) =>
      item.title === 'Parental Controls' ||
      item.TITLE === 'Parental Controls' ||
      item.title === 'Parental Control' ||
      item.TITLE === 'Parental Control'
    );

    expect(hasParentalControlsOption, 'Parental Controls option should not be present in UK region').to.be.false;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672522
  it('C672522 - New User - App Open - Verify there is no Espanol option @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB
     * 2. From Home, check if there is a Espanol option
     * 
     * Expected:
     * - User should not see any method to open Espanol mode (left Nav, Top Nav, etc)
     */

    // Mock the remote_config/roku endpoint to set country to GB
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';
          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Open side nav menu
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();

    // Get all menu items
    const menuItems = await testUtils.getAllRowListItemsContent('sideNavMenu');

    // Verify Espanol is not in the menu
    const hasEspanolOption = menuItems.some((item: any) =>
      item.title === 'Espanol' ||
      item.TITLE === 'Espanol' ||
      item.title === 'Español' ||
      item.TITLE === 'Español'
    );

    expect(hasEspanolOption, 'Espanol option should not be present in UK region').to.be.false;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672523
  it('C672523 - New User - App Open - Verify there is no Kids Mode option @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. Accept OneTrust consent
     * 3. From Home, check if there is a Kids Mode option
     * 
     * Expected:
     * - User should not see any method to open Kids Mode (left Nav, Top Nav, etc)
     */

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          // Disable Kids Mode feature
          responseJson.enable_kidsmode = false;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Check if OneTrust consent screen appears and accept it if present
    try {
      await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 5000);

      // Accept OneTrust consent by pressing OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
    } catch (error) {
      // Consent screen didn't appear, continue with test
      console.log('OneTrust consent screen did not appear, continuing...');
    }

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Open side nav menu
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();

    // Get all menu items
    const menuItems = await testUtils.getAllRowListItemsContent('sideNavMenu');

    // Verify Kids Mode is not in the menu
    const hasKidsModeOption = menuItems.some((item: any) =>
      item.title === 'Kids' ||
      item.TITLE === 'Kids' ||
      item.title === 'Kids Mode' ||
      item.TITLE === 'Kids Mode'
    );

    expect(hasKidsModeOption, 'Kids Mode option should not be present in UK region with OneTrust enabled').to.be.false;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672532
  it('C672532 - New User - App Open - Initial Consent - Reject All @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. From Initial Consent screen select Reject All
     * 3. From Home screen go to Settings
     * 4. From Settings go to Privacy Center
     * 
     * Expected:
     * - Privacy Center should be accessible and display consent options
     * - All non-essential consent options should be unchecked after rejecting all
     */

    // Clear registry first with dummy deeplinking
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: true });
    await utils.sleep(3000); // Wait for app to fully restart

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: false });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for OneTrust banner to show
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 10000);

    // Navigate to Reject All button (move left from default focused button) and click OK
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Privacy Center using helper
    await goToPrivacyCenter();

    // Move right to the "Manage Privacy Settings" button
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('managePrivacySettingsButton', 'Timed out waiting for Privacy Center header to have focus', 5000);


    // Click OK to enter Manage Privacy Settings
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });

    // Consent categories to verify (they should all be unchecked after "Reject All")
    const consentCategories = [
      'Functional',
      'Performance',
      'Marketing',
      'Personalized Advertising'
    ];

    // Verify each consent category has an unchecked checkbox
    for (let i = 0; i < consentCategories.length; i++) {
      const category = consentCategories[i];

      const checkbox = await testUtils.getNodeForElement('otConsentCheckbox');
      expect(checkbox.uri, `${category} consent should be unchecked`).to.equal('pkg:/components/OTPublishersSDK/images/checkbox-unselected.png');

      // Move down to next consent item (unless it's the last one)
      if (i < consentCategories.length - 1) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(100);
      }
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672531
  it('C672531 - New User - App Open - Initial Consent - Accept All @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. From Initial Consent screen select Accept All
     * 3. From Home screen go to Settings
     * 4. From Settings go to Privacy Center
     * 
     * Expected:
     * - Privacy Center should be accessible and display consent options
     * - All consent options should be checked after accepting all
     */

    // Clear registry first with dummy deeplinking
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: true });
    await utils.sleep(3000); // Wait for app to fully restart

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: false });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for OneTrust banner to show
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Privacy Center using helper
    await goToPrivacyCenter();

    // Move right to the "Manage Privacy Settings" button
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('managePrivacySettingsButton', 'Timed out waiting for Privacy Center header to have focus', 5000);


    // Click OK to enter Manage Privacy Settings
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });

    // Consent categories to verify (they should all be checked after "Accept All")
    const consentCategories = [
      'Functional',
      'Performance',
      'Marketing',
      'Personalized Advertising'
    ];

    // Verify each consent category has a checked checkbox
    for (let i = 0; i < consentCategories.length; i++) {
      const category = consentCategories[i];

      const checkbox = await testUtils.getNodeForElement('otConsentCheckbox');
      expect(checkbox.uri, `${category} consent should be checked`).to.equal('pkg:/components/OTPublishersSDK/images/checkbox-selected.png');

      // Move down to next consent item (unless it's the last one)
      if (i < consentCategories.length - 1) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(100);
      }
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672544
  it('C672544 - New User - App Open - Register as New User over 18 @manual_regression @gdpr @consent @registration', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. From Initial Consent screen select Accept All
     * 3. From Home screen go to Sign In from Left Nav
     * 4. From Registration flow, register a new Tubi user
     * 5. From Age Gate, enter birth year (YYYY) which is over 18yrs old
     * 
     * Expected:
     * - User is able to Register
     * - User is at Home screen
     * - User is signed in
     */
    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: true
    });
    await utils.sleep(3000);

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);
    proxy.pause();
    // Check if OneTrust consent screen appears and accept it if present
    try {
      await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 5000);

      // Accept OneTrust consent by pressing OK (Accept All)
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
    } catch (error) {
      // Consent screen didn't appear, continue with test
      console.log('OneTrust consent screen did not appear, continuing...');
    }

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Sign In from Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(5000);
    // If not, press Back to dismiss Roku sign-in prompt
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify on Enter Email Address page
    const enterEmailAddressTitle = await testUtils.getNodeForElement('emailInputScreenHeader');
    expect(enterEmailAddressTitle.text).to.equal('Enter Email Address');

    // Enter a new email account
    const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    await utils.sleep(2000);
    await ecp.sendText(email);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on Confirm your age page
    const confirmYourAgeText = await testUtils.getNodeForElement('ageGateHeaderInRegistrationFlow');
    expect(confirmYourAgeText.text).to.equal('Confirm your age*');

    await ecp.sendText('20');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await testUtils.waitForElementToHaveFocus('ageVerificationStartButton', 'Timed out waiting for Start watching Button to have focus', 5000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for registration to complete and return to home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);

    // Verify user is signed in by checking the side nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    let sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
    expect(sideNavSignedInLabel.text).to.contain('Hi');
    expect(sideNavSignedInLabel.visible, 'User should be signed in after registration').to.be.true;

    await shared.openSettings();
    await testUtils.waitForCurrentScreenToEqual('settingsScreen')
    await testUtils.waitForElementToHaveFocus('settingsMenu');
    await testUtils.jumpToGridItemWithTitle('settingsMenu', 'Sign Out');

    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify OneTrust banner appears again after sign out
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner should appear after sign out', 10000);
    const otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible, 'OneTrust banner should be visible after sign out').to.be.true;
    expect(otBanner.opacity, 'OneTrust banner should be fully visible').to.equal(1);

  });
});
