import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { ContentRatings, testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Kids Mode', function () {
  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/537398
  it.skip('C537398 - Guest User - Toggle ON - Home Screen - When User Switches Parental Control to Older Kids Then Exit Kids is still present, @kidsmode_guest', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
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
    await ecp.sendKeypress(ecp.Key.Back, { count: 2, wait: 1000 });

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/537396
  it.skip('C537396 - Guest User - Toggle ON - Home Screen - When User Switches Parental Control to Older Kids Then Exit Kids is still present, @kidsmode_guest', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

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
  it.skip('C537398b - Guest User - Toggle ON - Home Screen - When User Switches Parental Control to Little Kids Then Kids Mode icon is now grayed out, @kidsmode_guest', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

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

  // https://tubi.testrail.io/index.php?/cases/view/537403
  it.skip('C537403- Guest User - Toggle ON - Categories Screen - When User Switches Parental Control to Older Kids Then the App Stays in Kids Mode, @kidsmode_guest', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Open Categories
    await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Open Settings from Categories
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await utils.sleep(4000);// Improvement - try to work around sleeps
    await ecp.sendKeypress(ecp.Key.Ok);

    //Sign In
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(4000); // Improvement - try to work around sleeps
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(4000); // Improvement - try to work around sleeps
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();
  });

  // https://tubi.testrail.io/index.php?/cases/view/537401
  it.skip('C537401 - Guest User - Toggle ON - Categories Screen - When User Switches Parental Control to Little Kids Then the App Stays in Kids Mode, @kidsmode_guest', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

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
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();

    // Is the Tubi Kid's logo present?
    const tubiKidsLogo = await testUtils.getNodeForElement('tubiKidsLogo');
    expect(tubiKidsLogo.uri).to.equal('pkg:/images/logo-kids-large.webp');


  });

  // https://tubi.testrail.io/index.php?/cases/view/535860
  it('C535860 - Registered User - Toggle ON - When user switches to Kids Mode then Home Screen filters out non-kids title, @kidsmode_registered', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await openKidsMode();
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForSideNavMenuToNotBeExpanded();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');

    for (const itemContent of rowItemsContent) {
      const rating = itemContent.ratings[0].value;
      const restrictedRatings = ['R', 'MA', 'PG-13', 'NR', 'TV-13'];
      expect(rating).to.not.be.oneOf(restrictedRatings);
    }

  });


  // https://tubi.testrail.io/index.php?/cases/view/537689
  it('C537689 -  Registered User - Toggle ON - Home Screen - When User Switches Parental Control to Older Kids Then the App Stays in Kids Mode, @kidsmode_registered', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Open Settings
    await ecp.sendKeypress(ecp.Key.Left);
    await kidsOpenSettings();

    // Choose PC Older Kids
    await selectOlderKidsFromParentalSettings();

    // Is the Exit Kids button grayed out?
    await checkForKidsModeGrayed();

  });

  // https://tubi.testrail.io/index.php?/cases/view/219725
  it('C537690 - Registered User - Toggle ON - Home Screen - When User Switches Parental Control to Little Kids Then the App Stays in Kids Mode, @kidsmode_registered', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

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
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();
    await ecp.sendKeypress(ecp.Key.Left);
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
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

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
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Is the Exit Kids button not grayed out?
    await checkForKidsModeNotGrayed();

    // Exit app
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok, { count: 2 });
    await testUtils.waitForElementToShowOnScreen('kidsExitPrompt');
    await ecp.sendKeypress(ecp.Key.Ok);


    // Relaunch app
    await testUtils.restartApplication();
    await testUtils.waitForAppLaunchBeaconToFire();
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Check that we are no longer in Kids mode
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    const kidsLeftNavOption = await testUtils.getNodeForElement('kidsLeftNavOption');
    expect(kidsLeftNavOption.text).to.be.equal('Kids');

  });

  // https://tubi.testrail.io/index.php?/cases/view/548495
  it('C548495 - Kids Mode - Launch Tubi, enter Kids Mode, select movie with trailer, watch trailer, then watch movie @kids_trailer', async () => {
    // Launch Tubi
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for home screen');

    // From left nav enter Kids Mode
    await openKidsMode();

    // Navigate back to home screen content
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000); // Wait for nav to close
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

  //https://tubi.testrail.io/index.php?/cases/view/765060
  it('C765060 - Kids Categories - Focus on title with video preview should start video preview @kids @categories @video_preview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    await selectCategories();

    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(2000);

    await testUtils.waitForElementToHaveFocus('channelCategoryGrid', 'Timed out waiting for channelGrid to have focus');


    await utils.sleep(800);

    const categoryContent = await testUtils.getAllGridItemsContent('channelCategoryGrid');

    await testUtils.jumpToRowIndex('channelCategoryGrid', 0);

    const previewFound = await focusOnVideoTileWithPreviewUrlInCategoryGrid(categoryContent);

    if (previewFound) {
      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 5000);
    } else {
      console.log(' No video preview found, focused on default content');
    }

  });

  // https://tubi.testrail.io/index.php?/cases/view/145905
  it('C145905 - Kids Mode - When user signs out while in Kids mode, non-Kids UI integrity is maintained, @kidsmode_registered', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await openKidsMode();

    // Is the Exit Kids button not grayed out?
    await checkForKidsModeNotGrayed();

    // Sign out
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Sign Out button on Settings page of Kids mode
    const signOutButtonKidsMode = await testUtils.getNodeForElement('signOutButtonKidsMode');
    expect(signOutButtonKidsMode.text).is.equal('Sign Out');

    // Press OK and wait for verification modal
    await ecp.sendKeypress(ecp.Key.Ok);
    const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(signOutVerificationModalMessage.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check that we are no longer in Kids mode
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButton');


    // Check for Live News row
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 10000);
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

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

async function guestSelectOlderKidsParentalControls() {
  // Select Older Kids Parental Controls
  await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
  await signInUserFromParentalControls();
}

async function guestSelectLittleKidsParentalControls() {
  // Select Little Kids Parental Controls
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
  await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
  await signInUserFromParentalControls();
}


async function signInUserFromParentalControls() {
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('dialogBoxSignInButton');

  // Show request for info Roku overlay
  await ecp.sendKeypress(ecp.Key.Ok);
  await utils.sleep(8000); // We can't get rid of this sleep since this is Roku's native panel and we have no way to observe when it is showing
  await ecp.sendKeypress(ecp.Key.Ok);

  // Now we need to make our user
  const user = await testUtils.createRegisteredUser();

  // Enter email
  await ecp.sendText(user['userInfo'].email);
  await ecp.sendKeypress(ecp.Key.Down);
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('emailTexEditBox');
  await ecp.sendText(user['userInfo'].email);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1500 });
  await ecp.sendKeypress(ecp.Key.Ok);


  await testUtils.waitForElementToFullyShowOnScreen('signInScreenPasswordBox', 'Password box not found', 10000);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendText('111111');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(1500);
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('enterPasswordContentMessage');
  await ecp.sendKeypress(ecp.Key.Ok);

  await testUtils.waitForElementToFullyShowOnScreen('pcPasswordEntryBox', 'Password box not found', 10000);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendText('111111');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(1500);
  await ecp.sendKeypress(ecp.Key.Ok);


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

async function selectOlderKidsFromParentalSettings() {
  await ecp.sendKeypress(ecp.Key.Right);
  await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
  await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectLittleKidsFromParentalSettings() {
  await testUtils.waitForElementToFullyShowOnScreen('adultControlSelected');
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function checkForKidsModeGrayed() {
  const exitKidsGrayedOut = await testUtils.getNodeForElement('exitKidsGrayedOut');
  expect(exitKidsGrayedOut.text).to.equal('Exit Kids');
  expect(exitKidsGrayedOut.opacity).to.be.lessThan(1);
}

async function checkForKidsModeNotGrayed() {
  const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
  expect(exitKidsOption.text).to.equal('Exit Kids');
  expect(exitKidsOption.opacity).to.be.equal(1);
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
