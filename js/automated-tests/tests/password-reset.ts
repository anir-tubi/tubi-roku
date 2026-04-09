import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Sign In: On-Device Password Reset', function () {

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/476627
  it.skip('C476627 - Registered User - Sign In with valid credentials, @password_reset @manual_regression', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Roku Sign up dialog
    await ecp.sleep(8000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify if on the Sign In to Your Account page
    const signInScreenPageHeader = await testUtils.getNodeForElement('signInScreenPageHeader');
    expect(signInScreenPageHeader.text).to.equal('Sign In to Your Account');

    // Enter password
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('111111');
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on home page
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/476628
  it.skip('C476628 - Registered User - Sign In with invalid password, @password_reset1', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Roku Sign up prompt
    await ecp.sleep(8000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify if on the Sign In to Your Account page
    const signInScreenPageHeader = await testUtils.getNodeForElement('signInScreenPageHeader');
    expect(signInScreenPageHeader.text).to.equal('Sign In to Your Account');

    // Enter wrong password
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('22222');
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });

    // Oops! wrong password! screen is displayed
    await verifyWrongPasswordDialogDisplayed();
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/476629
  it.skip('C476629 - Registered User - Instant Sign-In Link - Prefilled email, @password_reset1', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    await ecp.sleep(8000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify if on the Sign In to Your Account age
    const signInScreenPageHeader = await testUtils.getNodeForElement('signInScreenPageHeader');
    expect(signInScreenPageHeader.text).to.equal('Sign In to Your Account');

    // Enter wrong password
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('222222');
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });

    // Oops! wrong password! screen is displayed
    await verifyWrongPasswordDialogDisplayed();

    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on the Help is on the way! screen
    await testUtils.waitForCurrentScreenToEqual('forgotPasswordProcessingScreen');
    const helpOnTheWayTitle = await testUtils.getNodeForElement('helpIsOnTheWayScreenTitle');
    expect(helpOnTheWayTitle.text).to.equal('Help is on the way!');
  });

  it('C476634 - Register New User - Default Mode, @password_reset', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Roku sign in prompt
    await ecp.sleep(8000);
    // Cancel to land on Enter Email Address page
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify if on the Enter Email Address Page
    const enterEmailAddressTitle = await testUtils.getNodeForElement('emailInputScreenHeader');
    expect(enterEmailAddressTitle.text).to.be.equal('Enter Email Address');

    // Enter a email account which has not been registered for Tubi
    const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    await ecp.sleep(2000);
    await ecp.sendText(email);
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on Confirm your age page
    const confirmYourAgeText = await testUtils.getNodeForElement('ageGateHeaderInRegistrationFlow');
    expect(confirmYourAgeText.text).to.equal('Confirm your age*');

    // enter age > 13
    await ecp.sleep(2000);
    await ecp.sendText('14');
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on Continue Watching Consent Page
    const continueWatchingConsentPage = await testUtils.getNodeForElement('continueWatchingConsentPage');
    expect(continueWatchingConsentPage.text).to.equal('Get Back to What You Love Faster');

    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentPageAcceptButton');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify user back to home screen and signed in
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.assertUserIsSignedIn();
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/476635
  it('C476635 - Register New User - Kids Mode, @password_reset', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Roku sign in prompt
    await ecp.sleep(8000);
    // Cancel to land on Enter Email Address page
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify if on the Enter Email Address Page
    const enterEmailAddressTitle = await testUtils.getNodeForElement('emailInputScreenHeader');
    expect(enterEmailAddressTitle.text).to.be.equal('Enter Email Address');

    // Enter a email account which has not been registered for Tubi
    const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    await ecp.sleep(2000);
    await ecp.sendText(email);
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on Confirm your age page
    const confirmYourAgeText = await testUtils.getNodeForElement('ageGateHeaderInRegistrationFlow');
    expect(confirmYourAgeText.text).to.equal('Confirm your age*');

    // enter age < 13
    await ecp.sleep(2000);
    await ecp.sendText('12');
    await ecp.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on home screen with welcome to tubi kids dialog displayed
    await testUtils.waitForCurrentScreenToEqual('homeScreen');
    const welcomeToTubiKids = await testUtils.getNodeForElement('welcomeToTubiKidsTitle');
    const buttonFocused = await testUtils.getNodeForElement('welcomeToTubiKidsOKButton');
    expect(welcomeToTubiKids.text).to.equal('Welcome to Tubi Kids');
    expect(buttonFocused.text).to.equal('OK');

    // Press Ok to dismiss the dialog, verify user on the Kids mode Home screen
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('tubiKidsLogo');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
  });
});


async function verifyWrongPasswordDialogDisplayed() {
  await testUtils.waitForElementToFullyShowOnScreen('wrongPasswordDialog');
  const wrongPasswordDialogTitle = await testUtils.getNodeForElement('wrongPasswordTitle');
  expect(wrongPasswordDialogTitle.text).to.equal('Oops, wrong Password');
  const wrongPasswordDialogMessage = await testUtils.getNodeForElement('wrongPasswordMessage');
  expect(wrongPasswordDialogMessage.text).to.contain('try again or enter a different password for this account:');
  const wrongPasswordDialogForgotButton = await testUtils.getNodeForElement('wrongPasswordForgotButton');
  expect(wrongPasswordDialogForgotButton.text).to.equal('Forgot Password');
  const wrongPasswordDialogRetryButton = await testUtils.getNodeForElement('wrongPasswordRetryButton');
  expect(wrongPasswordDialogRetryButton.text).to.equal('Retry');
}
