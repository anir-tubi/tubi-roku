import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Large Posters', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/4146
  it('C498789 -  On homegrid, user sees 3 images and a peek of the 4th in Featured row (For You tab), @large_poster', async () => {
    
    // On Home Page, see featured row, Check for large posters?
    
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    const featuredRowPoster = await testUtils.getNodeForElement('featuredRowPoster');
    expect(featuredRowPoster.width).to.equal(504);
   
    // Need helper here to verify peak https://app.shortcut.com/tubi/story/582832/need-a-helper-function-for-finding-the-poster-peak-on-multiple-screens
    });

  });