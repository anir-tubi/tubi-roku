import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';


describe('Parental Controls', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });

  // https://tubi.testrail.io/index.php?/cases/view/537376
  it('C537376 - Parental Settings - Little Kids - Deeplink Playback, @parental_controls', async () => {
    await testUtils.goToPage('settings');
    await selectLittleKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    await testUtils.waitForElementToShowOnScreen('parentalControlsSettingsLittleKids');
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Ok);

    // Send deep link for Adult title
    await testUtils.restartApplication({
      params: {
        'mediaType': 'movie',
        contentID: '679437'
      }
    });

    // Verify that the user can't view the title
    const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
    expect((await invalidDeepLinkDialog).visible).to.be.true;

  });

  // https://tubi.testrail.io/index.php?/cases/view/537375
  it('C537375 - Parental Settings - Teens - Deeplink Playback, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectTeensFromParentalSettings();
    await utils.sleep(2000);
    await shared.enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    await utils.sleep(3000);
    await testUtils.retryWithTimeOut(async () => {
      const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
      expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);
    });

    // Back to home
    await ecp.sendKeypress(ecp.Key.Ok);

    // Send deep link for Adult title
    await testUtils.restartApplication({
      params: {
        'mediaType': 'movie',
        contentID: '580334'
      }
    });

    // Verify that the user can't view the title
    const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
    expect((await invalidDeepLinkDialog).visible).to.be.true;

  });

  // https://tubi.testrail.io/index.php?/cases/view/537405
  it('C537405 - Parental Settings - Older Kids - Deeplink Playback, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectOlderKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Ok);

    // Send deep link for Adult title
    await testUtils.restartApplication({
      params: {
        'mediaType': 'movie',
        contentID: '580334'
      }
    });

    // Verify that the user can't view the title
    const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
    expect((await invalidDeepLinkDialog).visible).to.be.true;
  });

  // https://tubi.testrail.io/index.php?/cases/view/535834
  it('C535834 - Categories Page - When setting is changed from Adult to Little Kids then the categories only for Little Kids are listed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectLittleKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Select Categories
    await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we on Categories page?
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('kidsCategory');

    // Little Kids content?
    await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
    await testUtils.waitForElementToFullyShowOnScreen('littleKidsMenuItemText');
    const menuItemText = await testUtils.getNodeForElement('littleKidsMenuItemText');
    expect(menuItemText.text).to.equal('Dinosaurs & Dragons');
  });

  // https://tubi.testrail.io/index.php?/cases/view/535835
  it('C535835- Categories Page - When settings is changed from Adult to Older Kids then categories for Older kids are listed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectOlderKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.visible).to.be.true;
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Select Categories
    await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we on Categories page?
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('kidsCategory');

    // Little Kids content?
    await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
    await ecp.sendKeypress(ecp.Key.Right, { wait: 2000 });
    await testUtils.waitForElementToFullyShowOnScreen('channelInfoPanel');

    // Check Ratings label
    const categoryRatingsLabel = await testUtils.getNodeForElement('categoryRatingsLabel');
    await testUtils.waitForGridContentToLoad('categoryPageGrid');
    const rowItemsContent = await testUtils.getAllGridItemsContent('channelsVideoGrid');

    for (const itemContent of rowItemsContent) {
      const rating = itemContent.rating[0].value;
      expect(rating).to.not.equal('R');
      expect(rating).to.not.equal('MA');
      expect(rating).to.not.equal('PG-13');
      expect(rating).to.not.equal('NR');
      expect(rating).to.not.equal('TV-13');
      expect(rating).to.not.equal('PG');
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535836
  it('C535836 - Categories Page - When settings is changed from Adult to Teens then categories for Teens are listed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectTeensFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.visible).to.be.true;
    expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Select Categories
    await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we on Categories page?
    await utils.sleep(2000);
    await testUtils.waitForElementToFullyShowOnScreen('categoryHeader', 'Category page not shown', 15000);

    // Teens content?
    await testUtils.waitForElementToShowOnScreen('artHouseFilms');
  });


  // https://tubi.testrail.io/index.php?/cases/view/535864
  it('C535864 - Parental Controls - Little Kids - When user switches Parental Control to Little Kids then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectLittleKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Is Exit Kids menu option Grayed out?
    const exitKidsGrayedOut = testUtils.getNodeForElement('exitKidsGrayedOut');
    expect((await exitKidsGrayedOut).visible).to.be.true;
  });

  // https://tubi.testrail.io/index.php?/cases/view/6596
  it('C6596 - Parental Controls - Little Kids - When user switches Parental Control to Older Kids then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectOlderKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Is Exit Kids menu option Grayed out?
    const exitKidsGrayedOut = testUtils.getNodeForElement('exitKidsGrayedOut');
    expect((await exitKidsGrayedOut).visible).to.be.true;
  });

  // https://tubi.testrail.io/index.php?/cases/view/535866
  it('C535866 - Parental Controls - Teens - When user switches Parental Control to Teens then a modal is presented/Exit Kids is not present, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectTeensFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Is Kids menu option present?
    const kidsLeftNavOption = testUtils.getNodeForElement('kidsLeftNavOption');
    expect((await kidsLeftNavOption).visible).to.be.true;
  });

  // https://tubi.testrail.io/index.php?/cases/view/535867
  it('C535867 - Parental Controls - Adults - When user switches Parental Control to Adults then a modal is presented/Exit Kids is not present, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectAdultsFromParentalSettings();

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back, { count: 3 });

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Is Kids menu option present?
    const kidsLeftNavOption = testUtils.getNodeForElement('kidsLeftNavOption');
    expect((await kidsLeftNavOption).visible).to.be.true;
  });

  // https://tubi.testrail.io/index.php?/cases/view/535868
  it('C535868 - Parental Control - Change Before 5 minutes, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectTeensFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.visible).to.be.true;
    expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Select another PC Setting
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsMenuTextFocused');
    await utils.sleep(2000); // will improve these later
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000); // will improve these later
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Expect dialog instead of Password Screen (Verify that no password is needed to be entered to change parental controls)
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsOlderKids');
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.contain('Parental controls setting has changed');
  });

  // https://tubi.testrail.io/index.php?/cases/view/537901
  it('C537901 - Search - Adult to Older Kids - When titles above Older Kids is searched then no results should be displayed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('settings');
    await selectOlderKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the left Nav open?
    const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
    await testUtils.elementHasFocus('leftNavHomeButton');

    // Select Search
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Search');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Send adult title text
    await testUtils.waitForElementToFullyShowOnScreen('searchGrid');
    await ecp.sendText('drugs');
    await testUtils.waitForElementToFullyShowOnScreen('noResultsMessage');

    // Verify no result for Older Kids level
    const noResultsMessage = testUtils.getNodeForElement('noResultsMessage');

    let isAdultContentPresent = false;
    // In some cases we get some contents for the search term.
    if ((await noResultsMessage).text.includes('Please try again') == false) {
      const contents = await testUtils.getAllGridItemsContent(
        'searchResultGrid'
      );
      for (const [index, item] of contents.entries()) {
        if (item.rating == 'TV-MA') {
          isAdultContentPresent = true;
          break;
        }
      }
    }

    expect(isAdultContentPresent).to.be.false;
  });

  // https://tubi.testrail.io/index.php?/cases/view/535826
  it('C535826 - Continue Watching - When setting is changed to Little Kids then Continue Watching row has no content above TV-G or G @parental_controls', async () => {
    // Create a user with mix of little kids and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await shared.createUserHistoryWithRatings(user);

    // Start app, wait for home screen to load
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectLittleKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids', 8000);
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to CW row
    await shared.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'homeScreenRowList' });

    // TODO: revisit once back end issue is addressed
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['PG', 'R', 'NR', 'PG-13', 'TV-14', 'TV-MA', 'MA'].includes(itemContent.type)).to.be.false;
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535827
  it('C535827 - Continue Watching - When setting is changed to Adults then Continue Watching row should show all rated contents @parental_controls', async () => {
    // Create a user with mix of little kids and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await shared.createUserHistoryWithRatings(user);

    // Launch to home page, await home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Little Kids
    await shared.openSettings();

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set, Check PC for Adults (default)
    await selectAdultsFromParentalSettings();

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to CW row
    await shared.scrollDownToFindRow({ slug: 'continue_watching' });
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    // Check Ratings label
    const allowedRatings = ['R', 'PG', 'PG-13', 'TV-G', 'TV-MA'];
    for (const itemContent of rowItemsContent) {
      const rating = itemContent.ratings[0].value;
      const isAllowed = allowedRatings.some(allowedRating => rating.includes(allowedRating));
      expect(isAllowed, `Rating "${rating}" should match one of: ${allowedRatings.join(', ')}`).to.be.true;
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535762
  it('C535762 - Continue Watching - When setting is changed to Older Kids then Continue Watching row has no content above PG, TV-PG, TV-Y7 @parental_controls', async () => {
    // Create a user with mix of Older and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await shared.createUserHistoryWithRatings(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Older Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectOlderKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to CW row
    await shared.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'homeScreenRowList' });

    // Check ratings
    expect('homeScreenRatingsLabel').does.not.contain(['R', 'MA', 'TV-MA', 'PG-13']);

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'MA', 'TV-MA', 'PG-13'].includes(itemContent.type)).to.be.false;
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535764
  it('C535764 - My List - When setting is changed to Little Kids then My List row has no content above TV-G or G @parental_controls', async () => {
    // Create a user with mix of little kids and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectLittleKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to My List row
    await shared.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'homeScreenRowList' });

    // Check ratings
    expect('homeScreenRatingsLabel').does.not.contain(['R', 'PG', 'PG-13', 'MA', 'TV-MA']);

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'PG', 'PG-13', 'MA', 'TV-MA'].includes(itemContent.type)).to.be.false;
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535765
  it('C535765 - My List - When setting is changed to Older Kids then My List row has no content above PG, TV-PG, TV-Y7 @parental_controls', async () => {
    // Create a user with mix of Older and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Older Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    await testUtils.waitForElementToShowOnScreen('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectOlderKidsFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    await testUtils.waitForElementToShowOnScreen('parentalControlsSettingsOlderKids');
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to My List row
    await shared.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'homeScreenRowList' });

    // Check ratings
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'MA', 'TV-MA', 'PG-13'].includes(itemContent.type)).to.be.false;
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535766
  it('C535766 - My List - When setting is changed to Teens then My List row has no content above PG-13, TV-14 @parental_controls', async () => {
    // Create a user with mix of Older and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Teens
    await shared.openSettings();

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectTeensFromParentalSettings();
    await shared.enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000); // Wait for screen to fully load
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to My List row
    await shared.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'videoTitlesRowList' });

    // Check ratings
    expect('homeScreenRatingsLabel').does.not.contain(['R', 'MA', 'TV-MA', 'NR']);

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'MA', 'TV-MA', 'NR'].includes(itemContent.type)).to.be.false;
    }
  });
});


