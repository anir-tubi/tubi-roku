import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';


describe('Search', function () {
  describe('Linear Search', function () {
    it('C244256 When a user searches for a channel, the channel is shown in the search results', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
    });

    it('C244258 When a user clicks on the channel poster, the live channel should start playing', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Verify that the linear channel plays
      await testUtils.expectPlayerStateToEventuallyEqual('play', 10000);
    });

    it('C244259 When a user presses the back button, the user is sent back to the search result page', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Verify that the Linear channel plays
      await testUtils.expectPlayerStateToEventuallyEqual('play', 10000);

      // Press the back button and verify that the user is redirected back to the Search result page
      await ecp.sendKeyPress(ecp.Key.Back);
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });
    });

    it('C244260 - The user should be able to access the channel guide and other player features from the player page of the selected channe', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Verify that the linear channel plays
      await testUtils.expectPlayerStateToEventuallyEqual('play', 10000);

      // Press left to access the EPG left nav and verify the closed captions button exists
      await ecp.sendKeyPress(ecp.Key.Left, { count: 2 });
      await testUtils.retryWithTimeOut(async () => {
        const btnCC_label = await testUtils.getNodeForElement('btnCC_label');
        expect(btnCC_label.text).to.equal('Subtitles');
      });

      // Verify that the Full TV Guide button exists
      await testUtils.retryWithTimeOut(async () => {
        const epgFullTVGuide = await testUtils.getNodeForElement('epgFullTVGuide');
        expect(epgFullTVGuide.text).to.equal('Full TV Guide');
      });
    });

    // https://tubi.testrail.io/index.php?/cases/view/244261
    it('C244261  When a user searches for a linear channel, the channel matching to the search term should show up in the search results as primary results', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      // Verify search results and live icon
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
    });

    it('C244271  Ensure that when the user hover over a channel search result the channel name and description is displayed on the top left corner', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      //Verify that correct search results are present, live icon is present, and that the Linear Search Results Description exists

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
        expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
      });

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsDesc = await testUtils.getNodeForElement('searchResultsDesc');
        expect(searchResultsDesc).to.exist;
      });
    });

    it('C406434 When a user taps "Play" button on linear channel, backing out takes user back to search results @linearsearch', async () => {
      await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
      await ecp.sendText('nbc');

      // Call function to navigate right to search results grid
      await navigateRightToGrid();

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
      await ecp.sendKeyPress(ecp.Key.Play);

      // Verify that the Linear channel plays
      await testUtils.expectPlayerStateToEventuallyEqual('play', 10000);

      // Press the back button and verify that the user is redirected back to the Search result page
      await ecp.sendKeyPress(ecp.Key.Back);
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });
    });
  });
});


// Navigate right until the grid is in focus
async function navigateRightToGrid() {
  await testUtils.untilTrue(async () => {
    await ecp.sendKeyPress(ecp.Key.Right);
    const { value: id } = await odc.getValue({
      base: 'focusedNode',
      keyPath: 'id'
    });
    return id === 'ResultGrid';
  }, 'ResultGrid never obtained focus');
}
