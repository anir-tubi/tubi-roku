import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Age Gate', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/242480
  it('C242480 - COPPA V3 - Guest User access Kids mode and selects exit kids option. User is presented with Age Gate, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate screen
    await verifyAgeGateScreen();

  });

  // https://tubi.testrail.io/index.php?/cases/view/408197
  it('C408197 - Guest User - Error shown immediately when entering age above 125, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Sign in
    await selectSignInFromHomeScreen();

    // wait for Let's Create Your Account Modal and Continue
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Land on Sign In to Your Account page
    const signInScreenPasswordBox = await testUtils.getNodeForElement('signInScreenPasswordBox');
    expect(signInScreenPasswordBox.visible).to.be.true;

    // Create Account
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    const emailAddressBox = testUtils.getNodeForElement('emailAddressBox');
    expect(emailAddressBox).to.exist;

    // Now we need to make our user with not registered with Tubi
    const email = `build_roku_${Math.floor(Date.now() / 1000)}@tubi.tv`;

    // Send email address
    await ecp.sendText(email);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(500);

    // Verify Age Gate Screen
    await utils.sleep(2000);
    await yearsVerificationEntry();

    // Enter invalid Age >  125
    await ecp.sendText('126');

    // Verify error message
    const ageGateInvalidAge = await testUtils.getNodeForElement('ageGateInvalidAge');
    expect(ageGateInvalidAge.visible).to.equal(true);

  });

  // https://tubi.testrail.io/index.php?/cases/view/408196
  it('C408196 - Guest User - Error shown immediately when entering age with leading 0, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Sign in
    await selectSignInFromHomeScreen();

    // wait for Let's Create Your Account Modal and Continue
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Land on Sign In to Your Account page
    const signInScreenPasswordBox = await testUtils.getNodeForElement('signInScreenPasswordBox');
    expect(signInScreenPasswordBox.visible).to.be.true;

    // Create Account
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    const emailAddressBox = testUtils.getNodeForElement('emailAddressBox');
    expect(emailAddressBox).to.exist;

    // Now we need to make our user with not registered with Tubi
    const email = `build_roku_${Math.floor(Date.now() / 1000)}@tubi.tv`;

    // Send email address
    await ecp.sendText(email);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate Screen
    await yearsVerificationEntry();

    // Enter invalid Age of 0
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    const ageGateInvalidAge = await testUtils.getNodeForElement('ageGateInvalidAge');
    expect(ageGateInvalidAge.visible).to.equal(true);

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/242820
  it('C242820 - COPPA V3 - Guest User enters in age greater than 12 they are directed to the Tubi Homepage (non-kids), @age_gate, @smoke', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate Screen
    await verifyAgeGateScreen();

    // Enter age > 12
    await ecp.sendText('2009');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check if we are in the non-kids mode since user passed age gate
    // Verify on home screen
    const homeScreenRowList = testUtils.getNodeForElement('homeScreenRowList');
    const leftNavHomeButton = testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav and check for Kids left nav icon
    await ecp.sendKeypress(ecp.Key.Left);
    expect((await leftNavHomeButton).visible).to.equal(true);


  });

  // https://tubi.testrail.io/index.php?/cases/view/242819
  it('C242819 - COPPA V3 - Guest User enters in age lower than 13 they are locked into kids mode, @age_gate, @smoke', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate Screen
    await verifyAgeGateScreen();

    // Enter age > 12
    await ecp.sendText('2010');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check if we are in the non-kids mode since user passed age gate
    // Verify on home screen

    const homeScreenRowList = testUtils.getNodeForElement('homeScreenRowList');
    const cannotExitKidsMode = testUtils.getNodeForElement('cannotExitKidsMode');
    const exitKidsOption = testUtils.getNodeForElement('exitKidsOption');
    const leftNavHomeButton = testUtils.getNodeForElement('leftNavHomeButton');
    const buttonTextClose = testUtils.getNodeForElement('buttonTextClose');


    // Verify cannot exit Kids Mode modal
    expect((await cannotExitKidsMode).visible).to.equal(true);
    expect((await buttonTextClose).visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Left);
    expect((await leftNavHomeButton).visible).to.equal(true);

  });
  /*  https://tubi.testrail.io/index.php?/cases/edit/242815
      https://tubi.testrail.io/index.php?/cases/view/242816
      https://tubi.testrail.io/index.php?/cases/view/242818
  */
  it('C242818 - COPPA V3 - Guest User exits kids mode and enters age of user between 0-4 again after user is presented with make sure information is correct prompt, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate Screen
    await verifyAgeGateScreen();

    // Enter age between 2020
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    const ageGateVerificationErrorPrompt = await testUtils.getNodeForElement('ageGateVerificationErrorPrompt');
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');

    // Back to Exit Kids
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter age between 2021
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Verify error message
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');


    // Back to Exit Kids
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter age between 2022
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');

    // Back to Exit Kids
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter age between 2023
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');

  });
});



  async function openKidsMode() {

    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(3000); // Adding sleeps temporary
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.be.true;
  }

  async function selectSignInFromHomeScreen() {
    // Sign in
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  async function verifyAgeGateScreen() {
    const ageVerificationNumberPad = await testUtils.getNodeForElement('ageVerificationNumberPad');
    const hasFocus = await testUtils.elementHasFocus('ageVerificationNumberPad');
    expect(hasFocus).to.be.true;
  }

  async function yearsVerificationEntry() {
    await utils.sleep(2000);
    const yearsVerificationEntry = await testUtils.getNodeForElement('yearsVerificationEntry');
    expect(yearsVerificationEntry).to.exist;
  }
