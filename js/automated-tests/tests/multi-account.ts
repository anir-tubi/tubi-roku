import { expect } from "chai";
import { ecp, odc, utils, proxy } from "roku-test-automation";
import { testUtils } from "../test-utils";
import { testHelpers } from "../test-helpers";


describe('multi-account', function () {

  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });


  async function openProfileMenu() {
    await testHelpers.openLeftNav();
    await testUtils.jumpToRowIndex('sideNavMenu', 0);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToShowOnScreen('profileSelectionMenu', 'Profile menu did not open', 5000);
  }


  async function switchToProfile(profileName: string) {
    await openProfileMenu();
    await testUtils.jumpToRowWithTitle('profileSelectionMenu', profileName);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
  }


  async function addAdultAccount(email: string, password: string) {
    await openProfileMenu();
    await testUtils.jumpToRowWithTitle('profileSelectionMenu', 'Add Account');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('emailInputScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('emailInputOrAddKidsScreenKeyboard');
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendText(email);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('signInScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('signInScreenPasswordBox');
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText(password);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
  }


  async function addKidsAccount(parentProfileMatch: string, kidName: string, pin: string = '1111') {
    await openProfileMenu();
    await testUtils.jumpToRowWithTitle('profileSelectionMenu', 'Add Account');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('emailInputScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('emailInputOrAddKidsScreenKeyboard');

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    await testUtils.waitForElementToShowOnScreen('emailInputOrAddKidsScreenProfileMenu', 'Profile menu on Kids tab did not appear', 5000);
    await testUtils.jumpToProfile('emailInputOrAddKidsScreenProfileMenu', parentProfileMatch);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('nameInputScreen', 15000);
    await testUtils.waitForElementToFullyShowOnScreen('nameInputScreenNameBox');
    await ecp.sendText(kidName);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await testUtils.waitForCurrentScreenToEqual('kidsAgeSelectionScreen', 15000);
    await testUtils.waitForElementToFullyShowOnScreen('kidsAgeSelectionScreenHeader');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await testUtils.waitForCurrentScreenToEqual('parentalControlPinInputScreen', 15000);
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlPinInputScreenHeader');
    await ecp.sendText(pin);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await testUtils.waitForCurrentScreenToEqual('kidsAccountSetupScreen', 15000);
    await testUtils.waitForElementToFullyShowOnScreen('kidsAccountSetupScreenHeader');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
  }


  async function waitForHomeScreen() {
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
  }


  async function enterPinGate(pin: string = '1111') {
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlEnterPinPad', 'PIN pad did not appear', 10000);
    await ecp.sendText(pin);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
  }


  async function enterSettingsPasswordGate(password: string = '111111') {
    await testUtils.waitForElementToFullyShowOnScreen('pcPasswordEntryBox', 'Settings password box did not appear', 10000);
    await ecp.sendText(password);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(1500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
  }


  async function navigateToContentSettings() {
    await testHelpers.openLeftNav();
    await testUtils.jumpToRowIndex('sideNavMenu', 10);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('settingsScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('settingsMenu');
    await testUtils.waitForGridContentToLoad('settingsMenu');
    await testUtils.jumpToGridItemWithTitle('settingsMenu', 'Content Settings');
    await ecp.sendKeypress(ecp.Key.Ok);
  }


  // ═══════════════════════════════════════════════════════════════════
  // TOOLTIP TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/535773
  // https://tubi.testrail.io/index.php?/cases/view/825300
  it('C825300 - Sidenav tooltip element present for single user, @sidenav', async () => {
    await testUtils.startApplicationAtPage('home' as any, {
      clearRegistry: true,
      shouldCreateNewUser: true,
    });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 18000);
    await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');
    await utils.sleep(1000);

    const tooltip = await testUtils.getNodeForElement('sideNavAddAccountsTooltip', 5000);
    expect(tooltip).to.not.be.undefined;

    // Tooltip auto-hides after ~12 seconds; after 15 seconds it should be removed
    await utils.sleep(15000);
    const element = testUtils.getElementKeyPath('sideNavAddAccountsTooltip');
    const { found } = await odc.getValue(element, { timeout: 3000 });
    expect(found).to.be.false;
  });


  // ═══════════════════════════════════════════════════════════════════
  // PARENTAL CONTROLS TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C825287 - Parental controls: 6 parental controls are displayed in the settings', async () => {
    await navigateToContentSettings();
    await testUtils.waitForElementToShowOnScreen('parentalControlsMenu', 'Parental controls menu did not open', 5000);
    const parentalControlsCount = await testUtils.getElementField('parentalControlsMenu', 'content.getChildCount()');
    expect(parentalControlsCount).to.equal(6);
  });


  // https://tubi.testrail.io/index.php?/cases/view/825289
  it('C825289 - Parental control: when adult user switches to Teen account', async () => {
    // Continues from C825287: still in parental controls menu
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToShowOnScreen('parentalControlsChangeDialog', 'Content Settings Updated dialog did not appear', 10000);
    const dialogMessage = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(dialogMessage.text).to.contain('Age Rating 13–17 (Up to TV-14 / PG-13)');

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
  });


  // https://tubi.testrail.io/index.php?/cases/view/825288
  it('C825288 - Parental control: when user switch from adult to kids account', async () => {
    // Continues from C825289: still in parental controls area
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToShowOnScreen('parentalControlsChangeDialog', 'Content Settings Updated dialog did not appear', 10000);
    const dialogTitle = await testUtils.getNodeForElement('parentalControlsDialogTitle');
    expect(dialogTitle.text).to.equal('Content Settings Updated');

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);
  });


  it('C825297 - Parental control: Guest adult user change the parental control settings from teen to Adult by entering password', async () => {
    // Continues from C825288: password gate triggered
    await enterSettingsPasswordGate('111111');

    await testUtils.waitForElementToShowOnScreen('parentalControlsChangeDialog', 'Content Settings Updated dialog did not appear', 10000);
    const dialogTitle1 = await testUtils.getNodeForElement('parentalControlsDialogTitle');
    expect(dialogTitle1.text).to.equal('Content Settings Updated');
    const dialogMessage = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(dialogMessage.text).to.contain('Age Rating 18+ (Up to TV-MA / R / NC-17)');

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // SIGN OUT TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C825281 - Sign out: Adult parent can signout from their profile', async () => {
    // Continues from C825297: still in settings area
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToHaveFocus('signOutButton', 'Sign Out button did not have focus', 10000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await testUtils.waitForElementToShowOnScreen('signOutVerificationModalMessage', 'Sign Out verification modal message not found', 10000);
    const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(signOutVerificationModalMessage.text).to.equal('You are about to sign out of Tubi account. This will log out all linked kids accounts.');

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Back);
    await waitForHomeScreen();
  });


  // ═══════════════════════════════════════════════════════════════════
  // PROFILE MENU & ADD ACCOUNT TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/824326
  it('C824326 - Sidenav profile menu opens and gains focus when first item selected, @sidenav', async () => {
    await openProfileMenu();
    await testUtils.waitForElementToHaveFocus('profileSelectionMenu', 'Profile menu did not gain focus', 5000);

    // Add adult account via profile menu (testing profile menu focus + add account flow)
    await testUtils.jumpToRowWithTitle('profileSelectionMenu', 'Add Account');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('emailInputScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('emailInputOrAddKidsScreenKeyboard');

    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendText('automationparent1@tubi.tv');
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('signInScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('signInScreenPasswordBox');
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // CONTENT SETTINGS MANAGEMENT TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C825291 - Parental control: Adult parent editing child content settings', async () => {
    await navigateToContentSettings();
    await testUtils.waitForElementToShowOnScreen('AccountsList', 'account content settings menu did not open', 5000);
    const contentSettingsCount = await testUtils.getElementField('AccountsList', 'content.getChildCount()');
    expect(contentSettingsCount).to.greaterThan(1);
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForElementToShowOnScreen('kidsParentalControlsMenu', 'parental controls menu did not open', 5000);
    const parentalControlsCount = await testUtils.getElementField('kidsParentalControlsMenu', 'content.getChildCount()');
    expect(parentalControlsCount).to.equal(4);
    await ecp.sendKeypress(ecp.Key.Back);
  });


  it('C825292 - Parental control: Adult parent can edit their pin for the kids account', async () => {
    // Continues from C825291: in settings content area
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);
    await testUtils.waitForElementToShowOnScreen('AccountsList', 'account content settings menu did not open', 5000);
    await testUtils.jumpToRowWithTitle('AccountsList', 'AUTOMATIONPARENT1');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('adultParentalControlsMenu');
    await testUtils.jumpToRowIndex('adultParentalControlsMenu', 5, 5000);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Down);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlPinPad');
    const createPinTitle = await testUtils.getNodeForElement('parentalControlConfirmPinTitle');
    expect(createPinTitle.text).to.equal('Create New PIN');
    await ecp.sendText('1111');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await testUtils.waitForElementToFullyShowOnScreen('parentalControlPinPad');
    const confirmPinTitle = await testUtils.getNodeForElement('parentalControlConfirmPinTitle');
    expect(confirmPinTitle.text).to.equal('Confirm New PIN');
    await ecp.sendText('1111');
    await utils.sleep(1000);
    const continueButton = await testUtils.getNodeForElement('parentalControlPinContinueButton');
    expect(continueButton.text).to.equal('Update PIN');
    await ecp.sendKeypress(ecp.Key.Ok);
  });


  // ═══════════════════════════════════════════════════════════════════
  // PROFILE NAVIGATION TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/791744
  it('C791744 - Profile menu shows magalu1 item, @sidenav', async () => {
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await waitForHomeScreen();

    await openProfileMenu();
    await testUtils.jumpToRowWithTitle('profileSelectionMenu', 'magalu1');
  });


  // https://tubi.testrail.io/index.php?/cases/view/791742
  it('C791742 - Add Kids from side nav profile menu, @sidenav', async () => {
    await addKidsAccount('Automation', 'kid1', '1111');
  });


  // ═══════════════════════════════════════════════════════════════════
  // PIN & PASSWORD GATE TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C825298 - Forgot pin: adult user enter incorrect pin', async () => {
    // Switch to kids profile first
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(1000);

    // Switch to adult — triggers PIN gate from kids account
    await switchToProfile('AUTOMATIONPARENT1');

    // Navigate to "Forgot PIN" by scrolling down past the pin pad
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlEnterPinPad');
    await ecp.sendKeypress(ecp.Key.Down, { count: 5, wait: 1000 });
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter password on the forgot pin password screen
    await testUtils.waitForElementToFullyShowOnScreen('forgotPasswordEntryBox', 'Password box not found', 10000);
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(1500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Create new PIN
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlEnterPinPad');
    const createPinTitle = await testUtils.getNodeForElement('parentalControlForgotPinPadTitle');
    expect(createPinTitle.text).to.equal('Create New PIN');
    await ecp.sendText('1111');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Confirm new PIN
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlEnterPinPad');
    const confirmPinTitle = await testUtils.getNodeForElement('parentalControlForgotPinPadTitle');
    expect(confirmPinTitle.text).to.equal('Confirm New PIN');
    await ecp.sendText('1111');
    await utils.sleep(1000);
    const continueButton = await testUtils.getNodeForElement('parentalControlForgotPinContinueButton');
    expect(continueButton.text).to.equal('Update PIN');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
  });
});
