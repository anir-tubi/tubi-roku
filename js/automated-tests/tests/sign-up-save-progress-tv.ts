import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

describe('Sign up Save Progress TV', function () {
  beforeEach(async () => {
    const user = await testUtils.createAnonymousUser();
    user.setIsNewUser(false);
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.openSeries();
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
  });


  // https://tubi.testrail.io/index.php?/cases/view/260843
  it('C260843 - Guest - When (Tubi) user clicks the "Sign Up to Save Progress" button on the Details page, the user is redirected to the Registration/Sign In modal @signupsaveprogress,@smoke', async () => {
    // Select a title
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await testUtils.waitForElementToHaveFocus('detailScreenMenu', 'Timed out waiting for Menu to have focus');
    // Find and navigate to the Sign Up to Save Progress button
    await testUtils.jumpToGridItemWithTitle('detailScreenMenu', 'Sign Up to Save Progress');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    // Wait for Let's create your account screen or RPayShareDialog
    await utils.sleep(4000);

    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify we're on the Enter Email Address page
    await testUtils.waitForElementToShowOnScreen('emailInputScreenHeader', 'Email Input Screen not found');
    const emailInputScreenHeader = await testUtils.getNodeForElement('emailInputScreenHeader');
    expect(emailInputScreenHeader.text).to.equal('Enter Email Address');

    // Verify the Keyboard is focused
    await testUtils.waitForElementToBeInFocusChain('emailInputScreenKeyboard', 'Keyboard not focused');
  });
  
});