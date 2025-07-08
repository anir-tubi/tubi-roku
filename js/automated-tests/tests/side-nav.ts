import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import exp = require('constants');



describe('Side Navigation', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });

    // https://tubi.testrail.io/index.php?/cases/view/535773
    it('C535773 - Side Navigation - Home - When user presses the Back button then side nav should expand from collapsed state, @sidenav', async () => {
      
       // Press the back button
       await ecp.sendKeypress(ecp.Key.Back);

       // Is the left Nav open?
       await testUtils.waitForSideNavMenuToBeExpanded();

    });


    // https://tubi.testrail.io/index.php?/cases/view/535774
    it('C535774 - Side Navigation - Home - Left Nav Button - First Position, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Press Left
      await ecp.sendKeypress(ecp.Key.Left);

      // Is the left Nav closed?
      await testUtils.waitForSideNavMenuToNotBeExpanded();
    });


    // https://tubi.testrail.io/index.php?/cases/view/535776
    it('C535776 - Side Navigation - Search Page - Highlight, @sidenav', async () => {

      await openLeftNav();

      await ecp.sendKeypress(ecp.Key.Up);
      await ecp.sendKeypress(ecp.Key.Ok);
      expect(testUtils.waitForElementToNotBeInFocusChain('searchGrid'));

    });


    // https://tubi.testrail.io/index.php?/cases/view/535778
    it('C535778 - Side Navigation - Search query preserved - Accessing Left Nav, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      //Open left nav
      await openLeftNav();
      await ecp.sendKeypress(ecp.Key.Up);
      await utils.sleep(2000);
      await testUtils.verifyFocusedSideNavMenuItemEquals('search'); /// Fix this
      await ecp.sendKeypress(ecp.Key.Ok);
      await ecp.sendText('zapp');
      await utils.sleep(3000);
      await testUtils.retryWithTimeOut(async () => {
        const searchText = await testUtils.getNodeForElement('searchText');
        expect(searchText.text).to.equal('Results');
      });


      // Back to side nav
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.elementHasFocus('sideNavMenu', true);


      // Search Results still present?
      await navigateRightToGrid();
      await utils.sleep(2500);
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(await searchResultsText.text).to.contains('Zapped');

    });


    // https://tubi.testrail.io/index.php?/cases/view/535779
    it('C535779 - Side Navigation - Settings - Back Button, @sidenav', async () => {

        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        //Open left nav and browse down to Settings, select
        await openLeftNav();
        await testUtils.jumpToRowWithTitle('sideNavMenu', 'Settings');
        await ecp.sendKeypress(ecp.Key.Ok);


        //Verify that user is on the Settings page
        const settingsScreenTitle = await testUtils.getNodeForElement('settingsScreenTitle');
        expect(settingsScreenTitle.text).to.be.equal('Settings');

        // Back 3 times
        await ecp.sendKeypress(ecp.Key.Back, {count:3});
        await utils.sleep(2000);

        //Verify that Side nav is expanded and Home button is  highlighted
        const leftNavHomeLabel = await testUtils.getNodeForElement('leftNavHomeLabel');
        const color = await testUtils.getElementColorField('leftNavHomeLabel','color');
        expect(color).to.equal('#FFFFFFFF');

    });


    // https://tubi.testrail.io/index.php?/cases/view/535796
    it('C535796 - Side Navigation - Settings - Back Button, @sidenav', async () => {

      // Need to relaunch
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      //Open left nav and browse down to Settings, select
      await openLeftNav();
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Settings');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Settings screen has focus
      await testUtils.waitForCurrentScreenToEqual('settingsScreen');

      // Back 3 times
      await ecp.sendKeypress(ecp.Key.Back, {count:3});

      // Verify that the Exit modal dialog is displayed
      const exitPrompt = testUtils.getNodeForElement('exitPrompt');
      expect((await exitPrompt).visible).to.be.true;

    });


    // https://tubi.testrail.io/index.php?/cases/view/535780
    it('C535780 - Side Navigation - Expanded to Collapsed State - Right Button, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left nav
      await openLeftNav();

      // Press Right
      await ecp.sendKeypress(ecp.Key.Right, {count:1});

      // Is the left Nav closed?
      await testUtils.waitForSideNavMenuToNotBeExpanded();
      // Row list element checl

    });


    // https://tubi.testrail.io/index.php?/cases/view/535781
    it('C535781 - Side Navigation - Search Page - Select, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Select Search
      await ecp.sendKeypress(ecp.Key.Up);
      await utils.sleep(2000);
      const color = await testUtils.getElementColorField('leftNavSearchLabel','color');
      expect (color).to.equal('#FFFFFFFF');
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);

      // Are we on Search page?
      const searchKeyPad = await testUtils.getNodeForElement('searchKeyPad');
      expect(searchKeyPad.keyFocused).to.be.equal('a');

    });


    // https://tubi.testrail.io/index.php?/cases/view/537391
    it('C537391 - Side Navigation - Home Page - Select, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Press OK
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);

      //Verify that user is on the Home page
      await utils.sleep(2000);
      await testUtils.elementHasFocus('homeScreenRowList', true);

    });


    // https://tubi.testrail.io/index.php?/cases/view/535783
    it('C535783 - Side Navigation - Categories Page - Highlight, @sidenav', async () => {

      await openLeftNav();

      // Press Down to Categories
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');

      //Is Categories button highlighted?
      const color = await testUtils.getElementColorField('categoriesLabel','color');
      expect(color).to.equal('#FFFFFFFF');

      // Scroll right once
      await ecp.sendKeypress(ecp.Key.Right, {count:1});

      // Make sure we are NOT on Categories page, but still on Home page
      await testUtils.elementHasFocus('homeScreenRowList',true);


    });


    // https://tubi.testrail.io/index.php?/cases/view/535784
    it('C535784 - Side Navigation - Categories Page - Select, @sidenav', async () => {

      await openLeftNav();
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');

      // Does category menu item have focus?
      // await testUtils.verifySelectedMainMenuItemEquals('categories'); - Brian to change this.
      const color = await testUtils.getElementColorField('categoriesLabel','color');
      expect (color).to.equal('#FFFFFFFF');

      // Press OK
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);

      //Verify that user is on the Categories page
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');

    });



    // https://tubi.testrail.io/index.php?/cases/view/535787
    it('C535787 - Side Navigation - Settings Page - Highlight, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Press Down to Settings option
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Settings');

      //Navigate and highlight Settings 
      await testUtils.waitForElementToShowOnScreen('settingsLeftNavButtonSelected');

      // Press right once
      await ecp.sendKeypress(ecp.Key.Right);

      // Make sure we are NOT on Settings page, but still on home page
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');


    });


    // https://tubi.testrail.io/index.php?/cases/view/535788
    it('C535788 - Side Navigation - Settings Page - Select, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Settings');

      // Does settings menu item have focus?
      // await testUtils.verifySelectedMainMenuItemEquals('settings'); - wait for Brian to change
      const color = await testUtils.getElementColorField('categoriesLabel','color');
      expect(color).to.equal('#FFFFFFFF');

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);

      //Verify that user is on the Settings page
      const settingsScreenTitle = await testUtils.getNodeForElement('settingsScreenTitle');
      expect(settingsScreenTitle.text).to.be.equal('Settings');

    });


    // https://tubi.testrail.io/index.php?/cases/view/535790
    it('C535790 - Side Navigation - Categories Page - Select Title, @sidenav', async () => {

      // Relaunch
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left Nav
      await openLeftNav();
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
      await utils.sleep(2000); // Improvement for sleep

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000); //Improvement

      //Verify that user is on the Categories page
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');

      // Select a category
      await utils.sleep(4000); //Improvement
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);

      // On the title details page?
      await testUtils.waitForCurrentScreenToEqual('detailScreen');

     // Is Play button in focus?
      await utils.sleep(2000);
      const content = await testUtils.getCurrentlyFocusedGridItemContent('detailScreenMenu');
      expect (content.id).to.equal('PlayMenuItem');

    });

    // https://tubi.testrail.io/index.php?/cases/view/535791
    it('C535791 - Side Navigation - Details Page - Press Back Button, @sidenav', async () => {
      // Relaunch - Improvement
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left nav
      await openLeftNav();
      await utils.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Down);

      // Does category menu item have focus?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButton');

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      //Verify that user is on the Categories page
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');

      // Select a category
      await ecp.sendKeypress(ecp.Key.Ok);

      // On the Categories Details page?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

      // Select a title
      await utils.sleep(5000);
      await ecp.sendKeypress(ecp.Key.Right, {wait:2000});
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // On the title details page?
      await testUtils.waitForElementToFullyShowOnScreen('detailsPageMenu');

      // Press the back button and verify that the user is taken to the Category Detail Page
      await ecp.sendKeypress(ecp.Key.Back, {count:1});

      // On the Categories Details page?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

    });

    //https://tubi.testrail.io/index.php?/cases/view/538338
    it('C538338 - From Titles Detail Page > Categories Detail Page > Categories > Exit App @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open the Side nav and select Categories
      await openLeftNav();

      // Select Categories
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Categories page?
      await utils.sleep(2000);
      const categoryPageCategory = await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');

      // Choose a Category
      await ecp.sendKeypress(ecp.Key.Right, {wait:3000});
      await ecp.sendKeypress(ecp.Key.Ok, {wait:3000});

      await testUtils.getNodeForElement('channelInfoPanel');
     
      // Once in detail page press the back button 5x
      await ecp.sendKeypress(ecp.Key.Back, { count: 5 });

      // Verify that the Exit modal dialog is displayed
      await testUtils.waitForElementToFullyShowOnScreen('exitPrompt');
      
    });


    // https://tubi.testrail.io/index.php?/cases/view/538341
    it('C538341 - From Titles Detail Page > Home > Side Nav > Exit App, @sidenav', async () => {

        // Relaunch - Improvement
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForAppLaunchBeaconToFire();

        // Choose a title in the home screen and go into the details page
        await ecp.sendKeypress(ecp.Key.Ok);

        // Once in detail page press the back button 4x

        const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
        expect(detailScreenYearAndDuration.visible).to.equal(true);

        await ecp.sendKeypress(ecp.Key.Back, { count: 3 });

        // Verify that the Exit modal dialog is displayed
        await testUtils.waitForElementToFullyShowOnScreen('exitPrompt');

    });


    // https://tubi.testrail.io/index.php?/cases/edit/538342
    it('C538342 - From Search > Titles Detail Page > Side Nav > Exit App, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForAppLaunchBeaconToFire();

      // Open the Side nav and select Search
      await testUtils.goToPage('search');

      // Search for a title and enter the details page
      await ecp.sendText('zapped');
      // Navigate right until the grid is in focus
      await testUtils.untilTrue(async () => {
        await testUtils.waitForElementToShowOnScreen('searchResultGrid');
          await ecp.sendKeypress(ecp.Key.Right);
          const { value: id } = await odc.getValue({
              base: 'focusedNode',
              keyPath: 'id'
          });
          return id === 'ResultGrid';
      }, 'ResultGrid never obtained focus');

      // Wait until our content is loaded
      await odc.onFieldChangeOnce({
          base: 'focusedNode',
          keyPath: 'content',
          match: {
              base: 'focusedNode',
              keyPath: 'content.0.title',
              value: 'Zapped'
          }
      });

      // Go to the detail page
      await ecp.sendKeypress(ecp.Key.Ok);

      // Once in detail page press the back button 5x
      await testUtils.retryWithTimeOut(async () => {
          const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
          expect(detailScreenYearAndDuration.visible).to.equal(true);
      });

      await ecp.sendKeypress(ecp.Key.Back, { count: 5 });

      // Verify that the Exit modal dialog is displayed
      await testUtils.waitForElementToFullyShowOnScreen('exitPrompt');
      

    });


    // https://tubi.testrail.io/index.php?/cases/view/538343
    it('C538343 - From Titles Detail Page > Channel Detail Page > Channel > Side Nav > Exit App, @sidenav', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open the Side nav and select Categories
      await ecp.sendKeypress(ecp.Key.Left);

      // Is the left Nav open?
      await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButton');

      // Select Categories
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButton');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Categories page?
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader','20000');

      // Choose Networks
      await ecp.sendKeypress(ecp.Key.Down, {wait:3000});
      await ecp.sendKeypress(ecp.Key.Ok, {wait:3000});

      // Verify Channels Details page
      await testUtils.waitForElementToFullyShowOnScreen('networkPageInfoPanelDescription');
      await ecp.sendKeypress(ecp.Key.Ok);

      //Select title
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Once in detail page press the back button 6x
      await testUtils.waitForElementToFullyShowOnScreen('networksInfoPanel');
      await ecp.sendKeypress(ecp.Key.Back, { count: 5, wait:2000 });

      // Verify that the Exit modal dialog is displayed
      await testUtils.waitForElementToFullyShowOnScreen('exitPrompt');

    });

    // https://tubi.testrail.io/index.php?/cases/view/591018
    it('C591018 - The left side nav includes Movies option, @sidenav', async () => {

      await openLeftNav();

     // Verify that Movies option is present
      await testUtils.waitForElementToFullyShowOnScreen('leftNavMoviesItem');
      const leftNavMoviesItem = await testUtils.getNodeForElement('leftNavMoviesItem');
      const leftNavMoviesIconNotFocused = await testUtils.getNodeForElement('leftNavMoviesIconNotFocused');
      expect(leftNavMoviesItem.text).to.equal('Movies');

    });

    // https://tubi.testrail.io/index.php?/cases/view/591019 and https://tubi.testrail.io/index.php?/cases/view/591990
    it('C591019 - The left side nav includes TV Shows option and takes user to TVShows Screen, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      await selectTVShowsVerifyRedirect();

      // Open left nav while on TV Shows Screen
      await ecp.sendKeypress(ecp.Key.Left);
      await testUtils.waitForElementToFullyShowOnScreen('selectedTVShowsItem');

      // Navigate to Home item and press OK
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Home');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify redirect to Home page
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');


    });

    // https://tubi.testrail.io/index.php?/cases/view/591020 and https://tubi.testrail.io/index.php?/cases/view/C591988
    it('C591020 - The left side nav includes Live TV option, @sidenav', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Verify that TV Shows option is present

      const leftNavLiveTVItem = await testUtils.getNodeForElement('leftNavLiveTVItem');
      const leftNavLiveTVIconNotFocused = await testUtils.getNodeForElement('leftNavLiveTVIconNotFocused');
      expect(leftNavLiveTVItem.text).to.equal('Live TV');

      // Navigate down to Live TV option and select
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Live TV');
      await testUtils.waitForElementToFullyShowOnScreen('selectedLiveTVItem');
      await ecp.sendKeypress(ecp.Key.Ok);
      
      // Verify we are on the LIVE TV page
      await testUtils.waitForElementToFullyShowOnScreen('epgProgramGrid');

    });

    // https://tubi.testrail.io/index.php?/cases/view/591023 - includes https://tubi.testrail.io/index.php?/cases/view/591065
    it('C591023 - Left side nav: Networks moved to the Categories page, @sidenav', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();
      await selectCategoriesItem();

      // Verify Categories page
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');
    
      // Select Networks
      await ecp.sendKeypress(ecp.Key.Down);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify navigation to Networks page
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');

    });

    // https://tubi.testrail.io/index.php?/cases/view/591024
    it('C591024 - Left Side Nav: Exit has moved to Settings, @sidenav', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');

     // Verify that Exit item is on the Settings page
      await testUtils.waitForElementToFullyShowOnScreen('exitItem');
      const exitItem = await testUtils.getNodeForElement('exitItem');
      expect(exitItem.text).to.equal('Exit');

      // Navigate to Exit item Press OK
      await testUtils.jumpToRowWithTitle('settingsMenu', 'Exit');
      await testUtils.waitForElementToFullyShowOnScreen('exitItemSelected');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Exit prompt
      const exitPrompt = await testUtils.getNodeForElement('exitPrompt');
      expect(testUtils.elementHasFocus('exitPrompt'));    

    });


    // https://tubi.testrail.io/index.php?/cases/view/536528
    it('C536528 - Side Navigation - Exit - Exit App, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Press back once
      await ecp.sendKeypress(ecp.Key.Back, {count:2});

      // Select Exit from modal
      const exitPrompt = await testUtils.getNodeForElement('exitPrompt');
      expect(testUtils.elementHasFocus('exitPrompt'));

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);

      //Verify that app has exited
      expect(testUtils.waitForApplicationShutdown());

    });

    // https://tubi.testrail.io/index.php?/cases/view/591989 
    it('C591989 - Selecting Home while on the Live TV screen results in the redirection to Home screen, @sidenav', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Verify that TV Shows option is present
      const leftNavLiveTVItem = await testUtils.getNodeForElement('leftNavLiveTVItem');
      const leftNavLiveTVIconNotFocused = await testUtils.getNodeForElement('leftNavLiveTVIconNotFocused');
      expect(leftNavLiveTVItem.text).to.equal('Live TV');

      // Navigate down to Live TV option and select
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Live TV');
      await testUtils.waitForElementToFullyShowOnScreen('selectedLiveTVItem');
      await ecp.sendKeypress(ecp.Key.Ok);
      
      // Verify we are on the LIVE TV page
      await testUtils.waitForElementToFullyShowOnScreen('epgProgramGrid');

      // Open left nav while on Live TV Screen
      await ecp.sendKeypress(ecp.Key.Left);
      await testUtils.waitForElementToFullyShowOnScreen('selectedLiveTVItem');

      // Navigate to Home item and press OK
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Home');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify redirect to Home page
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    });

      // https://tubi.testrail.io/index.php?/cases/view/591992 and https://tubi.testrail.io/index.php?/cases/view/591993
    it('C591992 - Selecting Movies from left nav takes the user to Movies screen, @sidenav', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      await selectMoviesVerifyRedirect();

      // Open left nav while on Movies Screen
      await ecp.sendKeypress(ecp.Key.Left);
      await testUtils.waitForElementToFullyShowOnScreen('selectedMoviesItem');

      // Navigate to Home item and press OK
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Home');
      await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButton');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify redirect to Home page
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    });

    // https://tubi.testrail.io/index.php?/cases/view/575863
    it('C575863 - Side Navigation - Return to Home when pressing back from multiple side nav selections - Search, @sidenav_test', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 60000);

      // Open left nav
      await openLeftNav();

      // Go to Search
      await openPageFromLeftNav('Search');
      await testUtils.waitForElementToFullyShowOnScreen('searchGrid');

      // Open left nav
      await openLeftNav();

      // Go to My Stuff
      await openPageFromLeftNav('My Stuff');
      await testUtils.waitForElementToFullyShowOnScreen('unlockNowForMyStuff');

      // Open left nav
      await openLeftNav();

      // Verify press back should go to Home
      await ecp.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.verifyFocusedSideNavMenuItemEquals('home');

    });

    // https://tubi.testrail.io/index.php?/cases/view/610650
    it('C610650 - Side Navigation - Return to Home when pressing back from multiple side nav selections - Categories, @sidenav_test', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 60000);

      // Open left nav
      await openLeftNav();

      // Go to Categories
      await openPageFromLeftNav('Categories');
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');

      // Open left nav
      await openLeftNav();

      // Go to My Stuff
      await openPageFromLeftNav('My Stuff');
      await testUtils.waitForElementToFullyShowOnScreen('unlockNowForMyStuff');
      
      // Open left nav
      await openLeftNav();

      // Verify press back should go to Home
      await ecp.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.verifyFocusedSideNavMenuItemEquals('home');

    });

    // https://tubi.testrail.io/index.php?/cases/view/610651
    it('C610651 - Side Navigation - Return to Home when pressing back from multiple side nav selections - Channels, @sidenav_test', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 60000);

      // Open left nav
      await openLeftNav();

      // Go to Live Channels
      await openPageFromLeftNav('Live TV');
      await testUtils.waitForElementToFullyShowOnScreen('epgProgramGrid');

      // Open left nav
      await openLeftNav();

      // Go to My Stuff
      await openPageFromLeftNav('My Stuff');
      await testUtils.waitForElementToFullyShowOnScreen('unlockNowForMyStuff');
      
      // Open left nav
      await openLeftNav();

      // Verify press back should go to Home
      await ecp.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.verifyFocusedSideNavMenuItemEquals('home');

    });

    // https://tubi.testrail.io/index.php?/cases/view/610652
    it('C610652 - Side Navigation - Return to Home when pressing back from multiple side nav selections - Espanol, @sidenav_test', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 60000);

      // Open left nav
      await openLeftNav();

      // Go to Espanol
      await openPageFromLeftNav('Español');
      await testUtils.waitForElementToFullyShowOnScreen('espanolLogo');

      // Open left nav
      await openLeftNav();

      // Go to My Stuff from Espanol
      await openPageFromLeftNav('My Stuff');
      await testUtils.waitForElementToFullyShowOnScreen('unlockNowForMyStuff');

      // Open left nav
      await openLeftNav();

      // Verify press back should go to Home
      await ecp.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.verifyFocusedSideNavMenuItemEquals('home');

    });

  });


