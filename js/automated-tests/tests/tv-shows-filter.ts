import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Homescreen Navigation - TV Shows Filter', function () {
  before(async () => {
    // Create user with History
    const user = await testUtils.createRegisteredUser();
    const seriesContent = await user.getContent().ofContentType('series').retrieve({ limit: 5 });
    await user.addContentToViewHistory(seriesContent, 500);
    await user.addContentToWatchList(seriesContent);
    const movieContent = await user.getContent().ofContentType('movie').retrieve({ limit: 5 });
    await user.addContentToViewHistory(movieContent, 500);
    await user.addContentToWatchList(movieContent);
    await testUtils.startApplicationAtPage('tv', { user: user });
  });

  //https://tubi.testrail.io/index.php?/cases/view/63513
  it('C63513 - TV Shows Filter - When tv show filter is triggered then only Series Titles are present, @homescreen, @tvshows', async () => {


    await testUtils.waitForAppLaunchBeaconToFire();

    // Check if Featured row contains all Series titles
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');

    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('s');
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/76733
  it('C76733 - TV Shows Filter - When history category displayed then all titles are series, @homescreen, @tvshows', async () => {

    await testUtils.waitForAppLaunchBeaconToFire();

    // Scroll down to Continue Watching
    await testUtils.jumpToRowWithTitle('tvScreenRowList', 'Continue Watching');


    // Check if CW row contains all Series titles

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');


    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('s');
    }
  });

  // https://tubi.testrail.io/index.php?/cases/view/538328
  it('C538328 - Series Filter - When My List category displayed then all titles are series, @homescreen, @tvshows', async () => {


    // await testUtils.waitForAppLaunchBeaconToFire();

    // Scroll down to My List
    await testUtils.jumpToRowWithTitle('tvScreenRowList', 'My List');


    // Check if CW row contains all Series titles

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');


    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('s');
    }

  });
  // https://tubi.testrail.io/index.php?/cases/view/538329
  it('538329 - TV Shows Filter - When title is selected then corresponding details page displayed, @homescreen, @tvshows', async () => {

    await testUtils.waitForAppLaunchBeaconToFire();

    // Check if Featured row contains all Series titles
    const tvShowsSeriesLabel = await testUtils.getNodeForElement('tvShowsSeriesLabel');
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');

    for (const itemContent of rowItemsContent) {
      expect(tvShowsSeriesLabel.text).to.contain('Series');
    }

    // Now select a title to redirect us on the detail page
    await ecp.sendKeyPress(ecp.Key.Ok);
    await testUtils.retryWithTimeOut(async () => {
      await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Episodes list');
    });

    // Verify the Details page is a Series Details page
    const detailsPageSeriesLabel = await testUtils.getNodeForElement('detailsPageSeriesLabel');
    expect(detailsPageSeriesLabel.text).contains('Season');
  });
});
