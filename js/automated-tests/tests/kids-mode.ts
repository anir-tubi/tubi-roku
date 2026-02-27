import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { ContentRatings, testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';
import { moveToGrid } from '../analytics/utils/helpers';

describe('Kids Mode', function () {
  // https://tubi.testrail.io/index.php?/cases/view/537396
  it('C537396 - Guest User - Toggle ON - Home Screen - When User Switches Parental Control to Older Kids Then Exit Kids is still present, @kidsmode_guest', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * 
     * Test Steps:
     * 1. Launch app as guest user
     * 2. Wait for home screen row list to have focus
     * 3. Enter Kids Mode from left nav
     * 4. Open Settings from Kids Mode
     * 5. Sign in and select Older Kids from Parental Controls
     * 6. Verify Older Kids PC Settings Change dialog appears
     * 7. Navigate left to left nav
     * 8. Verify Exit Kids button is grayed out (user must stay in Kids Mode)
     */

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Open Settings
    await shared.openSettings();

    // Guest Select Older Kids ParentalControls
    await guestSelectOlderKidsParentalControls();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKidsMessage = await testUtils.getNodeForElement('parentalControlsSettingsOlderKidsMessage');
    expect(parentalControlsSettingsOlderKidsMessage.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();
  });

  // https://tubi.testrail.io/index.php?/cases/view/537398
  it('C537398b - Guest User - Toggle ON - Home Screen - When User Switches Parental Control to Little Kids Then Kids Mode icon is now grayed out, @kidsmode_guest', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * 
     * Test Steps:
     * 1. Launch app as guest user
     * 2. Wait for home screen row list to have focus
     * 3. Enter Kids Mode from left nav
     * 4. Open Settings from Kids Mode
     * 5. Sign in and select Little Kids from Parental Controls
     * 6. Verify Little Kids PC Settings Change dialog appears
     * 7. Navigate left to left nav
     * 8. Verify Exit Kids button is grayed out (user must stay in Kids Mode)
     */

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Open Settings
    await shared.openSettings();

    // Guest Select Little Kids ParentalControls
    await guestSelectLittleKidsParentalControls();

    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
    expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();

  });

  // https://tubi.testrail.io/index.php?/cases/view/535860
  it('C535860 - Registered User - Toggle ON - When user switches to Kids Mode then Home Screen filters out non-kids title, @kidsmode_registered', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await openKidsMode();
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForSideNavMenuToNotBeExpanded();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');

    for (const itemContent of rowItemsContent) {
      const rating = itemContent.ratings[0].value;
      const isAllowed = testHelpers.isKidsAppropriateRating(rating);
      expect(isAllowed).to.be.true;
    }

  });


  // https://tubi.testrail.io/index.php?/cases/view/537689
  it('C537689 -  Registered User - Toggle ON - Home Screen - When User Switches Parental Control to Older Kids Then the App Stays in Kids Mode, @kidsmode_registered', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Open Settings
    await kidsOpenSettings();

    // Choose PC Older Kids
    await selectOlderKidsFromParentalSettings();

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();

  });

  // https://tubi.testrail.io/index.php?/cases/view/219725
  it('C537690 - Registered User - Toggle ON - Home Screen - When User Switches Parental Control to Little Kids Then the App Stays in Kids Mode, @kidsmode_registered', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open Kids Mode
    await openKidsMode();

    // Open Settings
    await shared.openSettings();

    // Select Little Kids ParentalControls
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3, wait: 100 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we on the Kid's mode password screen?
    await testUtils.waitForElementToFullyShowOnScreen('passwordText');

    // Enter Password
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 100 });
    await utils.sleep(4000); // Improvement - try to work around sleeps
    const keyboardBackButton = await testUtils.getNodeForElement('keyboardBackButton');
    if (keyboardBackButton.opacity == 1) {
      await ecp.sendKeypress(ecp.Key.Right);
    }
    await ecp.sendKeypress(ecp.Key.Ok);

    // Parental Controls Settings Change
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsLittleKids');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();

  });

  // https://tubi.testrail.io/index.php?/cases/view/537393
  it('C537393 Kids Mode - Registered User - Toggle ON - Parental Control ON - Older Kids- modal dialog, @kidsmode_registered', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();
    await kidsOpenSettings();

    // Registered select Older kids from PC Settings page
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsHeader');
    await selectOlderKidsFromParentalSettings();

    // Are we on the Kid's mode password screen?
    await utils.sleep(2000);
    const kidsModePasswordTest = await testUtils.getNodeForElement('passwordText');
    expect(kidsModePasswordTest.visible).to.be.true;

    // Call function to Enter Password for PC Settings Change
    await enterPasswordSettingsChange();

    // Verify Older Kids PC Settings Change dialog
    const parentalControlsSettingsOlderKidsMessage = await testUtils.getNodeForElement('parentalControlsSettingsOlderKidsMessage');
    expect(parentalControlsSettingsOlderKidsMessage.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');


  });

  // https://tubi.testrail.io/index.php?/cases/view/535858
  it('C535858 - Registered User - Toggle OFF - Parental Control OFF - When user opens the app then Kids Icon should be displayed, @kidsmode_registered', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Open Settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Verify Adult
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000); // Improvement - try to work around sleeps
    await ecp.sendKeypress(ecp.Key.Ok);
    const adultControlSelected = await testUtils.getNodeForElement('adultControlSelected');
    expect(adultControlSelected.visible).to.be.true;

    // Verify that Kid's mode option in left nav is not grayed out and is accessible
    await ecp.sendKeypress(ecp.Key.Back, { count: 4 });
    await checkForKidsModeAdult();

  });

  // https://tubi.testrail.io/index.php?/cases/view/66347
  it('C66347 - Kids Mode does not persist - Registered user, @kidsmode_registered', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the Exit Kids button not grayed out?
    await checkForKidsModeNotGrayed();

    // Exit app
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok, { count: 2 });
    await testUtils.waitForElementToShowOnScreen('kidsExitPrompt');
    await ecp.sendKeypress(ecp.Key.Ok);


    // Relaunch app
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Check that we are no longer in Kids mode
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    const kidsLeftNavOption = await testUtils.getNodeForElement('kidsLeftNavOption');
    expect(kidsLeftNavOption.text).to.be.equal('Kids');
  });

  // https://tubi.testrail.io/index.php?/cases/view/548495
  it('C548495 - Kids Mode - Launch Tubi, enter Kids Mode, select movie with trailer, watch trailer, then watch movie @kids_trailer @manual_regression', async () => {
    // Launch Tubi
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen');

    // From left nav enter Kids Mode
    await openKidsMode();

    // Navigate back to home screen content
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForSideNavMenuToNotBeExpanded();
    // In Kids mode, the home screen uses homeScreenRowList instead of videoTitlesRowList
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist focus');

    // Select a Movie with trailer
    await focusOnVideoTileTrailer();
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify we're on detail screen
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Detail screen not displayed');
    const titleElement = await testUtils.getNodeForElement('detailScreenTitle');

    // Select Watch Trailer button
    // await selectWatchTrailerButton();
    await testUtils.selectAndVerifyDetailPageMenuItem('watchTrailer');

    // Verify trailer starts playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    await utils.sleep(800);

    await ecp.sendKeypress(ecp.Key.Down);

    await ecp.sendKeypress(ecp.Key.Left, { count: 4 });

    //Select Watch Movie
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    expect(videoPlayerScreen.position).to.not.be.greaterThan(10);
    console.log(videoPlayerScreen.position);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765060
  it('C765060 - Video preview play when title is in focus (Kids Mode) @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. In left nav, select "Kids".
     * 3. In left nav, select "Categories".
     * 4. Select any category.
     * 5. Focus on a title that has a video preview.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Navigate to Kids Mode using helper
    await shared.openKidsMode();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000); // Kids home screen
    await utils.sleep(1000);

    // Navigate to Categories using helper
    await testHelpers.navigateToCategories();
    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });

    await utils.sleep(1000);

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for the first poster to be selected
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Find and navigate to a title with video preview using helper
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoriesScreenContentGrid', true, 4);
    expect(position.length).to.equal(2, 'Could not find content with video preview in Kids Mode');

    // Verify video preview is playing in Kids Mode category screen
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('categoriesScreenContentGrid');
    const playerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(playerContent).to.exist;
    expect(playerContent.id).to.equal(focusedContent.id, 'Preview player should be playing the focused content in Kids Mode');
  });

  // https://tubi.testrail.io/index.php?/cases/view/145905
  it('C145905 - Kids Mode - When user signs out while in Kids mode, non-Kids UI integrity is maintained, @kidsmode_registered', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();
    await ecp.sendKeypress(ecp.Key.Left);

    // Is the Exit Kids button not grayed out?
    await checkForKidsModeNotGrayed();

    // Sign out
    await ecp.sendKeypress(ecp.Key.Rewind);
    await ecp.sendKeypress(ecp.Key.Ok);


    await testUtils.waitForCurrentScreenToEqual('settingsScreen', 10000);
    await testUtils.waitForElementToHaveFocus('settingsMenu', 'Timed out waiting for Settings menu to have focus');

    // Wait for Sign Out button on Settings page of Kids mode
    const signOutButtonKidsMode = await testUtils.getNodeForElement('signOutButtonKidsMode');
    expect(signOutButtonKidsMode.text).is.equal('Sign Out');

    // Press OK and wait for verification modal
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToShowOnScreen('signUpExitDialog', 'Timed out waiting for Sign out verification modal message to be shown');
    await testUtils.waitForElementToHaveFocus('dialogBoxButtonList', 'Timed out waiting for Dialog box button list to have focus');
    const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(signOutVerificationModalMessage.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Ok);
    // Check that we are no longer in Kids mode
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    // Scroll down to find "On Now" row (due to pagination)
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels' });
  });

});

