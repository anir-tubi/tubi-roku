import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { count, timeEnd } from 'console';

describe('Details Page', function () {
  describe('Movie Details Page', function () {
    let itemData;

    before(async () => {
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // We now want to find a piece of content that doesn't have a video preview
      const rowListElement = testUtils.getElementKeyPath('movieScreenRowList');
      const result = await findIndexForFirstItemWithoutVideoPreview(rowListElement.keyPath);
      itemData = result.item;

      // If we found it go ahead and jump to it
      if (result.index) {
        await odc.setValue({
          keyPath: rowListElement.keyPath,
          field: 'jumpToRowItem',
          value: result.index
        });
      } else {
        console.error('Could not find a piece of content without video preview');
      }

      // Now select that content to land us on the detail page
      await ecp.sendKeypress(ecp.Key.Ok);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537369
    it('C537369 - Movie Details - When Movie Details page is opened then Title Text is displayed @registered_user,@smoke,@mdp_1', async () => {
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      expect(detailScreenTitle.text).to.equal(itemData.title);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535838
    it('C535838 - Movie Details - When Movie Details page is opened then background image is seen @registered_user,@smoke,@mdp_1', async () => {
      const backgroundGroup = await testUtils.getNodeForElement('backgroundGroup');
      expect(backgroundGroup.posterVisible).to.equal(true);
      expect(backgroundGroup.backgroundInfo.urilist.length).to.be.greaterThan(0);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537370
    it('C537370 - Movie Details - When Movie Details page is opened then runtime and year is displayed @registered_user,@mdp_1', async () => {
      const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
      expect(detailScreenYearAndDuration.visible).to.equal(true);
      expect(detailScreenYearAndDuration.text).to.contain(itemData.year);
      // Improvement we could add check here to make sure the duration is also correct as well but this could get pretty complicated to cover all cases
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535808
    it('C5358081 - Movie - No History - When title is added to queue then Add to Queue changed to Remove from Queue @registered_user,@smoke,@mdp_1', async () => {
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535809
    it('C535809 - Movie Details - No History - When backing out of playback then buttons change to reflect movie with history @mdp_1', async () => {

      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      await ecp.sendKeypress(ecp.Key.Play);
      await createHistory();
      await utils.sleep(2000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);

      // Check for Resume button
      await testUtils.retryWithTimeOut(async () => {
        const resumePlayingButton = await testUtils.getNodeForElement('resumePlayingButton');
        expect(resumePlayingButton.text).to.equal('Resume Playing');
      });


      try {
        await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
      } catch (e) {
        // IMPROVEMENT remove the need for this
        await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
      }
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535810
    it('C535810 - Movie Details - With History - When title is added to queue then "Add to My List" is changed to "Remove from My List" @mdp_1,@registered_user', async () => {
      // Press Add to My List Button
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');

      // Check that Add to My List button changed to Remove from My List
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535812
    it('C535812- Movie Details - With History - When "Play From Beginning" selected then movie playback starts from beginning @mdp_1,@registered_user', async () => {

      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Create history
      await ecp.sendKeypress(ecp.Key.Play);
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('detailScreen');

      // Check that movie has history)
      await testUtils.retryWithTimeOut(async () => {
        const resumePlayingButton = await testUtils.getNodeForElement('resumePlayingButton');
        expect(resumePlayingButton.text).to.equal('Resume Playing');
      });

      // Press Play from Beginning and check playback
      await testUtils.selectAndVerifyDetailPageMenuItem('playFromBeginning');

      // await testUtils.selectAndVerifyDetailPageMenuItem('play');  Need an update from Brian here
      await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing',5000);

      // Verify Movie title playback starts from beginning
      const position = await testUtils.getPlayerPosition();
      expect(position).to.be.greaterThanOrEqual(0);
      expect(position).to.be.lessThan(5000);

      // Clean up
      await ecp.sendKeypress(ecp.Key.Back, {count:1, wait:2000});
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    });


    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535813
    it('C535813 - Movie Details - With History - When "Resume Playing" is selected then movie playback resumes from history @mdp_1', async () => {
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select another title
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.id).to.equal('Title');

      // Verify and select the Play button

      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history
      //await ecp.sendKeypress(ecp.Key.Play);
      await createHistory();

      // Get player postion
      const position = await testUtils.getPlayerPosition();
      const currentposition = position;

      // Back to Details page
      await utils.sleep(2000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);

      // Select Resume and check for playback

      await testUtils.retryWithTimeOut(async () => {
        await testUtils.selectAndVerifyDetailPageMenuItem('resume');
      });

      await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

      // Find resume position
      const resumeposition = await testUtils.getPlayerPosition();
      const difference = (resumeposition - currentposition);

      // Find out if current postion and resume postion are within range
      const min = 0;
      const max = 5000;
      const between = (difference, min, max) => {
        expect(difference).greaterThanOrEqual(min);
        expect(difference).lessThanOrEqual(max);
      };

      // Back to Details page
      await ecp.sendKeypress(ecp.Key.Back, { count: 1 });
    });

    // https://tubi.testrail.io/index.php?/cases/view/535870
    it('C535870 - Movie Details - Given movie has history, when "Remove From History" is selected then buttons change to reflect a movie with no history @mdp_1', async () => {


      // Launch app on Movies page
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Create history
      await ecp.sendKeypress(ecp.Key.Play);
      await createHistory();

      // Back to Details page
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);

      // Check that movie has history by clicking the Remove from History Button
      await utils.sleep(2500);
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

      // Verify that Remove from History changes to Add to My List
      await utils.sleep(3000);
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/6409
    it('C6409 - Movie Details - With History - When "Play From Beginning" selected then movie playback starts from beginning" @mdp_1', async () => {

      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select another title
      await ecp.sendKeypress(ecp.Key.Down);
      await ecp.sendKeypress(ecp.Key.Ok);
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.id).to.equal('Title');

      // Play title to create history
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history
      await createHistory();

      // Back out of the video player to land on Details page
      await utils.sleep(2000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);

      // Check that movie has history
      await testUtils.retryWithTimeOut(async () => {
        await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Remove from history');
      });

      // Press the Play (from beginning) button on title with History
      await testUtils.selectAndVerifyDetailPageMenuItem('playFromBeginning');
      await utils.sleep(3000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Ok);

      // Find current position
      const currentposition = await testUtils.getPlayerPosition();

      // Check that we played from Beginning
      expect(currentposition).lessThanOrEqual(5000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537688
    it('C537688 - Movies - Details Page Displays History Progress Bar @mdp_1,@registered_user', async () => {
      // Launch to Home> Movies page with registered user
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

      // On Movies page?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');


      //Select title
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Play title to create history
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history
      await createHistory();
      await utils.sleep(2000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);
      await utils.sleep(2000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Back);


      // Check that Resume has progress bar
      await testUtils.retryWithTimeOut(async () => {
        const resumedProgressBar = await testUtils.getNodeForElement('resumedProgressBar');
        expect(resumedProgressBar.visible).to.equal(true);
      });

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/48643
    it('C48643 - Movie - No History - When title is removed from queue then Remove from Queue changed to Add to Queue @mdp_1,@registered_user', async () => {

      // Launch to Home> Movies page with registered user
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

      // On Movies page?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      //Select title
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Ok);

      // Find Add to My List and verify that text is correct
      await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Add to My List');


      // Select Add to My List so that it changes to Remove from My List
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
      await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Remove from My List');

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76705
    it('C76705 - Movie Details - When Movie Details page is opened then runtime is displayed @mdp_1,@registered_user', async () => {

      // Launch to Home> Movies page with registered user
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

      // On Movies page?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      //Select title
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000); // Improvement - try to work around sleeps
      await ecp.sendKeypress(ecp.Key.Ok);



      // Verify that the title is listed on the Movies Details screen
      const movieRunTime = await testUtils.waitForElementToFullyShowOnScreen('movieRunTime');

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/141195
    it('C141195 Selecting YMAL video on Details page after viewing should work - Movies @registered_user,@smoke,@mdp_1', async () => {
      //Go to a movie detail page and click play.
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

      // On Movies page?
      await testUtils.waitForCurrentScreenToEqual('movieScreen');

      // Used to wait until the rowlist content is loaded
      await testUtils.getCurrentlyFocusedGridItemIndex('movieScreenRowList');

      // Select a title and press the Play button
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.selectAndVerifyDetailPageMenuItem('play', 8000);

      // Create history, then back to details page-
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeypress(ecp.Key.Back);

      // Navigate down to the YAML container and try selecting a video.
      // Press down until YMAL row is focused - Can we create a down until function?
      await ecp.sendKeypress(ecp.Key.Down, { count: 6 });

      //YMAL focused?
      const relatedYMALGrid = await testUtils.getNodeForElement('relatedYMALGrid');
      expect(relatedYMALGrid.visible).to.equal(true);

      //Detail page for the selected YAML title should open after selecting
      await ecp.sendKeypress(ecp.Key.Ok);

      const detailInfoPanel = await testUtils.getNodeForElement('detailInfoPanel');
      expect(detailInfoPanel.visible).to.equal(true);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/307688
    it('C307688 Registered User - Details page has Play button selected by Default @registered_user,@smoke,@mdp_1', async () => {
      // Start Application at Movies page with logged in user
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
       // On Movies page?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');


      // Used to wait until the rowlist content is loaded
      await testUtils.getCurrentlyFocusedGridItemIndex('movieScreenRowList');

      // Select title
      await ecp.sendKeypress(ecp.Key.Ok);

      // Make sure Play button is selected on opening Details page
      await testUtils.getNodeForElement('detailScreenMenu', 10000);
      const content = await testUtils.getCurrentlyFocusedGridItemContent('detailScreenMenu');
      expect(content.id).to.equal('PlayMenuItem');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/https://tubi.testrail.io/index.php?/cases/view/537368
    it('C537368 - Movie Details - No History present - Guest - Resume Playback from beginning @smoke,@mdp_1', async () => {
      // Start Application at Movies page with Guest user
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: false });

      // On Movies page?
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Used to wait until the rowlist content is loaded
      await testUtils.getCurrentlyFocusedGridItemIndex('movieScreenRowList');

      // Select a title
      await ecp.sendKeypress(ecp.Key.Ok);

      //Make sure Play button is selected when landing on details page
      let content = await testUtils.getCurrentlyFocusedGridItemContent('detailScreenMenu');
      expect(content.id).to.equal('PlayMenuItem');

      // Capture the current item title so we can make sure we got the same item on the next launch
      const firstScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');

      // Select Play button
      await ecp.sendKeypress(ecp.Key.Ok);


      // Call to createHistory function
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeypress(ecp.Key.Back);

      // Back out to home screen
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('movieScreen');

      // Exit app
      await ecp.sendKeypress(ecp.Key.Back, { count: 4 });
      await ecp.sendKeypress(ecp.Key.Ok);

      //Relaunch app as guest
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: false, clearRegistry:false });

      // Make sure we're on movies page
      await testUtils.waitForCurrentScreenToEqual('movieScreen');
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      //Select title
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify that we got the same item otherwise we aren't actually confirming if resume went away
      await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Title not shown', 6000);
      const secondScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(firstScreenTitle.text).to.equal(secondScreenTitle.text);

      //Check that Play button is focused, not Resume button
      content = await testUtils.getCurrentlyFocusedGridItemContent('detailScreenMenu');
      expect(content.id).to.equal('PlayMenuItem');
    });

    // https://tubi.testrail.io/index.php?/cases/view/521094
    it('C521094 - Registered User - Check Resume and Play icon and text from Details screen @mdp_1', async () => {

      // On Movies page?
      await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Create history
      await ecp.sendKeypress(ecp.Key.Play);
      await createHistory();

      // Back to Details page
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Back);

      // Check that UI has Resume button
      await utils.sleep(2000);
      await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');

      // Verify that UI also has a Play button
      await utils.sleep(2000); // Improvement
      await testUtils.selectAndVerifyDetailPageMenuItem('playFromBeginning');
    });



  }); // Close describe Movies page

  // Series Details Page tests (tv)
  describe('Series Details Page', function () {
    let itemData;

    before(async () => {
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });

      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // We now want to find a piece of content that doesn't have a video preview
      const rowListElement = testUtils.getElementKeyPath('tvScreenRowList');
      const result = await findIndexForFirstItemWithoutVideoPreview(rowListElement.keyPath);
      itemData = result.item;

      // If we found it go ahead and jump to it
      if (result.index) {
        await odc.setValue({
          keyPath: rowListElement.keyPath,
          field: 'jumpToRowItem',
          value: result.index
        });
      } else {
        console.error('Could not find a piece of content without video preview');
      }

      // Now select that content to land us on the detail page
      await ecp.sendKeypress(ecp.Key.Ok);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537453
    it('C537453 - Series - When series details page is opened then background poster should be displayed, @registered_user,@sdp_2,@smoke', async () => {

      // Verify we are on the details page
      let detailScreenTitle;
      await testUtils.retryWithTimeOut(async () => {
        detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
      });

      // Verify background poster is displayed
      await testUtils.retryWithTimeOut(async () => {
        const titleSeriesBackgroundPoster = await testUtils.getNodeForElement('titleSeriesBackgroundPoster');
        expect(titleSeriesBackgroundPoster.visible).to.equal(true);
      });
    });


    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537454
    it('C537454 - Series - No History - When "Add to My List" selected then series is added to queue,@registered_user,@sdp_1', async () => {

      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select a title
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify we are on the details page
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Screen title not found', 10000);
      await testUtils.waitForElementToFullyShowOnScreen('titleDescriptionNew');
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');


      // Press Add to My List Button
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');

      // Check the My List container exists
      await ecp.sendKeypress(ecp.Key.Left, { count: 2 });
      await testUtils.waitForSideNavMenuToBeExpanded();
      await testUtils.waitForElementToFullyShowOnScreen('leftNavMoviesIconNotFocused');
      await ecp.sendKeypress(ecp.Key.Up, {count:2});
      await testUtils.waitForElementToFullyShowOnScreen('myStuffSelected');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Check we are on the My Stuff page
      await testUtils.waitForElementToShowOnScreen('myStuffGrid');
      await ecp.sendKeypress(ecp.Key.Down);

      // Jump to the My List row
      await testUtils.jumpToRowWithTitle('myStuffGrid', 'My List');

      // Find the title of the video that was added to My List
      const content = await testUtils.getCurrentlyFocusedGridItemContent('myStuffGrid');

      // Verify that the title that was added to My List is present on the My Stuff page
      expect(content.title).to.equal(detailScreenTitle.text);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535820
    it('C535820 Series - No History - When title is removed from queue then Remove From Queue changed to Add To Queue @sdp_1,@regression,@registered_user', async () => {
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select a Title
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

      // Select the Remove from my list button and verify that it changes to Add to My List
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
      await testUtils.waitForElementToFullyShowOnScreen('addToMyListButtonFocused');

    });


    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535821
    it('C535821 - Series - No History - When episode is chosen then playback should triggered from the beginning @sdp_1,@smoke,@regression,@registered_user', async () => {
      // While on Series Details page, lets play and check playback starts from the beginning
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select a Title
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify Playback from beginning
      await verifyPlayFromBeginning();
    });



    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/536524
    it('C536524 - Series - With History - When episode is played back from bookmark then playback will resume from saved history @registered_user,@sdp_1,@regression', async () => {
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify we are on the details page
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

      // Verify resume
      await verifyResumeWithinRange();

      // Back to Details page
      await ecp.sendKeypress(ecp.Key.Back);

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/141195
    it('C141195b Selecting YMAL video on Details page after viewing should work - Series,@sdp_1', async () => {

      await ecp.sendKeypress(ecp.Key.Right);

      // Verify we are on the details page
      await utils.sleep(4000); // Improvement
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.text).to.not.be.empty;

      // Select Play button
      await ecp.sendKeypress(ecp.Key.Ok);

      // Call to createHistory function
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeypress(ecp.Key.Back);

      // Navigate down to YMAL
      await ecp.sendKeypress(ecp.Key.Down, { count: 7 });
      await ecp.sendKeypress(ecp.Key.Ok);

      // Make sure we see the play button and then press it
      // Verify we are on the details page
      await utils.sleep(4000); // Improvement
      expect(detailScreenTitle.text).to.not.be.empty;

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/705809 and https://tubi.testrail.io/index.php?/cases/view/705811
    it('C705809 - Selecting "All Episodes" opens Season/Episode list screen,@sdp_1', async () => {
      // While on Series Details page, lets play and check playback starts from the beginning
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select a Title
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Details page?
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');


      // Select All Episodes button
      await testUtils.waitForElementToFullyShowOnScreen('allEpisodesButton');
      const episodesButtonText = await testUtils.getNodeForElement('allEpisodesButton');
      expect(episodesButtonText.text).to.equal('All Episodes');
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToFullyShowOnScreen('allEpisodesButtonFocused');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on the Episodes page?
      await testUtils.waitForElementToFullyShowOnScreen('episodesScreenSeasonHeader');
      await testUtils.waitForElementToShowOnScreen('episodesScreenRowList');
      
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/705810
    it('C705810 - "All Episodes" button is shown in series details page (guest user),@sdp_1', async () => {
      // While on Series Details page, lets play and check playback starts from the beginning
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Select a Title
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on Details page?
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

      // Select All Episodes button
      await testUtils.waitForElementToFullyShowOnScreen('allEpisodesButton');
      const episodesButtonText = await testUtils.getNodeForElement('allEpisodesButton');
      expect(episodesButtonText.text).to.equal('All Episodes');
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToFullyShowOnScreen('allEpisodesButtonFocused');
      await ecp.sendKeypress(ecp.Key.Ok);

      // Are we on the Episodes page?
      await testUtils.waitForElementToFullyShowOnScreen('episodesScreenSeasonHeader');
      await testUtils.waitForElementToShowOnScreen('episodesScreenRowList');
      
    });


  }); //Close describe Series Details page

});// Close describe Details page

async function findIndexForFirstItemWithoutVideoPreview(rowListKeyPath) {
  const contentBaseKeyPath = rowListKeyPath + '.content';
  const { value: totalRowCount } = await odc.getValue({
    keyPath: contentBaseKeyPath + '.getChildCount()'
  });


  for (let rowIndex = 0; rowIndex < totalRowCount; rowIndex++) {
    const { value: row } = await odc.getValue({
      keyPath: contentBaseKeyPath + `.${rowIndex}`,
      responseMaxChildDepth: 1
    });
    const json = JSON.parse(row.json);

    for (let itemIndex = 0; itemIndex < row.children.length; itemIndex++) {
      const item = row.children[itemIndex];
      const itemFullInfo = json[item.id];
      if (itemFullInfo && !itemFullInfo.video_preview_url) {
        return {
          index: [rowIndex, itemIndex],
          item: itemFullInfo
        };
      }
    }
  }
}
/* Create History function
// An example of this called from a test after landing on a details page and pressing Play
// After selecting a title from the details page, press the Play button
    await ecp.sendKeypress(ecp.Key.Ok); // selecting the title
    await testUtils.selectAndVerifyDetailPageMenuItem('play');  // verify the play button and press it
    await createHistory(); // create history function is called
*/

// Create history function
async function createHistory() {
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
  await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 120 * 1000, 'current');
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
}

// Play from Beginning check function
async function verifyPlayFromBeginning() {

  // Press Play and check playback
  await testUtils.selectAndVerifyDetailPageMenuItem('play');
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 15000);


  // Verify Movie title playback starts from beginning
  const position = await testUtils.getPlayerPosition('videoPlayerScreen');
  expect(position).to.be.greaterThanOrEqual(0);
  expect(position).to.be.lessThan(1000); //changed this value from original of 5000
}

async function verifyResumeWithinRange() {
  await utils.sleep(2000);
  await ecp.sendKeypress(ecp.Key.Play);// PLay to create history
  await utils.sleep(2000);
  await createHistory(); // Create history function
  const currentposition = await testUtils.getPlayerPosition('videoPlayerScreen');
  //console.log(currentposition);
  await utils.sleep(2000);
  await ecp.sendKeypress(ecp.Key.Back);

  // Verify we are on the details page
 await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

  // Select Resume and check for playback
  await testUtils.selectAndVerifyDetailPageMenuItem('resume');
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 15000);

  // Find resume position
  const resumeposition = await testUtils.getPlayerPosition();
  const difference = (resumeposition - currentposition);

  // Find out if current postion and resume postion are within range
  const min = -5000;
  const max = 5000;
  expect(difference).greaterThanOrEqual(min);
  expect(difference).lessThanOrEqual(max);
}
