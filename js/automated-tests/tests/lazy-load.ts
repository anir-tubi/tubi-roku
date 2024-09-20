import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('LazyLoad', function () {
    

    // https://tubi.testrail.io/index.php?/cases/view/432577
   it('C432577 - Lazy load does not occur when less than 200 titles, @lazyload', async () => {

       // Start app with Guest user
       await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
       await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      
       // Open side nav and navigate to Categories
      await openLeftNav();

      // Select Categories
      await selectCategories();
      
      // Navigate to a category with < 200 titles and validate < 200
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
      await ecp.sendKeypress(ecp.Key.Down, {count:3, wait:4000});
      await ecp.sendKeypress(ecp.Key.Right);
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

      // Navigate down 20 rows
      await ecp.sendKeypress(ecp.Key.Down, {count:30});
      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      const itemCounterValue = await testUtils.getNodeForElement('itemCounter');
      expect(itemCounterValue.text).is.not.equal(' · 400');

    });


  // https://tubi.testrail.io/index.php?/cases/view/432577 and https://tubi.testrail.io/index.php?/cases/view/431533
    it('C431532 User can access more than 200 titles in Categories full screen view., @lazyload', async () => {

      // Start app with Guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    
        // Open side nav and navigate to Categories
      await openLeftNav();

      // Select Categories
      await selectCategories();
      

      // Navigate to a category with < 200 titles and validate < 200
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
      await ecp.sendKeypress(ecp.Key.Down, {count:2, wait:4000});
      await ecp.sendKeypress(ecp.Key.Right);
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

      // Navigate down 
      await ecp.sendKeypress(ecp.Key.Down, {count:26});
      await utils.sleep(4000); // itemCounter update isn't recognized without sleep

      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      const itemCounter = await testUtils.getNodeForElement('itemCounter');
      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      expect(itemCounter.text).contains('400+');

    });


  // https://tubi.testrail.io/index.php?/cases/view/431534
    it('C431534 1000 max titles can be loaded, @lazyload', async () => {

      // Start app with Guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
        
      // Open side nav and navigate to Categories
        
      await openLeftNav();

      // Select Categories
      await selectCategories();
        
      // Navigate to a category with 1000
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
      await ecp.sendKeypress(ecp.Key.Down, {count:2, wait:4000});
      await testUtils.waitForElementToFullyShowOnScreen('actionButtonFocused');
      await ecp.sendKeypress(ecp.Key.Right);
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

      // Navigate down to where counter shows 600+
      await ecp.sendKeypress(ecp.Key.Down, {count:30});
      await utils.sleep(2000); // itemCounter update isn't recognized without sleep
      await ecp.sendKeypress(ecp.Key.Down, {count:51});
      await utils.sleep(2000); // itemCounter update isn't recognized without sleep
      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      const itemCounter = await testUtils.getNodeForElement('itemCounter');
      expect(itemCounter.text).contains('600+');

      // Navigate down to where counter shows 800+
      await ecp.sendKeypress(ecp.Key.Down, {count:47});
      await utils.sleep(4000); // itemCounter update isn't recognized without sleep
      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      const itemCounter800 = await testUtils.getNodeForElement('itemCounter');
      expect(itemCounter800.text).contains('800+');

      // Navigate down to 1000 titles
      await ecp.sendKeypress(ecp.Key.Down, {count:50});
      await utils.sleep(4000); // itemCounter update isn't recognized without sleep
      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      const itemCounter1000 = await testUtils.getNodeForElement('itemCounter');
      expect(itemCounter1000.text).contains('1000');
        
      // Navigate down to last row
      await ecp.sendKeypress(ecp.Key.Down, {count:82});
      await utils.sleep(4000); // itemCounter update isn't recognized without sleep
      await testUtils.waitForElementToFullyShowOnScreen('itemCounter');
      const itemCounterLast = await testUtils.getNodeForElement('itemCounter');
      expect(itemCounterLast.text).contains('1000');

    });
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
        await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton'); 
      }
   