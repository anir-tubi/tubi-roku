import { expect } from "chai";
import { ecp, odc, utils, proxy } from "roku-test-automation";
import { testUtils } from "../test-utils";
import { testHelpers } from "../test-helpers";


/**
 * Account switching matrix tests
 *This is a complex function which maps the below table to the various switch requirements.
* From ↓ Switch To →
*                           | Guest_Normal            | Guest_(Kids_Mode)           | Adult_Account            | Adult_Account(Kids_mode) | Kids_Account_(younger_or_same)     | Kids_Account_(older) | "Add_a_new_account:_Sign_In/_Sign_up
* |-------------------------|-------------------------|-----------------------------|--------------------------|--------------------------|---------------------------------   |----------------------|--------------------------------------------|
* | Guest_Normal            | -------                 | allowed                     | Allowed                  | No_Path                  | allowed                            | allowed              | allowed
* | Guest_(Kids_Mode)       | Age_gate                | -------                     | Age_gate                 | No_Path                  | Age_gate                           | Age_gate             | allowed
* | Guest_(Locked_Kids_Mode)| No_Path                 | -------                     | signInPasswordGate       | No_Path                  | allowed                            | allowed              | allowed
* | Adult_Account           | allowed                 | No_Path                     | allowed                  | allowed                  | allowed                            | allowed              | allowed
* | Adult_Account(Kids_mode)| passWordGate            | No_Path                     | passwordGate             | -------                  | allowed                            | PasswordGate         | allowed
* | Kids_Account_(younger)  | PIN,_if_enabled         | No_Path                     | PIN,_if_enabled          | No_Path                  | allowed                            | PIN,_if_enabled      | allowed
* | Kids_Account_(older)    | PIN,_if_enabled         | No_Path                     | PIN,_if_enabled          | No_Path                  | allowed                            | PIN,_if_enabled      | allowed
* | Adult Account(Kid pc)   | passWordGate            | No_Path                     | passwordGate             | No_path                  | allowed                            | PasswordGate         | allowed

 */
