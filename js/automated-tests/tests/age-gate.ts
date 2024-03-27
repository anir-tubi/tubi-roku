import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Age Gate', function () {
  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/242480
  it('C242480 - COPPA V3 - Guest User access Kids mode and selects exit kids option. User is presented with Age Gate, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await exitKidsMode();

    // Verify Age Gate screen
    await verifyAgeGateScreen();

  });

  // https://tubi.testrail.io/index.php?/cases/view/408197
  it('C408197 - Guest User - Error shown immediately when entering age above 125, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Sign in
    await selectSignInFromHomeScreen();

    // wait for Let's Create Your Account Modal and Continue
    await utils.sleep(3000); // Roku modal
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
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate Screen
    await testUtils.waitForElementToShowOnScreen('ageVerificationPad');
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
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Sign in
    await selectSignInFromHomeScreen();

    // wait for Let's Create Your Account Modal and Continue
    await utils.sleep(3000); // Roku modal
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
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');


    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await exitKidsMode();

    // Verify Age Gate Screen
    await verifyAgeGateScreen();

    // Enter age > 12
    await ecp.sendText('2009');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check if we are in the non-kids mode since user passed age gate
    // Verify on home screen
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav and check for Kids left nav icon
    await ecp.sendKeypress(ecp.Key.Left);
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    expect(leftNavHomeButton.visible).to.equal(true);
  });

  // https://tubi.testrail.io/index.php?/cases/view/242819
  it('C242819 - COPPA V3 - Guest User enters in age lower than 13 they are locked into kids mode, @age_gate, @smoke', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await exitKidsMode();

    // Verify Age Gate Screen
    await verifyAgeGateScreen();

    // Enter age < 13
    const year = new Date().getFullYear() - 13;
    await ecp.sendText(year.toString());
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on home screen

    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    const cannotExitKidsModeTitle = await testUtils.getNodeForElement('cannotExitKidsModeTitle');
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    const leftNavHomeButtonLabel = await testUtils.getNodeForElement('leftNavHomeButtonLabel');
    const buttonTextClose = await testUtils.getNodeForElement('buttonTextClose');


    // Verify cannot exit Kids Mode modal appears and can be closed
    expect(cannotExitKidsModeTitle.text).to.equal('Cannot Exit Kids Mode');
    expect(buttonTextClose.text).to.equal('Close');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Left);
    expect(leftNavHomeButtonLabel.text).to.equal('Home');
  });

  /*  https://tubi.testrail.io/index.php?/cases/edit/242815
      https://tubi.testrail.io/index.php?/cases/view/242816
      https://tubi.testrail.io/index.php?/cases/view/242818
  */
  it('C242818 - COPPA V3 - Guest User exits kids mode and enters age of user between 0-4 again after user is presented with make sure information is correct prompt, @age_gate', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open Kids Mode
    await openKidsMode();

    // Exit Kids Mode
    await exitKidsMode();

    // Verify Age Gate Screen
    await verifyAgeGateScreen();

    // Enter age between 0 and 4
    const year = new Date().getFullYear() - 3;
    await ecp.sendText(year.toString());
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    const ageGateVerificationErrorPrompt = await testUtils.getNodeForElement('ageGateVerificationErrorPrompt');
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');

    // Back to Exit Kids
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter age between 0 and 4
    await ecp.sendKeypress(ecp.Key.Right);
    const year2 = new Date().getFullYear() - 2;
    await ecp.sendText(year2.toString());
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);


    // Verify error message
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');


    // Back to Exit Kids
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter age between 0 and 4
    await ecp.sendKeypress(ecp.Key.Right);
    const year3 = new Date().getFullYear() - 1;
    await ecp.sendText(year3.toString());
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');

    // Back to Exit Kids
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter age between
    await ecp.sendKeypress(ecp.Key.Right);
    const year4 = new Date().getFullYear() - 0;
    await ecp.sendText(year4.toString());
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify error message
    expect(ageGateVerificationErrorPrompt.text).to.equal('Please be sure the information you entered is correct');

  });
});

  async function openKidsMode() {
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.selectMenuItem('sideNavMenu', 'Kids');
  }

  async function exitKidsMode() {
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.selectMenuItem('sideNavMenu', 'Exit Kids');
  }

  async function selectSignInFromHomeScreen() {
    // Sign in
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  async function verifyAgeGateScreen() {
    await testUtils.waitForElementToShowOnScreen('ageVerificationNumberPad');
  }

  async function yearsVerificationEntry() {
    await testUtils.waitForElementToShowOnScreen('yearsVerificationEntry');
    expect(yearsVerificationEntry).to.exist;
  }
