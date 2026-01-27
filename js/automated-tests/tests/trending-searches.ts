import { expect } from "chai";
import { ecp, proxy, utils } from "roku-test-automation";
import { testUtils } from "../test-utils";
import { testHelpers } from "../test-helpers";

describe("General Regression Tests", function () {
	before(async () => {
		await proxy.start();
	});

	after(async () => {
		await proxy.stop();
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/539948
	it('C539948 - Search page fetches "Top Searched" container @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Navigate to search page
		 * 3. Wait for search screen to load
		 * 4. Verify network call to "Top Searched" container is made
		 */

		let topSearchedCallDetected = false;

		const proxyPromise = new Promise<void>((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes("containers/top_searched");
				},
				processResponse: (args) => {
					topSearchedCallDetected = true;
					resolve();
					args.removeCallback();
					return args.responseBuffer;
				},
			});
		});

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);

		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 10000);

		await utils.promiseTimeout(proxyPromise, 10000);

		expect(topSearchedCallDetected).to.equal(
			true,
			'Expected GET call for "Top Searched" container not detected',
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/540007
	it('C540007 - Search page fetches "Featured" container, while in Kids mode @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Open Kids mode
		 * 3. Navigate to search page
		 * 4. Wait for search screen to load
		 * 5. Verify network call to "Featured" container is made (not "Top Searched")
		 */

		let featuredCallDetected = false;

		const proxyPromise = new Promise<void>((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes("containers/featured");
				},
				processResponse: (args) => {
					featuredCallDetected = true;
					resolve();
					args.removeCallback();
					return args.responseBuffer;
				},
			});
		});

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);

		await testHelpers.openKidsMode();
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);

		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 10000);

		await utils.promiseTimeout(proxyPromise, 10000);

		expect(featuredCallDetected).to.equal(
			true,
			'Expected GET call for "Featured" container not detected',
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/540008
	it('C540008 - Search page fetches "Featured" container, while Parental Controls = Little Kids @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Navigate to settings page
		 * 3. Set Parental Controls to "Little Kids"
		 * 4. Return to home screen
		 * 5. Navigate to search page
		 * 6. Wait for search screen to load
		 * 7. Verify network call to "Featured" container is made
		 */

		let featuredCallDetected = false;

		const proxyPromise = new Promise<void>((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes("containers/featured");
				},
				processResponse: (args) => {
					featuredCallDetected = true;
					console.log("Featured container network call detected:", args.url);
					resolve();
					args.removeCallback();
					return args.responseBuffer;
				},
			});
		});

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);
		proxy.pause();
		await testUtils.goToPage("settings");
		await testUtils.waitForCurrentScreenToEqual("settingsScreen", 10000);
		await testUtils.waitForElementToHaveFocus(
			"settingsMenu",
			"Timed out waiting for Settings menu to have focus",
			10000,
		);

		await testHelpers.setParentalControls("littleKids");
		await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
		await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
		await testUtils.waitForElementToHaveFocus(
			"homeScreenRowList",
			"Timed out waiting for Rowlist to have focus",
			15000,
		);

		proxy.resume();
		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 15000);

		await utils.promiseTimeout(proxyPromise, 10000);

		expect(featuredCallDetected).to.equal(
			true,
			'Expected GET call for "Featured" container not detected',
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/540009
	it('C540009 - Search page fetches "Featured" container, while Parental Controls = Older Kids @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Navigate to settings page
		 * 3. Set Parental Controls to "Older Kids"
		 * 4. Return to home screen
		 * 5. Navigate to search page
		 * 6. Wait for search screen to load
		 * 7. Verify network call to "Featured" container is made
		 */

		let featuredCallDetected = false;

		const proxyPromise = new Promise<void>((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes("containers/featured");
				},
				processResponse: (args) => {
					featuredCallDetected = true;
					console.log("Featured container network call detected:", args.url);
					resolve();
					args.removeCallback();
					return args.responseBuffer;
				},
			});
		});

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);

		proxy.pause();
		await testUtils.goToPage("settings");
		await testUtils.waitForCurrentScreenToEqual("settingsScreen", 10000);
		await testUtils.waitForElementToHaveFocus(
			"settingsMenu",
			"Timed out waiting for Settings menu to have focus",
			10000,
		);

		await testHelpers.setParentalControls("olderKids");
		await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
		await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
		await testUtils.waitForElementToHaveFocus(
			"homeScreenRowList",
			"Timed out waiting for Rowlist to have focus",
			15000,
		);
		proxy.resume();
		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 20000);

		await utils.promiseTimeout(proxyPromise, 15000);

		expect(featuredCallDetected).to.equal(
			true,
			'Expected GET call for "Featured" container not detected',
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/540010
	it('C540010 - Search page fetches "Featured" container, while Parental Controls = Teens @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Navigate to settings page
		 * 3. Set Parental Controls to "Teens"
		 * 4. Return to home screen
		 * 5. Navigate to search page
		 * 6. Wait for search screen to load
		 * 7. Verify network call to "Featured" container is made
		 */

		let featuredCallDetected = false;

		const proxyPromise = new Promise<void>((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes("containers/featured");
				},
				processResponse: (args) => {
					featuredCallDetected = true;
					console.log("Featured container network call detected:", args.url);
					resolve();
					args.removeCallback();
					return args.responseBuffer;
				},
			});
		});

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);

		proxy.pause();
		await testUtils.goToPage("settings");
		await testUtils.waitForCurrentScreenToEqual("settingsScreen", 10000);
		await testUtils.waitForElementToHaveFocus(
			"settingsMenu",
			"Timed out waiting for Settings menu to have focus",
			10000,
		);

		await testHelpers.setParentalControls("teens");
		await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
		await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
		await testUtils.waitForElementToHaveFocus(
			"homeScreenRowList",
			"Timed out waiting for Rowlist to have focus",
			15000,
		);

		proxy.resume();
		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 20000);

		await utils.promiseTimeout(proxyPromise, 15000);

		expect(featuredCallDetected).to.equal(
			true,
			'Expected GET call for "Featured" container not detected',
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/540011
	it('C540011 - If search page fetches "Top Searched" container, more than 10 titles are displayed under Trending Searches @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Navigate to search page
		 * 3. Wait for trending search results grid to show
		 * 4. Scroll down to ensure all items are loaded
		 * 5. Verify more than 10 titles are displayed under Trending Searches
		 */

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);

		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 10000);

		await testUtils.waitForElementToShowOnScreen(
			"trendingSearchResultsGrid",
			"Timed out waiting for trending search results grid",
			10000,
		);

		await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
		await testUtils.waitForElementToFullyShowOnScreen("trendingSearchResult11");

		const trendingSearchResults = await testUtils.getAllGridItemsContent(
			"trendingSearchResultsGrid",
		);
		expect(trendingSearchResults.length).to.be.greaterThan(
			10,
			"Expected more than 10 titles under Trending Searches",
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/540012
	it('C540012 - If search page fetches "Featured" container, X titles are displayed under Trending Searches @manual_regression', async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Launch app as guest user on home page
		 * 2. Count the number of items in the Featured row
		 * 3. Open Kids mode
		 * 4. Navigate to search page
		 * 5. Wait for kids search results grid to show
		 * 6. Verify the number of trending searches matches the Featured row count
		 */

		await testUtils.startApplicationAtPage("home", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);


		await testHelpers.openKidsMode();
		await testUtils.waitForElementToHaveFocus(
			"videoTitlesRowList",
			"Timed out waiting for Rowlist to have focus",
		);
		const featuredRowCount = await testUtils.getRowListRowItemsContent(
			"videoTitlesRowList",
			0,
		);
		const expectedCount = featuredRowCount.length;

		await testUtils.goToPage("search");
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 20000);

		await testUtils.waitForElementToShowOnScreen(
			"kidsSearchResultsGrid",
			"Timed out waiting for kids search results grid",
			20000,
		);

		await utils.sleep(2000);

		const trendingSearchResults = await testUtils.getAllGridItemsContent(
			"kidsSearchResultsGrid",
		);
		expect(trendingSearchResults.length).to.be.greaterThanOrEqual(
			expectedCount,
			`Expected at least ${expectedCount} titles under Trending Searches to match Featured row count`,
		);
	});

	// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/591013
	it("C591013 - Verify trending searches are displayed when user deeplinks to search page @manual_regression", async () => {
		/**
		 * Pre-conditions:
		 * - Guest user
		 * - Proxy is started to intercept network calls
		 *
		 * Test Steps:
		 * 1. Deeplink directly to search page (startApplicationAtPage('search'))
		 * 2. Wait for search screen to load
		 * 3. Enter search query "fox"
		 * 4. Wait for search results
		 * 5. Clear the search query by pressing backspace
		 * 6. Verify "Top Searched" network call is made
		 * 7. Verify trending searches are displayed after clearing the query
		 */

		let topSearchedCallDetected = false;

		const proxyPromise = new Promise<void>((resolve) => {
			proxy.addCallback({
				shouldProcess: (args) => {
					return args.url.includes("containers/top_searched");
				},
				processResponse: (args) => {
					topSearchedCallDetected = true;
					resolve();
					args.removeCallback();
					return args.responseBuffer;
				},
			});
		});

		await testUtils.startApplicationAtPage("search", {
			shouldCreateNewUser: true,
			clearRegistry: false,
		});
		await testUtils.waitForCurrentScreenToEqual("searchScreen", 20000);
		await testUtils.waitForElementToShowOnScreen(
			"trendingSearchResultsGrid",
			"Timed out waiting for trending search results grid",
			20000,
		);

		await ecp.sendText("fox");
		await utils.sleep(3000);

		await testUtils.waitForElementToShowOnScreen(
			"searchResultGrid",
			"Search results grid not visible",
			20000,
		);

		await ecp.sendKeypress(ecp.Key.Backspace, { count: 3, wait: 200 });
		await utils.sleep(3000);

		await utils.promiseTimeout(proxyPromise, 20000);

		expect(topSearchedCallDetected).to.equal(
			true,
			'Expected GET call for "Top Searched" container not detected',
		);

		await testUtils.waitForElementToShowOnScreen(
			"trendingSearchResultsGrid",
			"Timed out waiting for trending search results grid",
			20000,
		);

		const trendingSearchResults = await testUtils.getAllGridItemsContent(
			"trendingSearchResultsGrid",
		);
		expect(trendingSearchResults.length).to.be.greaterThan(
			0,
			"Expected trending searches to be displayed",
		);
	});
});
