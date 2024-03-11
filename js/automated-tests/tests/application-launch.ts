import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';


describe('Application Launch', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
    await testUtils.waitForAppLaunchBeaconToFire();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
  });

  // https://tubi.testrail.io/index.php?/cases/view/535807
  it('C535807 User Signed in - Homescreen Display @registered_user,@smoke,@application_launch @application_launch', async () => {
    await testUtils.retryWithTimeOut(async () => {
      const sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
      expect(sideNavSignedInLabel.text).to.contain('Hi');
    });
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/edit/535837
  it('C535837 - Application Launch - When user opens the application after registering as a new user then the home screen is displayed @application_launch', async () => {
    await testUtils.findRowIndexWithTitle('homeScreenRowList', 'Featured');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535748
  it('C535748 - Application Launch - Registered User - When user tries to play a title after user has registered device then the title should play on tubi @application_launch, @smoke', async () => {
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/70718
  it('C70718 - Sign out after setting Parental Controls @application_launch', async () => {
    // Go to Settings page and select Older Kids
   // await testUtils.goToPage('settings');
    await testUtils.goToPage('settings');
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToShowOnScreen('adultOptionChecked');
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Validate Enter Password Page and message
    const enterPasswordMessage = await testUtils.getNodeForElement('enterPasswordMessage');
    expect(enterPasswordMessage.text).to.equal('Enter Password to update parental controls');

    // Send password and click Continue
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500); // moving too fast here, sometimes when pressing down lands on Back, others Continue
    await ecp.sendKeypress(ecp.Key.Down, { count: 3});
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Validate Older Kids modal message, back out to Left Nav and Check Exit Kids menu item is grayed out
    await testUtils.retryWithTimeOut(async () => {
      const settingsScreen = await testUtils.getNodeForElement('settingsScreen');
      expect(settingsScreen.visible).to.be.true;
    });
    const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
    expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Back);
    const exitKidsGrayedOut = await testUtils.getNodeForElement('exitKidsGrayedOut');
    expect(exitKidsGrayedOut.visible).to.equal(true);

    // Sign out to check that we are not in Kids mode now
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.retryWithTimeOut(async () => {
      const settingsScreen = await testUtils.getNodeForElement('settingsScreen');
      expect(settingsScreen.visible).to.be.true;
    });
    const signOutButtonKidsMode = await testUtils.getNodeForElement('signOutButtonKidsMode');
    expect(signOutButtonKidsMode.text).to.equal('Sign Out');
    await ecp.sendKeypress(ecp.Key.Ok);
    const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(signOutVerificationModalMessage.text).to.equal('You are about to sign out of your Tubi account.');
    await ecp.sendKeypress(ecp.Key.Ok);
    const node = await testUtils.getNodeForElement('topNavRecommendedWhiteLabel');
    await testUtils.findRowIndexWithTitle('homeScreenRowList', 'Featured');
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/116528
  it('C116528_1 - Resume Watching - Guest User - Movie - User plays back content, exits and selects content again, @application_launch', async () => {
    // Start Open Movies
    await testUtils.startApplicationAtPage('movies');

    // Check for presence of Movies Grid
    await testUtils.findRowIndexWithTitle('movieScreenRowList', 'Featured');
    // End Open Movies

    // Open and play a title, create history, then back to details page to check for "Resume" button
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Play);
    await createHistory();
    await ecp.sendKeypress(ecp.Key.Back);
    const resumePlayingButton = await testUtils.getNodeForElement('resumePlayingButton');
    expect(resumePlayingButton.visible).to.equal(true);

    // Exit app and restart
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    expect(testUtils.findRowIndexWithTitle('homeScreenRowList', 'Featured'));

    // Test for resume button (Roku retains resume button for 24 hours)
    await ecp.sendKeypress(ecp.Key.Ok);
    expect(resumePlayingButton.visible).to.equal(true);
  });



  // https://tubi.testrail.io/index.php?/cases/view/129714
  it('C129714 - Logged in user should not see Registration Prompt Container in Movies filter @application_launch @registered_user', async () => {

    // Launch app
    await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Play title
    await ecp.sendKeypress(ecp.Key.Play);

    // Create CW row
    await createHistory();

    // Back out to Details page
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Jump To Continue Watching Row
    await testUtils.jumpToRowWithTitle('movieScreenRowList', 'Continue Watching');
    const movieScreenPoster = await testUtils.getNodeForElement('movieScreenPoster');
    expect(movieScreenPoster).to.exist;
  });

  // https://tubi.testrail.io/index.php?/cases/view/114199
  it('C114199 - Registration Prompt in Continue Watching Container - Homescreen - Navigate to Continue Watching Container @guest_user @application_launch', async () => {
    // Launch as guest
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    // Jump To Continue Watching Row
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');
    const signUpToSaveProgressDescription = await testUtils.getNodeForElement('signUpToSaveProgressDescription');
    expect(signUpToSaveProgressDescription.visible).to.be.true;

    // Check CW row title

    const continueWatchingRowContent = await testUtils.getCurrentlyFocusedGridItemContent('homeScreenRowList');
    expect(continueWatchingRowContent.title).to.equal('Sign Up to Save Your Progress');


  });

  // https://tubi.testrail.io/index.php?/cases/view/129714
  it('C129714 - Logged in user should not see Registration Prompt Container in Movies filter @application_launch @registered_user', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    const movieContent = await user.getContent().ofContentType('movie').retrieve({ limit: 5});
    await user.addContentToViewHistory(movieContent, 500);

    // Launch app with created user
    await testUtils.startApplicationAtPage('home', {user: user});
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Jump To Continue Watching Row (verify it is present)
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching',10000);
  // 
    const continueWatchingRowContent = await testUtils.getCurrentlyFocusedGridItemContent('homeScreenRowList');
    expect(continueWatchingRowContent.title).to.not.equal('Sign Up to Save Your Progress');
  });



});


async function createHistory() {
  const node = await testUtils.getNodeForElement('videoPlayerScreen');
  expect(node.visible).to.be.true;
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
  await ecp.sendKeypress(ecp.Key.Forward);
  await ecp.sendKeypress(ecp.Key.Forward);
  await ecp.sendKeypress(ecp.Key.Forward);
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Play);
  await utils.sleep(2000);
}