async function openLeftNav() {
  // Press left
  await ecp.sendKeypress(ecp.Key.Left);

  // Is the left Nav open?
  await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');
}

async function selectCategoriesItem() {
  
  await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeIconFocused');
  await ecp.sendKeypress(ecp.Key.Down);
  await testUtils.waitForElementToFullyShowOnScreen('leftNavCategoriesButtonSelected');
  const leftNavCategoriesButtonSelected = await testUtils.getNodeForElement('leftNavCategoriesButtonSelected');
  expect(leftNavCategoriesButtonSelected.text).to.equal('Categories');
  await ecp.sendKeypress(ecp.Key.Ok);

}

async function selectTVShowsVerifyRedirect() {

  // Verify that TV Shows option is present
  const leftNavTVShowsItem = await testUtils.getNodeForElement('leftNavTVShowsItem');
  const leftNavTVShowsIconNotFocused = await testUtils.getNodeForElement('leftNavTVShowsIconNotFocused');
  expect(leftNavTVShowsItem.text).to.equal('TV Shows');
  expect(leftNavTVShowsIconNotFocused.uri).to.equal('pkg:/images/sideNavTvShows.webp');

  // Select TV Shows option and verify redirect
  // Navigate down to TV Shows option and select
  await testUtils.jumpToRowWithTitle('sideNavMenu', 'TV Shows');
  await testUtils.waitForElementToFullyShowOnScreen('selectedTVShowsItem');

  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToHaveFocus('tvShowsScreenRowList', 'Timed out waiting for Rowlist to have focus');
}