async function openKidsMode() {
  await ecp.sendKeypress(ecp.Key.Left);
  await ecp.sendKeypress(ecp.Key.Up);
  await ecp.sendKeypress(ecp.Key.Up);
  // IMPROVEMENT remove need for this by addressing the weird behavior when animation ends
  await utils.sleep(500); // Adding sleeps temporary
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('exitKidsOption');
}

async function signInAndSetParentalControlPassword() {
  // Sign in with existing registered user
  await ecp.sendKeypress(ecp.Key.Ok);
  await utils.sleep(10000); // Wait for Roku sign-in dialog
  await ecp.sendKeypress(ecp.Key.Back); // Cancel Roku dialog to use email/password

  // Create registered user
  const user = await testUtils.createRegisteredUser();

  // Enter email
  await testUtils.waitForElementToShowOnScreen('emailInputScreenHeader', 'Email input screen header not found', 15000);
  await utils.sleep(2000);
  await ecp.sendText(user['userInfo'].email);
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await ecp.sendKeypress(ecp.Key.Ok);

  // Enter password
  await testUtils.waitForElementToShowOnScreen('signInScreenPageHeader', 'Sign In screen page header not found', 15000);
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendText('111111');
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Ok);

  // Enter password for Parental Controls
  await testUtils.waitForElementToFullyShowOnScreen('pcPasswordEntryBox', 'Password box not found', 10000);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendText('111111');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(1500);
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function guestSelectOlderKidsParentalControls() {
  // Select Older Kids Parental Controls
  await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('dialogBoxSignInButton');

  await signInAndSetParentalControlPassword();
}