async function createWatchList(user) {
  // Create a user with mix of little kids and non-little kid rated titles with history
  const ContentTVG = await user.getContent().ofContentType(['series']).withRating('TV-G').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentTVG);
  const ContentG = await user.getContent().ofContentType('movie').withRating('G').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentG);
  const movieContentTVY7 = await user.getContent().ofContentType(['series']).withRating('TV-Y7').retrieve({ limit: 3 });
  await user.addContentToWatchList(movieContentTVY7);
  const movieContentTVMA = await user.getContent().ofContentType(['series']).withRating('TV-MA').retrieve({ limit: 3 });
  await user.addContentToWatchList(movieContentTVMA);
  const movieContentR = await user.getContent().ofContentType(['series', 'movie']).withRating('R').retrieve({ limit: 2 });
  await user.addContentToWatchList(movieContentR);
  const movieContentPG = await user.getContent().ofContentType(['series', 'movie']).withRating('PG').retrieve({ limit: 2 });
  await user.addContentToWatchList(movieContentPG);
  const movieContentPG13 = await user.getContent().ofContentType(['series', 'movie']).withRating('PG-13').retrieve({ limit: 2 });
  await user.addContentToWatchList(movieContentPG13);
  const movieContentTV14 = await user.getContent().ofContentType(['series']).withRating('TV-14').retrieve({ limit: 2 });
  await user.addContentToWatchList(movieContentTV14);
  const movieContentNR = await user.getContent().ofContentType(['movie']).withRating('NR').retrieve({ limit: 2 });
  await user.addContentToWatchList(movieContentNR);
}

async function selectOlderKidsFromParentalSettings() {
  await ecp.sendKeypress(ecp.Key.Right);
  await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
  await testUtils.jumpToGridItemWithTitle('parentalControlsMenu', 'Older Kids');
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectLittleKidsFromParentalSettings() {
  await ecp.sendKeypress(ecp.Key.Right);
  await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
  await testUtils.jumpToGridItemWithTitle('parentalControlsMenu', 'Little Kids');
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectTeensFromParentalSettings() {
  await ecp.sendKeypress(ecp.Key.Right);
  await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
  await testUtils.jumpToGridItemWithTitle('parentalControlsMenu', 'Teens');
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectAdultsFromParentalSettings() {
  await ecp.sendKeypress(ecp.Key.Right);
  await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
  await ecp.sendKeypress(ecp.Key.Ok);
}

// Navigate right until the grid is in focus
async function navigateRightToGrid() {
  await testUtils.untilTrue(async () => {
    await ecp.sendKeypress(ecp.Key.Right);
    const { value: id } = await odc.getValue({
      base: 'focusedNode',
      keyPath: 'id'
    });
    return id === 'ResultGrid';
  }, 'ResultGrid never obtained focus');
}
