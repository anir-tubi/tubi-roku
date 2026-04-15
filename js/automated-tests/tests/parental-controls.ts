import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers, shared } from '../test-helpers';


describe('Parental Controls', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });


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


  async function selectContentSetting(level: string) {
    await testUtils.waitForElementToShowOnScreen('parentalControlsMenu', 'Parental controls menu did not open', 5000);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForGridContentToLoad('parentalControlsMenu');
    await testUtils.jumpToGridItemWithTitle('parentalControlsMenu', level);
    await ecp.sendKeypress(ecp.Key.Ok);
  }


  async function verifyContentSettingsDialog(expectedContains: string) {
    await testUtils.waitForElementToShowOnScreen('parentalControlsChangeDialog', 'Content Settings Updated dialog did not appear', 10000);
    const dialogMessage = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(dialogMessage.text).to.contain(expectedContains);
    await ecp.sendKeypress(ecp.Key.Ok);
  }


  async function backToHomeFromContentSettings() {
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
  }


  // ═══════════════════════════════════════════════════════════════════
  // DEEPLINK PLAYBACK TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/537376
  it('C537376 - Parental Settings - Age Rating 4-6 - Deeplink Playback, @parental_controls', async () => {
    await navigateToContentSettings();
    await selectContentSetting('Age Rating 4-6');
    await verifyContentSettingsDialog('Age Rating 4-6');
    await backToHomeFromContentSettings();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Deep link an Adult-rated title — should be blocked
    await testUtils.restartApplication({
      params: {
        'mediaType': 'movie',
        contentID: '679437'
      }
    });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    let detailScreenLoaded = false;
    try {
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);
      detailScreenLoaded = true;
    } catch (_) { }
    expect(detailScreenLoaded, 'Detail screen should not have loaded for restricted content').to.be.false;
  });


  // https://tubi.testrail.io/index.php?/cases/view/537375
  it('C537375 - Parental Settings - Teen - Deeplink Playback, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 13-17');
    await verifyContentSettingsDialog('Age Rating 13–17');
    await backToHomeFromContentSettings();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Deep link an Adult-rated title — should be blocked
    // await testUtils.restartApplication({
    //   params: {
    //     'mediaType': 'movie',
    //     contentID: '580334'
    //   }
    // });
    // await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // let detailScreenLoaded = false;
    // try {
    //   await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);
    //   detailScreenLoaded = true;
    // } catch (_) { }
    // expect(detailScreenLoaded, 'Detail screen should not have loaded for restricted content').to.be.false;
  });


  // https://tubi.testrail.io/index.php?/cases/view/537405
  it('C537405 - Parental Settings - Age Rating 10-12 - Deeplink Playback, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
    await backToHomeFromContentSettings();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Deep link an Adult-rated title — should be blocked
    await testUtils.restartApplication({
      params: {
        'mediaType': 'movie',
        contentID: '580334'
      }
    });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);

    let detailScreenLoaded = false;
    try {
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);
      detailScreenLoaded = true;
    } catch (_) { }
    expect(detailScreenLoaded, 'Detail screen should not have loaded for restricted content').to.be.false;
  });


  // ═══════════════════════════════════════════════════════════════════
  // CATEGORIES PAGE TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/535834
  it('C535834 - Categories Page - When setting is changed from Adult to Age Rating 4-6 then the categories only for that level are listed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 4-6');
    await verifyContentSettingsDialog('Age Rating 4-6');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Navigate to Categories via left nav
    await testHelpers.openLeftNav();
    await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('kidsCategory');

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await testUtils.waitForElementToFullyShowOnScreen('littleKidsMenuItemText');
    const menuItemText = await testUtils.getNodeForElement('littleKidsMenuItemText');
    expect(menuItemText.text).to.equal('Dinosaurs & Dragons');
  });


  // https://tubi.testrail.io/index.php?/cases/view/535835
  it('C535835 - Categories Page - When settings is changed from Adult to Age Rating 10-12 then categories for that level are listed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
    await backToHomeFromContentSettings();

    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Navigate to Categories via left nav
    await testHelpers.openLeftNav();
    await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('kidsCategory');

    await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
    await ecp.sendKeypress(ecp.Key.Right, { wait: 2000 });
    await testUtils.waitForElementToFullyShowOnScreen('channelInfoPanel');

    const categoryRatingsLabel = await testUtils.getNodeForElement('categoryRatingsLabel');
    await testUtils.waitForGridContentToLoad('categoryPageGrid');
    const rowItemsContent = await testUtils.getAllGridItemsContent('categoriesScreenContentGrid');

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
  it('C535836 - Categories Page - When settings is changed from Adult to Teen then categories for Teens are listed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 13-17');
    await verifyContentSettingsDialog('Age Rating 13–17');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Navigate to Categories via left nav
    await testHelpers.openLeftNav();
    await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(2000);
    await testUtils.waitForElementToFullyShowOnScreen('categoryHeader', 'Category page not shown', 15000);

    await testUtils.waitForElementToShowOnScreen('artHouseFilms');
  });


  // ═══════════════════════════════════════════════════════════════════
  // EXIT KIDS / MODAL PRESENTATION TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/535864
  it('C535864 - Parental Controls - Age Rating 4-6 - When user switches PC then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 4-6');
    await verifyContentSettingsDialog('Age Rating 4-6');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Open left nav and verify Exit Kids is grayed out
    await ecp.sendKeypress(ecp.Key.Left);
    const exitKidsGrayedOut = await testUtils.getNodeForElement('exitKidsGrayedOut');
    expect(exitKidsGrayedOut.visible).to.be.true;
  });


  // https://tubi.testrail.io/index.php?/cases/view/6596
  it('C6596 - Parental Controls - Age Rating 10-12 - When user switches PC then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Open left nav and verify Exit Kids is grayed out
    await ecp.sendKeypress(ecp.Key.Left);
    const exitKidsGrayedOut = await testUtils.getNodeForElement('exitKidsGrayedOut');
    expect(exitKidsGrayedOut.visible).to.be.true;
  });


  // https://tubi.testrail.io/index.php?/cases/view/535866
  it('C535866 - Parental Controls - Teen - When user switches PC to Teen then Exit Kids is not present, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 13-17');
    await verifyContentSettingsDialog('Age Rating 13–17');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Open left nav and verify Kids mode option is present (not in kids mode)
    await ecp.sendKeypress(ecp.Key.Left);
    const kidsLeftNavOption = await testUtils.getNodeForElement('kidsLeftNavOption');
    expect(kidsLeftNavOption.visible).to.be.true;
  });


  // https://tubi.testrail.io/index.php?/cases/view/535867
  it('C535867 - Parental Controls - Adults - When user switches PC to Adults then Exit Kids is not present, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 18+');
    await backToHomeFromContentSettings();

    // Open left nav and verify Kids mode option is present (not in kids mode)
    await ecp.sendKeypress(ecp.Key.Left);
    const kidsLeftNavOption = await testUtils.getNodeForElement('kidsLeftNavOption');
    expect(kidsLeftNavOption.visible).to.be.true;
  });


  // https://tubi.testrail.io/index.php?/cases/view/535868
  it('C535868 - Parental Control - Change Before 5 minutes, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // First change: set to Teen
    await navigateToContentSettings();
    await selectContentSetting('Age Rating 13-17');
    await verifyContentSettingsDialog('Age Rating 13–17');

    // Second change within 5 minutes: should show dialog without password
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
  });


  // ═══════════════════════════════════════════════════════════════════
  // SEARCH TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/537901
  it('C537901 - Search - Age Rating 10-12 - When titles above that level are searched then no results should be displayed, @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Open left nav and navigate to Search
    await testHelpers.openLeftNav();
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Search');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Search for adult content
    await testUtils.waitForElementToFullyShowOnScreen('searchGrid');
    await ecp.sendText('drugs');

    // Wait for either search results or no-results message
    let hasResults = false;
    await testUtils.untilTrue(async () => {
      const noResults = await testUtils.isElementShowingOnScreen('noResultsMessage');
      const results = await testUtils.isElementShowingOnScreen('searchResultGrid');
      if (noResults.isShowing || results.isShowing) {
        hasResults = results.isShowing;
        return true;
      }
      return false;
    }, 'Neither search results nor no-results message appeared', 15000);

    let isAdultContentPresent = false;
    if (hasResults) {
      const contents = await testUtils.getAllGridItemsContent('searchResultGrid');
      isAdultContentPresent = contents.some((item: any) => item.rating === 'TV-MA');
    }

    expect(isAdultContentPresent).to.be.false;
  });


  // ═══════════════════════════════════════════════════════════════════
  // CONTINUE WATCHING TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/535826
  it('C535826 - Continue Watching - When setting is changed to Age Rating 4-6 then CW row has no content above TV-G or G @parental_controls', async () => {
    const user = await testUtils.createRegisteredUser();
    await shared.createUserHistoryWithRatings(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 4-6');
    await verifyContentSettingsDialog('Age Rating 4-6');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to CW row
    await shared.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'homeScreenRowList' });

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['PG', 'R', 'NR', 'PG-13', 'TV-14', 'TV-MA', 'MA'].includes(itemContent.type)).to.be.false;
    }
  });


  // https://tubi.testrail.io/index.php?/cases/view/535827
  it('C535827 - Continue Watching - When setting is Adults then CW row should show all rated contents @parental_controls', async () => {
    const user = await testUtils.createRegisteredUser();
    await shared.createUserHistoryWithRatings(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Adults is the default; explicitly confirm it via Content Settings
    await navigateToContentSettings();
    await selectContentSetting('Age Rating 18+');
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500)
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(500)

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to CW row
    await shared.scrollDownToFindRow({ slug: 'continue_watching' });
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

    const allowedRatings = ['R', 'PG', 'PG-13', 'TV-G', 'TV-MA'];
    let adultContentPresent = false;
    for (const itemContent of rowItemsContent) {
      const rating = itemContent.ratings[0].value;
      const isAllowed = allowedRatings.some(allowedRating => rating.includes(allowedRating));
      if (isAllowed) {
        adultContentPresent = true;
        break;
      }
    }
    expect(adultContentPresent).to.be.true;
  });


  // https://tubi.testrail.io/index.php?/cases/view/535762
  it('C535762 - Continue Watching - When setting is changed to Age Rating 10-12 then CW row has no content above PG, TV-PG, TV-Y7 @parental_controls', async () => {
    const user = await testUtils.createRegisteredUser();
    await shared.createUserHistoryWithRatings(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to CW row
    await shared.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'homeScreenRowList' });

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'MA', 'TV-MA', 'PG-13'].includes(itemContent.type)).to.be.false;
    }
  });


  // ═══════════════════════════════════════════════════════════════════
  // MY LIST TESTS
  // ═══════════════════════════════════════════════════════════════════

  // https://tubi.testrail.io/index.php?/cases/view/535764
  it('C535764 - My List - When setting is changed to Age Rating 4-6 then My List row has no content above TV-G or G @parental_controls', async () => {
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 4-6');
    await verifyContentSettingsDialog('Age Rating 4-6');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to My List row
    await shared.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'homeScreenRowList' });

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'PG', 'PG-13', 'MA', 'TV-MA'].includes(itemContent.type)).to.be.false;
    }
  });


  // https://tubi.testrail.io/index.php?/cases/view/535765
  it('C535765 - My List - When setting is changed to Age Rating 10-12 then My List row has no content above PG, TV-PG, TV-Y7 @parental_controls', async () => {
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 10-12');
    await verifyContentSettingsDialog('Age Rating 10-12');
    await backToHomeFromContentSettings();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to My List row
    await shared.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'homeScreenRowList' });

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'MA', 'TV-MA', 'PG-13'].includes(itemContent.type)).to.be.false;
    }
  });


  // https://tubi.testrail.io/index.php?/cases/view/535766
  it('C535766 - My List - When setting is changed to Teen then My List row has no content above PG-13, TV-14 @parental_controls', async () => {
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await navigateToContentSettings();
    await selectContentSetting('Age Rating 13-17');
    await verifyContentSettingsDialog('Age Rating 13–17');
    await backToHomeFromContentSettings();
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Jump to My List row
    await shared.scrollDownToFindRow({ slug: 'queue', rowListElementId: 'videoTitlesRowList' });

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R', 'MA', 'TV-MA', 'NR'].includes(itemContent.type)).to.be.false;
    }
  });
});


async function createWatchList(user) {
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
