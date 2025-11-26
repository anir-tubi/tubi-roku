import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

describe('Sign up Save Progress Movies', function () {
    beforeEach(async () => {
        const user = await testUtils.createAnonymousUser();
        user.setIsNewUser(false);
        await testUtils.startApplicationAtPage('home', { user: user });
        await shared.openMovies();
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });


    // https://tubi.testrail.io/index.php?/cases/view/260855
    // Test C260849 is covered by this test. https://tubi.testrail.io/index.php?/cases/view/260849

    it('C260855 - Guest - When user completes registration after Sign Up to Save Progress, the user is returned to Movies Details page with Play button replacing the sign up prompt,@signupsaveprogress', async () => {
        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        // Verify we are on the details page
        let detailScreenTitle;
        await testUtils.retryWithTimeOut(async () => {
            detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
            expect(detailScreenTitle.text).to.not.be.empty;
        });

        // Is Sign Up to Save Progress Button present, with Badge Label?
        const moviesSignUpToSaveProgressButtonText = await testUtils.getNodeForElement('moviesSignUpToSaveProgressButtonText');
        expect(moviesSignUpToSaveProgressButtonText.text).to.equal('Sign Up to Save Progress');

        // Click and verify user is taken to sign up/sign in flow
        await ecp.sendKeypress(ecp.Key.Down);
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
        const emailInputScreenHeader = await testUtils.getNodeForElement('emailInputScreenHeader');
        expect(emailInputScreenHeader.text).to.equal('Enter Email Address');

        // Enter user info email
        await ecp.sendText(userInfo.email);
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        await ecp.sendKeypress(ecp.Key.Ok);

        // Enter password
        await utils.sleep(550);
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        await utils.sleep(550);
        await ecp.sendKeypress(ecp.Key.Ok);
        await utils.sleep(1000);


        // Are we on details page with Play button at top position?
        // Verify we are on the details page
        await testUtils.retryWithTimeOut(async () => {
            detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
            expect(detailScreenTitle.text).to.not.be.empty;
        });
        const playButtonIconFocused = await testUtils.getNodeForElement('playButtonIconFocused');
        expect(playButtonIconFocused.uri).to.equal('pkg:/images/icon-play.webp');


    });
    /** Removed due to magic link graduation - need a workaround
    // https://tubi.testrail.io/index.php?/cases/view/260857
    it('C260857 - Guest - When user selects the "Sign Up to Save Progress" button and registers/signs in, the title can be played successfully, @signupsaveprogress', async () => {
        
        // Select a title
        await ecp.sendKeypress(ecp.Key.Ok);

        // Is Sign Up to Save Progress Button present, with Badge Label?
        const moviesSignUpToSaveProgressButtonText = await testUtils.getNodeForElement('moviesSignUpToSaveProgressButtonText');
        expect(moviesSignUpToSaveProgressButtonText.text).to.equal('Sign Up to Save Progress');
        const moviesSignUpBadgeLabelText = await testUtils.getNodeForElement('moviesSignUpBadgeLabelText');
        expect(moviesSignUpBadgeLabelText.text).to.equal('FREE');

        // Click and verify user is taken to sign up/sign in flow
        await ecp.sendKeypress(ecp.Key.Down);
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
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right);
        await ecp.sendKeypress(ecp.Key.Down, {count:4});
        await testUtils.waitForElementToFullyShowOnScreen('continueButtonSignInPage');
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Ok);   

        // Are we on details page with Play button at top position?
        // Verify we are on the details page
        let detailScreenTitle;
        await testUtils.retryWithTimeOut(async () => {
            detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
            expect(detailScreenTitle.text).to.not.be.empty;
        });

        // Press play and verify playback
        await testUtils.selectAndVerifyDetailPageMenuItem('play');
        await ecp.sendKeypress(ecp.Key.Ok);

        // Is video playing?
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 10000);
    });  
    */
});
