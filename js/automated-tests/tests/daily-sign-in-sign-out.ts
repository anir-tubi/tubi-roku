import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

/**
 * Daily Sign In/Sign Out Automation Test
 * 
 * This test runs every 24 hours to verify sign-in and sign-out functionality.
 * - Test 1: Sign Up and Sign Out Flow
 *   - Launches the app as guest user
 *   - Signs up (for new users)
 *   - Signs out
 *   - Verifies sign out was successful
 * - Test 2: Sign In Flow
 *   - Creates a registered user
 *   - Signs in with existing credentials
 *   - Verifies sign in was successful
 * 
 * Test Tag: @daily_sign_in_sign_out
 */

describe('Daily Sign In/Sign Out Automation', function () {
  it('C825399 - Daily Sign up and Sign Out Flow @daily_sign_in_sign_out', async () => {
    // Step 1: Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Step 2: Sign up/Sign in flow

    // Navigate to Sign In from home screen
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Select register/unlock button to start registration flow
    // completeGuestUserRegistrationFlow() will handle the Roku modal and email entry
    await shared.completeGuestUserRegistrationFlow()

    // Verify Age Gate Screen
    await testUtils.waitForElementToFullyShowOnScreen('ageVerificationPad', 'age verification keypad not found', 10000);


    // For automation emails (@tubi.tv), the backend automatically processes the magic link
    // Wait for the automatic verification and transition to age gate
    await utils.sleep(5000); // Allow time for backend magic link processing

    // Age gate should appear after automatic magic link verification
    await testUtils.waitForElementToFullyShowOnScreen('ageVerificationPageHeader');

    // Enter valid age (over 13)
    await ecp.sendText('20');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Dismiss CW consent screen if it appears (not always shown, e.g. after age gate flow)
    const consentResult = await testUtils.isElementShowingOnScreen('continueWatchingConsentPageAcceptButton', 5000);
    if (consentResult.isShowing) {
      await ecp.sendKeypress(ecp.Key.Ok);
    }

    // Should return to home screen as registered user
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen after registration');

    // Open side nav to check signed in status
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementToShowOnScreen('sideNavSignedInLabel', 'Side nav signed in label not found', 15000);
    await testUtils.assertUserIsSignedIn();


    // Step 4: Sign out
    // Navigate to Settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Verify we're on Settings screen
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen', 'Settings screen not found', 15000);

    // Account panel is first item in settings menu, so activate it and go to Sign Out option
    await ecp.sendKeypress(ecp.Key.Ok, { count: 2, wait: 500 });

    // Wait for sign out verification modal
    await testUtils.waitForElementToShowOnScreen('signOutVerificationModalMessage', 'Sign out verification modal message not found', 15000);
    const signOutVerificationModalMessage = await testUtils.getNodeForElement('signOutVerificationModalMessage');
    expect(signOutVerificationModalMessage.visible).to.be.true;
    expect(signOutVerificationModalMessage.text).to.contain('You are about to sign out');

    // Confirm sign out
    await ecp.sendKeypress(ecp.Key.Ok);

    // Step 5: Verify sign out was successful
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen after sign out', 20000);

    // Verify user is signed out (label should not contain any known signed-in user name)
    await testUtils.retryWithTimeOut(async () => {
      const sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
      if (sideNavSignedInLabel !== undefined && sideNavSignedInLabel.text !== undefined) {
        expect(sideNavSignedInLabel.text).to.not.contain('Automation');
        expect(sideNavSignedInLabel.text).to.not.contain('build_roku_');
      } else {
        console.log('User successfully signed out');
      }
    }, 10000);

  });

  it('C781337 - Daily Sign In Flow @daily_sign_in_sign_out', async () => {
    // Step 1: Create a registered user and sign them in initially
    const user = await testUtils.createRegisteredUser();

    // Step 2: Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Step 3: Sign out if already signed in (cleanup from previous test)
    await ecp.sendKeypress(ecp.Key.Left);
    const sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
    if (sideNavSignedInLabel !== undefined && sideNavSignedInLabel.text !== undefined && (sideNavSignedInLabel.text.includes('Automation') || sideNavSignedInLabel.text.includes('build_roku_'))) {
      console.log('User is already signed in, signing out first...');
      await shared.openSettings();
      await testUtils.waitForElementToFullyShowOnScreen('settingsScreen', 'Settings screen not found', 15000);
      await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForElementToShowOnScreen('signOutVerificationModalMessage', 'Sign out verification modal message not found', 15000);
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen after sign out', 20000);
    }

    // Step 4: Navigate to Sign In
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Step 5: Handle Roku sign-in dialog - cancel to use email/password instead
    await utils.sleep(10000); // Wait for Roku sign-in dialog
    await ecp.sendKeypress(ecp.Key.Back); // Cancel Roku dialog to use email/password

    // Step 6: Verify we're on the Enter Email Address page
    await testUtils.waitForElementToShowOnScreen('emailInputScreenHeader', 'Email input screen header not found', 15000);
    const enterEmailAddressTitle = await testUtils.getNodeForElement('emailInputScreenHeader');
    expect(enterEmailAddressTitle.text).to.equal('Enter Email Address');

    // Step 7: Enter the registered user's email
    const userEmail = user['userInfo'].email;
    await utils.sleep(2000);
    await ecp.sendText(userEmail);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Step 8: Verify we're on the Sign In to Your Account page
    await testUtils.waitForElementToShowOnScreen('signInScreenPageHeader', 'Sign In screen page header not found', 15000);
    const signInScreenPageHeader = await testUtils.getNodeForElement('signInScreenPageHeader');
    expect(signInScreenPageHeader.text).to.equal('Sign In to Your Account');

    // Step 9: Enter password
    await utils.sleep(3000); // Wait for password field to be ready
    await ecp.sendKeypress(ecp.Key.Ok); // Focus password field
    await ecp.sendText('111111'); // Enter password
    await utils.sleep(3000); // Wait for text input
    await ecp.sendKeypress(ecp.Key.Right); // Move to continue button
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 }); // Navigate to continue button
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok); // Submit sign-in

    // Step 10: Verify sign-in was successful - should return to home screen
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen after sign in', 20000);

    // Step 11: Verify user is signed in
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementToShowOnScreen('sideNavSignedInLabel', 'Side nav signed in label not found', 15000);
    await testUtils.assertUserIsSignedIn();

    console.log('Sign in completed successfully. User is now signed in.');
  });
});
