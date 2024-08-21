import { expect } from 'chai';
import { ecp } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { Key } from 'roku-test-automation/client/dist/ECP';

describe('Large Posters', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/4146 - Placeholder
  /*
  it('C498789 -  On homegrid, user sees 3 images and a peek of the 4th in Featured row (For You tab), @large_poster', async () => {
    
    // On Home Page, see featured row, Check for large posters?
    
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    const featuredRowPoster = await testUtils.getNodeForElement('featuredRowPoster');
    expect(featuredRowPoster.width).to.equal(520);
   
    // Need helper here to verify peak https://app.shortcut.com/tubi/story/582832/need-a-helper-function-for-finding-the-poster-peak-on-multiple-screens
    });
*/

   // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/524601
    it('C524601 - User sees 6 titles per row on full screen categories page, @large_poster', async () => {

      await testUtils.startApplicationAtPage('genre', { shouldCreateNewUser: false });
      
      // Open Recommended category
      await testUtils.waitForElementToFullyShowOnScreen('categoryGridTitle', 'Category List Page not present', 10000);
      await ecp.sendKeypress(ecp.Key.Ok)

      await testUtils.waitForElementToFullyShowOnScreen('categoryDetailsScreenTitleCount')
      let categoryDetailsScreenFocusIndex = await testUtils.getNodeForElement('categoryDetailsScreenFocusIndex');
      expect(categoryDetailsScreenFocusIndex.text).to.equal("1");

      await verify6TitlesInOneRow();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/524602
  it('C524602 - User sees 6 titles per row on full screen categories page (kids mode)User sees 6 titles per row on full screen categories page (kids mode), @large_poster', async () => {

    await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: false });
    
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.selectMenuItem('sideNavMenu', 'Categories');
    await ecp.sendKeypress(ecp.Key.Ok);
    
    //Open a category
    await testUtils.waitForElementToFullyShowOnScreen('categoryGridTitle', 'Category List Page not present', 10000);
    await ecp.sendKeypress(ecp.Key.Right)
    await ecp.sendKeypress(ecp.Key.Ok)

    await testUtils.waitForElementToFullyShowOnScreen('categoryDetailsScreenTitleCount')
    let categoryDetailsScreenFocusIndex = await testUtils.getNodeForElement('categoryDetailsScreenFocusIndex');
    expect(categoryDetailsScreenFocusIndex.text).to.equal("1");

    await verify6TitlesInOneRow();
});

})

async function verify6TitlesInOneRow() {

  await ecp.sendKeypress(Key.Right, {wait: 1000, count: 6})
  await testUtils.waitForElementFieldToEqual('categoryDetailsScreenFocusIndex', 'text', '6', 3000)
  
  await ecp.sendKeypress(Key.Right, {wait: 1000, count: 3})
  await testUtils.waitForElementFieldToEqual('categoryDetailsScreenFocusIndex', 'text', '6', 3000)
  
  await ecp.sendKeypress(Key.Down);
  await testUtils.waitForElementFieldToEqual('categoryDetailsScreenFocusIndex', 'text', '12', 3000)
}
