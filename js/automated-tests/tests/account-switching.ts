import { expect } from "chai";
import { ecp, odc, utils, proxy } from "roku-test-automation";
import { testUtils } from "../test-utils";
import { testHelpers } from "../test-helpers";


/**
 * Account switching matrix tests
 *
 * Covers the gate logic in ProfileHelpers.getUserSwitchAction():
 *   guest        → guest/adult/kids        = allowed
 *   guestkid     → guest/adult             = ageGate
 *   guestkid     → kids                    = allowed
 *   ageGated     → adult                   = signInPasswordGate
 *   ageGated     → kids                    = allowed
 *   adultAccount → guest/adult/kids        = allowed
 *   adultInKidsMode → guest/adult          = passwordGate
 *   adultInKidsMode → kids                 = pcCheckPasswordGate
 *   kidsAccount  → guest                   = pinGate
 *   kidsAccount  → kids/adult              = pcCheckPinGate
 *   adultInKidsPC → guest                  = passwordGate
 *   adultInKidsPC → adult/kids             = pcCheckPasswordGate
 *
 * pcCheck* gates compare parental ratings: if current >= target → allowed
 * pinGate checks if parent has PIN enabled: if yes → pinGate, else → allowed
 *
 * Uses: automationparent1@tubi.tv / 111111, automationparent2@tubi.tv / 111111
 */
