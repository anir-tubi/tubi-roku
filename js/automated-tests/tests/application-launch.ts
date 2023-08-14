import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Application Launch', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
    });


    it('C4146 User Signed in - Homescreen Display @registered_user,@smoke,@application_launch @application_launch', async () => {
      await testUtils.retryWithTimeOut(async () => {
        const sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
      expect(sideNavSignedInLabel.text).to.contain('Hi');
      });

    });


    it('C5769 - Application Launch - When user opens the application after registering as a new user then the home screen is displayed @application_launch', async () => {
      const node = await testUtils.getNodeForElement('topNavRecommendedWhiteLabel');
      await testUtils.findRowIndexWithTitle('homeScreenRowList', 'Featured');
    });


    it('C21197 - Application Launch - Registered User - When user tries to play a title after user has registered device then the title should play on tubi @application_launch', async () => {
      await ecp.sendKeyPress(ecp.Key.Ok);
      await ecp.sendKeyPress(ecp.Key.Play);
      await testUtils.expectPlayerStateToEventuallyEqual('play', 20000);
    });


    it('C70718 - Sign out after setting Parental Controls @application_launch', async () => {
      // Go to Settings page and select Older Kids
      await testUtils.goToPage('settings');
      await ecp.sendKeyPress(ecp.Key.Right);
      await utils.sleep(2000);
      await ecp.sendKeyPress(ecp.Key.Up, {count:2});
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Validate Enter Password Page and message
      const enterPasswordMessage = await testUtils.getNodeForElement('enterPasswordMessage');
      expect(enterPasswordMessage.text).to.equal('Enter Password to update');

      // Send password and click Continue
      await ecp.sendText('111111');
      await ecp.sendKeyPress(ecp.Key.Down, {count:4});
      await utils.sleep(100); // Only goes over to the right if we sleep here for some reason
      await ecp.sendKeyPress(ecp.Key.Ok);

      // Validate Older Kids modal message, back out to Left Nav and Check Exit Kids menu item is grayed out
      const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
      expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
      await ecp.sendKeyPress(ecp.Key.Ok);
      await ecp.sendKeyPress(ecp.Key.Back);
      await ecp.sendKeyPress(ecp.Key.Back);
      const exitKidsGrayedOut = await testUtils.getNodeForElement('exitKidsGrayedOut');
      expect(exitKidsGrayedOut.visible).to.equal(true);

      // Sign out to check that we are not in Kids mode
      await ecp.sendKeyPress(ecp.Key.Up, {count:3});
      await ecp.sendKeyPress(ecp.Key.Ok);
      const signOutButtonKidsMode = await testUtils.getNodeForElement('signOutButtonKidsMode');
      expect(signOutButtonKidsMode.text).to.equal('Sign Out');
      await ecp.sendKeyPress(ecp.Key.Ok);
      const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
      expect(signOutVerificationModalMessage.text).to.equal('You are about to sign out of your Tubi account.');
      await ecp.sendKeyPress(ecp.Key.Ok);
      const node = await testUtils.getNodeForElement('topNavRecommendedWhiteLabel');
      await testUtils.findRowIndexWithTitle('homeScreenRowList', 'Featured');
  });

    it('C116528_1 - Resume Watching - Guest User - Movie - User plays back content, exits and selects content again @new_test,@application_launch', async () => {
    // Start Open Movies
    await testUtils.startApplicationAtPage('movies');

    // Check for presence of Movies Grid
    await testUtils.findRowIndexWithTitle('movieScreenRowList', 'Featured');
    // End Open Movies

    // Open and play a title, create history, then back to details page to check for "Resume" button
    await ecp.sendKeyPress(ecp.Key.Right);
    await ecp.sendKeyPress(ecp.Key.Ok);
    await ecp.sendKeyPress(ecp.Key.Play);
    await createHistory();
    const resumeButton = await testUtils.getNodeForElement('resumeButton');
    expect(resumeButton.visible).to.equal(true);

    // Exit app and restart
    await testUtils.restartApplication();
    await testUtils.waitForApplicationStartup();
    await ecp.sendKeyPress(ecp.Key.Right);
    await ecp.sendKeyPress(ecp.Key.Ok);
    expect(testUtils.findRowIndexWithTitle('homeScreenRowList', 'Featured'));

    // Test for resume button (Roku retains resume button for 24 hours)
    await ecp.sendKeyPress(ecp.Key.Ok);
    expect(resumeButton.visible).to.equal(true);
  });
});
// Create history
async function createHistory(){
  await testUtils.expectPlayerStateToEventuallyEqual('play',15000);
  await ecp.sendKeyPress(ecp.Key.Forward, {count:3});
  await utils.sleep(3000);
  await ecp.sendKeyPress(ecp.Key.Play);
  await utils.sleep(2000);
}
