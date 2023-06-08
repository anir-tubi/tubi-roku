import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { count, timeEnd } from 'console';

describe('Details Page', function() {
  describe('Movie Details Page', function() {
    let itemData;

    before(async () => {
      await testUtils.startApplicationAtPage('movies', true);

      // TODO make this into a helper
      // Wait until RowList is in focus so we know we're good to proceed
      await testUtils.untilTrue(async () => {
        const { value: id } = await odc.getValue({
          base: 'focusedNode',
          keyPath: 'id'
        });
        return id === 'RowList';
      }, 'Timed out waiting for Rowlist to have focus');

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
      await ecp.sendKeyPress(ecp.Key.Ok);
    });

    it('C5829 - Movie Details - When Movie Details page is opened then Title Text is displayed @registered_user,@smoke,@mdp_1', async () => {
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      expect(detailScreenTitle.text).to.equal(itemData.title);
    });

    it('C5830 - Movie Details - When Movie Details page is opened then background image is seen @registered_user,@smoke,@mdp_1', async () => {
      const backgroundGroup = await testUtils.getNodeForElement('backgroundGroup');
      expect(backgroundGroup.posterVisible).to.equal(true);

      for (const [index, url] of backgroundGroup.backgroundInfo.urilist.entries()) {
        expect(url).to.equal(itemData.backgrounds[index]);
      }
    });


    it('C5831 - Movie Details - When Movie Details page is opened then runtime and year is displayed @registered_user,@smoke,@mdp_1', async () => {
      const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
      expect(detailScreenYearAndDuration.visible).to.equal(true);
      expect(detailScreenYearAndDuration.text).to.contain(itemData.year);
      // Improvement we could add check here to make sure the duration is also correct as well but this could get pretty complicated to cover all cases
    });


    it('C4151 - Movie - No History - When title is added to queue then Add to Queue changed to Remove from Queue @registered_user,@smoke,@mdp_1', async () => {
      await testUtils.startApplicationAtPage('movies', true);
      await ecp.sendKeyPress(ecp.Key.Ok);
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
    });


    it('C4153 - Movie Details - No History - When backing out of playback then buttons change to reflect movie with history @mdp_1', async () => {
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      await ecp.sendKeyPress(ecp.Key.Play);
      await createHistory();
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Back);

      // Check for Resume button
      await testUtils.retryWithTimeOut(async () => {
        const resumeButton = await testUtils.getNodeForElement('resumeButton');
        expect(resumeButton.visible).to.equal(true);
      });


      try {
        await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
      } catch (e) {
        // IMPROVEMENT remove the need for this
        await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
      }
    });


    it('4156 - Movie Details - With History - When title is added to queue then "Add to My List" is changed to "Remove from My List" @mdp_1,@registered_user', async () => {
      // Press Add to My List Button
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');

      // Check that Add to My List button changed to Remove from My List
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
    });


    it('4158 - Movie Details - With History - When "Play From Beginning" selected then movie playback starts from beginning @mdp_1,@registered_user', async () => {
      // Create history
      await ecp.sendKeyPress(ecp.Key.Play);
      await createHistory();

      // Back out of the video player to land on Details page
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Back);

      // Check that movie has history)
      await testUtils.retryWithTimeOut(async () => {
        const resumeButton = await testUtils.getNodeForElement('resumeButton');
        expect(resumeButton.visible).to.equal(true);
    });

      // Press Play and check playback
      await testUtils.selectAndVerifyDetailPageMenuItem('play');
      await testUtils.expectPlayerStateToEventuallyEqual('play', 5000);

      // Verify Movie title playback starts from beginning
      const position = await testUtils.getPlayerPosition();
      expect(position).to.be.greaterThanOrEqual(0);
      expect(position).to.be.lessThan(5000);

      // Clean up
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    });



    it('C4159 - Movie Details - With History - When "Resume Playing" is selected then movie playback resumes from history @mdp_1', async () => {


      // Verify and select the Play button
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history
      //await ecp.sendKeyPress(ecp.Key.Play);
      await createHistory();

      // Get player postion
      const position = await testUtils.getPlayerPosition();
      const currentposition = position;

      // Back to Details page
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Back);
      await utils.sleep(2000);

      // Select Resume and check for playback

      await testUtils.retryWithTimeOut(async () => {
        await testUtils.selectAndVerifyDetailPageMenuItem('resume');
      });

      await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);

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
      await ecp.sendKeyPress(ecp.Key.Back, { count: 1 });
    });

    it('C4160 - Movie Details - Given movie has history, when "Remove From History" is selected then buttons change to reflect a movie with no history @mdp_1', async () => {

      // Back to Movies Screen
      await ecp.sendKeyPress(ecp.Key.Back, { count: 1 });
      await ecp.sendKeyPress(ecp.Key.Down);  //Move to fresh movie title

      // On Movies page?
      const onMoviesPageButton = await testUtils.getNodeForElement('onMoviesPageButton');
      expect(onMoviesPageButton.visible).to.equal(true);

      // Create history
      await ecp.sendKeyPress(ecp.Key.Play);
      await createHistory();

      // Back to Details page
      await ecp.sendKeyPress(ecp.Key.Back);

      // Check that movie has history by clicking the Remove from History Button
      await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

      // Verify that Remove from History changes to Add to My List
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
    });


    it('C6409 - Movie Details - With History - When "Play From Beginning" selected then movie playback starts from beginning" @mdp_1', async () => {
      // Play title to create history
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history
      await createHistory();
      // Back out of the video player to land on Details page
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Back);
      await ecp.sendKeyPress(ecp.Key.Down, {count:5});

      // Check that movie has history
      await testUtils.retryWithTimeOut(async () => {
        await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Remove from history');
      });

      // Press the Play (from beginning) button on title with History
      await testUtils.selectAndVerifyDetailPageMenuItem('play');
      await utils.sleep(3000);

      // Find current position
      const currentposition = await testUtils.getPlayerPosition();

      // Check that we played from Beginning
      expect(currentposition).lessThanOrEqual(5000);
    });


    it('C5919 - Details Page Displays History Progress Bar @mdp_1,@registered_user', async () => {
      // Launch to Home> Movies page with registered user
      await testUtils.startApplicationAtPage('movies', true);

      // On Movies page?
      const onMoviesPageButton = await testUtils.getNodeForElement('onMoviesPageButton');
      expect(onMoviesPageButton.visible).to.equal(true);

      //Select title
      await ecp.sendKeyPress(ecp.Key.Right);
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Play title to create history
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history
      await createHistory();
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Back);
      await utils.sleep(2000);


      // Check that Resume has progress bar
      await testUtils.retryWithTimeOut(async () => {
        const resumedProgressBar = await testUtils.getNodeForElement('resumedProgressBar');
        expect(resumedProgressBar.visible).to.equal(true);
      });

    });

    it('C48643 - Movie - No History - When title is removed from queue then Remove from Queue changed to Add to Queue @mdp_1,@registered_user', async () => {

      // Launch to Home> Movies page with registered user
      await testUtils.startApplicationAtPage('movies', true);

      // On Movies page?
      const onMoviesPageButton = await testUtils.getNodeForElement('onMoviesPageButton');
      expect(onMoviesPageButton.visible).to.equal(true);

      //Select title
      await ecp.sendKeyPress(ecp.Key.Right);
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Find Add to My List and verify that text is correct
      await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Add to My List');


      // Select Add to My List so that it changes to Remove from My List
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
      await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Remove from My List');

    });

    it('C76705 - Movie Details - When Movie Details page is opened then runtime is displayed @mdp_1,@registered_user', async () => {

      // Launch to Home> Movies page with registered user
      await testUtils.startApplicationAtPage('movies', true);

      // On Movies page?
      const onMoviesPageButton = await testUtils.getNodeForElement('onMoviesPageButton');
      expect(onMoviesPageButton.visible).to.equal(true);

      //Select title
      await ecp.sendKeyPress(ecp.Key.Ok);
      await utils.sleep(2000);


      // Verify that the title is listed on the Movies Details screen
      const movieRunTime = await testUtils.getNodeForElement('movieRunTime');
      expect(movieRunTime.visible).to.equal(true);
    });


    it('C141195 Selecting YMAL video on Details page after viewing should work - Movies @registered_user,@smoke,@mdp_1', async () => {
      //Go to a movie detail page and click play.
      await testUtils.startApplicationAtPage('movies', true);

      // On Movies page?
      const onMoviesPageButton = await testUtils.getNodeForElement('onMoviesPageButton');
      expect(onMoviesPageButton.visible).to.equal(true);

      // Select a title and press the Play button
      await ecp.sendKeyPress(ecp.Key.Ok);
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Create history, than back to details page-
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeyPress(ecp.Key.Back);

      // Navigate down to the YAML container and try selecting a video.
      // Press down until YMAL row is focused - Can we create a down until function?
      await ecp.sendKeyPress(ecp.Key.Down, { count: 6 });

      //YMAL focused?
      const relatedYMALGrid = await testUtils.getNodeForElement('relatedYMALGrid');
      expect(relatedYMALGrid.visible).to.equal(true);

      //Detail page for the selected YAML title should open after selecting
      await ecp.sendKeyPress(ecp.Key.Ok);

      const detailInfoPanel = await testUtils.getNodeForElement('detailInfoPanel');
      expect(detailInfoPanel.visible).to.equal(true);
    });


    it('C307688 Registered User - Details page has Play button selected by Default @registered_user,@smoke,@mdp_1', async () => {
      // Start Application at Movies page with logged in user
      await testUtils.startApplicationAtPage('movies', true);

      // Select title
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Make sure Play button is selected on opening Details page
      const playButtonSelected = await testUtils.getNodeForElement('playButtonSelected');
      expect(playButtonSelected.visible).to.equal(true);
    });

    it('C4154 - Movie Details - No History present - Guest - Resume Playback from beginning @guest_user,@smoke,@mdp_1', async () => {
      // Start Application at Movies page with Guest user
      await testUtils.startApplicationAtPage('movies', false);

      // Select a title
      await ecp.sendKeyPress(ecp.Key.Ok);

      //Make sure Play button is selected when landing on details page
      const playButtonSelected = await testUtils.getNodeForElement('playButtonSelected');
      expect(playButtonSelected.visible).to.equal(true);

      // Select Play button
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Call to createHistory function
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeyPress(ecp.Key.Back);

      // Exit app
      await ecp.sendKeyPress(ecp.Key.Back, { count: 4 });
      await ecp.sendKeyPress(ecp.Key.Ok);

      //Relaunch app as guest
      await testUtils.startApplicationAtPage('movies', false);
      await utils.sleep(7000);
      //Check that Play button is selected, no Resume button
      expect(playButtonSelected.visible).to.equal(true);
    });

  }); // Close describe Movies page

  // Series Details Page tests (tv)
  describe('Series Details Page', function() {
    let itemData;

    before(async () => {
      await testUtils.startApplicationAtPage('tv', true);

      // TODO make this into a helper
      // Wait until RowList is in focus so we know we're good to proceed
      await testUtils.untilTrue(async () => {
        const { value: id } = await odc.getValue({
          base: 'focusedNode',
          keyPath: 'id'
        });
        return id === 'RowList';
      }, 'Timed out waiting for Rowlist to have focus');

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
      await ecp.sendKeyPress(ecp.Key.Ok);
    });

    it('C6519 - Series - When series details page is opened then background poster should be displayed, @registered_user,@sdp_2, @smoke', async () => {

      // Verify we are on the details page
      let detailScreenTitle;
      await testUtils.retryWithTimeOut(async () => {
        detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
      });

      // Verify background poster is displayed
      await testUtils.retryWithTimeOut(async () => {
        const titleSeriesBackgroundPoster = await testUtils.getNodeForElement('titleSeriesBackgroundPoster');
        expect(titleSeriesBackgroundPoster).to.exist;
      });
    });


    it('C4192 - Series - No History - When "Add to My List" selected then series is added to queue,@registered_user,@sdp_1', async () => {

      // Verify we are on the details page
      let detailScreenTitle;
      await testUtils.retryWithTimeOut(async () => {
        detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
      });


      // Press Add to My List Button
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');

      // Check the My List container exists
      await ecp.sendKeyPress(ecp.Key.Back, { count: 4 });
      await utils.sleep(3000);
      await testUtils.retryWithTimeOut(async () => {
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        expect(leftNavHomeButton.visible).to.equal(true);
      });
      await ecp.sendKeyPress(ecp.Key.Down);
      await ecp.sendKeyPress(ecp.Key.Ok);
      await utils.sleep(2000);
      

      // Check we are on the My Stuff page
      await testUtils.retryWithTimeOut(async () => {
        const myStuffCallToAction = await testUtils.getNodeForElement('myStuffCallToAction');
        expect(myStuffCallToAction).to.exist;
      });
      await ecp.sendKeyPress(ecp.Key.Down);

      // Check we are on the My List row


      // Find My Stuff Grid
      const index = await testUtils.findRowIndexWithTitle('myStuffGrid', 'My List');
      const myStuffGrid = await odc.getValue(testUtils.getElementKeyPath('myStuffGrid', {responseMaxChildDepth:3}));

      // Find the title of the video that was added to My List
      const myListItem = myStuffGrid.value.content.children[index].children[0];

      // Verify that the title that was added to My List is present on the My Stuff page
      expect (myListItem.TITLE).to.equal((detailScreenTitle.text));

    });


    it('C4193 Series - No History - When title is removed from queue then Remove From Queue changed to Add To Queue @sdp_1,@regression,@registered_user', async () => {
      await testUtils.startApplicationAtPage('tv', true);
      await ecp.sendKeyPress(ecp.Key.Ok);
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);

      // Select the Remove from my list button and verify that it changes to Add to My List
      await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
      await testUtils.retryWithTimeOut(async () => {
        await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
      });
    });


    it('C4194 - Series - No History - When episode is chosen then playback should triggered from the beginning @sdp_1,@smoke,@regression,@registered_user', async () => {
      // While on Series Details page, lets play and check playback starts from the beginning
      await ecp.sendKeyPress(ecp.Key.Ok);
      await verifyPLayFromBeginning();
      await ecp.sendKeyPress(ecp.Key.Back); // Back to Details page
    });


    it('C4200 - Series - With History - When episode is played back from bookmark then playback will resume from saved history @registered_user,@sdp_1,@regression', async () => {
      // Verify we are on the details page
      let detailScreenTitle;
      await testUtils.retryWithTimeOut(async () => {
        detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
      });


      // Verify resume
      await verifyResumeWithinRange();

      // Back to Details page
      await ecp.sendKeyPress(ecp.Key.Back);

    });

    it('C141195 Selecting YMAL video on Details page after viewing should work - Series,@sdp_1', async () => {
      // Verify we are on the details page
      let detailScreenTitle;
      await testUtils.retryWithTimeOut(async () => {
        detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
      });

      // Select Play button
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Call to createHistory function
      await createHistory();

      // Back out of the video player to land on Details page
      await ecp.sendKeyPress(ecp.Key.Back);

      // Navigate down to YMAL
      await ecp.sendKeyPress(ecp.Key.Down, { count: 7 });
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Make sure we see the play button and then press it
      await testUtils.selectAndVerifyDetailPageMenuItem('play');

      // Verify it works from the YMAL title
      await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);

    });
  }); //Close describe Series Details page

}); // Close describe Details page

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
    await ecp.sendKeyPress(ecp.Key.Ok); // selecting the title

    //
    await testUtils.selectAndVerifyDetailPageMenuItem('play');  // verify the play button and press it
    await createHistory(); // create history function is called
*/

// Create history function
async function createHistory() {
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
  await ecp.sendKeyPress(ecp.Key.Forward, { count: 3 });
  await utils.sleep(3000);
  await ecp.sendKeyPress(ecp.Key.Play);
}

// Play from Beginning check function
async function verifyPLayFromBeginning() {
  // Press Play and check playback
  await testUtils.selectAndVerifyDetailPageMenuItem('play');
  await testUtils.expectPlayerStateToEventuallyEqual('play', 5000);

  // Verify Movie title playback starts from beginning
  const position = await testUtils.getPlayerPosition();
  expect(position).to.be.greaterThanOrEqual(0);
  expect(position).to.be.lessThan(5000);
}

async function verifyResumeWithinRange() {
  await ecp.sendKeyPress(ecp.Key.Play);// PLay to create history
  await createHistory(); // Create history function
  const currentposition = await testUtils.getPlayerPosition();
  await utils.sleep(2000);
  await ecp.sendKeyPress(ecp.Key.Back);


  // Select Resume and check for playback
  await testUtils.selectAndVerifyDetailPageMenuItem('resume');
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);

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
}
