import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { randomBytes } from 'crypto';
import { PLAYER_NODES } from '../../../out/automated_tests_branch/js/automated-tests/analytics/utils/constants';


describe('SLtests', function () {

  // SL as guest user test
  it('Guest User - SL launch as Guest user @sl', async () => {
    await testUtils.startApplicationAtPage('home', {enablePurpleCarpetContainerAndBanner: true, shouldCreateNewUser: false});
    await testUtils.waitForElementToShowOnScreen('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Check for "Sign In to Watch Button"
    await testUtils.waitForElementToFullyShowOnScreen('slSignInToWatch');

    // Click button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Click "Use Different email" on Roku Sign In modal after waiting for Roku Modal
    await utils.sleep(10000);
    await ecp.sendKeypress(ecp.Key.Down, {wait:1000});
    await ecp.sendKeypress(ecp.Key.Ok);

    // Enter new email not associated with Tubi email
    await testUtils.waitForElementToFullyShowOnScreen('enterEmailAddressHeader');
    
    // Create a user email
    const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    
    // Enter user info email
    await ecp.sendText(email);
    await ecp.sendKeypress(ecp.Key.Down, {count:4});
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Age Gate
    await verifyAgeGateScreen();

    // Enter valid age > 12
    await ecp.sendText('20');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // See "Accept Now" page for watch history permission, verify and click button
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentScreen'); 
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Fox Player
    await testUtils.waitForPlayerStateToEqual('foxPLayerElementID', 'playing'); 

  });

  it('Registered User - SL launch as Registered User user @sl', async () => {
    await testUtils.startApplicationAtPage('home', {enablePurpleCarpetContainerAndBanner: true, shouldCreateNewUser: true});
    await testUtils.waitForElementToShowOnScreen('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Check for "Sign In to Watch Button"
    await testUtils.waitForElementToFullyShowOnScreen('slWatchLiveButton');
    await testUtils.waitForElementToFullyShowOnScreen('slWatchLiveText');

    // Click button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Fox Player
    await testUtils.waitForPlayerStateToEqual('foxPLayerElementID', 'playing');

  });

});
async function verifyAgeGateScreen() {
  await testUtils.waitForElementToFullyShowOnScreen('ageVerificationPageHeader', 'Age gate did not appear in timeout range');
}
