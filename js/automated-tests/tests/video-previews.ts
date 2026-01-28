import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';
import type { ElementOrElementId } from '../../../automated-tests-config/elements';


describe('Video Preview', function () {
  // Increase timeout for video preview tests as they wait for video playback
  this.timeout(300000); // 5 minutes

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/257895
  it('C257895 - Verify that High TVT Evergreen titles will have Video Preview clips @videopreview', async () => {
    const user = await testUtils.createRegisteredUser();
    await user.addContentToWatchList({
      id: '342067',
      type: 'movie'
    });
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Scroll down to find My List row (it might not be initially visible)
    await shared.scrollDownToFindRow({ slug: 'queue' });

    // Now get the index of the My List row
    const myListIndex = await testUtils.findRowIndexWithSlug('videoTitlesRowList', 'queue');

    // Get the video preview url for this content
    const args = testUtils.getElementKeyPath('videoTitlesRowList', {
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

      expect(content?.url).to.equal(videoPreviewUrl);
    });

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Go to the detail screen
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
  });

  // https://tubi.testrail.io/index.php?/cases/view/257900
  it('C257900 - Ensure background image of the title transition automatically into a Video Preview clip immediately upon hovering over a Preview @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Verify that video is playing
    await checkForPreview();

  });

  // https://tubi.testrail.io/index.php?/cases/view/257901
  it('C257901 - Verify that if the user access details page during Video Preview we continue to show this clip. @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

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
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/257902
  it('C257902 - Verify when user transitions from Video Preview > Details > HomeGrid the preview continue to play if clip did not end. @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Verify that video is playing
    await checkForPreview();

    // Go to details page and verify that video preview continues
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 5000);

    // Back to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 5000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/264595
  it('C264595 - Ensure Registered users have access to turn off Video preview feature from settings @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Turn off video previews
    await shared.enablePreviewInSettings(false);

    // Go back to home page and verify that autoplay is off
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Verify that video preview is not playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', ['stopped', '', 'none']);
  });

  // https://tubi.testrail.io/index.php?/cases/view/345985
  it('C345985 - When the video preview ends the user should autoplay directly into the movie with prompt. @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Verify that video is playing
    await checkForPreview();

    // Let the preview end (wait for duration + 2 seconds)
    const videoPlayerNode = await testUtils.getNodeForElement('previewVideoPlayer');
    await utils.sleep((videoPlayerNode.duration * 1000) + 3000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/264838
  it('C264838 - Access Kids Mode and ensure the behavior of the Video Preview mirrors that of the non-kids mode @videopreview', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Open Kids Mode
    await openKidsMode();

    // Navigate right to home page focus
    await utils.sleep(2500);
    await ecp.sendKeypress(ecp.Key.Right, { wait: 1500 });
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });

    // Verify that video is playing
    await checkForPreview('homeScreenRowList');

    // Let the preview end (wait for duration + 2 seconds)
    const videoPlayerNode = await testUtils.getNodeForElement('previewVideoPlayer');
    await utils.sleep((videoPlayerNode.duration * 1000) + 2000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);

  });

  // https://tubi.testrail.io/index.php?/cases/view/275042
  it('C275042 - Roku: Guest Users should be prompted to sign in if they choose to turn off autoplay preview in Settings @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Are we on Settings page?
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');


    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
    // Expect Sign In dialog box
    await testUtils.waitForElementToFullyShowOnScreen('autoPlaySignInDialogMessage');
    const autoPlaySignInDialogMessage = await testUtils.getNodeForElement('autoPlaySignInDialogMessage');
    expect(autoPlaySignInDialogMessage.visible).to.be.true;

    await testUtils.waitForElementToShowOnScreen('dialogBoxSignInButton');
    const signInButton = await testUtils.getNodeForElement('dialogBoxSignInButton');
    expect(signInButton.visible).to.be.true;
  });

  // https://tubi.testrail.io/index.php?/cases/view/494418
  it('C494418 - Video Preview should not play after last title in Continue Watching is removed from My Stuff. @videopreview', async () => {

    // Create a user with one title with history
    const user = await testUtils.createRegisteredUser();
    const movieContent = await user.getContent().ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContent, 500);
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await shared.openMyStuff();

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

    await testUtils.waitForElementToHaveFocus('myStuffAllEmptyUIMenu', 'Timed out waiting for My Stuff All Empty UI Menu to have focus');
    await testUtils.waitForElementToNotShowOnScreen('previewVideoPlayer');
  });

  // https://tubi.testrail.io/index.php?/cases/view/257906
  it('C257906 - Ensure when user hovers to the next video preview supported title the preview changes to that new title @videopreview', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Navigate right to home page focus
    await ecp.sendKeypress(ecp.Key.Right);

    // Verify that video is playing
    await checkForPreview();

  });

  // https://tubi.testrail.io/index.php?/cases/view/676756
  it('C676756 - "Autoplay Previews" setting defaults to "on" when user signs out @videopreview', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await shared.enablePreviewInSettings(false);

    // Sign out
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Hi ');
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('settingsScreen');
    await ecp.sendKeypress(ecp.Key.Ok);
    const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(signOutVerificationModalMessage.text).to.equal('You are about to sign out of your Tubi account.');
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await utils.sleep(5000);
    await shared.ensurePlayableContentFocused();
    // Verify that video is playing
    await checkForPreview();

    // Check Preview in Settings
    await ecp.sendKeypress(ecp.Key.Back);
    await shared.openSettings();
    await testUtils.waitForCurrentScreenToEqual('settingsScreen');

    await testUtils.jumpToRowWithTitle('settingsMenu', 'Autoplay Controls');
    await testUtils.waitForElementToFullyShowOnScreen('autoplayPreviewOn');
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('previewOnCheckMark');
  });

  // https://tubi.testrail.io/index.php?/cases/view/705821
  it('C705821- Roku Autoplay OFF - Video previews are disabled, @autoplay @videopreview @manual_regression', async () => {

    // Start app with Roku's autoplay setting disabled
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, isAutoplayEnabled: false });

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Verify that video preview is not playing (autoplay is disabled)
    const position = await shared.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length > 0) {
      await shared.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
      await utils.sleep(1000);
    }

    const previewVideoPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
    expect(previewVideoPlayer.state).to.not.be.oneOf(['playing', 'buffering'])

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

async function checkForPreview(listElement: ElementOrElementId = 'videoTitlesRowList') {
  const position = await shared.findContentPositionInRowListThatContainsVideoPreview(listElement, true, 5);
  if (position.length === 0) {
    throw new Error(`Could not find content with video preview in ${listElement}`);
  }
  await shared.jumpToRowListPosition(listElement, position[0], position[1]);
  await utils.sleep(1000);
  await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 5000);
}
