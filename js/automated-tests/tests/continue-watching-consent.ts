import { expect } from 'chai';
import { ecp } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';

describe('Continue Watching Consent During Registration', function () {
    beforeEach(async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    });


    // https://tubi.testrail.io/index.php?/cases/view/547227
    it('C547227 - Guest User - Do not show CW Consent Pop Up if Guest and does not Register, @cwconsent', async () => {
        // Exit and re-open Tubi app
        await testUtils.restartApplication();

        // Verify user on Home page, continue watching consent page is not displayed
        await testUtils.waitForCurrentScreenToEqual('homeScreen');
        await testUtils.waitForElementToNotShowOnScreen('continueWatchingConsentPage')
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    });

    // // https://tubi.testrail.io/index.php?/cases/view/547229
    // it('C547229 - Guest User - Do not show CW Consent Pop Up if Locale is not USA and Registers, @cwconsent', async () => {

    // });

    // https://tubi.testrail.io/index.php?/cases/view/547230
    it('C547230 - Guest User - Show CW Consent screen during Registration, @cwconsent', async () => {

        await signInWithEmail();

        // Verify on Continue Watching Consent Page
        const continueWatchingConsentPage = await testUtils.getNodeForElement('continueWatchingConsentPage');
        expect(continueWatchingConsentPage.text).to.equal('Get Back to What You Love Faster');
    });

    // https://tubi.testrail.io/index.php?/cases/view/547231
    it('C547231 - Guest User - CW Consent - Accept Now, @cwconsent', async () => {

        await signInWithEmail();

        // Verify on Continue Watching Consent Page
        const continueWatchingConsentPage = await testUtils.getNodeForElement('continueWatchingConsentPage');
        expect(continueWatchingConsentPage.text).to.equal('Get Back to What You Love Faster');

        // Select Accept
        await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentPageAcceptButton');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify user back to home screen and signed in
        await testUtils.waitForCurrentScreenToEqual('homeScreen');
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.assertUserIsSignedIn();

        // Navigate to Settings > Privacy Center
        await goToPrivacyCenter();

        //Verify Continue Watching Consent is 'On'
        const privacyCenterContinueWatchingHeader = await testUtils.getNodeForElement('privacyCenterContinueWatchingHeader');
        expect(privacyCenterContinueWatchingHeader.text).to.equal('Continue Watching');
        const privacyCenterContinueWatchingToggle = await testUtils.getNodeForElement('privacyCenterContinueWatchingToggle');
        expect(privacyCenterContinueWatchingToggle.text).to.equal('On');
    });

    // https://tubi.testrail.io/index.php?/cases/view/547232
    it('C547232 - Guest User - CW Consent - Maybe Later, @cwconsent', async () => {

        await signInWithEmail();

        // Verify on Continue Watching Consent Page
        const continueWatchingConsentPage = await testUtils.getNodeForElement('continueWatchingConsentPage');
        expect(continueWatchingConsentPage.text).to.equal('Get Back to What You Love Faster');

        // Select Maybe Later
        await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentPageAcceptButton');
        await ecp.sendKeypress(ecp.Key.Down);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify user back to home screen and signed in
        await testUtils.waitForCurrentScreenToEqual('homeScreen');
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.assertUserIsSignedIn();

        // Navigate to Settings > Privacy Center
        await goToPrivacyCenter();

        // Verify Continue Watching Consent is 'Off'
        const privacyCenterContinueWatchingHeader = await testUtils.getNodeForElement('privacyCenterContinueWatchingHeader');
        expect(privacyCenterContinueWatchingHeader.text).to.equal('Continue Watching');
        const privacyCenterContinueWatchingToggle = await testUtils.getNodeForElement('privacyCenterContinueWatchingToggle');
        expect(privacyCenterContinueWatchingToggle.text).to.equal('Off');
    });

    // https://tubi.testrail.io/index.php?/cases/view/547233
    it('C547233 - Guest User - Press Back from CW Consent screen, @cwconsent', async () => {
        await signInWithEmail();

        // Verify on Continue Watching Consent Page
        const continueWatchingConsentPage = await testUtils.getNodeForElement('continueWatchingConsentPage');
        expect(continueWatchingConsentPage.text).to.equal('Get Back to What You Love Faster');

        // Press Back button
        await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentPageAcceptButton');
        await ecp.sendKeypress(ecp.Key.Back);

        // Verify user back to home screen and signed in
        await testUtils.waitForCurrentScreenToEqual('homeScreen');
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.assertUserIsSignedIn();

        await goToPrivacyCenter();

        //Verify Continue Watching Consent is 'Off'
        const privacyCenterContinueWatchingHeader = await testUtils.getNodeForElement('privacyCenterContinueWatchingHeader');
        expect(privacyCenterContinueWatchingHeader.text).to.equal('Continue Watching');
        const privacyCenterContinueWatchingToggle = await testUtils.getNodeForElement('privacyCenterContinueWatchingToggle');
        expect(privacyCenterContinueWatchingToggle.text).to.equal('Off');
    });

    // https://tubi.testrail.io/index.php?/cases/view/547236
    it('C547236 - Guest User - Show CW Consent Screen during Registration after Exiting Kids Mode, @cwconsent', async () => {
        // Enter Kids mode
        await testHelpers.openKidsMode();
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
        // Exit Kids mode
        await testHelpers.exitKidsMode();

        // Verify on Confirm your age page
        await testUtils.waitForElementToShowOnScreen('ageVerificationNumberPad');

        // Enter age > 12
        await ecp.sendText('2009');
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify user back to home screen
        await testUtils.waitForCurrentScreenToEqual('homeScreen');

        await signInWithEmail();

        // Verify on Continue Watching Consent Page
        const continueWatchingConsentPage = await testUtils.getNodeForElement('continueWatchingConsentPage');
        expect(continueWatchingConsentPage.text).to.equal('Get Back to What You Love Faster');

        // Select Accept
        await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentPageAcceptButton');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify user back to home screen and signed in
        await testUtils.waitForCurrentScreenToEqual('homeScreen');
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.assertUserIsSignedIn();
    });
});



async function goToPrivacyCenter() {
    // Navigate to Settings > Privacy Center
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Settings');
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');
    await testUtils.jumpToRowWithTitle('settingsMenu', 'Privacy Center');
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToFullyShowOnScreen('privacyPolicyHeader');
}

async function signInWithEmail() {
    // Navigate to Left Nav and select Sign in
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Roku sign in prompt
    await ecp.sleep(10000);
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
}

