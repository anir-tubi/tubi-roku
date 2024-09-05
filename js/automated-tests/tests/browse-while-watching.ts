import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { ParentalRating, auth, testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Browse While Watching', function () {
      before(async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      });
    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611427
    it('C611427 - YMAL is shown below transport controls during movie playback, @browse_watching', async () => {

        // Select a movie title and Play
        await selectMovieTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();

    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611428
    it('C611428 - YMAL is shown below transport controls during series playback, @browse_watching', async () => {

        // Select a movie title and Play
        await selectSeriesTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();

    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611429
    it('C611429 - With transport controls displayed, pressing "down" expands the YMAL section, @browse_watching', async () => {

        // Select a movie title and Play
        await selectSeriesTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();
        
        // Verify that video is still playing in background
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);    

    });

    // https://tubi.testrail.io/index.php?/cases/view/611433
    it('611433 - When YMAL is expanded, tapping "back" minimizes it, @browse_watching', async () => {

        // Select a movie title and Play
        await selectMovieTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();
        
        // Verify that video is still playing in background
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);  
        
        // Press the back button
       //  await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Back);

        // Transport Controls are not shown on screen
        await testUtils.waitForElementToNotShowOnScreen('transportButtons', 'Transport section is still displayed', 10000);

        // Video is still playing
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611434
    it('C611434 - When YMAL is expanded, tapping "up" minimizes it, @browse_watching', async () => {

        // Select a movie title and Play
        await selectMovieTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();
        
        // Verify that video is still playing in background
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);  
        
        // Press UP on the remote
        await ecp.sendKeypress(ecp.Key.Up);

        // YMAL minimizes and player controls are shown on screen
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport section is still displayed', 10000);
    });

    
    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611432
    it('C611432 - When title in YMAL is in focus, tapping "ok" will begin playback of that title, @browse_watching', async () => {

        // Select a movie title and Play
        await selectMovieTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();
        
        // Press Ok and verify playback
        //await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
        

    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611438
    it('C611438 - When title in YMAL is in focus, tapping "play/pause" button will play/pause current playing title, @browse_watching', async () => {

        // Select a movie title and Play
        await selectMovieTitle();

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();
        
        // Press Play button, verify pause and play states 
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused', 5000);
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);     
    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611435
    it('C611435 - 5 seconds of inactivity hides BWW row and transport controls, @browse_watching', async () => {

        // Select a movie title and Play
        await selectMovieTitle();

        // Verify BWW row in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('transportButtons', 'Transport not shown', 3000);
        
        // Verify BWW Row not shown after time out 
        await utils.sleep(6000); // time out
        await testUtils.waitForElementToNotShowOnScreen('transportButtons', 'BWW Row is shown', 3000);


    }); 
    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611443
    it('C611443 - YMAL is NOT shown below transport controls when in Kids Mode, @browse_watching', async () => {

        // start in Kids mode
        await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play); 

        // Verify YMAL row NOT in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToNotShowOnScreen('videoPlayYmalPoster', 'poster not shown', 3000);     
    
    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611444
    it('C611444 - YMAL is NOT shown below transport controls when PC = Little Kids, @browse_watching', async () => {

        // Create registered user, set PC to little Kids
        const user = await testUtils.createRegisteredUser();
        await user.changeParentalRating(ParentalRating.littleKids);
 
        // Launch to home page
        await testUtils.startApplicationAtPage('home', { user: user }); 
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
        
        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play); 

        // Verify YMAL row NOT in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToNotShowOnScreen('videoPlayYmalPoster', 'poster shown on screen', 3000);     
    
    });

     //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611442
     it('C611442 - When Parental Controls = Teen, BWW screen does NOT have content over TV-14 or PG-13, @browse_watching', async () => {

        // Create registered user, set PC to little Kids
        const user = await testUtils.createRegisteredUser();
        await user.changeParentalRating(ParentalRating.teens);
        await testUtils.startApplicationAtPage('home', { user : user});
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play); 

        // Verify YMAL row in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingRowListPoster', 'BWW row not shown', 4000);

         // Check ratings
        expect('ymalRatingsLabel').does.not.contain(['R','MA','TV-MA', 'NR']);
        const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
        for (const itemContent of rowItemsContent) {
            expect(['R','MA','TV-MA', 'NR'].includes(itemContent.type)).to.be.false;
        }
  
    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611439
    it('C611439 - YMAL is shown below transport controls when deeplinking to movie, @browse_watching', async () => {

        // Select a movie title and Play
        await testUtils.startApplicationWithDeeplink({mediaType: 'movie', contentID: '342067', shouldCreateNewUser: true });

        // Wait for movie to start playing
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();       

    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611440
    it('C611440 - YMAL is shown below transport controls when deeplinking to series, @browse_watching', async () => {

        // Select a movie title and Play
        await testUtils.startApplicationWithDeeplink({mediaType: 'episode', contentID: '200051058', shouldCreateNewUser: true });

        // Wait for movie to start playing
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();
        

    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611446
    it('C611446 - YMAL is shown below transport controls for Guest User, @browse_watching', async () => {

        // Select a movie title and Play
        await testUtils.startApplicationWithDeeplink({mediaType: 'movie', contentID: '342067', shouldCreateNewUser: false});

        // Wait for movie to start playing
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();       

    });

     // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611441
     it('C611441 - YMAL is shown below transport controls when in Español mode, @browse_watching', async () => {

        // start in espanol mode
        await testUtils.startApplicationAtPage('espanol', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('espanolScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play);

        // Wait for title to start playing
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();

    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611448
 

   
    it('C611400 - Continue Watching row is shown as one of the containers in YMAL section (Registered User), @browse_watching', async () => {

        // Create user with history
        const user = await testUtils.createRegisteredUser();
        await createHistoryEvergreenMovieTitle(user);
        await createHistoryEvergreenSeriesTitle(user);
         
        // Start app
        await testUtils.startApplicationAtPage('movies', { user: user });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();

        // Verify CW row
        await testUtils.jumpToRowWithTitle('browseWhileWatchingRowList', 'Continue Watching');    

    });

    // https://tubi.testrail.io/index.php?/cases/view/611653
    it('C611653 - Continue Watching row is NOT shown as one of the containers in YMAL section (Guest User), @browse_watching', async () => {

         
        // Start app
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: false });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();

        // Verify CW row not present
        await isContinueWatchingInRowList();
           

    });

     // https://tubi.testrail.io/index.php?/cases/view/613727
     it('C613727 - If registered user selects from CW row, playback should start from resume point, @browse_watching', async () => {
  
        // Create user with history
        const user = await testUtils.createRegisteredUser();
        await createHistoryEvergreenMovieTitle(user);
    
         
        // Start app
        await testUtils.startApplicationAtPage('movies', { user: user });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play); 

        // Verify YMAL row in player
        await verifyYMALRowInPlayer();

        // Verify CW row
        await testUtils.jumpToRowWithTitle('browseWhileWatchingRowList', 'Continue Watching'); 

        // Select content and verify resume point is NOT the beginning

        // Select a title and Play
        await ecp.sendKeypress(ecp.Key.Ok, {wait:3000});
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        

        // Check that title resumes from history

        await verifyPlayFromHistory();      

    });


});


    async function selectMovieTitle() {
        await testUtils.goToPage('movies');
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Movie screen row not found', 15000);
        await ecp.sendKeypress(ecp.Key.Ok);  
        await testUtils.waitForElementToFullyShowOnScreen('playButton', 'Play button not found', 15000); 
        await ecp.sendKeypress(ecp.Key.Ok);  
    }

    async function selectSeriesTitle() {
        await testUtils.goToPage('tv');
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'TV screen row not found', 15000);
        await ecp.sendKeypress(ecp.Key.Play); 
    }

    async function verifyYMALRowInPlayer() {

         // Verify YMAL row in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await ecp.sendKeypress(ecp.Key.Down, {wait:1000});
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'player controls not present', 10000);
        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Down, {wait:1000}); 
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW rows not shown', 10000);
    }

    async function createHistoryEvergreenMovieTitle(user) {

        // Create a watch list one Evergreen title movie
        const contentId = await user.getContentById(342067);
        await user.addContentToViewHistory(contentId, 500);

    }

    async function createHistoryEvergreenSeriesTitle(user) {

        // Create a watch list one Evergreen title movie
        const contentId = await user.getContentById(300005163);
        await user.addContentToViewHistory(contentId, 500);

    }

    async function isContinueWatchingInRowList() {

        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'YMAL row list not shown', 7000);

        // Check Row List Headers
        
        expect('browseWhileWatchingRowList').does.not.contain(['Continue Watching']);
    }
  
    
    async function verifyPlayFromHistory() {
    
        // Verify Movie title playback starts from beginning
        await testUtils.waitForPlayerPositionToEqual('videoPlayerScreen', (500 * 1000));
    }
        
       
    



