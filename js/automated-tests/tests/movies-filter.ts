import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Homescreen Navigation - Movies Filter', function () {
  before(async () => {
    const user = await testUtils.createRegisteredUser();
    const seriesContent = await user.getContent().ofContentType('series').retrieve({ limit: 5 });
    await user.addContentToViewHistory(seriesContent, 500);
    await user.addContentToWatchList(seriesContent);
    const movieContent = await user.getContent().ofContentType('movie').retrieve({ limit: 5 });
    await user.addContentToViewHistory(movieContent, 500);
    await user.addContentToWatchList(movieContent);

    await testUtils.startApplicationAtPage('movies', { user: user });
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





});
