import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';
import { downloadTranslations } from '../../translate';
import { ok } from 'assert';
import PlayBack from '../analytics/pages/playback';


describe('Categories', function () {
    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48644
    it('C48644 - Continue Watching Row - when user plays a title and navigates back to Home screen then Continue Watching row should be displayed, @categories', async () => {
      // Launch as registered user

      // Create user with history only
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      // Start app with Registered user
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus(
        'homeScreenRowList',
        'Timed out waiting for Rowlist to have focus'
      );

      // Navigate to find Continue Watching category
      await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await testUtils.waitForElementToFullyShowOnScreen(
        'continueWatchingRowHome'
      );
      
    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48646
    it('C48646 - Continue Watching - Category removed after choosing Remove From history in the details page, @categories', async () => {
      // Create user with history only
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      // Start app with Registered user
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus(
        'homeScreenRowList',
        'Timed out waiting for Rowlist to have focus'
      );

      // Go to All Categories page
      await openLeftNav();
      await selectCategories();

      // Navigate to Continue Watching category
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Press OK to reach Details of title
      await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRowHomeTitle');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Remove from History
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

      // Go to All Categories page
      await openLeftNav();
      await selectCategories();

      // Verify Continue Watching category does not exist
      await testUtils.waitForElementToNotShowOnScreen('categoriesContinueWatchingTile');

    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48647
    it('C48647 - Continue Watching - When user removes title from history and navigates back to Home screen then Continue Watching row should be removed, @categories', async () => {
      // Launch as registered user

      // Create user with history only
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      // Start app with Registered user
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus(
        'homeScreenRowList',
        'Timed out waiting for Rowlist to have focus'
      );

      // Jump to CW row
      await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');

      await testUtils.waitForElementToFullyShowOnScreen(
        'continueWatchingRowHome'
      );

      // Press Ok to reach Details page for title in CW Row
      await ecp.sendKeypress(ecp.Key.Ok);

      // Remove from History
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

      // Back to Home
      await ecp.sendKeypress(ecp.Key.Back);
      await ecp.sendKeypress(ecp.Key.Ok);
      
      // Homescreen page should not display Continue Watching Row
      await testUtils.waitForElementToNotShowOnScreen('continueWatchingRowHome');
    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/524602
    it('C524602 - User sees 6 titles per row on full screen categories page (kids mode), @categories', async () => {
      await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
  
      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();
      await ecp.sendKeypress(ecp.Key.Down);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on the Video Grid? 
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsVideoGridPoster');

      // If so, navigate horizontally to last poster + 1
      await verifySixColumns();
    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/539354
    it('C539354 - User sees 6 titles per row on full screen channels page, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
  
      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      // Navigate to the video grid in a channel
      await ecp.sendKeypress(ecp.Key.Right);
      const categoryGridTitle = await testUtils.getNodeForElement('categoryGridTitle');
      expect(categoryGridTitle.text).to.equal('Networks');
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForElementToFullyShowOnScreen('networksPageGridPoster');
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForElementToFullyShowOnScreen('titleDescriptionInChannelGrid');
      await testUtils.waitForElementToFullyShowOnScreen('channelsListScreenPoster');

      // Verify 6 rows only, navigate horizontally to last poster + 1
      await verifySixColumns();

    });

    
    async function openLeftNav() {
      
      // Press left
      await ecp.sendKeypress(ecp.Key.Left);
    
      // Is the left Nav open?
      await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');
    }

    async function selectCategories() {
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
      await utils.sleep(1000);
      await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButtonSelected');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Categories page?
      await testUtils.waitForElementToFullyShowOnScreen('categoryPageCategory'); 
    }

    async function verifySixColumns() {

       // Verify 6 rows only, navigate horizontally to last poster + 1
       await utils.sleep(1000);
       await ecp.sendKeypress(ecp.Key.Right, {count:6});
       await utils.sleep(1000);

       // Are we still on the 6th title after navigating right more than 5 times?
      const channelsVideoGrid = await testUtils.getNodeForElement('channelsVideoGrid');
      expect(channelsVideoGrid.currFocusColumn).to.equal(5); 
      
    }

    
});

async function createHistory(user) {

        // Create a user with mix of little kids and non-little kid rated titles with history
 
        const ContentG = await user.getContent().withRating('G').ofContentType('movie').retrieve({ limit: 1});
        await user.addContentToViewHistory(ContentG, 600);
        // const ContentTVY7 = await user.getContent().withRating('TV-Y7').ofContentType('series').retrieve({ limit: 3});
        // await user.addContentToViewHistory(ContentTVY7, 600);
        // const movieContentTVMA = await user.getContent().withRating('TV-MA').ofContentType('series').retrieve({ limit: 3});
        // await user.addContentToViewHistory(movieContentTVMA, 600);
        // const movieContentR = await user.getContent().withRating('R').ofContentType('movies').retrieve({ limit: 2});
        // await user.addContentToViewHistory(movieContentR, 500);
        // const movieContentPG = await user.getContent().withRating('PG').ofContentType('movies').retrieve({ limit: 2});
        // await user.addContentToViewHistory(movieContentPG, 500);

}