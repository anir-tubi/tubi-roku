import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

describe('Sign up Save Progress Exit Prompt', function () {
    beforeEach(async () => {
        const user = await testUtils.createAnonymousUser();
        user.setIsNewUser(false);
        await testUtils.startApplicationAtPage('home', { user: user });
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
        await shared.openSeries();
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });


    // https://tubi.testrail.io/index.php?/cases/view/450483
    it('C450483 - Exit prompt - Press back button when the Sign up to save your progress modal surfaces, @signupsaveprogressexit', async () => {

        // Select a title to play
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
        await triggerSaveProgressExitPrompt();

        await verifySaveProgressExitPrompt();

        // Press Back when sign up prompt displayed
        await ecp.sendKeypress(ecp.Key.Back);

        // User should directly back to details screen, not signed in
        await testUtils.waitForCurrentScreenToEqual('detailScreen');
        const seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory = await testUtils.getNodeForElement('seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory');
        expect(seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory.text).to.equal('Sign Up to Save Progress');
    });


    // https://tubi.testrail.io/index.php?/cases/view/450484
    it('C450484 - Exit prompt - User click Sign up to save your progress button on the modal, @signupsaveprogressexit', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

        await triggerSaveProgressExitPrompt();
        await utils.sleep(1000);

        await verifySaveProgressExitPrompt();
        await utils.sleep(1000);

        // Press OK on Sign Up to Save Progress button
        await ecp.sendKeypress(ecp.Key.Ok, { wait: 10000 });

        // Wait for the Roku sign up prompt to show up and Continue
        //await ecp.sleep(5000);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify if on the Sign In to Your Account age
        await testUtils.waitForCurrentScreenToEqual('signInScreen');

    });

    // https://tubi.testrail.io/index.php?/cases/view/450485
    it('C450485 - Exit prompt - User click Sign up later button on the modal, @signupsaveprogressexit', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

        await triggerSaveProgressExitPrompt();

        await verifySaveProgressExitPrompt();

        // Select Sign Up Later button
        await ecp.sendKeypress(ecp.Key.Down);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify user is back to details screen, not signed in
        const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
        const seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory = await testUtils.getNodeForElement('seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory');
        expect(seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory.text).to.equal('Sign Up to Save Progress');
    });

    // https://tubi.testrail.io/index.php?/cases/view/450487
    it('C450487 - Exit prompt - Guest user press back button when lands on activation page, @signupsaveprogressexit', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

        await triggerSaveProgressExitPrompt();

        await verifySaveProgressExitPrompt();

        // Select Sign Up to Save Progress
        await ecp.sendKeypress(ecp.Key.Ok);

        // Wait for the Roku sign up prompt and press Back
        await ecp.sleep(5000);
        await ecp.sendKeypress(ecp.Key.Back);

        // Verify if on the Enter Email Address Page
        await testUtils.waitForElementToFullyShowOnScreen('emailAddressBox');
        const enterEmailAddressTitle = await testUtils.getNodeForElement('enterEmailAddressTitle');
        expect(enterEmailAddressTitle.text).to.be.equal('Enter Email Address');
    });

    // https://tubi.testrail.io/index.php?/cases/view/450490 - Need to remove this because of Magic Link
    it.skip('C450490 - Exit prompt - Guest user sign in through the modal and the CW row should populate, @signupsaveprogressexit', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

        await triggerSaveProgressExitPrompt();

        await verifySaveProgressExitPrompt();

        // Select Sign Up to Save Progress
        await ecp.sendKeypress(ecp.Key.Ok);

        // Wait for the Roku sign up prompt and press Back
        await ecp.sleep(5000);
        await ecp.sendKeypress(ecp.Key.Back);

        // Verify if on the Enter Email Address Page
        const enterEmailAddressTitle = await testUtils.getNodeForElement('emailInputScreenHeader');
        expect(enterEmailAddressTitle.text).to.be.equal('Enter Email Address');

        // Create a user email
        const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;

        // Enter user info email
        await ecp.sendText(email);
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Enter password
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForElementToFullyShowOnScreen('signInScreenPasswordBox');
        await ecp.sendText('111111');
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        await testUtils.waitForElementToFullyShowOnScreen('continueButtonSignInPage');
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify on the details page
        await testUtils.waitForElementToFullyShowOnScreen('resumedProgressBar');

        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForElementToHaveFocus('tvShowsScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Navigate to verify Continue Watching category appeared
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        await testUtils.waitForElementToFullyShowOnScreen('tvContinueWatchingRow');
    });

    // https://tubi.testrail.io/index.php?/cases/view/450491
    it('C450491 - Exit prompt - Guest user autoplay to next episode, after playback more than 5 minutes press back button, @signupsaveprogressexit', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);

        //seek to autoplay cue point
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
        await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');

        await testUtils.waitForElementToHaveFocus('autoplayUINextEpisodeButton', 'Timed out waiting for Next Episode button to have focus', 15000);
        // play next episode
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

        // Trigger Sign up modal when exit playback
        await triggerSaveProgressExitPrompt();

        // verify Sign up modal when exit playback
        await verifySaveProgressExitPrompt();
    });

    // https://tubi.testrail.io/index.php?/cases/view/450495
    it('C450495 - Exit prompt - Only show this treatment once per viewing session, @signupsaveprogressexit', async () => {
        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);

        // Trigger Sign up modal when exit playback
        await triggerSaveProgressExitPrompt();

        // verify Sign up modal when exit playback
        await verifySaveProgressExitPrompt();

        // Press back
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForCurrentScreenToEqual('detailScreen');
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForCurrentScreenToEqual('tvScreen');

        // Play a title
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);

        // Trigger Sign up modal when exit playback
        await triggerSaveProgressExitPrompt();

        // Verify the exit prompt of sign up won't be displayed this time
        await testUtils.waitForElementToNotShowOnScreen('signUpExitDialog');
        const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.not.be.empty;
    });
});



async function verifySaveProgressExitPrompt() {
    await testUtils.waitForElementToFullyShowOnScreen('signUpExitDialog');
    const signUpToSaveProgressTitle = await testUtils.getNodeForElement('signUpExitDialogTitle');
    expect(signUpToSaveProgressTitle.text).to.contain('lose your progress!');
    const signUpToSaveProgressDescription = await testUtils.getNodeForElement('signUpExitDialogDescription');
    expect(signUpToSaveProgressDescription.text).to.equal('Sign up to save your progress to pick up where you left off. No credit card required.');
    const signUpExitDialogSignUpButton = await testUtils.getNodeForElement('signUpExitDialogSignUpButton');
    expect(signUpExitDialogSignUpButton.text).to.equal('Sign Up to Save Progress - FREE');
    const signUpExitDialogLaterButton = await testUtils.getNodeForElement('signUpExitDialogLaterButton');
    expect(signUpExitDialogLaterButton.text).to.equal('Sign Up Later');
}

async function triggerSaveProgressExitPrompt() {
    await ecp.sendKeypress(ecp.Key.Forward, { count: 2 });
    await ecp.sleep(6000);
    await ecp.sendKeypress(ecp.Key.Play, { wait: 2000 });
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Back);
}