import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';
import { ok } from 'assert';
import PlayBack from '../analytics/pages/playback';


describe('Categories', function () {
    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48644 ,  https://tubi.testrail.io/index.php?/cases/view/637122 , https://tubi.testrail.io/index.php?/cases/view/638442
    it('C48644 and C637123 - Continue Watching Row - when user plays a title and navigates back to Home screen then Continue Watching row should be displayed, @categories', async () => {
    
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
      await openLeftNav();
      await selectCategories();
      await ecp.sendKeypress(ecp.Key.Down, {wait:2000});
      await testUtils.waitForElementToFullyShowOnScreen('continueWatchingButton');
      const continueWatchingButtonText = testUtils.getNodeForElement('continueWatchingButton');
      expect((await continueWatchingButtonText).text).to.equal('Continue Watching');
      
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
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton',  'button not found');
      await ecp.sendKeypress(ecp.Key.Down, {wait:2000});
      
      // Press OK to reach Details of title
      await testUtils.waitForElementToFullyShowOnScreen('categoryPageTitle');
      await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRowPoster');
      await ecp.sendKeypress(ecp.Key.Right, {wait:2000});
      await ecp.sendKeypress(ecp.Key.Ok);

      // Remove from History
      await testUtils.waitForElementToShowOnScreen('resumeButton');
      //await ecp.sendKeypress(ecp.Key.Down, {count:5});
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

      // Go to All Categories page
      await ecp.sendKeypress(ecp.Key.Back,  {count:4, wait:2000});
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Continue Watching category does not exist
      await testUtils.waitForElementToNotShowOnScreen('continueWatchingButton');

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
      await testUtils.waitForElementToShowOnScreen('channelsVideoGrid');
      await ecp.sendKeypress(ecp.Key.Right);

      // Are we on the Video Grid? 
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

      // If so, navigate horizontally to last poster + 1
      await verifyFourColumns();
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
      await testUtils.getNodeForElement('categoryNameInCategoryDetailsPage');
      await ecp.sendKeypress(ecp.Key.Right);

      // Are we on the Video Grid? 
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

      // If so, navigate horizontally to last poster + 1
      await verifyFourColumns();

    });

     // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/637124 and https://tubi.testrail.io/index.php?/cases/view/690609
    it('C637124 - Guest User - Recommended is shown at the top of list, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    });

     // https://tubi.testrail.io/index.php?/cases/view/637123
    it('C637123 - Registered User - Continue Watching is NOT displayed near top of list, if user does not have titles to resume, @categories', async () => {
      // Create user with history only
      const user = await testUtils.createRegisteredUser();
      await createHistory(user);

      // Start app with Registered user
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList','Timed out waiting for Rowlist to have focus');

      // Go to All Categories page
      await openLeftNav();
      await selectCategories();
      await testUtils.waitForElementToNotShowOnScreen('continueWatchingButton');
    });

    // https://tubi.testrail.io/index.php?/cases/view/638438
    it('C638438 - Registered User - My List is displayed near top of list, if user has titles in "My List", @categories', async () => {
       
      // Create user with watchlist
      const user = await testUtils.createRegisteredUser();
      await createWatchList(user);

      // Start app with Registered user
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to All Categories page
      await openLeftNav();
      await selectCategories();
      await testUtils.waitForElementToShowOnScreen('categoryMyListMenuItem');
      const categoryMyListMenuItemText = await testUtils.getNodeForElement('categoryMyListMenuItem');
      expect(categoryMyListMenuItemText.text).to.equal('My List');

    });


     // https://tubi.testrail.io/index.php?/cases/view/638439
     it('C638439 - Registered User - My List is NOT displayed near top of list, if user has no titles in "My List", @categories', async () => {
       
      // Create user with watchlist
      const user = await testUtils.createRegisteredUser();

      // Start app with Registered user
      await testUtils.startApplicationAtPage('home', { user: user });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to All Categories page
      await openLeftNav();
      await selectCategories();
      await testUtils.waitForElementToFullyShowOnScreen('categoryMyListMenuItem');
      const buttonText = await testUtils.getNodeForElement('categoryMyListMenuItem');
      expect(buttonText.title).to.not.equal('My List');

    });


    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/638443
    it('C638443 - "Networks" is shown near the top of the list, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify that the Networks button is near the top
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToFullyShowOnScreen('channelNetworksButtonFocused');
      const channelNetworkButton = testUtils.getNodeForElement('channelNetworksButtonFocused');
      
    });

     // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638445 and https://tubi.testrail.io/index.php?/cases/view/C638441
     it('C638445 - Selecting a network poster will display the category page view of all the titles in the network, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

      // Down to Networks button
      await ecp.sendKeypress(ecp.Key.Down);
      await ecp.sendKeypress(ecp.Key.Right);

      // Are we on the Video Grid and are the category titles available? 
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Channel Video Grid
      await testUtils.waitForElementToShowOnScreen('channelsVideoGrid');

    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638444
    it('C638444 - Selecting "Networks" will display the networks as separate posters, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

      // Down to Networks button and select
      await ecp.sendKeypress(ecp.Key.Down, {wait:1500});
      await testUtils.waitForElementToFullyShowOnScreen('categoryPageTitle');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Network posters
      await testUtils.waitForElementToShowOnScreen('networksContentGrid');


    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638446 and https://tubi.testrail.io/index.php?/cases/view/638447
    it('C638446 - Selecting any category will move focus to first title in the container, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

      // Select Category Button
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Is the first poster now selected? 
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      
      // Is the Background Poster present?
      await testUtils.waitForElementToShowOnScreen('backgroundPoster');

      // Is the metadate Info panel present?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');   

    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638446 
    it('C690605 - When a title is in focus, video preview does NOT play, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

      // Select Category Button
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Is the first poster now selected? 
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      
      // Is the Background Poster present?
      await testUtils.waitForElementToShowOnScreen('backgroundPoster');

    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C690718 and https://tubi.testrail.io/index.php?/cases/view/638449
    it('C690718 - When title is NOT in focus, the metadata/static image is removed from the top of the screen, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

      // Select Category Button
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Is the first poster now selected? 
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      
      // Is the Background Poster present?
      await testUtils.waitForElementToShowOnScreen('backgroundPoster');

      // Is the metadate Info panel present?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');  
      
      // Press back and check background poster and metadata info is no longer present
      await ecp.sendKeypress(ecp.Key.Back, {wait:2000});

      // Is the Background Poster present?
      await testUtils.waitForElementToNotShowOnScreen('backgroundPoster');

      // Is the metadate Info panel present?
      await testUtils.waitForElementToNotShowOnScreen('categoriesDetailsPageInfo');  

      // Is the category menu item selected? 
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    });

     // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/637124 and https://tubi.testrail.io/index.php?/cases/view/690609
    it('C638448 - Selecting a title opens the details page, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:1000});

      // Select Category Button
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Is the metadate Info panel present?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

      // Select a Title
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Verify Details page opens
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');   

    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C690716
    it('C690716 - Verify UI/UX while in Kids mode, @categories', async () => {
      await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Networks category button at the top
      await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');
      const headerName = await testUtils.getNodeForElement('categoryHeader');
      expect(headerName.text).to.equal('Networks');

    });

    // https://tubi.testrail.io/index.php?/cases/view/690606
    it('690606 - Pressing "back" from details page takes user back to category tile screen, @categories', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Go to Categories Details page
      await openLeftNav();
      await selectCategories();

      //Verify Recommended button at the top
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:1000});

      // Select Category Button
      await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Is the metadata Info panel present?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

      // Select a Title
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Verify Details page opens
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');  
      
      // Press back to go back to category title screen
      await ecp.sendKeypress(ecp.Key.Back, {wait:2000});

      // Is the metadata Info panel present?
      await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');   

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
      await ecp.sendKeypress(ecp.Key.Ok, {wait:2000});

      // Are we on Categories page?
      await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton', 'Category page not shown', 15000); 
    }

    async function verifyFourColumns() {

       // Verify 6 rows only, navigate horizontally to last poster + 1
       await utils.sleep(1000);
       await ecp.sendKeypress(ecp.Key.Right, {count:4});
       await utils.sleep(1000);

       // Are we still on the 4th title after navigating right more than 3 times?
      const channelsVideoGrid = await testUtils.getNodeForElement('channelsVideoGrid');
      expect(channelsVideoGrid.currFocusColumn).to.equal(3); 
      
    }

    async function createWatchList(user) {

      // Create a user with mix of little kids and non-little kid rated titles with history

      const ContentTVG = await user.getContent().ofContentType(['series']).withRating('TV-G').retrieve({ limit: 6});
      await user.addContentToWatchList(ContentTVG);
      const ContentG = await user.getContent().ofContentType(['movie']).withRating('G').retrieve({ limit: 6});
      await user.addContentToWatchList(ContentG);
      const ContentPG = await user.getContent().ofContentType(['movie']).withRating('PG').retrieve({ limit: 6});
      await user.addContentToWatchList(ContentPG);

    }

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
        const movieContentPG = await user.getContent().withRating('PG').ofContentType('movies').retrieve({ limit: 2});
        await user.addContentToViewHistory(movieContentPG, 500);
    }
