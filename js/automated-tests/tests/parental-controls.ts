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

    // https://tubi.testrail.io/index.php?/cases/view/5503
    it('C5503 - Parental Settings - Little Kids - Deeplink Playback, @parental_controls', async () => {
        await testUtils.goToPage('settings');
        await selectLittleKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
        expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Ok);

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

    // https://tubi.testrail.io/index.php?/cases/view/5504
    it('C5504 - Parental Settings - Teens - Deeplink Playback, @parental_controls', async () => {

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
            await ecp.sendKeyPress(ecp.Key.Ok);
          });


        // Back to home
        await ecp.sendKeyPress(ecp.Key.Ok);

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



    // https://tubi.testrail.io/index.php?/cases/view/5505
    it('C5505 - Parental Settings - Older Kids - Deeplink Playback, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectOlderKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
        expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Ok);

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

    //https://tubi.testrail.io/index.php?/cases/view/5603
    it('C5603 - Categories Page - When setting is changed from Adult to Little Kids then the categories only for Little Kids are listed, @parental_controls', async () => {
        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectLittleKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
        expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeyPress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeyPress(ecp.Key.Down, {count:2});
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Little Kids content?
        const horsesAndPoniesTile = testUtils.getNodeForElement('horsesAndPoniesTile');
        expect((await horsesAndPoniesTile).visible).to.be.true;
    });

        //https://tubi.testrail.io/index.php?/cases/view/5604
    it('C5604 - Categories Page - When settings is changed from Adult to Older Kids then categories for Older kids are listed, @parental_controls', async () => {

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
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeyPress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeyPress(ecp.Key.Down, {count:2});
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Older Kids content?
        const kidFriendlyClassics = testUtils.getNodeForElement('kidFriendlyClassics');
        expect((await kidFriendlyClassics).visible).to.be.true;
    });

    //https://tubi.testrail.io/index.php?/cases/view/5605
    it('C5605 - Categories Page - When settings is changed from Adult to Teens then categories for Teens are listed, @parental_controls', async () => {

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
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeyPress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeyPress(ecp.Key.Down, {count:2});
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Teens content?
        const artHouseFilms = testUtils.getNodeForElement('artHouseFilms');
        expect((await artHouseFilms).visible).to.be.true;
    });


    //https://tubi.testrail.io/index.php?/cases/view/6596
    it('C6596 - Parental Controls - Little Kids - When user switches Parental Control to Little Kids then a modal is presented/Exit Kids is grayed out, @parental_controls', async () => {

        await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('settings');
        await selectLittleKidsFromParentalSettings();
        await enterPasswordSettingsChange();

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
        expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeyPress(ecp.Key.Left);


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

        // Verify Little Kids PC Settings Change dialog
        const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
        expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Back to home
        await ecp.sendKeyPress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Open left nav
        await ecp.sendKeyPress(ecp.Key.Left);


        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Is Exit Kids menu option Grayed out?
        const exitKidsGrayedOut = testUtils.getNodeForElement('exitKidsGrayedOut');
        expect((await exitKidsGrayedOut).visible).to.be.true;
    });

    //https://tubi.testrail.io/index.php?/cases/view/6598
    it('C6598 - Parental Controls - Teens -  When user switches Parental Control to Teens then a modal is presented/Exit Kids is not present, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectTeensFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Teens PC Settings Change dialog
      const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
      expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Back to home
      await ecp.sendKeyPress(ecp.Key.Back);
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left nav
      await ecp.sendKeyPress(ecp.Key.Left);


      // Is the left Nav open?
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      await testUtils.elementHasFocus('leftNavHomeButton');

      // Is Kids menu option present?
      const kidsLeftNavOption = testUtils.getNodeForElement('kidsLeftNavOption');
      expect((await kidsLeftNavOption).visible).to.be.true;
  });

    //https://tubi.testrail.io/index.php?/cases/view/6599
    it('C6599 - Parental Controls - Adults - When user switches Parental Control to Adults then a modal is presented/Exit Kids is not present, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectAdultsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Back to home
      await ecp.sendKeyPress(ecp.Key.Back, {count:4});

      // Is the left Nav open?
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      await testUtils.elementHasFocus('leftNavHomeButton');

      await ecp.sendKeyPress(ecp.Key.Ok);


      // Open left nav
      await ecp.sendKeyPress(ecp.Key.Left);


      // Is the left Nav open?
      await testUtils.elementHasFocus('leftNavHomeButton');

      // Is Kids menu option present?
      const kidsLeftNavOption = testUtils.getNodeForElement('kidsLeftNavOption');
      expect((await kidsLeftNavOption).visible).to.be.true;
});

    //https://tubi.testrail.io/index.php?/cases/view/6666
    it('C6666 - Parental Control - Change Before 5 minutes, @parental_controls', async () => {

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
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Select another PC Setting
      const parentalControlsMenuTextFocused = testUtils.getNodeForElement('parentalControlsMenuTextFocused');
      await parentalControlsMenuTextFocused;
      await ecp.sendKeyPress(ecp.Key.Right);
      await ecp.sendKeyPress(ecp.Key.Up);
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Expect dialog instead of Password Screen (Verify that no password is needed to be entered to change parental controls)
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.contain('Parental controls setting has changed');


    });

    //https://tubi.testrail.io/index.php?/cases/view/21246
    it('C21246- Search - Adult to Older Kids - When titles above Older Kids is searched then no results should be displayed, @parental_controls', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForAppLaunchBeaconToFire();
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.goToPage('settings');
      await selectOlderKidsFromParentalSettings();
      await enterPasswordSettingsChange();

      // Verify Little Kids PC Settings Change dialog
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Back to home
      await ecp.sendKeyPress(ecp.Key.Back);
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Open left nav
      await ecp.sendKeyPress(ecp.Key.Left);


      // Is the left Nav open?
      const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
      await testUtils.elementHasFocus('leftNavHomeButton');

      // Select Search
      await ecp.sendKeyPress(ecp.Key.Up);
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Send adult title text
      const searchGrid = testUtils.getNodeForElement('searchGrid');
      expect((await searchGrid).visible).to.be.true;
      await ecp.sendText('gone before her time');
      await utils.sleep(2000); // Improve

      const noResultsMessage = testUtils.getNodeForElement('noResultsMessage');
      expect((await noResultsMessage).visible).to.be.true;

  });




});


    async function selectOlderKidsFromParentalSettings() {
        await ecp.sendKeyPress(ecp.Key.Right);
        await ecp.sendKeyPress(ecp.Key.Up, {count:2});
        await ecp.sendKeyPress(ecp.Key.Ok);
      }

      async function selectLittleKidsFromParentalSettings() {
        await ecp.sendKeyPress(ecp.Key.Right);
        await ecp.sendKeyPress(ecp.Key.Up, {count:3});
        await ecp.sendKeyPress(ecp.Key.Ok);
      }

      async function selectTeensFromParentalSettings() {
        await ecp.sendKeyPress(ecp.Key.Right);
        await ecp.sendKeyPress(ecp.Key.Up, {count:1});
        await ecp.sendKeyPress(ecp.Key.Ok);
      }

      async function selectAdultsFromParentalSettings() {
        await ecp.sendKeyPress(ecp.Key.Right);
        await ecp.sendKeyPress(ecp.Key.Ok);
      }
      async function enterPasswordSettingsChange() {
        // Enter Password for PC Settings Change
        await ecp.sendKeyPress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await ecp.sendKeyPress(ecp.Key.Down, {count:4});
        await utils.sleep(4000);
        await ecp.sendKeyPress(ecp.Key.Right);
        await ecp.sendKeyPress(ecp.Key.Left);
        await ecp.sendKeyPress(ecp.Key.Ok);
    }

    // Navigate right until the grid is in focus
    async function navigateRightToGrid() {
      await testUtils.untilTrue(async () => {
        await ecp.sendKeyPress(ecp.Key.Right);
        const {value: id} = await odc.getValue({
          base: 'focusedNode',
          keyPath: 'id'
        });
        return id === 'ResultGrid';
      }, 'ResultGrid never obtained focus');
    }
