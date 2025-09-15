import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Sign up Save Progress TV', function () {
    beforeEach(async () => {
        const user = await testUtils.createAnonymousUser();
        user.setIsNewUser(false);
        await testUtils.startApplicationAtPage('home', { user: user });
        await shared.openSeries();
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });


    // https://tubi.testrail.io/index.php?/cases/view/260843
    it('C260843 - Guest - When (Tubi) user clicks the "Sign Up to Save Progress" button on the Details page, the user is redirected to the Registration/Sign In modal @signupsaveprogress,@smoke', async () => {
        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);
        // Is Sign Up to Save Progress Button present?
        const seriesSignUpToSaveProgressButtonText = await testUtils.getNodeForElement('seriesSignUpToSaveProgressButtonText');
        expect(seriesSignUpToSaveProgressButtonText.text).to.equal('Sign Up to Save Progress');

        // Click and verify user is taken to sign up/sign in flow
        await ecp.sendKeypress(ecp.Key.Down);
        await ecp.sendKeypress(ecp.Key.Ok);
        // Wait for Let's create your account screen
        await utils.sleep(4000);
        // Click OK
        await ecp.sendKeypress(ecp.Key.Ok, { wait: 10000 });
        // Are we on the magic link page?
        await testUtils.waitForElementToFullyShowOnScreen('emailVerificationButton', 'Email Verification Button not found');
    });
    /* Magic link issue - need workaround - removed from run, moved to manual
    // https://tubi.testrail.io/index.php?/cases/view/260844
    it('C260844 - Guest - When user completes registration after Sign Up to Save Progress, the user is returned to Series Details page with Play button replacing the sign up prompt,@signupsaveprogress', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        // Is Sign Up to Save Progress Button present, with Badge Label?
        const seriesSignUpToSaveProgressButtonText = await testUtils.getNodeForElement('seriesSignUpToSaveProgressButtonText');
        expect(seriesSignUpToSaveProgressButtonText.text).to.equal('Sign Up to Save Progress');
        const seriesSignUpBadgeLabelText = await testUtils.getNodeForElement('seriesSignUpBadgeLabelText');
        expect(seriesSignUpBadgeLabelText.text).to.equal('FREE');

        // Click and verify user is taken to sign up/sign in flow
        await ecp.sendKeypress(ecp.Key.Ok);

        // Wait for Let's create your account screen
        await utils.sleep(5000);

         // Click Down, Ok to Cancel
         await ecp.sendKeypress(ecp.Key.Down);
         await ecp.sendKeypress(ecp.Key.Ok);

         // Create user
         const user = await testUtils.createRegisteredUser();
         const userInfo = user['userInfo'];

         // Are we on the Enter Email Address page?
         const  emailInputScreenHeader = await testUtils.getNodeForElement('emailInputScreenHeader');
         expect(emailInputScreenHeader.text).to.equal('Enter Email Address');

        // Enter user info email
        await ecp.sendText(userInfo.email);
        await ecp.sendKeypress(ecp.Key.Down, {count:4});
        await ecp.sendKeypress(ecp.Key.Ok);

        // Enter password
        await utils.sleep(550);
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Down, {count:4});
        await utils.sleep(550);
        await ecp.sendKeypress(ecp.Key.Ok);
        await utils.sleep(1000);


        // Are we on details page with Play button at top position?
        // Verify we are on the details page
        let detailScreenTitle;
        await testUtils.retryWithTimeOut(async () => {
            detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
            expect(detailScreenTitle.text).to.not.be.empty;
        });
        const playButtonIconFocused = await testUtils.getNodeForElement('playButtonIconFocused');
        expect(playButtonIconFocused.uri).to.equal('pkg:/images/icon-play.webp');


    });

     // Removed due to magic link graduation - need a workaround
    it('C260845 - Guest - When user  presses Play on the Series Details page after choosing to Sign Up to Save Progress, the title plays,@signupsaveprogress', async () => {

        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        // Is Sign Up to Save Progress Button present, with Badge Label?
        const seriesSignUpToSaveProgressButtonText = await testUtils.getNodeForElement('seriesSignUpToSaveProgressButtonText');
        expect(seriesSignUpToSaveProgressButtonText.text).to.equal('Sign Up to Save Progress');
        const seriesSignUpBadgeLabelText = await testUtils.getNodeForElement('seriesSignUpBadgeLabelText');
        expect(seriesSignUpBadgeLabelText.text).to.equal('FREE');

        // Click and verify user is taken to sign up/sign in flow
        await ecp.sendKeypress(ecp.Key.Ok);

        // Wait for Let's create your account modal (Roku modal, no elements)
        await utils.sleep(5000);

         // Click Down, Ok to Cancel
        await ecp.sendKeypress(ecp.Key.Down);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Create a user email
        const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    

        // Are we on the Enter Email Address page?
        const  emailInputScreenHeader = await testUtils.getNodeForElement('emailInputScreenHeader');
        expect(emailInputScreenHeader.text).to.equal('Enter Email Address');

         // Enter user info email
        await ecp.sendText(email);
        await ecp.sendKeypress(ecp.Key.Down, {count:4});
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);

        // Enter password
        await utils.sleep(550);
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Down, {count:4});
        await utils.sleep(550);
        await ecp.sendKeypress(ecp.Key.Ok);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await ecp.sendKeypress(ecp.Key.Ok);


        // Are we on details page with Play button at top position?
        // Verify we are on the details page
        let detailScreenTitle;
        await testUtils.retryWithTimeOut(async () => {
            detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
            expect(detailScreenTitle.text).to.not.be.empty;
        });
        const playButtonIconFocused = await testUtils.getNodeForElement('playButtonIconFocused');
        expect(playButtonIconFocused.uri).to.equal('pkg:/images/icon-play.webp');

        // Press play and verify playback
        await ecp.sendKeypress(ecp.Key.Ok);

        // Is video playing?
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 10000);
    });
  
*/
});