async function guestSelectLittleKidsParentalControls() {
  // Select Little Kids Parental Controls
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
  await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('dialogBoxSignInButton');

  await signInAndSetParentalControlPassword();
}

async function kidsOpenSettings() {
  await ecp.sendKeypress(ecp.Key.Left);
  await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButton', 'Left Nav home button not found', 10000);
  await ecp.sendKeypress(ecp.Key.Down, { count: 7 });
  await ecp.sendKeypress(ecp.Key.Ok);

}

async function enterPasswordSettingsChange() {
  // Enter Password for PC Settings Change
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendText('111111');
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(4000);
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Left);
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectOlderKidsFromParentalSettings() { await shared.selectParentalControlLevel('olderKids'); }
async function selectLittleKidsFromParentalSettings() { await shared.selectParentalControlLevel('littleKids'); }

async function checkForKidsModeGrayed() {
  const exitKidsGrayedOut = await testUtils.getNodeForElement('exitKidsGrayedOut');
  expect(exitKidsGrayedOut.text).to.equal('Exit Kids');
  expect(exitKidsGrayedOut.opacity).to.be.lessThan(1);
}

async function checkForKidsModeNotGrayed() {
  // Wait until Exit Kids option is fully visible (opacity = 1)
  await testUtils.untilTrue(async () => {
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    return exitKidsOption.text === 'Exit Kids' && exitKidsOption.opacity === 1;
  }, 'Exit Kids option should be fully visible with opacity 1', 5000);
}

async function checkForKidsModeAdult() {
  await testUtils.waitForElementToFullyShowOnScreen('exitKidsOption');
}

async function focusOnVideoTileTrailer() {
  const rowIndex = 0;
  const content = await testUtils.getRowListRowItemsContent('homeScreenRowList', 0);
  for (const [itemIndex, item] of content.entries()) {
    if (item.hasTrailer == true) {
      await testUtils.jumpToRowItem('homeScreenRowList', [rowIndex, itemIndex]);
      break;
    }
  }
}

async function selectCategories() {
  await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
  await utils.sleep(1000);
  await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButtonSelected');
  await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });
}


async function focusOnVideoTileWithPreviewUrlInCategoryGrid(categoryContent: any[]) {
  let previewFound = false;

  for (const [itemIndex, item] of categoryContent.entries()) {
    if (item.videoPreviewUrl !== '' && item.videoPreviewUrl !== null && item.videoPreviewUrl !== undefined) {
      await testUtils.jumpToRowIndex('channelCategoryGrid', itemIndex);
      previewFound = true;
      break;
    }
  }

  if (!previewFound) {
    // Focus on first item if no preview found
    await testUtils.jumpToRowIndex('channelCategoryGrid', 0);
  }

  return previewFound;
}

