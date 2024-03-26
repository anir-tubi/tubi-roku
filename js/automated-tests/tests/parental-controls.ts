import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import exp = require('constants');


describe('Parental Controls', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');


    });

    // https://tubi.testrail.io/index.php?/cases/view/537376
    it('C537376 - Parental Settings - Little Kids - Deeplink Playback, @parental_controls', async () => {
        await testUtils.goToPage('settings');
        await selectLittleKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
        expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Ok);

        // Send deep link for Adult title
        await testUtils.restartApplication({
            params: {
              'mediaType': 'movie',
              contentID: '679437'
            }
          });

        // Verify that the user can't view the title
        const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
        expect((await invalidDeepLinkDialog).visible).to.be.true;

    });

    // https://tubi.testrail.io/index.php?/cases/view/537375
    it('C537375 - Parental Settings - Teens - Deeplink Playback, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectTeensFromParentalSettings();
        await utils.sleep(2000);
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        await utils.sleep(3000);
        await testUtils.retryWithTimeOut(async () => {
            const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
            expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
            await ecp.sendKeypress(ecp.Key.Ok);
          });


        // Back to home
        await ecp.sendKeypress(ecp.Key.Ok);

        // Send deep link for Adult title
        await testUtils.restartApplication({
            params: {
              'mediaType': 'movie',
              contentID: '580334'
            }
          });

        // Verify that the user can't view the title
        const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
        expect((await invalidDeepLinkDialog).visible).to.be.true;

    });



    // https://tubi.testrail.io/index.php?/cases/view/537405
    it('C537405 - Parental Settings - Older Kids - Deeplink Playback, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectOlderKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Older Kids PC Settings Change dialog
        const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
        expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Ok);

        // Send deep link for Adult title
        await testUtils.restartApplication({
            params: {
              'mediaType': 'movie',
              contentID: '580334'
            }
          });

        // Verify that the user can't view the title
        const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
        expect((await invalidDeepLinkDialog).visible).to.be.true;


    });

    // https://tubi.testrail.io/index.php?/cases/view/535834
    it('C535834 - Categories Page - When setting is changed from Adult to Little Kids then the categories only for Little Kids are listed, @parental_controls', async () => {
        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectLittleKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
        expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeypress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeypress(ecp.Key.Down, {count:2});
        await utils.sleep(2000); // Improvement
        await ecp.sendKeypress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Little Kids content?
        const horsesAndPoniesTile = testUtils.getNodeForElement('horsesAndPoniesTile');
        expect((await horsesAndPoniesTile).visible).to.be.true;
    });

        //https://tubi.testrail.io/index.php?/cases/view/535835
    it('C535835- Categories Page - When settings is changed from Adult to Older Kids then categories for Older kids are listed, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectOlderKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Older Kids PC Settings Change dialog
        const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
        expect(parentalControlsSettingsOlderKids.visible).to.be.true;
        expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeypress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeypress(ecp.Key.Down, {count:2});
        await utils.sleep(2000); // Improvement
        await ecp.sendKeypress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Older Kids content?
        const kidFriendlyClassics = testUtils.getNodeForElement('kidFriendlyClassics');
        expect((await kidFriendlyClassics).visible).to.be.true;
    });

    // https://tubi.testrail.io/index.php?/cases/view/535836
    it('C535836 - Categories Page - When settings is changed from Adult to Teens then categories for Teens are listed, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectTeensFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Teens PC Settings Change dialog
        const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
        expect(parentalControlsSettingsTeens.visible).to.be.true;
        expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeypress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeypress(ecp.Key.Down, {count:2});
        await utils.sleep(2000); // Improvement
        await ecp.sendKeypress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Teens content?
        const artHouseFilms = testUtils.getNodeForElement('artHouseFilms');
        expect((await artHouseFilms).visible).to.be.true;
    });


    // https://tubi.testrail.io/index.php?/cases/view/535864
    it('C535864 - Parental Controls - Little Kids - When user switches Parental Control to Little Kids then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectLittleKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
        expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeypress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Is Exit Kids menu option Grayed out?
        const exitKidsGrayedOut = testUtils.getNodeForElement('exitKidsGrayedOut');
        expect((await exitKidsGrayedOut).visible).to.be.true;
    });

    //https://tubi.testrail.io/index.php?/cases/view/6597
     it('C6596 - Parental Controls - Little Kids - When user switches Parental Control to Older Kids then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectOlderKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Older Kids PC Settings Change dialog
        const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
        expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeypress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Is Exit Kids menu option Grayed out?
        const exitKidsGrayedOut = testUtils.getNodeForElement('exitKidsGrayedOut');
        expect((await exitKidsGrayedOut).visible).to.be.true;
    });

    // https://tubi.testrail.io/index.php?/cases/view/535866
    it('C535866 - Parental Controls - Teens -  When user switches Parental Control to Teens then a modal is presented/Exit Kids is not present, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectTeensFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Teens PC Settings Change dialog
      const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
      expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Back to home
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left nav
      await ecp.sendKeypress(ecp.Key.Left);


      // Is the left Nav open?
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      await testUtils.elementHasFocus('leftNavHomeButton');

      // Is Kids menu option present?
      const kidsLeftNavOption = testUtils.getNodeForElement('kidsLeftNavOption');
      expect((await kidsLeftNavOption).visible).to.be.true;
  });

    // https://tubi.testrail.io/index.php?/cases/view/535867
    it('C535867 - Parental Controls - Adults - When user switches Parental Control to Adults then a modal is presented/Exit Kids is not present, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectAdultsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Back to home
      await ecp.sendKeypress(ecp.Key.Back, {count:4});

      // Is the left Nav open?
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      await testUtils.elementHasFocus('leftNavHomeButton');

      await ecp.sendKeypress(ecp.Key.Ok);


      // Open left nav
      await ecp.sendKeypress(ecp.Key.Left);


      // Is the left Nav open?
      await testUtils.elementHasFocus('leftNavHomeButton');

      // Is Kids menu option present?
      const kidsLeftNavOption = testUtils.getNodeForElement('kidsLeftNavOption');
      expect((await kidsLeftNavOption).visible).to.be.true;
});

    // https://tubi.testrail.io/index.php?/cases/view/535868
    it('C535868 - Parental Control - Change Before 5 minutes, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectTeensFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Teens PC Settings Change dialog
      const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
      expect(parentalControlsSettingsTeens.visible).to.be.true;
      expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Select another PC Setting
      const parentalControlsMenuTextFocused = testUtils.getNodeForElement('parentalControlsMenuTextFocused');
      await parentalControlsMenuTextFocused;
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Up);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Expect dialog instead of Password Screen (Verify that no password is needed to be entered to change parental controls)
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.contain('Parental controls setting has changed');


    });

    // https://tubi.testrail.io/index.php?/cases/view/537901
    it('C537901 - Search - Adult to Older Kids - When titles above Older Kids is searched then no results should be displayed, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectOlderKidsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Older Kids PC Settings Change dialog
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Back to home
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left nav
      await ecp.sendKeypress(ecp.Key.Left);


      // Is the left Nav open?
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      await testUtils.elementHasFocus('leftNavHomeButton');


      // Select Search
      await ecp.sendKeypress(ecp.Key.Up);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Send adult title text
      const searchGrid = testUtils.getNodeForElement('searchGrid');
      expect((await searchGrid).visible).to.be.true;
      await ecp.sendText('gone before her time');
      await utils.sleep(2000); // Improve

      const noResultsMessage = testUtils.getNodeForElement('noResultsMessage');
      expect((await noResultsMessage).text).to.include('Please try again');

  });

  // https://tubi.testrail.io/index.php?/cases/view/535826
  it('C535826 - Continue Watching - When setting is changed to Little Kids then Continue Watching row has no content above TV-G or G @parental_controls', async () => {

      // Create a user with mix of little kids and non-little kid rated titles with history
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      // Start app, wait for home screen to load
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Set Parental Controls to Little Kids
      await testUtils.goToPage('settings');

      // On Settings Page?
      const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
      expect(parentalControlsHeader.text).to.equal('Parental Controls');

      // Set PC
      await selectLittleKidsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Little Kids PC Settings Change dialog
      const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
      expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Back to home
      await testUtils.goToPage('home');
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Jump to CW row
      await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');


    // To Do : revisit once back end issue is addressed.
      const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');

    // Add this for loop for all checks on Ratings.
    //
      for (const itemContent of rowItemsContent) {
        expect(['PG','R','NR','PG-13', 'TV-14', 'TV-MA', 'MA'].includes(itemContent.type)).to.be.false;
      }
  });

  // https://tubi.testrail.io/index.php?/cases/view/535827
  it('C535827 - Continue Watching - When setting is changed to Adults then Continue Watching row should show all rated contents @parental_controls', async () => {

      // Create a user with mix of little kids and non-little kid rated titles with history
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      // Launch to home page, await home page
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Set Parental Controls to Little Kids
      await testUtils.goToPage('settings');

      // On Settings Page?
      const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
      expect(parentalControlsHeader.text).to.equal('Parental Controls');

      // Set, Check PC for Adults (default)
      await selectAdultsFromParentalSettings();

      // Back to home
      await ecp.sendKeypress(ecp.Key.Back, {count:2});
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Jump to CW row
      await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');
      const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');

     // Check Ratings label  - Improvement use array to check.

     for (const itemContent of rowItemsContent) {
       const rating = itemContent.ratings[0].value;
       expect((rating).includes('R') || (rating).includes('PG') || (rating).includes('PG-13') || (rating).includes('TV-G')|| (rating).includes('TV-MA'));

     }

  });

  // https://tubi.testrail.io/index.php?/cases/view/535762
  it('C535762 - Continue Watching - When setting is changed to Older Kids then Continue Watching row has no content above  PG, TV-PG, TV-Y7 @parental_controls', async () => {

      // Create a user with mix of Older and non-little kid rated titles with history
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Set Parental Controls to Older Kids
      await testUtils.goToPage('settings');

      // On Settings Page?
      const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
      expect(parentalControlsHeader.text).to.equal('Parental Controls');

      // Set PC
      await selectOlderKidsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Older Kids PC Settings Change dialog
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Back to home
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Jump to CW row
      await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');

      // Check ratings
      expect('homeScreenRatingsLabel').does.not.contain(['R','MA','TV-MA', 'PG-13']);


      const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
      for (const itemContent of rowItemsContent) {
        expect(['R','MA','TV-MA', 'PG-13'].includes(itemContent.type)).to.be.false;
      }
  });


  // https://tubi.testrail.io/index.php?/cases/view/535764
  it('C535764 - My List- When setting is changed to Little Kids then My List row has no content above TV-G or G @parental_controls', async () => {

      // Create a user with mix of little kids and non-little kid rated titles with history
      const user = await testUtils.createRegisteredUser();
      await createWatchList(user);


      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Set Parental Controls to Little Kids
      await testUtils.goToPage('settings');

      // On Settings Page?
      const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
      expect(parentalControlsHeader.text).to.equal('Parental Controls');

      // Set PC
      await selectLittleKidsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Little Kids PC Settings Change dialog
      const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
      expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Back to home
      await testUtils.goToPage('home');
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Jump to My List row
      await testUtils.jumpToRowWithTitle('homeScreenRowList', 'My List');


    // Check ratings
      expect('homeScreenRatingsLabel').does.not.contain(['R','PG', 'PG-13', 'MA','TV-MA']);


      const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
      for (const itemContent of rowItemsContent) {
        expect(['R','PG', 'PG-13', 'MA','TV-MA'].includes(itemContent.type)).to.be.false;
      }


  });

  // https://tubi.testrail.io/index.php?/cases/view/535765
  it('C535765 - My List - When setting is changed to Older Kids then My List row has no content above PG, TV-PG, TV-Y7 @parental_controls', async () => {

    // Create a user with mix of Older and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    // Launch app

    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Older Kids
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectOlderKidsFromParentalSettings();
    await enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to CW row
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'My List');

    // Check ratings

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R','MA','TV-MA', 'PG-13'].includes(itemContent.type)).to.be.false;
    }


});

  // https://tubi.testrail.io/index.php?/cases/view/535766
  it('C535766 - My List - When setting is changed to Teens then My List row has no content above PG-13, TV-14 @parental_controls', async () => {

    // Create a user with mix of Older and non-little kid rated titles with history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);


    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Teens
    await testUtils.goToPage('settings');

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Parental Controls');

    // Set PC
    await selectTeensFromParentalSettings();
    await enterPasswordSettingsChange();

    // Verify Teens PC Settings Change dialog
    const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
    expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump to CW row
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'My List');

    // Check ratings
    expect('homeScreenRatingsLabel').does.not.contain(['R','MA','TV-MA', 'NR']);

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    for (const itemContent of rowItemsContent) {
      expect(['R','MA','TV-MA', 'NR'].includes(itemContent.type)).to.be.false;

    }



  });

});
    async function createHistory(user) {

       // Create a user with mix of little kids and non-little kid rated titles with history

       const ContentG = await user.getContent().withRating('G').ofContentType('movie').retrieve({ limit: 10});
       await user.addContentToViewHistory(ContentG, 600);
       const ContentTVY7 = await user.getContent().withRating('TV-Y7').ofContentType('series').retrieve({ limit: 3});
       await user.addContentToViewHistory(ContentTVY7, 600);
       const movieContentTVMA = await user.getContent().withRating('TV-MA').ofContentType('series').retrieve({ limit: 3});
       await user.addContentToViewHistory(movieContentTVMA, 600);
       const movieContentR = await user.getContent().withRating('R').ofContentType('movies').retrieve({ limit: 2});
       await user.addContentToViewHistory(movieContentR, 500);
       const movieContentPG = await user.getContent().withRating('PG').ofContentType('movies').retrieve({ limit: 2});
       await user.addContentToViewHistory(movieContentPG, 500);
       const movieContentPG13 = await user.getContent().withRating('PG-13').ofContentType('movies').retrieve({ limit: 2});
       await user.addContentToViewHistory(movieContentPG13, 500);
       const movieContentTV14 = await user.getContent().withRating('TV-14').ofContentType('series').retrieve({ limit: 2});
       await user.addContentToViewHistory(movieContentTV14, 500);
       const movieContentNR = await user.getContent().withRating('NR').ofContentType('movies').retrieve({ limit: 2});
       await user.addContentToViewHistory(movieContentNR, 500);

    }

    async function createWatchList(user) {

      // Create a user with mix of little kids and non-little kid rated titles with history

      const ContentTVG = await user.getContent().ofContentType(['series']).withRating('TV-G').retrieve({ limit: 6});
      await user.addContentToWatchList(ContentTVG);
      const ContentG = await user.getContent().ofContentType(['movie']).withRating('G').retrieve({ limit: 6});
      await user.addContentToWatchList(ContentG);
      const movieContentTVY7 = await user.getContent().ofContentType(['series']).withRating('TV-Y7').retrieve({ limit: 3});
      await user.addContentToWatchList(movieContentTVY7);
      const movieContentTVMA = await user.getContent().ofContentType(['series']).withRating('TV-MA').retrieve({ limit: 3});
      await user.addContentToWatchList(movieContentTVMA);
      const movieContentR = await user.getContent().ofContentType(['series', 'movie']).withRating('R').retrieve({ limit: 2});
      await user.addContentToWatchList(movieContentR);
      const movieContentPG = await user.getContent().ofContentType(['series', 'movie']).withRating('PG').retrieve({ limit: 2});
      await user.addContentToWatchList(movieContentPG);
      const movieContentPG13 = await user.getContent().ofContentType(['series', 'movie']).withRating('PG-13').retrieve({ limit: 2});
      await user.addContentToWatchList(movieContentPG13);
      const movieContentTV14 = await user.getContent().ofContentType(['series']).withRating('TV-14').retrieve({ limit: 2});
      await user.addContentToWatchList(movieContentTV14);
      const movieContentNR = await user.getContent().ofContentType(['movie']).withRating('NR').retrieve({ limit: 2});
      await user.addContentToWatchList(movieContentNR);

   }


    async function selectOlderKidsFromParentalSettings() {
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Up, {count:2});
        await ecp.sendKeypress(ecp.Key.Ok);
      }

      async function selectLittleKidsFromParentalSettings() {
        await ecp.sendKeypress(ecp.Key.Right);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Up, {count:3});
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);
      }

      async function selectTeensFromParentalSettings() {
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Up, {count:1});
        await ecp.sendKeypress(ecp.Key.Ok);
      }

      async function selectAdultsFromParentalSettings() {
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Ok);
      }
      async function enterPasswordSettingsChange() {
        // Enter Password for PC Settings Change
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await ecp.sendKeypress(ecp.Key.Down, {count:4});
        await utils.sleep(4000);
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Left);
        await ecp.sendKeypress(ecp.Key.Ok);
        await utils.sleep(800);
    }

    // Navigate right until the grid is in focus
    async function navigateRightToGrid() {
      await testUtils.untilTrue(async () => {
        await ecp.sendKeypress(ecp.Key.Right);
        const {value: id} = await odc.getValue({
          base: 'focusedNode',
          keyPath: 'id'
        });
        return id === 'ResultGrid';
      }, 'ResultGrid never obtained focus');
    }
