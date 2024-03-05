import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import exp = require('constants');




describe('Top Navigation', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    });

    // https://tubi.testrail.io/index.php?/cases/view/148678
    it('C148678 - Application Launch - Focus is on the first piece of content in the featured row, @topnav', async () => {

        // Focus should be on the first piece of content in the Featured Row
        const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
        expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
        expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
        await testUtils.elementHasFocus('homeScreenRowList',true);

      });

      // https://tubi.testrail.io/index.php?/cases/view/150519
    it('C150519 - Application Launch - Side nav is closed with Home icon selected, @topnav', async () => {

        // Focus should be on the first piece of content in the Featured Row
        const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
        expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
        expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
        await testUtils.elementHasFocus('homeScreenRowList',true);

        // Home icon in present in the left nav
        const homeButtonContent = await testUtils.getGridItemContent('sideNavMenu', 3);
        expect(homeButtonContent.id).to.equal('home');

      });


      // https://tubi.testrail.io/index.php?/cases/view/150520
    it('C150520 - Application Launch - For You is selected in the top nav, @topnav', async () => {

      // For You Top Nav option is highlighted, not focused (white background)
      await topNavForYouLabelNotFocused();

    });

     // https://tubi.testrail.io/index.php?/cases/view/150521
     it('C150521 - Pressing up on the remote from the top content row moves focus to Top - Recommended, @topnav', async () => {

      // For You Top Nav option is highlighted (not focused)
      await topNavForYouLabelNotFocused();


      // Press the Up button
      await ecp.sendKeypress(ecp.Key.Up);

      // Top Nav "For You" is in focus and changes color
      await topNavForYouLabelFocused();
    });

     // https://tubi.testrail.io/index.php?/cases/view/150527
     it('C150527 - Top Nav Options when Top nav is in focus Top Navigation Tests, @topnav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Press back on the remote
      await ecp.sendKeypress(ecp.Key.Back);

      // For You Top Nav option is focused
      await topNavForYouLabelFocused();

      // Movies option is available
      const topNavMoviesItem = await testUtils.getNodeForElement('topNavMoviesItem');
      expect(await topNavMoviesItem.text).to.equal('Movies');

      // TV Shows option is available
      const topNavTVShowsItem = await testUtils. getNodeForElement('topNavTVShowsItem');
      expect(await topNavTVShowsItem.text).to.equal('TV Shows');

      // Live option is avaiable
      const topNavLiveItem = await testUtils. getNodeForElement('topNavLiveItem');
      expect(await topNavLiveItem.text).to.equal('Live TV');

    });

     // https://tubi.testrail.io/index.php?/cases/view/150529
     it('C150529 - The only scroll direction available from the rightmost position of the Top Nav is left, @topnav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

       // For You Top Nav option is highlighted
       await topNavForYouLabelNotFocused();

      // Movies option is available
      const topNavMoviesItem = await testUtils.getNodeForElement('topNavMoviesItem');
      expect(await topNavMoviesItem.text).to.equal('Movies');

      // Press the Up button
      await ecp.sendKeypress(ecp.Key.Up);

      // Press right 4 times (try to scroll right beyond the Live TV top nav option)
      await ecp.sendKeypress(ecp.Key.Right,  {count: 4});

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on the Live TV page?
      await testUtils.waitForCurrentScreenToEqual('epgScreen');

      // Press Up to highlight Live TV option
      await ecp.sendKeypress(ecp.Key.Up);

      // Live option is selected and in focus
      await topNavForYouLabelFocused();


    });

     // https://tubi.testrail.io/index.php?/cases/view/150530
     it('C150530 - Home icon in the Side Nav remains highlighted as the user is interacting with HOME canvas, @topnav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');


      // Home icon is highlighed

      await testUtils.waitForFocusedSideNavMenuItemToEqual('home');

      // Scroll down
      await ecp.sendKeypress(ecp.Key.Down, {count : 4});

      // Home icon is highlighed
      await testUtils.waitForFocusedSideNavMenuItemToEqual('home');

      // Scroll right
      await ecp.sendKeypress(ecp.Key.Right, {count : 4});

      // Home icon is highlighed
      await testUtils.waitForFocusedSideNavMenuItemToEqual('home');

    });

     // https://tubi.testrail.io/index.php?/cases/view/150531
     it('C150531 - Selecting Movies in Top Nav results in redirection to the Movies page, @topnav', async () => {

      // Focus should be on the first piece of content in the Featured Row

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');


      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);

      // Scroll right to Movies tab
      await ecp.sendKeypress(ecp.Key.Right);

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Movie screen?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      const movieScreenFirstRowName = testUtils.getNodeForElement('movieScreenFirstRowName');
      expect((await movieScreenFirstRowName).text).to.equal('Featured');
    });

     // https://tubi.testrail.io/index.php?/cases/view/150532
     it('C150532 - Selecting TV Shows in Top Nav results in redirection to the TV Shows page, @topnav', async () => {

      // Start on Home Page
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

      // Focus should be on the first piece of content in the Featured Row

      const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
      expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
      expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
      await testUtils.elementHasFocus('homeScreenRowList',true);

      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);
      await topNavForYouLabelFocused();

      // Scroll right to TV Shows tab
      await ecp.sendKeypress(ecp.Key.Right, {count : 2});

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on TV Shows screen?
      await testUtils.waitForElementToHaveFocus('tvShowsScreenRowList', 'Timed out waiting for Rowlist to have focus');
      const tvShowsScreenFirstRowName = testUtils.getNodeForElement('tvShowsScreenFirstRowName');
      expect((await tvShowsScreenFirstRowName).text).to.equal('Featured');
    });

      // https://tubi.testrail.io/index.php?/cases/view/150533
      it('C150533 - Selecting Live in Top Nav results in redirection to the Live page, @topnav', async () => {

      // Start on Home Page
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

      // Highlight should be on the first piece of content in the Featured Row
      await topNavForYouLabelNotFocused();

      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);
      await topNavForYouLabelFocused();

      // Scroll right to Live tab
      await ecp.sendKeypress(ecp.Key.Right, {count : 3});

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Live screen?
      await utils.sleep(5000); // timeout in getNodeForElement did not work here -- Brian
      const liveScreenHeader = await testUtils.getNodeForElement('liveScreenHeader', 10000);
      expect(liveScreenHeader.text).to.equal('Featured');
    });

    // https://tubi.testrail.io/index.php?/cases/view/150536
    it('C150536 - Pressing “back” ONCE from the non-default Movies top nav position results in focus on Default "For You", @topnav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Focus should be on the first piece of content in the Featured Row

      const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
      expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
      expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
      await testUtils.elementHasFocus('homeScreenRowList',true);

      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);

      // Scroll right to Movies tab
      await ecp.sendKeypress(ecp.Key.Right);

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Movie screen?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      const movieScreenFirstRowName = await testUtils.getNodeForElement('movieScreenFirstRowName');
      expect(movieScreenFirstRowName.text).to.equal('Featured');

      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);

      // Press the Back button
      await ecp.sendKeypress(ecp.Key.Back);

      // Is For You focused?
      await topNavForYouLabelFocused();


    });

    // https://tubi.testrail.io/index.php?/cases/view/150543
    it('C150543 - For You page - Pressing left from the left-most position in any row reveals the side nav, @topnav', async () => {

      // Start on Home Page
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

      // Focus should be on the first piece of content in the Featured Row
      const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
      expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
      expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
      await testUtils.elementHasFocus('homeScreenRowList',true);

      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);
      await topNavForYouLabelFocused();


      // Scroll Left to Open left Nav
      await ecp.sendKeypress(ecp.Key.Left);

      // Home icon is highlighed - Need helper to verify it's highlighted
      const color = await testUtils.getElementColorField('leftNavHomeButton','color');
      expect(color).to.equal('#FFFFFFFF');

    });

     // https://tubi.testrail.io/index.php?/cases/view/150544
    it('C150544 - Pressing left from the left-most position of the top nav reveals the side nav, @topnav', async () => {

      // Start on Home Page
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

      // Focus should be on the first piece of content in the Featured Row
      const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
      expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
      expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
      await testUtils.elementHasFocus('homeScreenRowList',true);

      // Scroll down the page
      await ecp.sendKeypress(ecp.Key.Down, {count: 9});

      // Scroll Left to Open left Nav
      await ecp.sendKeypress(ecp.Key.Left);

      // Home icon is highlighed
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      const color = await testUtils.getElementColorField('leftNavHomeButton','color');
      expect(color).to.equal('#FFFFFFFF');

    });

     // https://tubi.testrail.io/index.php?/cases/view/150561
    it('C150561 - Top Nav is not present in Kids mode, @topnav', async () => {

      // Start on Home Page
      await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Focus should be on the first piece of content in the Featured Row
      const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
      expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
      expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
      await testUtils.elementHasFocus('homeScreenRowList',true);

      // Scroll up to top nav
      await ecp.sendKeypress(ecp.Key.Up);

      // Check for Top Nav (should not be visible)
      const topNavMenuHome = await testUtils.getNodeForElement('topNavMenuHome');
      expect(topNavMenuHome.visible).to.equal(false);


    });


       // https://tubi.testrail.io/index.php?/cases/view/150562
       it('C150579 -  When user navigates away from Home via side nav to another page, then returns home, For You is the default focusTop Nav is not present in Search page, @topnav', async () => {

        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open side nav ,select Search, then Home again
        await openLeftNav();
        await testUtils.selectMenuItem('sideNavMenu','Search');
        await testUtils.waitForFocusedSideNavMenuItemToEqual('search');
        await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.selectMenuItem('sideNavMenu','Home');

        // Verify we are on home screen again and top nav state
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // For You Top Nav option is not highlighted
        await topNavForYouLabelNotFocused();


      });

      it('C150580 - Pressing back once from a non-home level 1 page results in opening the side nav, @topnav', async () => {

        // Focus should be on the first piece of content in the Featured Row
        const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
        expect(homeScreenRowList.rowItemFocused[0]).to.equal(0);
        expect(homeScreenRowList.rowItemFocused[1]).to.equal(0);
        await testUtils.elementHasFocus('homeScreenRowList',true);

        // Open left Nav
        await openLeftNav();

        // Select Categories
        await testUtils.selectMenuItem('sideNavMenu','Categories');

        //Verify that user is on the Categories page
        const channelCategoryGrid = await testUtils.getNodeForElement('channelCategoryGrid');
        await testUtils.elementHasFocus('channelCategoryGrid',true);

        // Press the back button
        await ecp.sendKeypress(ecp.Key.Back);

        // Is left Nav Open?
        await testUtils.waitForSideNavMenuToBeExpanded();
        await testUtils.waitForFocusedSideNavMenuItemToEqual('categories');

      });


      it('C150582 - Pressing back a third time from non-home level 1 page, @topnav', async () => {


        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left Nav
        await openLeftNav();

        // Select Categories
        await testUtils.selectMenuItem('sideNavMenu','Categories');

        //Verify that user is on the Categories page
        const channelCategoryGrid = await testUtils.getNodeForElement('channelCategoryGrid');
        await testUtils.elementHasFocus('channelCategoryGrid',true);

        // Press the back button
        await ecp.sendKeypress(ecp.Key.Back, {count:3});

        // Verify that the Exit modal dialog is displayed
        const exitDialogButtonText = await testUtils.getNodeForElement('exitDialogButtonText');
     

      });


    });

    async function topNavForYouLabelNotFocused() {
      const topNavForYouLabelNotFocused = await testUtils.getNodeForElement('topNavForYouLabelNotFocused', 5000);
      expect(topNavForYouLabelNotFocused.text).to.equal('For You');
      const colorForYouUnfocused = await testUtils.getElementColorField('topNavForYouLabelNotFocused','color');
      expect(colorForYouUnfocused).to.equal('#FFFFFFFF');
     }

     async function topNavForYouLabelFocused() {
      const topNavForYouLabelFocused = await testUtils.getNodeForElement('topNavForYouLabelFocused', 3000);
      expect(topNavForYouLabelFocused.text).to.equal('For You');
      const colorForYouFocused = await testUtils.getElementColorField('topNavForYouLabelFocused','color');
      expect(colorForYouFocused).to.equal('#0B0019FF');
     }

     async function openLeftNav() {

      // Press back twice
      await ecp.sendKeypress(ecp.Key.Back, {count:2});

      // Home icon is highlighed
      await testUtils.waitForSideNavMenuToBeExpanded(10000);
      await testUtils.waitForFocusedSideNavMenuItemToEqual('home', 10000);
   }
