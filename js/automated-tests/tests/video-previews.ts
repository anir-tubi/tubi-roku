import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';


describe('Video Preview', function () {
  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/257895
  it('C257895 - Verify that High TVT Evergreen titles will have Video Preview clips @videopreview', async () => {
    const user = await testUtils.createRegisteredUser();
    await user.addContentToWatchList({
      id: '342067',
      type: 'movie'
    });
    await testUtils.startApplicationAtPage('home', { user: user });

    // Now find where the My List Row is and jump to it
    const myListIndex = await testUtils.jumpToRowWithTitle('homeScreenRowList', 'My List');

    // Get the video preview url for this content
    const args = testUtils.getElementKeyPath('homeScreenRowList', {
      responseMaxChildDepth: 1
    });

    args.keyPath += `.content.${myListIndex}`;
    const { value: row } = await odc.getValue(args);
    const json = JSON.parse(row.json);
    const videoPreviewUrl = json[row.children[0].id].video_preview_url;

    await testUtils.retryWithTimeOut(async () => {
      const args = testUtils.getElementKeyPath('previewVideoPlayer');
      args.keyPath += `.content`;
      const { value: content } = await odc.getValue(args);
      expect(content?.URL).to.equal(videoPreviewUrl);
    });

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 10000);

    // Go to the detail screen
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 10000);
  });

  // https://tubi.testrail.io/index.php?/cases/view/257900
  it('C257900 - Ensure background image of the title transition automatically into a Video Preview clip immediately upon hovering over a Preview @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video is playing
    await checkForPreview(); 

  });

  // https://tubi.testrail.io/index.php?/cases/view/257901
  it('C257901 - Verify that if the user access details page during Video Preview we continue to show this clip. @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video is playing
    await checkForPreview();

    // Go to details page and verify that video preview continues
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000); // Need sleep to see Screen title

    // Verify we are on the details page
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
    const detailScreenPanel = await testUtils.getNodeForElement('detailScreenPanel');
    expect(detailScreenPanel.opacity).to.be.equal(1);
    

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 10000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/257902
  it('C257902 - Verify when user transitions from Video Preview > Details > HomeGrid the preview continue to play if clip did not end. @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video is playing
    await checkForPreview();

    // Go to details page and verify that video preview continues
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 5000);

    // Back to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 5000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/264595
  it('C264595 - Ensure Registered users have access to turn off Video preview feature from settings @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    //Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Open settings
    await shared.openSettings();

    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Go back to home page and verify that autoplay is off
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Verify that video preview is not playing
    const player = await ecp.getMediaPlayer();
    expect(player.state).to.not.equal('play');
    expect(player.state).to.not.equal('pause');
    expect(player.state).to.not.equal('buffer');


  });

  // https://tubi.testrail.io/index.php?/cases/view/345985
  it('C345985 - When the video preview ends the user should autoplay directly into the movie with prompt. @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video is playing
    await checkForPreview();

    // Let the preview end
    await utils.sleep(90000); // IMPROVEMENT with helper (See to End)

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 10000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/264838
  it('C264838 - Access Kids Mode and ensure the behavior of the Video Preview mirrors that of the non-kids mode @videopreview', async () => {
    
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open Kids Mode
    await openKidsMode();

    // Navigate right to home page focus
    await utils.sleep(1500);
    await ecp.sendKeypress(ecp.Key.Right);
  
    // Verify that video is playing
    await checkForPreview();

    // Let the preview end
    await utils.sleep(90000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 5000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/275042
  it('C275042 - Roku: Guest Users should be prompted to sign in if they choose to turn off autoplay preview in Settings @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Are we on Settings page?
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');


    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000); // Improvement
    // const autoplayPreviewOff = await testUtils.getNodeForElement('autoplayPreviewOff');
    // expect(autoplayPreviewOff.visible).to.be.true;

    // Expect Sign In dialog box
    const autoPlaySignInDialogMessage = await testUtils.getNodeForElement('autoPlaySignInDialogMessage');
    expect(autoPlaySignInDialogMessage.visible).to.be.true;
    const signInButton = await testUtils.getNodeForElement('signInButton');
    expect(signInButton.visible).to.be.true;



  });

  // https://tubi.testrail.io/index.php?/cases/view/494418
  it('C494418 - Video Preview should not play after last title in Continue Watching is removed from My Stuff. @videopreview', async () => {

    // Create a user with one title with history
    const user = await testUtils.createRegisteredUser();
    const movieContent = await user.getContent().ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContent, 500);
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff
    await ecp.sendKeypress(ecp.Key.Left);

    // Check for left nav home button
    await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButton');
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Down, {count:2});
    await testUtils.waitForElementToFullyShowOnScreen('myStuffLeftNav');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Let's check for My Stuff page, CW row here
    await testUtils.waitForElementToFullyShowOnScreen('myStuffContinueWatchingRow');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter Details page and remove history
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);

    // 2nd movie
    await testUtils.waitForElementToFullyShowOnScreen('myStuffContinueWatchingRow');
    await utils.sleep(5000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);

    await testUtils.waitForElementToFullyShowOnScreen('emptyMyStuffButton');

    // Check for presence of Video Player
    const previewVideoPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
    expect(previewVideoPlayer.visible).to.be.false;
  });

   // https://tubi.testrail.io/index.php?/cases/view/257906
   it('C257906 - Ensure when user hovers to the next video preview supported title the preview changes to that new title @videopreview', async () => {
    
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate right to home page focus
    await ecp.sendKeypress(ecp.Key.Right);

    // Verify that video is playing
    await checkForPreview();

  });
});



  async function openKidsMode() {

    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(3000); // Adding sleeps temporary // Improvement - try to work around sleeps
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.be.true;
  }

  async function checkForPreview() {
    const rowIndex = 0;
    const content = await testUtils.getRowListRowItemsContent('homeScreenRowList', 0);
    for (const [itemIndex, item] of content.entries()) {
      if (item.video_preview_url !== '') {
        await testUtils.jumpToRowItem('homeScreenRowList', [rowIndex, itemIndex]);
        break;
      }
    }
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 5000);
    }