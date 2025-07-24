import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { moveToGrid } from '../analytics/utils/helpers';
import { shared } from '../shared';


describe('Search', function () {
  describe('Linear Search', function () {
    const LINEAR_CHANNEL_TITLE = 'NBC News NOW';

    it('C244256 When a user searches for a channel, the channel is shown in the search results @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);
      await ecp.sendText('nbc');

      await shared.navigateToContentInSearchResults({title: LINEAR_CHANNEL_TITLE});
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
    });

    it('C244258 When a user clicks on the channel poster, the live channel should start playing @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);
      await ecp.sendText('nbc');

      await shared.navigateToContentInSearchResults({title: LINEAR_CHANNEL_TITLE});
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify that the linear channel plays
      await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing');
    });

    it('C244259 When a user presses the back button, the user is sent back to the search result page @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);
      await ecp.sendText('nbc');

      await shared.navigateToContentInSearchResults({title: LINEAR_CHANNEL_TITLE});
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify that the Linear channel plays
      await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing');

      // Press the back button and verify that the user is redirected back to the Search result page
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });
    });

    it('C244260 - The user should be able to access the channel guide and other player features from the player page of the selected channel @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);
      await ecp.sendText('nbc');

      await shared.navigateToContentInSearchResults({title: LINEAR_CHANNEL_TITLE});
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify that the linear channel plays
      await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 10000);

      // Press left to access the EPG left nav and verify the closed captions button exists
      await ecp.sendKeypress(ecp.Key.Left, { count: 2 });
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

    it('C244271  Ensure that when the user hover over a channel search result the channel name and description is displayed on the top left corner @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);
      await ecp.sendText('nbc');

      await shared.navigateToContentInSearchResults({title: LINEAR_CHANNEL_TITLE});
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
      });

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
        expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
      });

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsDesc = await testUtils.getNodeForElement('searchResultsDesc');
        expect(searchResultsDesc).to.exist;
      });
    });

    it('C406434 When a user taps "Play" button on linear channel, backing out takes user back to search results @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);
      await ecp.sendText('nbc');

      await shared.navigateToContentInSearchResults({title: LINEAR_CHANNEL_TITLE});
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
      await ecp.sendKeypress(ecp.Key.Play);

      // Verify that the Linear channel plays
      await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 10000);

      // Press the back button and verify that the user is redirected back to the Search result page
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.retryWithTimeOut(async () => {
        const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
        expect(searchResultsText.text).to.equal('NBC News NOW');
      });
    });

    // https://tubi.testrail.io/index.php?/cases/view/540011
    it('540011 - If search page fetches "Top Searched" container, more than 10 titles are displayed under Trending Searches @search', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await testUtils.goToPage('search');
      await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus',10000);

      // Navigate down 3 rows
      await ecp.sendKeypress(ecp.Key.Down, {count:3});
      await testUtils.waitForElementToFullyShowOnScreen('trendingSearchResult11');
  
    });

    // https://tubi.testrail.io/index.php?/cases/view/540012
    it('540012 - Trending Searches in Kids Mode, more than 10 titles are displayed under Trending Searches @search', async () => {
      await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for rowlist to have focus');
      await testUtils.goToPage('search');

      // Navigate down 3 rows
      await ecp.sendKeypress(ecp.Key.Down, {count:3});
      await testUtils.waitForElementToFullyShowOnScreen('trendingSearchResult11');
  
    });
    
  });
    
});

