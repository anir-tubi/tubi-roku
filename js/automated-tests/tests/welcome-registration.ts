
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Welcome Registration', function () {
  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/450808
  it('C450808 - The Welcome Registration component should have correct content and buttons displayed, @welcome_modal', async () => {
    await testUtils.startApplicationAtPage('home', { clearRegistry: true, shouldCreateNewUser: false, hideStartupModals: false });

    // Verify Welcome Registration Dialog Displayed
    await verifyRegModalDialog();

    const welcomeRegModalHeader = await testUtils.getNodeForElement('welcomeRegModalHeader');
    const welcomeRegModalSignInButton = await testUtils.getNodeForElement('welcomeRegModalSignInButtonFocused');
    const welcomeRegModalContinueAsGuestButton = await testUtils.getNodeForElement('welcomeRegModalContinueAsGuestButton');

    expect(welcomeRegModalHeader.text).to.equal('Welcome to Tubi');
    expect(welcomeRegModalSignInButton.text).to.equal('Continue to Sign In');
    expect(welcomeRegModalContinueAsGuestButton.text).to.equal('Continue as Guest');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/450809
  it('C450809 - Clicking on Continue to Sign In should direct to Sign In flow, @welcome_modal', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, hideStartupModals: false });

    // Verify Welcome Registration Dialog Displayed
    await verifyRegModalDialog();

    // Press ok on Continue to Sign In button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Let's create your account modal (Roku modal, no elements)
    await utils.sleep(5000);

    // Press ok on Continue button
    await ecp.sendKeypress(ecp.Key.Ok);

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/450812
  it('C450812 - User is able to dismiss Welcome Registration modal by pressing Back button, @welcome_modal', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, hideStartupModals: false });

    // Verify Welcome Registration Dialog Displayed
    await verifyRegModalDialog();

    // Press Back button to dismiss welcome modal
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000);

    await testUtils.waitForElementToNotShowOnScreen('welcomeRegModal', 'Welcome Modal still showing on screen', 3000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/450824
  it('C450824 - When user does not complete sign in flow do not show Welcome Registration modal - Exit from Email Address page, @welcome_modal', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, hideStartupModals: false });

    // Verify Welcome Registration Dialog Displayed
    await verifyRegModalDialog();

    // Press ok on Continue to Sign In button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Let's create your account modal (Roku modal, no elements)
    await utils.sleep(5000);

    // Press ok on Continue button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Press Back on the Sign In screen
    await utils.sleep(2000); // Test fails without
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify Welcome Modal not displayed and Homescreen displayed
    await testUtils.waitForElementToNotShowOnScreen('welcomeRegModal', 'Welcome Modal still showing on screen', 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/452709
  it('C452709 - User is unable to use Up and Down buttons to dismiss Welcome Registration modal, @welcome_modal', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, hideStartupModals: false });

    // Verify Welcome Registration Dialog Displayed
    await verifyRegModalDialog();

    await ecp.sendKeypress(ecp.Key.Up);

    await testUtils.waitForElementToShowOnScreen('welcomeRegModal', 'Welcome Modal not showing on screen', 1000);
    await testUtils.waitForElementToFullyShowOnScreen('welcomeRegModalSignInButtonFocused', 'Continue to Sign In not shown on screen', 1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToShowOnScreen('welcomeRegModal', 'Welcome Modal not showing on screen', 1000);
    await testUtils.waitForElementToFullyShowOnScreen('welcomeRegModalContinueAsGuestButtonFocused', 'Continue as guest button not focused', 2000);
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/450820
  it('C450820 - Returning registered user should not see the Welcome Registration component, @welcome_modal', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, hideStartupModals: false });

    // Verify Welcome Modal not displayed and Homescreen displayec
    await testUtils.waitForElementToNotShowOnScreen('welcomeRegModal', 'Welcome Modal still showing on screen', 3000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });

});

async function verifyRegModalDialog() {
  await testUtils.waitForElementToShowOnScreen('welcomeRegModal');
  await testUtils.waitForElementToFullyShowOnScreen('welcomeRegModalHeader', 'Welcome Modal Header not shown on screen');
  await testUtils.waitForElementToFullyShowOnScreen('welcomeRegModalSignInButtonFocused', 'Continue to Sign In not shown on screen');
  await testUtils.waitForElementToFullyShowOnScreen('welcomeRegModalContinueAsGuestButton', 'Continue as Guest not shown on screen');
}