describe('account-switching-matrix', function () {

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


  /**
   * Handles the PIN gate that appears when switching from a kids account.
   * Maps to getUserSwitchAction "pinGate" / "pcCheckPinGate" when PIN is set.
   * Uses parentalControlEnterPinPad at ScreenStack position 1.
   */
  async function enterPinGate(pin: string = '1111') {
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlEnterPinPad', 'PIN pad did not appear', 10000);
    await ecp.sendText(pin);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
  }


  /**
   * Handles the password gate (ConfirmPasswordScreen) that appears when
   * switching from adultInKidsMode / adultInKidsPC accounts.
   * Maps to getUserSwitchAction "passwordGate" / "pcCheckPasswordGate".
   * ConfirmPasswordScreen is pushed at ScreenStack position 1 from home;
   * its PasswordEntryKeyboard matches forgotPasswordEntryBox element path.
   */
  async function enterPasswordGate(password: string = '111111') {
    await testUtils.waitForElementToFullyShowOnScreen('forgotPasswordEntryBox', 'Password gate did not appear', 10000);
    await ecp.sendText(password);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(1500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
  }


  /**
   * Handles the password gate used for parental control changes within settings.
   * Uses pcPasswordEntryBox at ScreenStack position 2 (settings → password screen).
   */
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


  async function changeParentalControlLevel(level: string) {
    await navigateToContentSettings();
    await testUtils.waitForElementToShowOnScreen('kidsParentalControlsMenu', 'Parental controls menu did not open', 5000);

    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForGridContentToLoad('kidsParentalControlsMenu');
    await testUtils.jumpToGridItemWithTitle('kidsParentalControlsMenu', level);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
  }


  async function changeParentalControlLevelwithPassword(level: string) {
    await navigateToContentSettings();
    await testUtils.waitForElementToShowOnScreen('kidsParentalControlsMenu', 'Parental controls menu did not open', 5000);

    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForGridContentToLoad('kidsParentalControlsMenu');
    await testUtils.jumpToGridItemWithTitle('kidsParentalControlsMenu', level);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testHelpers.enterPassword('111111');
    await testUtils.waitForElementToShowOnScreen('parentalControlsChangeDialog', 'Content Settings Updated dialog did not appear', 10000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate', 20000);
  }


  /**
   * Wipes the registry, relaunches the app, and rebuilds the
   * AP1 + AP2 + testkid1 environment from scratch.
   *
   * Password cache (pwExpTs) lives in the registry under each profile's auth
   * info for 24 hours. The only reliable way to reset it within a test run is
   * to clear the registry and re-add the users. Call this before any test
   * block that needs a deterministic passwordGate to appear.
   *
   * After this helper returns, AP1 is the active profile and testkid1 exists
   * under AP1 with PIN 1111.
   */
  async function resetAndRecreateUsers() {
    await testUtils.startApplicationAtPage('home' as any, {
      clearRegistry: true,
      shouldCreateNewUser: true,
    });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus after reset');

    await addAdultAccount('automationparent1@tubi.tv', '111111');
    await waitForHomeScreen();

    await addAdultAccount('automationparent2@tubi.tv', '111111');
    await waitForHomeScreen();

    // Restart so the kid-account flow sees a hydrated profile list
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 18000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus after reset restart', 20000);

    await addKidsAccount('Automation', 'testkid1', '1111');

    // `addKidsAccount` ends with testkid1 active. Kids → Adult routes through
    // pcCheckPinGate, which is pinGate since the parent (AP1) now has a PIN.
    // pinGate (unlike passwordGate) does NOT prime the pwExpTs cache, so using
    // it here is safe for downstream passwordGate assertions.
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after reset', 20000);
  }



  // ═══════════════════════════════════════════════════════════════════
  // SETUP: Create multi-account environment with 2 adults + 1 kid
  // ═══════════════════════════════════════════════════════════════════

  it('C791743 - Account creation existing user, not parent: Returning adult user can activate account and see "Welcome, First Name", @account_switching', async () => {
    await testUtils.startApplicationAtPage('home' as any, {
      clearRegistry: true,
      shouldCreateNewUser: true,
    });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await addAdultAccount('automationparent1@tubi.tv', '111111');
    await waitForHomeScreen();
  });


  it('C791741 - Account creation: Returning adult user can add account for adults, @account_switching', async () => {
    await addAdultAccount('automationparent2@tubi.tv', '111111');
    await waitForHomeScreen();
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 18000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);

    await openProfileMenu();
    const profileMenu = await testUtils.getNodeForElement('profileSelectionMenu');
    expect(profileMenu).to.not.be.undefined;

    // Close profile menu and side nav, return focus to main content
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Focus did not return to main content after profile menu check', 10000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM ADULT ACCOUNT → Various (default Adult content settings)
  // switchmap: adultAccount-* = "pcCheckPasswordGate"
  // With both source and target on the default Adult rating (pcMap=5),
  // the currentPCRating >= inComingPCRating short-circuit returns "allowed"
  // and no gate is shown.
  // ═══════════════════════════════════════════════════════════════════

  it('C824324 - Account switching: Registered adult to registered adult, @account_switching', async () => {
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after adult → adult switch', 20000);
  });


  it('C824325 - Account switching: Registered adult to registered kid, @account_switching', async () => {
    // Default Adult (pcMap=5) → Kid (pcMap 0-2): 5 >= * → allowed.
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
  });




  it('C824330 - Account switching: Registered Kid to Registered Adult - with Pin, @account_switching', async () => {
    // Currently on testkid1 does not have a PIN set, switch to AUTOMATIONPARENT1
    // processKidsPinGate checks parentAuthInfo.hasPin → shows ParentalControlPinInputScreen
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('C791742 - Account creation: Returning adult user can add account for kids, @account_switching', async () => {
    // Kid creation must happen after restart so that the parent's hasPin flag
    // stays in memory for processKidsPinGate / checkIfPinSetByParent
    await addKidsAccount('Automation', 'testkid1', '1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('C824333 - Account switching: Registered Kid to Guest Adult, @account_switching', async () => {

    // Switch to testkid1 first (AP1 has PIN set from setup)

    // Kid (rating 0) → Guest (rating 5): 0 < 5 → pcCheckPinGate.
    // checkIfPinSetByParent(testkid1) === true because AP1 has PIN → pinGate.
    await switchToProfile('Guest');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after kids → guest pin gate', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM GUEST NORMAL → Various
  // switchmap: guest-guest/adultAccount/kidsAccount = "allowed"
  // ═══════════════════════════════════════════════════════════════════

  it('C824339 - Account switching: Guest adult to Registered adult, @account_switching', async () => {
    // Currently on Guest from previous test
    await switchToProfile('AUTOMATIONPARENT2');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after guest → adult', 20000);
  });


  it('C824328 - Account switching: Registered adult to Guest Adult, @account_switching', async () => {
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after adult → guest', 20000);
  });


  it('C824340 - Account switching: Guest adult to Registered kid, @account_switching', async () => {
    // Currently on Guest
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
  });


  it('C824344 - Account switching: Guest Adult to Guest kid, @account_switching', async () => {
    // Switch to Guest, then enter Kids Mode
    await switchToProfile('Guest');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);

    await testHelpers.openKidsMode();

    // Exit kids mode → age gate per switchmap guestkid-guest
    await testHelpers.exitKidsModeWithAgeGate(18);

  });


  it('C824347 - Account switching: Guest kid to registered adult when there are previously registered users, @account_switching', async () => {
    // Re-enter kids mode
    await testHelpers.openKidsMode();

    // Exit kids mode — age gate was already passed in previous test,
    // so this time it's a direct pass (no age gate shown)
    await testHelpers.exitKidsMode();

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus(
      'videoTitlesRowList',
      'Home screen did not load after exiting kids mode (second exit, no age gate)',
      20000,
    );
  });


  it('C824349 - Account switching: Guest Kid to Registered Kids, @account_switching', async () => {
    // Re-enter kids mode as guest
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
    await testHelpers.openKidsMode();

    // Switching to a kids account from guest kids mode should be allowed
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    // Return to adult (PIN gate from kid)
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM ADULT (Teen content setting) → Various
  // With the new logic, every `adultAccount-*` entry in switchmap is
  // `pcCheckPasswordGate`. Teen has currentPCRating = pcMap["2"] = 4,
  // while a default adult has inComingPCRating = pcMap["3"] = 5.
  // Teen (4) < Adult (5) so switching Teen → Adult falls through to the
  // pcCheckPasswordGate branch → passwordGate is required.
  // Teen → Kids (<=4) is still allowed because 4 >= kidRating.
  // Adult (default, 5) → Teen (4) is allowed because 5 >= 4.
  // ═══════════════════════════════════════════════════════════════════

  it('C825289 - Parental control: when adult user switches to Teen account, @parental_controls', async () => {
    await navigateToContentSettings();
    await testUtils.waitForElementToShowOnScreen('kidsParentalControlsMenu', 'Parental controls menu did not open', 5000);

    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForGridContentToLoad('kidsParentalControlsMenu');

    await testUtils.jumpToGridItemWithTitle('kidsParentalControlsMenu', 'Age Rating 13-17');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Right);


    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('C824336 - Account switching: Registered Kid older kid to Registered Kid - Teen (No Pin set), @account_switching', async () => {
    // Teen (pcMap=4) → Kid (pcMap 0-2): 4 >= * → allowed (short-circuits the
    // adultAccount-kidsAccount pcCheckPasswordGate entry).
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after adult(teen) → kids', 20000);
    await utils.sleep(2000);
  });


  it('C824335 - Account switching: Registered Kid older kid to Registered Kid - Teen (with Pin), @account_switching', async () => {
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });




  //adult to Teen
  it('C825289 - Parental control: when adult user switches to Teen account, @parental_controls', async () => {
    await switchToProfile('AUTOMATIONPARENT2');
    await enterPasswordGate('111111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after teen → adult password gate', 20000);
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);

    // it('Setup: Reset registry and rebuild AP1+AP2+testkid1 for Little Kids section, @content_settings', async () => {
    // Reset registry and rebuild AP1+AP2+testkid1 for Little Kids section,
    await resetAndRecreateUsers();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
    await changeParentalControlLevel('Age Rating 4-6');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
  });


  it('C825288 - Parental control: when user switch from adult to kids account, @parental_controls', async () => {
    await switchToProfile('AUTOMATIONPARENT2');
    await enterPasswordGate('111111');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate', 20000);

    // AP2 default Adult (pcMap=5) → AP1 Little Kids (pcMap=1): 5 >= 1 → allowed.
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate', 20000);

    // AP1 Little Kids (pcMap=1) → testkid1 (young kid, pcMap 0 or 1).
    // 1 >= 0/1 → allowed up-front, no gate.
    await switchToProfile('testkid1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    // Return to AP1 — kidsAccount-adultAccount = pcCheckPinGate → pinGate.
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000)
  });












  it('C835213 - [Kids v1] Adult Registration - Submit age gate, @kids_v1', async () => {

    await testUtils.restartApplication();
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);
    await testHelpers.openKidsMode();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);
    await testHelpers.exitKidsMode();

    // Wait for age gate screen to appear
    await testUtils.waitForElementToShowOnScreen(
      'ageVerificationNumberPad',
      'Age gate not shown after selecting Exit Kids',
      10000,
    );

    // Enter birth year for the given age
    const birthYear = new Date().getFullYear() - 11;
    await ecp.sendText(birthYear.toString());

    // Navigate to submit button and press OK
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);
    await switchToProfile('AUTOMATIONPARENT2');
    await enterPasswordGate('111111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);
    // Age Gated to kids
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);
    await switchToProfile('testkid1');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after cached guest switch', 20000);


    //Reset Automation


    await switchToProfile('AUTOMATIONPARENT2');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);

    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
    await changeParentalControlLevelwithPassword('Age Rating 18+');

  });



});
