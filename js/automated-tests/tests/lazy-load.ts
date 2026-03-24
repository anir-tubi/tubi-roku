import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

describe('LazyLoad', function () {


  // https://tubi.testrail.io/index.php?/cases/view/432577
  it('C432577 - Lazy load does not occur when less than or equal to 200 titles, @lazyload', async () => {

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to Categories
    await openLeftNav();

    // Select Categories
    await selectCategories();

    // Navigate to a category with < 200 titles and validate < 200
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');
    // Navigate down 50 rows(4 * 50 = 200)
    await ecp.sendKeypress(ecp.Key.Down, { count: 50, wait: 50 });
    // Just waiting for some time incase the request is not completed yet.
    await utils.sleep(1000);
    const contents = await testUtils.getAllGridItemsContent('channelCategoryGrid');
    const itemCounterValue = contents.length;
    // Adding a buffer since backend is actually returning 201 titles.
    expect(itemCounterValue).is.lessThanOrEqual(300);

  });


  // https://tubi.testrail.io/index.php?/cases/view/432577 and https://tubi.testrail.io/index.php?/cases/view/431533
  it('C431532 User can access more than 200 titles in Categories full screen view., @lazyload', async () => {

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to Categories
    await openLeftNav();

    // Select Categories
    await selectCategories();

    // Navigate to a category with < 200 titles and validate < 200
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
    await testUtils.jumpToGridItemWithTitle('categoriesListMenu', 'Classic TV & Movies');
    await testUtils.retryWithTimeOut(async () => {
      const focused = await testUtils.getCurrentlyFocusedGridItemContent('categoriesListMenu');
      expect(focused.title).to.equal('Classic TV & Movies');
    });
    await testUtils.waitForElementToShowOnScreen('channelCategoryGrid', 'Category grid not loaded');
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

    // Navigate down 
    await ecp.sendKeypress(ecp.Key.Down, { count: 50 });
    await utils.sleep(5000);

    const contents = await testUtils.getAllGridItemsContent('channelCategoryGrid');
    const itemCounter = contents.length;
    expect(itemCounter).greaterThan(200);
  });


  // https://tubi.testrail.io/index.php?/cases/view/431534
  it('C431534 1000 max titles can be loaded, @lazyload', async () => {

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to Categories

    await openLeftNav();

    // Select Categories
    await selectCategories();

    // Navigate to a category with 1000
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
    await testUtils.jumpToGridItemWithTitle('categoriesListMenu', 'Classic TV & Movies');
    await testUtils.retryWithTimeOut(async () => {
      const focused = await testUtils.getCurrentlyFocusedGridItemContent('categoriesListMenu');
      expect(focused.title).to.equal('Classic TV & Movies');
    });
    await testUtils.waitForElementToShowOnScreen('channelCategoryGrid', 'Category grid not loaded');
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

    // Navigate down to until we reach 600 titles vertically downwards.
    await ecp.sendKeypress(ecp.Key.Down, { count: 30 });
    await utils.sleep(2000); // itemCounter update isn't recognized without sleep
    await ecp.sendKeypress(ecp.Key.Down, { count: 51 });
    await utils.sleep(2000); // itemCounter update isn't recognized without sleep
    let contents = await testUtils.getAllGridItemsContent('channelCategoryGrid');
    const itemCounter = contents.length;
    expect(itemCounter).greaterThanOrEqual(600);

    // Navigate down to until we reach 800 titles vertically downwards
    await ecp.sendKeypress(ecp.Key.Down, { count: 47 });
    await utils.sleep(4000); // itemCounter update isn't recognized without sleep
    contents = await testUtils.getAllGridItemsContent('channelCategoryGrid');
    const itemCounter800 = contents.length;
    expect(itemCounter800).greaterThanOrEqual(800);

    // Navigate down to 1000 titles
    await ecp.sendKeypress(ecp.Key.Down, { count: 50 });
    await utils.sleep(4000); // itemCounter update isn't recognized without sleep
    contents = await testUtils.getAllGridItemsContent('channelCategoryGrid');
    const itemCounter1000 = contents.length;
    expect(itemCounter1000).lessThanOrEqual(1000);

    // Navigate down to last row
    await ecp.sendKeypress(ecp.Key.Down, { count: 82 });
    await utils.sleep(4000); // itemCounter update isn't recognized without sleep
    contents = await testUtils.getAllGridItemsContent('channelCategoryGrid');
    const itemCounterLast = contents.length;
    expect(itemCounterLast).lessThanOrEqual(1000);

  });
});

async function openLeftNav() {
  // Press left
  await ecp.sendKeypress(ecp.Key.Left);

  // Is the left Nav open?
  await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');
}

async function selectCategories() {
  await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
  await utils.sleep(1000);
  await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButtonSelected');
  await ecp.sendKeypress(ecp.Key.Ok);

  // Are we on Categories page?
  await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
}