async function selectMoviesVerifyRedirect() {

  // Verify that Movies option is present
  await testUtils.waitForElementToFullyShowOnScreen('leftNavMoviesItem');
  const leftNavMoviesItem = await testUtils.getNodeForElement('leftNavMoviesItem');
  const leftNavMoviesIconNotFocused = await testUtils.getNodeForElement('leftNavMoviesIconNotFocused');
  expect(leftNavMoviesItem.text).to.equal('Movies');
  expect(leftNavMoviesIconNotFocused.uri).to.equal('pkg:/images/sideNavMovies.webp');
  
  // Select Movies option and verify redirect
  // Navigate down to Movies option and select
  await testUtils.jumpToRowWithTitle('sideNavMenu', 'Movies');
  await testUtils.waitForElementToFullyShowOnScreen('selectedMoviesItem');

  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

  
}

async function navigateRightToGrid() {
  await testUtils.untilTrue(async () => {
  await ecp.sendKeypress(ecp.Key.Right);
  const { value: id } = await odc.getValue({
      base: 'focusedNode',
      keyPath: 'id'
    });
    return id === 'ResultGrid';
  }, 'ResultGrid never obtained focus');
}


async function openPageFromLeftNav(title: string) {
  await testUtils.jumpToRowWithTitle('sideNavMenu', title);
  await ecp.sleep(1000);
  await ecp.sendKeypress(ecp.Key.Ok);
}
