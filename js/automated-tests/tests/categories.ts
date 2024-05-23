import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';



describe('Categories', function () {
    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/524601
    it('C524601 - User sees 6 titles per row on full screen categories page, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
  
      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on the Video Grid? 
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsVideoGridPoster');

      // If so, navigate horizontally to last poster + 1
      await verifySixColumns();
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