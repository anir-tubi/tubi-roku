import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('User Reactions', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });
  
    // https://tubi.testrail.io/index.php?/cases/view/307689
    it('C307689 - Registered User - Navigate to Like or Dislike button from Details page, @reactions', async () => {
        
        // Select a Movie Title after landing on Movies page
        await testUtils.goToPage('movies');
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
        await ecp.sendKeypress(ecp.Key.Ok);

        // From Details page, navigate to highlight Like or Dislike button
        await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
        await testUtils.selectAndVerifyDetailPageMenuItem('likeOrDislike');

        // There should be a secondary menu with two buttons: thumbs up/like and thumbs down/dislike.
        // Verify the Like Button
        await testUtils.waitForElementToFullyShowOnScreen('secondaryMenuButtonLike');
        await ecp.sendKeypress(ecp.Key.Down);

        // Verify the Dislike Button
        await testUtils.waitForElementToFullyShowOnScreen('secondaryMenuButtonDislike');
  
      });

      // https://tubi.testrail.io/index.php?/cases/view/307690
    it('C307690a - Registered User - Click OK button after selecting Like button from Details page, @reactions', async () => {
        
      // Select a Movie Title after landing on Movies page
      await testUtils.goToPage('movies');
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      await selectLike();

    });
     // https://tubi.testrail.io/index.php?/cases/view/307690 and https://tubi.testrail.io/index.php?/cases/view/307693
     it('C307690b - Registered User - Click OK button after selecting Dislike button from Details page, @reactions', async () => {
        
      // Select a Movie Title after landing on Movies page
      await testUtils.goToPage('movies');
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      await selectDislike();

      // Verify that the title is now Disliked
      await testUtils.waitForElementToFullyShowOnScreen('reactionButtonDisliked');

    });

    // https://tubi.testrail.io/index.php?/cases/view/307696
    it('C307696 - Registered User - Change rating from Like to Neutral, @reactions', async () => {

      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
        
      // Select a Movie Title after landing on Movies page
      await testUtils.goToPage('movies');
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      await selectLike();
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Neutral state
      await testUtils.waitForElementToFullyShowOnScreen('likeOrDislikeButton', 'Button not found', 15000);
    });

    // https://tubi.testrail.io/index.php?/cases/view/307697
    it('C307697 Registered User - Change rating from Disliked to Neutral, @reactions', async () => {
        
      // Select a Movie Title after landing on Movies page
      await testUtils.goToPage('movies');
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      await selectDislike();
      await testUtils.waitForElementToFullyShowOnScreen('DislikedButtonRemove', 'Button Not Found', 15000);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Neutral state
      await testUtils.waitForElementToFullyShowOnScreen('likeOrDislikeButton', 'Button not found', 15000);
    });

    it('C307702 Registered User - Like and Dislike not available while in Kids Mode after already Liked or Disliked in non-Kids mode, @reactions', async () => {

      const user = await testUtils.createRegisteredUser();
      await testUtils.startApplicationWithDeeplink({mediaType: 'movie', contentID: '342067'}, {user: user});
      await ecp.sendKeypress(ecp.Key.Back);
      await selectLike();
        
      // Go to Kids mode
      await testUtils.goToPage('kids');
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      
      //Open left nav
      await openLeftNav();
      await ecp.sendKeypress(ecp.Key.Up);
      await utils.sleep(1000);
      await testUtils.waitForElementToFullyShowOnScreen('kidsSearchSelected');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Wait for Search Grid
      await testUtils.waitForElementToFullyShowOnScreen('kidsSearchKeyPad');
      await ecp.sendText('zapped');
      await testUtils.waitForElementToFullyShowOnScreen('kidsSearchResultsText');

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

      // Once on detail screen, Verify that the Reaction buttons are not showing on screen
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
      await testUtils.waitForElementToNotShowOnScreen('likeOrDislikeButton');
   
    });

    // https://tubi.testrail.io/index.php?/cases/view/308984
    it('C308984 - Registered User - Like and Dislike not available when Parental Controls is Little Kids, @reactions', async () => {
      
      // Set Parental Controls to Little Kids
      await setPCToLittleKids();

      // Select a Title after landing on Home page
      await testUtils.goToPage('home');
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Once on detail screen, Verify that the Reaction buttons are not showing on screen
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
      await testUtils.waitForElementToNotShowOnScreen('likeOrDislikeButton');
    });

    // https://tubi.testrail.io/index.php?/cases/view/308985
    it('C308985 - Registered User - Like and Dislike not available when Parental Controls is Older Kids, @reactions', async () => {
      
      await setPCToOlderKids();
   
      // Select a Title after landing on Home page
      await testUtils.goToPage('home');
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Once on detail screen, Verify that the Reaction buttons are not showing on screen
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
      await testUtils.waitForElementToNotShowOnScreen('likeOrDislikeButton');
    });


    });

    async function selectLike(){

      // From Details page, navigate to highlight Like or Dislike button
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
      await testUtils.selectAndVerifyDetailPageMenuItem('likeOrDislike');

      // There should be a secondary menu with two buttons: thumbs up/like and thumbs down/dislike.
      // Select the Like Button
      await testUtils.waitForElementToFullyShowOnScreen('secondaryMenuButtonLike');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify that the title is now liked
      await testUtils.waitForElementToFullyShowOnScreen('reactionButtonLiked');
    }

    async function selectDislike(){
      // From Details page, navigate to highlight Like or Dislike button
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
      await testUtils.selectAndVerifyDetailPageMenuItem('likeOrDislike');

      // There should be a secondary menu with two buttons: thumbs up/like and thumbs down/dislike.
      // Select the Dislike Button
      await testUtils.waitForElementToFullyShowOnScreen('secondaryMenuButtonLike');
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToFullyShowOnScreen('DislikedButtonFocused');
      await ecp.sendKeypress(ecp.Key.Ok);
    }

    async function openLeftNav() {
      // Press left
      await ecp.sendKeypress(ecp.Key.Left);
    
      // Is the left Nav open?
      await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');
    }

    async function setPCToOlderKids() {
      await testUtils.goToPage('settings');

      // On Settings Page?
      const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
      expect(parentalControlsHeader.text).to.equal('Parental Controls');

      // Set PC
      await selectOlderKidsFromParentalSettings();
      await shared.enterPasswordSettingsChange();

      // Verify Older Kids PC Settings Change dialog
      await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsOlderKids', 'Element not found', 7000);
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);
    }

    async function setPCToLittleKids() {
      await testUtils.goToPage('settings');

      // On Settings Page?
      const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
      expect(parentalControlsHeader.text).to.equal('Parental Controls');

      // Set PC
      await shared.selectLittleKidsFromParentalSettings();
      await shared.enterPasswordSettingsChange();

      // Verify Older Kids PC Settings Change dialog
      const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
      expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeypress(ecp.Key.Ok);
    }

    async function selectOlderKidsFromParentalSettings() {
      await ecp.sendKeypress(ecp.Key.Right, {wait:2000});
      await ecp.sendKeypress(ecp.Key.Up, {count:2});
      await ecp.sendKeypress(ecp.Key.Ok);
    }