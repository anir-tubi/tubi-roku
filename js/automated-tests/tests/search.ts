import { expect } from 'chai';
import { ecp, odc, proxy, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { moveToGrid } from '../analytics/utils/helpers';
import { shared, testHelpers } from '../test-helpers';


describe('Search', function () {
	describe('Linear Search', function () {
		const LINEAR_CHANNEL_TITLE = 'NBC News NOW';

		it('C244256 When a user searches for a channel, the channel is shown in the search results @search', async () => {
			await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
			await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
			await testUtils.goToPage('search');
			await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus', 10000);
			await ecp.sendText('nbc');

			await shared.navigateToContentInSearchResults({ title: LINEAR_CHANNEL_TITLE });
			await testUtils.retryWithTimeOut(async () => {
				const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
				expect(searchResultsText.text).to.equal(LINEAR_CHANNEL_TITLE);
			});

			const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
			expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon-filled.webp');
		});

		it('C244258 When a user clicks on the channel poster, the live channel should start playing @search', async () => {
			await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
			await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
			await testUtils.goToPage('search');
			await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus', 10000);
			await ecp.sendText('nbc');

			await shared.navigateToContentInSearchResults({ title: LINEAR_CHANNEL_TITLE });
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
			await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
			await testUtils.goToPage('search');
			await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus', 10000);
			await ecp.sendText('nbc');

			await shared.navigateToContentInSearchResults({ title: LINEAR_CHANNEL_TITLE });
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

		it('C244271  Ensure that when the user hover over a channel search result the channel name and description is displayed on the top left corner @search', async () => {
			await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
			await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
			await testUtils.goToPage('search');
			await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus', 10000);
			await ecp.sendText('nbc');

			await shared.navigateToContentInSearchResults({ title: LINEAR_CHANNEL_TITLE });
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
			await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
			await testUtils.goToPage('search');
			await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for element to have focus', 10000);
			await ecp.sendText('nbc');

			await shared.navigateToContentInSearchResults({ title: LINEAR_CHANNEL_TITLE });
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

		// https://tubi.testrail.io/index.php?/cases/view/22728
		it('C22728 - Search - When movie selected then corresponding movie details page displayed @search @navigation @manual_regression', async () => {
			/**
			 * Pre-conditions: None
			 * 
			 * Test Steps:
			 * 1. Launch app
			 * 2. Navigate to search
			 * 3. Search for a movie
			 * 4. Select movie from results
			 * 5. Verify movie details page is displayed with correct content
			 */

			// Launch app
			await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
			await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
			await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

			// Navigate to search
			await testUtils.goToPage('search');
			await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);
			await utils.sleep(1000);

			// Enter search query for a popular movie
			await ecp.sendText('action');
			await utils.sleep(2000);

			// Verify search results appear
			await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);

			// Navigate to search results grid using helper
			await testHelpers.navigateRightToSearchGrid();
			await utils.sleep(500);

			// Navigate to first movie in search results (type 'v' and no seriesId)
			await testUtils.navigateToGridItem('searchResultGrid', (item) => item.type === 'video' && (!item.seriesId || item.seriesId === ''));
			await utils.sleep(500);

			// Get the focused movie content
			const movieContent = await testUtils.getCurrentlyFocusedGridItemContent('searchResultGrid');
			expect(movieContent.type).to.equal('video', 'Selected content should be a movie');

			// Select the movie
			await ecp.sendKeypress(ecp.Key.Ok);
			await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

			// Verify movie details page is displayed
			await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 5000);
			const detailTitle = await testUtils.getNodeForElement('detailScreenTitle');
			expect(detailTitle.visible).to.equal(true, 'Movie details page should be visible');
			expect(detailTitle.text).to.exist.and.not.be.empty;

			// Verify content matches
			const detailContent = await testUtils.getElementField('detailScreen', 'content');
			expect(detailContent).to.exist;
			expect(detailContent.id).to.equal(movieContent.id, 'Detail page should show the selected movie');
		});

	});

	//https://tubi.testrail.io/index.php?/cases/view/585698
	it('C585698 - Should display trending searches under search results for no results scenario @search @manual_regression', async () => {
		// Launch Tubi and observe homescreen
		await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
		await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

		// Navigate to Search page using testUtils.goToPage
		await testUtils.goToPage('search');

		// Verify we're on the search screen by checking trending results grid with no search text
		await testUtils.untilTrue(async () => {
			const contents = await testUtils.getAllGridItemsContent('trendingSearchResultsGrid');
			return contents.length > 5;
		}, 'trendingSearchResultsGrid content count not greater than 5', 30000);

		// Enter search terms that will return no results
		const noResultsQuery = 'dddd';
		await ecp.sendText(noResultsQuery);
		await utils.sleep(3000);


		// Verify the no matching results message content
		const noResultsMessage = await testUtils.getNodeForElement('noMatchingResultsMessage');

		const translation = await testUtils.getElementField('trendingSearchResultsContainer', 'translation');
		expect(translation[1]).to.be.lessThanOrEqual(100, 'Trending searches container is not at the top of the screen');
		//If no matching results are found, trending searches will show on the results area.
		if (noResultsMessage.visible == true) {
			await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for search screen', 10000);
		}

		await proxy.start();
		await ecp.sendKeypress(ecp.Key.Backspace, { count: 4, wait: 100 });
		await ecp.sendText('test');

		// Set up proxy to limit search results to just 4 entries
		const proxyPromise = new Promise((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes('/api/v2/search');
				},
				processResponse(args) {
					const responseJson = JSON.parse(args.responseBuffer.toString());
					console.log('Search response intercepted', args.url);

					// Limit the contents to just 4 entries
					if (responseJson.contents) {
						const contentIds = Object.keys(responseJson.contents);
						const limitedContentIds = contentIds.slice(0, 4);

						// Create new contents object with only 4 entries
						const limitedContents = {};
						limitedContentIds.forEach(id => {
							limitedContents[id] = responseJson.contents[id];
						});

						responseJson.contents = limitedContents;
						console.log(`Limited search results from ${contentIds.length} to ${limitedContentIds.length}`);
					}

					resolve(null);
					args.removeCallback();
					return JSON.stringify(responseJson);
				},
			});
		});

		await utils.promiseTimeout(proxyPromise, 5000);

		// Verify we have limited results and trending searches are visible
		const searchResultsGrid = await testUtils.getAllGridItemsContent('searchResultGrid');
		expect(searchResultsGrid.length).to.equal(4, 'Search results should be limited to 4');

		const newTranslation = await testUtils.getElementField('trendingSearchResultsContainer', 'translation');
		expect(newTranslation[1]).to.be.lessThanOrEqual(500, 'Trending searches container is not at the top of the screen');

		// Now test with more results (no proxy limit)
		await proxy.stop();
		await ecp.sendKeypress(ecp.Key.Backspace, { count: 4, wait: 100 });
		await ecp.sendText('Fox');

		const searchResultsGridUpdated = await testUtils.getAllGridItemsContent('searchResultGrid');

		//When we have more search results for search terrm, you will not see the trensing searches but it will be on the bottom of the screen
		if (searchResultsGridUpdated.length > 8) {
			const trendingSearches = await testUtils.getNodeForElement('trendingSearchResultsGrid');
			const translation = await testUtils.getElementField('trendingSearchResultsContainer', 'translation');
			expect(translation[1]).to.be.greaterThan(700, 'Trending searches container is not at the bottom of the screen');
			const trendingSearchResults = await testUtils.getAllGridItemsContent('trendingSearchResultsGrid');
			expect(trendingSearches.visible).to.equal(true);
			expect(trendingSearchResults.length).to.be.greaterThan(0);
		}

	});

});

