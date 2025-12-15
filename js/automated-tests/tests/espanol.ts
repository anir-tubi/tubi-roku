import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';

describe('Espanol', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

  });

  // https://tubi.testrail.io/index.php?/cases/view/115396
  it('C115396 - Tubi Latino is not accessible if parental controls are set to: Little Kids, @espanol', async () => {

    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectLittleKidsFromParentalSettings();
    await enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Select Espanol from Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 6 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Espanol Disabled for Little Kids
    await verifyEspanolDisabledKids();


  });

  // https://tubi.testrail.io/index.php?/cases/view/115397
  it('C115397 - Tubi Latino is not accessible if a user is in Kids Mode, @espanol', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await shared.openKidsMode();

    // In Kids Mode?
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.be.true;

    // Select Espanol from Left Nav
    await ecp.sendKeypress(ecp.Key.Down, { count: 6 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Espanol Disabled for Kids mode
    await verifyEspanolDisabledKids();


  });

  //https://tubi.testrail.io/index.php?/tests/view/115398
  it('C115398 - Latino mode is not persistent between sessions @espanol', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open the Side nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Select Espanol
    await ecp.sendKeypress(ecp.Key.Down, { count: 6 });
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we in Espanol mode?
    await testUtils.waitForElementToHaveFocus('espanolScreenRowList', 'Timed out waiting for Espanol screen to have focus');

    //Relaunch app and verify we are no longer in Espanol mode
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });

  // https://tubi.testrail.io/index.php?/cases/view/116489
  it('C116489 - Tubi Latino is not accessible if parental controls are set to: Older Kids, @espanol', async () => {


    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await shared.selectOlderKidsFromParentalSettings();
    await enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Select Espanol from Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 6 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Espanol Disabled for Older Kids
    await verifyEspanolDisabledKids();

  });

  // https://tubi.testrail.io/index.php?/cases/view/116490
  it('C116490 - Tubi Latino is not accessible if parental controls are set to: Teens, @espanol', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Teens
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectTeensFromParentalSettings();
    await enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Select Espanol from Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 6 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Espanol Disabled for Teens
    await verifyEspanolDisabledTeens();

  });

  // https://tubi.testrail.io/index.php?/cases/view/116526
  it('C116526 - My List and Continue Watching container names are translated, @espanol', async () => {

    // Create user with watch list and history
    const user = await testUtils.createRegisteredUser();
    await createEspanolWatchListEvergreenTitle(user);
    await createHistoryEspanolEvergreenTitle(user);

    // Launch at Espanol page with user above that has watch list and history

    await testUtils.startApplicationAtPage('espanol', { user: user });
    await testUtils.waitForElementToFullyShowOnScreen('espanolLogo', 'Timed out waiting for espanol page');

    // Scroll to CW and verify translation
    await testHelpers.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'categoryGridRowList' });

    // Scroll to My List and verify tranlation
    await testHelpers.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'categoryGridRowList' });

  });

  async function createHistoryEspanolEvergreenTitle(user) {

    // Create history with one Evergreen title movie

    const contentId = await user.getContentById(300005220);
    await user.addContentToViewHistory(contentId, 500);

  }

  async function createEspanolWatchListEvergreenTitle(user) {

    // Create a user with one title series

    await user.addContentToWatchList({
      id: '0300005220',
      type: 'series'
    });



  }


});

async function enterPasswordSettingsChange() {
  await utils.sleep(1000);
  await ecp.sendText('111111');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(2000);
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function verifyEspanolDisabledKids() {
  // Wait for dialog to appear - use longer timeout since user confirmed it shows
  await testUtils.waitForElementToShowOnScreen('espanolDisabledTitle', 'Espanol Disabled dialog not shown', 10000);
  const espanolDisabledTitle = await testUtils.getNodeForElement('espanolDisabledTitle');
  expect(espanolDisabledTitle.text).to.equal('Español Disabled');
  const espanolDisabledMessage = await testUtils.getNodeForElement('espanolDisabledMessage');
  expect(espanolDisabledMessage.text).to.equal('Please exit Tubi Kids to use this feature.');
  const espanolDisabledButton = await testUtils.getNodeForElement('espanolDisabledButton');
  expect(espanolDisabledButton.text).to.equal('OK');
}

async function verifyEspanolDisabledTeens() {
  // Wait for dialog to appear - use longer timeout and same elements as Kids
  // (The element keypaths are identical, only the message text differs)
  await testUtils.waitForElementToShowOnScreen('espanolDisabledTitle', 'Espanol Disabled dialog not shown', 10000);
  const espanolDisabledTitle = await testUtils.getNodeForElement('espanolDisabledTitle');
  expect(espanolDisabledTitle.text).to.equal('Español Disabled');
  const espanolDisabledMessage = await testUtils.getNodeForElement('espanolDisabledMessage');
  expect(espanolDisabledMessage.text).to.equal('Please turn off parental controls to use this feature.');
  const espanolDisabledButton = await testUtils.getNodeForElement('espanolDisabledButton');
  expect(espanolDisabledButton.text).to.equal('OK');
}

async function selectLittleKidsFromParentalSettings() {
  await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
  await ecp.sendKeypress(ecp.Key.Right);
  await utils.sleep(2000);
  await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
  await utils.sleep(2000);
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectTeensFromParentalSettings() {
  await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
  await ecp.sendKeypress(ecp.Key.Right);
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Up, { count: 1 });
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Ok);
}
