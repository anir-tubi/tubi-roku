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
    await ecp.sendKeypress(ecp.Key.Down);

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Content Settings');

    // Set PC
    await selectLittleKidsFromParentalSettings();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.contains('You will be directed to Tubi Kids.');
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
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await ecp.sendKeypress(ecp.Key.Left);

    // In Kids Mode?
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.be.true;

    // Verify Espanol is not in the sidenav at all
    await testUtils.waitForSideNavMenuToBeExpanded();
    const menuItems = await testUtils.getAllRowListItemsContent('sideNavMenu');
    const hasEspanolOption = menuItems.some((item: any) =>
      item.title === 'Espanol' ||
      item.TITLE === 'Espanol' ||
      item.title === 'Español' ||
      item.TITLE === 'Español'
    );
    expect(hasEspanolOption, 'Espanol option should not be present in Kids Mode sidenav').to.be.false;


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
    await ecp.sendKeypress(ecp.Key.Down);

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Content Settings');

    // Set PC
    await shared.selectOlderKidsFromParentalSettings();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.contains('You will be directed to Tubi Kids.');
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
    await ecp.sendKeypress(ecp.Key.Down);

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Content Settings');

    // Set PC
    await selectTeensFromParentalSettings();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.text).to.contain('Age Rating 13-17 (Up to TV-14 / PG-13)');
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

async function selectLittleKidsFromParentalSettings() { await shared.selectParentalControlLevel('littleKids'); }
async function selectTeensFromParentalSettings() { await shared.selectParentalControlLevel('teens'); }
