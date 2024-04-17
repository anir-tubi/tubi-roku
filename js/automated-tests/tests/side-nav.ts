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
      expect(await searchResultsText.text).to.equal('Zapped');

    });


    // https://tubi.testrail.io/index.php?/cases/view/535779
    it('C535779 - Side Navigation - Settings - Back Button, @sidenav', async () => {

        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        //Open left nav and browse down to Settings, select
        await openLeftNav();
        await ecp.sendKeypress(ecp.Key.Down, {count:7});
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
      await ecp.sendKeypress(ecp.Key.Down, {count:7});
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
      await utils.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Ok);

      //Verify that user is on the Home page
      await utils.sleep(2000);
      await testUtils.elementHasFocus('homeScreenRowList', true);

    });


    // https://tubi.testrail.io/index.php?/cases/view/535783
    it('C535783 - Side Navigation - Categories Page - Highlight, @sidenav', async () => {

      await openLeftNav();

      // Press Down to Categories
      await ecp.sendKeypress(ecp.Key.Down, {count:2});

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
      await ecp.sendKeypress(ecp.Key.Down, {count:1});

      // Does category menu item have focus?
      // await testUtils.verifySelectedMainMenuItemEquals('categories'); - Brian to change this.
      const color = await testUtils.getElementColorField('categoriesLabel','color');
      expect (color).to.equal('#FFFFFFFF');

      // Press OK
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);

      //Verify that user is on the Categories page
      await testUtils.waitForElementToFullyShowOnScreen('categoryPagePoster');

    });



    // https://tubi.testrail.io/index.php?/cases/view/535787
    it('C535787 - Side Navigation - Settings Page - Highlight, @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await openLeftNav();

      // Press Down to Settings option
      await utils.sleep(1000);
      await ecp.sendKeypress(ecp.Key.Down, {count:7});

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
      await ecp.sendKeypress(ecp.Key.Down, {count:7});

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
      await ecp.sendKeypress(ecp.Key.Down, {count:1});

      // Does category menu item have focus? // Change this for menu item
      // await testUtils.verifySelectedMainMenuItemEquals('categories'); - Wait for Brian to change
      await utils.sleep(2000); // Improvement for sleep

      // Press OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000); //Improvement

      //Verify that user is on the Categories page
      await testUtils.waitForElementToFullyShowOnScreen('categoryPagePoster');

      // Select a category
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000); //Improvement

      // On the Categories Details page?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesVideoGridPoster');

      // Select a title
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
      await testUtils.waitForElementToFullyShowOnScreen('categoryPagePoster');

      // Select a category
      await ecp.sendKeypress(ecp.Key.Ok);

      // On the Categories Details page?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesVideoGridPoster');

      // Select a title
      await ecp.sendKeypress(ecp.Key.Ok);

      // On the title details page?
      await testUtils.waitForElementToFullyShowOnScreen('detailsPageMenu');

      // Is Play button in focus?
      const content = await testUtils.getCurrentlyFocusedGridItemContent('detailScreenMenu');
      expect (content.id).to.equal('PlayMenuItem');

      // Press the back button and verify that the user is taken to the Category Detail Page
      await ecp.sendKeypress(ecp.Key.Back);

      // On the Categories Details page?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesVideoGridPoster');

    });

    //https://tubi.testrail.io/index.php?/cases/view/538338
    it('C538338 - From Titles Detail Page > Categories Detail Page > Categories > Exit App @sidenav', async () => {

      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open the Side nav and select Categories
      await openLeftNav();

      // Select Categories
      await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
      await utils.sleep(2000); // Improvement
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Categories page?
      await utils.sleep(2000);
      const categoryPageCategory = await testUtils.getNodeForElement('categoryPageCategory');
      expect(categoryPageCategory.visible).to.be.true;

      // Choose a Category
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Category Details page
      await testUtils.retryWithTimeOut(async () => {
          const categoriesDetailsGrid = await testUtils.getNodeForElement('categoriesDetailsGrid');
          expect(categoriesDetailsGrid.visible).to.be.true;
      });

      // Select title
      await utils.sleep(2000); // Improvement
      await ecp.sendKeypress(ecp.Key.Ok);



      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.be.true;

      // Once in detail page press the back button 5x
      await ecp.sendKeypress(ecp.Key.Back, { count: 5 });

      // Verify that the Exit modal dialog is displayed
      const exitPrompt = testUtils.getNodeForElement('exitPrompt');
      expect((await exitPrompt).visible).to.be.true;
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
        const exitPrompt = testUtils.getNodeForElement('exitPrompt');
        expect((await exitPrompt).visible).to.be.true;

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
      const exitPrompt = testUtils.getNodeForElement('exitPrompt');
      expect((await exitPrompt).visible).to.be.true;

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
      await testUtils.waitForElementToFullyShowOnScreen('categoryPagePoster','20000');

      // Choose Networks
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Channels Details page
      await testUtils.waitForElementToFullyShowOnScreen('channelsListScreenPoster');
      await ecp.sendKeypress(ecp.Key.Ok);

      //Select title
      await testUtils.waitForElementToFullyShowOnScreen('channelsVideoGridPoster');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Once in detail page press the back button 6x
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
      await ecp.sendKeypress(ecp.Key.Back, { count: 6 });

      // Verify that the Exit modal dialog is displayed
      await testUtils.waitForElementToFullyShowOnScreen('exitPrompt');

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
  });


async function openLeftNav() {
  // Press left
  await ecp.sendKeypress(ecp.Key.Left);

  // Is the left Nav open?
  await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButtonLabel');
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