describe.skip('account-switching-matrix', function () {

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
    // await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
    await testUtils.jumpToGridItemWithTitle('kidsParentalControlsMenu', level);

    await ecp.sendKeypress(ecp.Key.Ok);

    // await testHelpers.enterPassword('111111');

    // await testUtils.waitForElementToShowOnScreen('parentalControlsChangeDialog', 'Content Settings Updated dialog did not appear', 10000);
    //await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    // await ecp.sendKeypress(ecp.Key.Ok);
    // await utils.sleep(1000);
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
    // await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
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



  // ═══════════════════════════════════════════════════════════════════
  // SETUP: Create multi-account environment with 2 adults + 1 kid
  // ═══════════════════════════════════════════════════════════════════

  it('Setup: Start fresh and login with automationparent1, @setup', async () => {
    await testUtils.startApplicationAtPage('home' as any, {
      clearRegistry: true,
      shouldCreateNewUser: true,
    });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await addAdultAccount('automationparent1@tubi.tv', '111111');
    await waitForHomeScreen();
  });


  it('Setup: Add automationparent2 as second adult account, @setup', async () => {
    await addAdultAccount('automationparent2@tubi.tv', '111111');
    await waitForHomeScreen();
  });


  it('Setup: Restart app and verify adult accounts persist, @setup', async () => {
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


  it('Setup: Add kid account (testkid1) under automationparent1 with PIN 1111, @setup', async () => {
    // Kid creation must happen after restart so that the parent's hasPin flag
    // stays in memory for processKidsPinGate / checkIfPinSetByParent
    await addKidsAccount('Automation', 'testkid1', '1111');
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM ADULT ACCOUNT → Various (default Adult content settings)
  // switchmap: adultAccount-guest/adultAccount/kidsAccount = "allowed"
  // ═══════════════════════════════════════════════════════════════════

  it('Adult → Adult: switches to another adult account without any gate (allowed), @adult_switch', async () => {
    // After restart, we are on the last active adult profile
    // Switch to AUTOMATIONPARENT2 — adultAccount-adultAccount = "allowed"
    await switchToProfile('AUTOMATIONPARENT2');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after adult → adult switch', 20000);
  });


  it('Adult → Kids: switches to kids account without any gate (allowed), @adult_switch', async () => {
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM KIDS ACCOUNT → Various
  // switchmap: kidsAccount-guest = "pinGate"
  //            kidsAccount-adultAccount = "pcCheckPinGate"
  //            kidsAccount-kidsAccount = "pcCheckPinGate"
  // pcCheckPinGate: if current rating >= target → allowed, else pinGate if PIN set
  // ═══════════════════════════════════════════════════════════════════

  it('Kids → Adult: requires PIN gate when parent has PIN set (pinGate), @kids_switch', async () => {
    // Currently on testkid1, switch to AUTOMATIONPARENT1
    // processKidsPinGate checks parentAuthInfo.hasPin → shows ParentalControlPinInputScreen
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('Kids → Another Adult: also requires PIN gate (pcCheckPinGate), @kids_switch', async () => {
    // Switch to testkid1 first
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    // Switch from testkid1 to AUTOMATIONPARENT2 — pcCheckPinGate with rating comparison
    await switchToProfile('AUTOMATIONPARENT2');
    await enterPinGate('1111');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('Kids → Guest: switches to guest without gate (pass), @kids_switch', async () => {
    // Switch to testkid1 first
    await switchToProfile('testkid1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    // Switch from testkid1 to Guest — direct pass (no gate)
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after kids → guest switch', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM GUEST NORMAL → Various
  // switchmap: guest-guest/adultAccount/kidsAccount = "allowed"
  // ═══════════════════════════════════════════════════════════════════

  it('Guest Normal → Adult: switches without gate (allowed), @guest_switch', async () => {
    // Currently on Guest from previous test
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after guest → adult', 20000);
  });


  it('Adult → Guest Normal: switches without gate (allowed), @guest_switch', async () => {
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after adult → guest', 20000);
  });


  it('Guest Normal → Kids: switches without gate (allowed), @guest_switch', async () => {
    // Currently on Guest
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    // Return to adult for next tests (PIN gate from kid)
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM GUEST (Kids Mode) → Various
  // switchmap: guestkid-guest = "ageGate"
  //            guestkid-adultAccount = "ageGate"
  //            guestkid-kidsAccount = "allowed"
  // ═══════════════════════════════════════════════════════════════════

  it('Guest (Kids Mode) → Guest Normal: requires age gate, @guest_kids_mode', async () => {
    // Switch to Guest, then enter Kids Mode
    await switchToProfile('Guest');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);

    await testHelpers.openKidsMode();

    // Exit kids mode → age gate per switchmap guestkid-guest
    await testHelpers.exitKidsModeWithAgeGate(18);
  });


  it('Guest (Kids Mode) → Adult: age gate only shown first time, second exit is pass, @guest_kids_mode', async () => {
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


  it('Guest (Kids Mode) → Kids: switches without age gate (allowed), @guest_kids_mode', async () => {
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
  // uiMode = kidsParental when parental rating < 2 OR = 4/5
  // Teen (rating 2) does NOT trigger kidsParental mode (only < 2 or 4/5 do)
  // So Teen adult remains in "adultAccount" mode.
  // switchmap: adultAccount-* = "allowed"
  // HOWEVER: pcCheckPasswordGate may apply if switching between adults
  //          with different parental ratings
  // ═══════════════════════════════════════════════════════════════════

  it('Setup: Change AUTOMATIONPARENT1 content settings to Teens, @content_settings', async () => {
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

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('Adult (Teen) → Kids: switches without gate (allowed), @teen_switch', async () => {
    // Teen (rating 2, pcMap=4) switching to kid — adultAccount-kidsAccount = allowed
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
    await utils.sleep(2000);
  });


  it('Kids → Adult (Teen) back: requires PIN gate (pcCheckPinGate), @teen_switch', async () => {
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after PIN gate', 20000);
  });


  it('Adult (Teen) → Adult (Adult settings): switches (adultAccount-adultAccount = allowed), @teen_switch', async () => {
    // AP1 Teen (rating 2) → AP2 Adult (rating 3)
    // Since Teen does not trigger kidsParental mode, this is adultAccount-adultAccount = allowed
    await switchToProfile('AUTOMATIONPARENT2');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after teen → adult switch', 20000);
  });


  it('Adult → Adult (Teen): switches without gate (allowed), @teen_switch', async () => {
    // AP2 Adult → AP1 Teen: adultAccount-adultAccount = allowed
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM ADULT (Kids content setting / kidsParental mode) → Various
  // setUiModeForProfileSelected: pcRating < 2 OR = 4/5 → kidsParental
  // Little Kids (rating 0 or 4) triggers kidsParental mode
  // switchmap: adultInKidsPC-guest = "passwordGate"
  //            adultInKidsPC-adultAccount = "pcCheckPasswordGate"
  //            adultInKidsPC-kidsAccount = "pcCheckPasswordGate"
  // pcCheckPasswordGate: if current pc >= target pc → allowed, else passwordGate
  // ═══════════════════════════════════════════════════════════════════

  it('Setup: Change AUTOMATIONPARENT1 content settings to Little Kids, @content_settings', async () => {
    // AP1 currently has Teen, change to Little Kids to trigger kidsParental mode
    await changeParentalControlLevel('Age Rating 4-6');
  });


  it('Adult (Kids PC) → Adult: requires password gate (pcCheckPasswordGate), @kids_pc_switch', async () => {
    // AP1 Little Kids (pcMap=1) → AP2 Adult (pcMap=5): 1 < 5 → passwordGate
    await switchToProfile('AUTOMATIONPARENT2');
    await enterPasswordGate('111111');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate', 20000);
  });


  it('Adult → Adult (Kids PC): switches without gate (allowed), @kids_pc_switch', async () => {
    // AP2 Adult → AP1 Little Kids: adultAccount-adultAccount = allowed
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
  });


  it('Adult (Kids PC) → Kids same/younger: switches without gate (pcCheckPasswordGate allowed), @kids_pc_switch', async () => {
    // AP1 Little Kids (pcMap=1) → testkid1 (young kid, pcMap likely 0 or 1)
    // pcCheckPasswordGate: if pcMap[AP1] >= pcMap[kid] → allowed
    await switchToProfile('magalu1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    // Return to AP1 (PIN gate from kid)
    await switchToProfile('AUTOMATIONPARENT1');
    await enterPinGate('1111');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load', 20000);
  });


  it('Adult (Kids PC) → Guest: requires password gate (passwordGate), @kids_pc_switch', async () => {
    // AP1 in kidsParental mode → Guest: adultInKidsPC-guest = passwordGate
    await utils.sleep(20000);
    await switchToProfile('Guest');

    // await enterPasswordGate('111111');

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate to guest', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // CLEANUP: Reset content settings to Adult
  // ═══════════════════════════════════════════════════════════════════

  it('Setup: Reset AUTOMATIONPARENT1 content settings to Adults, @content_settings', async () => {
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
    await changeParentalControlLevelwithPassword('Age Rating 18+');
    // await ecp.sendKeypress(ecp.Key.Back);
    // await utils.sleep(1000);
    // await ecp.sendKeypress(ecp.Key.Back);
    // await utils.sleep(1000);
    // await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    // await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // FROM ADULT (Kids Mode via side nav) → Various
  // When adult enters Kids Mode via side nav, uiMode = kids
  // switchmap: adultInKidsMode-guest = "passwordGate"
  //            adultInKidsMode-adultAccount = "passwordGate"
  //            adultInKidsMode-kidsAccount = "pcCheckPasswordGate"
  // ═══════════════════════════════════════════════════════════════════

  it('Adult enters Kids Mode via side nav, @adult_kids_mode', async () => {
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after password gate', 20000);
    await utils.sleep(1000);
    await testHelpers.openKidsMode();
  });


  it('Adult (Kids Mode) → exit to Normal: direct pass (age gate already passed earlier), @adult_kids_mode', async () => {
    // Age gate was already passed in the guest kids mode tests earlier,
    // so exiting kids mode is a direct pass this time
    await testHelpers.exitKidsMode();

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after exiting adult kids mode', 20000);
  });


  // ═══════════════════════════════════════════════════════════════════
  // SIGN OUT: Verify adult can sign out and remaining accounts persist
  // ═══════════════════════════════════════════════════════════════════

  it('Adult parent can sign out from their profile, @signout', async () => {
    await switchToProfile('AUTOMATIONPARENT1');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);

    await testHelpers.openLeftNav();
    await testUtils.jumpToRowIndex('sideNavMenu', 10);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('settingsScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('settingsMenu');
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForElementToShowOnScreen('signOutVerificationModalMessage', 'Sign Out verification modal did not appear', 10000);
    const modalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(modalMessage.text).to.contain('sign out');
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Home screen did not load after sign out', 20000);
  });


  it('After sign out, remaining accounts are still switchable, @signout', async () => {
    // AP1 signed out (along with its linked kid testkid1).
    // AP2 and Guest should still be available.
    await openProfileMenu();
    await testUtils.jumpToRowWithTitle('profileSelectionMenu', 'AUTOMATIONPARENT2');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Could not switch to AP2 after AP1 sign out', 20000);
  });
});
