import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';


describe('Application Launch', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await testUtils.jumpToRowWithTitle('videoTitlesRowList', 'Featured');
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
    await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
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
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await testUtils.goToPage('settings');
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToShowOnScreen('adultControlSelected');
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Validate Enter Password Page and message
    const enterPasswordMessage = await testUtils.getNodeForElement('enterPasswordMessage');
    expect(enterPasswordMessage.text).to.equal('Enter Password to update parental controls');

    // Send password and click Continue
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500); // moving too fast here, sometimes when pressing down lands on Back, others Continue
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
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
    await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
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
    await ecp.sendKeypress(ecp.Key.Play);
    await shared.createHistory(900000, true);
    await ecp.sendKeypress(ecp.Key.Back);

    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');

    // Exit app and restart
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await testUtils.goToPage('movies');
    await testUtils.findRowIndexWithTitle('movieScreenRowList', 'Featured');
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Test for resume button (Roku retains resume button for 24 hours)
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton', 'Resume Playing button not found', 8000);
  });



  // https://tubi.testrail.io/index.php?/cases/view/129714
  it('C129714 - Logged in user should not see Registration Prompt Container in Movies filter @application_launch @registered_user', async () => {

    // Launch app
    await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await ecp.sendKeypress(ecp.Key.Play);

    // Create CW row
    await shared.createHistory(900000, true);
    await ecp.sendKeypress(ecp.Key.Back);

    await testUtils.waitForCurrentScreenToEqual('detailScreen');
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');

    // Back out to Details page
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');


    // Jump To Continue Watching Row
    await shared.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'movieScreenRowList' });
    await testUtils.waitForElementToFullyShowOnScreen('infoPanelTitleMovies');
    const infoPanelTitleMovies = await testUtils.getNodeForElement('infoPanelTitleMovies');
    expect(infoPanelTitleMovies.text).to.not.equal('Sign Up to Save Your Progress');
  });

  // https://tubi.testrail.io/index.php?/cases/view/114199
  it('C114199 - Registration Prompt in Continue Watching Container - Homescreen - Navigate to Continue Watching Container @application_launch', async () => {
    // Launch as guest
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    // Check for presence of Movies Grid
    await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');

    // Jump To Continue Watching Row (validates row exists and is focused)
    await shared.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    const rowIndex = await testUtils.findRowIndexWithSlug('videoTitlesRowList', 'continue_watching');

    // Construct dynamic element objects with runtime row index
    const titleElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#RowList.${rowIndex}.items.0.#contentSection.#title`
    };
    const descriptionElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#RowList.${rowIndex}.items.0.#contentSection.#description`
    };
    const buttonElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#RowList.${rowIndex}.items.0.#contentSection.#signUpButton`
    };
    const buttonLabelElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#RowList.${rowIndex}.items.0.#contentSection.#signUpButton.#label`
    };

    // Validate registration CTA title
    const titleNode = await testUtils.getNodeWithDynamicPath(titleElement, 10000);
    expect(titleNode.visible).to.equal(true, 'Guest user CW tile title should be visible');
    expect(titleNode.text).to.equal('Sign Up to Save Your Progress', 'CW tile should display "Sign Up to Save Your Progress" title');

    // Validate registration CTA description
    const descriptionNode = await testUtils.getNodeWithDynamicPath(descriptionElement, 10000);
    expect(descriptionNode.visible).to.equal(true, 'Guest user CW tile description should be visible');
    expect(descriptionNode.text).to.equal('Pick up right where you left off next time you play a TV Series or a Movie.',
      'CW tile should display correct description');

    // Validate sign up button is present and visible
    const buttonNode = await testUtils.getNodeWithDynamicPath(buttonElement, 10000);
    expect(buttonNode.visible).to.equal(true, 'Sign up button should be visible');

    // Validate button label text
    const buttonLabelNode = await testUtils.getNodeWithDynamicPath(buttonLabelElement, 10000);
    expect(buttonLabelNode.text).to.include('Sign Up to Save Progress', 'Button label should contain "Sign Up to Save Progress"');
  });


});


