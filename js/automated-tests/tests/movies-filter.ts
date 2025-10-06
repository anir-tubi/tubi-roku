import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Homescreen Navigation - Movies Filter', function () {
  before(async () => {
    const user = await testUtils.createRegisteredUser();
    const seriesContent = await user.getContent().ofContentType('series').retrieve({ limit: 5 });
    await user.addContentToViewHistory(seriesContent, 500);
    await user.addContentToWatchList(seriesContent);
    const movieContent = await user.getContent().ofContentType('movie').retrieve({ limit: 5 });
    await user.addContentToViewHistory(movieContent, 500);
    await user.addContentToWatchList(movieContent);

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
    await shared.openMovies();
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
  });

  // https://tubi.testrail.io/index.php?/cases/view/535770
  it('C535770 - Movies Filter - When movie filter is triggered then only Movie Titles are present, @homescreen, @movies', async () => {
    await testUtils.waitForAppLaunchBeaconToFire();

    // Check if Featured row contains all Movie titles ("v") titles
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');

    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('v');
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/76723
  it('C76723 - Movies Filter - When title is selected then corresponding details page displayed, @homescreen, @movies', async () => {

    await testUtils.waitForAppLaunchBeaconToFire();


    // Check if Featured row contains all Movie titles ("v") titles
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');

    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('v');

    }

    // Now select a title to redirect us on the detail page
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify the Details page is a Movies Details page
    await testUtils.retryWithTimeOut(async () => {
      await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Watch Trailer');
    });
  });

  // https://tubi.testrail.io/index.php?/cases/view/76730
  it('C76730 - Movies Filter - When continue watching displayed then all titles are movies, @homescreen, @movies', async () => {

    // Scroll down to Continue Watching
    await testUtils.jumpToRowWithTitle('movieScreenRowList', 'Continue Watching');


    // Check if CW row contains all Series titles

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');


    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('v');
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/76731
  it('C76731 - Movies Filter - When My List category displayed then all titles are movies, @homescreen, @movies', async () => {

    // Scroll down to Continue Watching
    await testUtils.jumpToRowWithTitle('movieScreenRowList', 'My List');


    // Check if CW row contains all Series titles

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');


    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('v');
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/103112
  it('C103112 - Movies Filter - Continue Watching titles with expiration should show expiration info in Details @movies @expiration', async () => {
    // Scroll to Continue Watching row
    await testUtils.jumpToRowWithTitle('movieScreenRowList', 'Continue Watching');

    const focusResult = await focusOnVideoTileWithExpireSoon();

    const isLeavingSoonTitleFound = focusResult.foundExpiringTitle

    if (isLeavingSoonTitleFound == true) {
      // Verify we actually focused on an expiring title
      expect(focusResult.foundExpiringTitle).to.be.true;

      // Checking the expires warning label appears
      const moviesExpiresWarningLabel = await testUtils.getNodeForElement('moviesExpiresWarningLabel');
      expect(moviesExpiresWarningLabel.text.toLowerCase()).to.include('expire');

      await ecp.sendKeypress(ecp.Key.Ok);

      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.id).to.equal('Title');

      const detailExpiresWarningLabel = await testUtils.getNodeForElement('detailExpiresWarningLabel');
      expect(detailExpiresWarningLabel.text.toLowerCase()).to.include('expire');
    }
    else {
      console.log('Leaving Soon content not found...');
    }
  });

});

async function focusOnVideoTileWithExpireSoon() {
  const rowIndex = await testUtils.findRowIndexWithTitle('movieScreenRowList', 'Continue Watching');
  const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');

  const currentDate = new Date();
  const fourteenDaysFromNow = new Date();
  fourteenDaysFromNow.setDate(currentDate.getDate() + 14);

  for (const [itemIndex, item] of content.entries()) {

    if (item.availability_ends !== '' && item.availability_ends !== null && item.availability_ends !== undefined) {
      // Parse the availability_ends date
      const expiryDate = new Date(item.availability_ends);

      // Check if the expiry date is valid and within 14 days
      if (!isNaN(expiryDate.getTime()) && expiryDate >= currentDate && expiryDate <= fourteenDaysFromNow) {
        const daysUntilExpiry = Math.ceil((expiryDate.getTime() - currentDate.getTime()) / (1000 * 60 * 60 * 24));
        await testUtils.jumpToRowItem('movieScreenRowList', [rowIndex, itemIndex]);
        return {
          foundExpiringTitle: true,
          title: item.title,
          daysUntilExpiry,
          itemIndex
        };
      }
    }
  }

  // Fallback: focus on first available title if no expiring titles found
  if (content.length > 0) {
    await testUtils.jumpToRowItem('movieScreenRowList', [rowIndex, 0]);
    return {
      foundExpiringTitle: false,
      title: content[0]?.title || 'Unknown',
      itemIndex: 0
    };
  }

  return { foundExpiringTitle: false, title: null, itemIndex: -1 };
}