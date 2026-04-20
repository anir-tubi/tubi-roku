import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

async function navigateToTransportButtons() {
  await ecp.sendKeypress(ecp.Key.Up);
  await testUtils.waitForElementToHaveFocus('playerScreenProgressBar');
  await testUtils.untilTrue(async () => {
    await utils.sleep(200);
    await ecp.sendKeypress(ecp.Key.Up);
    const { node } = await odc.getFocusedNode();
    return node.subtype === 'TextIconButton' || node.subtype === 'EnhancedButton';
  }, 'Timed out waiting for a transport button to have focus');
}

async function navigateToSendFeedbackButton(maxPresses = 10) {
  for (let i = 0; i < maxPresses; i++) {
    const { node } = await odc.getFocusedNode();
    if (node.id === 'sendFeedBackButton') return;
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(200);
  }
  throw new Error('Could not navigate to sendFeedBackButton');
}

describe('Send Feedback Tests', function () {

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574103
  it('C574103 Guest user shows the feedback icon on movie player, @send_feedback', async () => {
    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Select a movie title and Play
    await selectMovieTitle();

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Move focus to top overlay area where transport buttons are visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(300);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton).to.exist;

    // If node is found, ensure it is visible when HUD is up
    if (sendFeedbackButton.visible !== undefined) {
      expect(Boolean(sendFeedbackButton.visible)).to.equal(true);
    }
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574104
  it('C574104 Guest user shows the feedback icon on series player, @send_feedback', async () => {
    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Select a series title and Play
    await selectSeriesTitle();

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Move focus to top overlay area where transport buttons are visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(300);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton).to.exist;

    // If node is found, ensure it is visible when HUD is up
    if (sendFeedbackButton.visible !== undefined) {
      expect(Boolean(sendFeedbackButton.visible)).to.equal(true);
    }
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574105
  it('C574105 Registered user shows the feedback icon on movie player, @send_feedback', async () => {
    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Select a movie title and Play
    await selectMovieTitle();

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Move focus to top overlay area where transport buttons are visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(300);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton).to.exist;

    // If node is found, ensure it is visible when HUD is up
    if (sendFeedbackButton.visible !== undefined) {
      expect(Boolean(sendFeedbackButton.visible)).to.equal(true);
    }
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574106
  it('C574106 Registered user shows the feedback icon on series player, @send_feedback', async () => {
    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Select a series title and Play
    await selectSeriesTitle();

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Move focus to top overlay area where transport buttons are visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(300);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton).to.exist;

    // If node is found, ensure it is visible when HUD is up
    if (sendFeedbackButton.visible !== undefined) {
      expect(Boolean(sendFeedbackButton.visible)).to.equal(true);
    }
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574107
  it('C574107 User clicks on the send feedback icon and menu show up, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const overlayGroup = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(overlayGroup.visible).to.equal(true);
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574108
  it('C574108 User could scroll down/up on the side menu to browse options of user feedback, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const overlayGroup = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(overlayGroup.visible).to.equal(true);

    // Verify if the user can navigate
    verifySendFeedbackNavigation()
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574109
  it('C574109 User could choose one item and see the confirm page, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const overlayGroup = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(overlayGroup.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Down);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(800);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574110
  it('C574110 User could close the send feedback side menu be pressing back button, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const sendFeedbackSelectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlay');
    await utils.sleep(800);

    await testUtils.elementHasFocus('sendFeedbackSelectionOverlay');

    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(800);

    // Verify overlay is hidden
    await testUtils.waitForElementToNotShowOnScreen('sendFeedbackSelectionOverlay')
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574111
  it('C574111 User could back to send feedback side menu from confirm page by pressing back button, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlay');
    expect(selectionOverlay.opacity).to.equal(1);

    await ecp.sendKeypress(ecp.Key.Down);

    await utils.sleep(500);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(500);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);

    // Close the selection overlay from back press
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(800);

    //QR code will loose focus and sendfeedbackOverlay has focus
    const sendFeedbackOverlaygroup = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(sendFeedbackOverlaygroup.visible).to.equal(true);
    expect(selectionOverlay.opacity).to.equal(1);
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574113
  it('C574113 User could submit the issue automatically aftering clicking one item from the panel, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    const playerState = videoPlayerScreen.state

    // Show HUD and navigate up to transport buttons
    await navigateToTransportButtons();

    // Navigate to sendFeedback button
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Down);

    await utils.sleep(500);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(500);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);
    await utils.sleep(800);

    const headerLabel = await testUtils.getNodeForElement('sendFeedbackQRCodeHeaderLabel');
    expect(headerLabel.title).to.equal('Thank you!');
    await utils.sleep(800);

    const closeButton = await testUtils.getNodeForElement('closeButton');
    expect(closeButton.visible).to.equal(true);

    // Close the selection overlay from back press
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(800);

    //QR code will loose focus and sendfeedbackOverlay has focus
    const sendFeedbackOverlaygroup = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(sendFeedbackOverlaygroup.visible).to.equal(true);
    expect(videoPlayerScreen.state).to.equal(playerState);
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574114
  it('C574114 User could scan the QR code to report issue on mobile phone, @send_feedback', async () => {

    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Down);

    await utils.sleep(500);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(500);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);
    await utils.sleep(800);

    const qrCodeUri = await testUtils.getNodeForElement('sendFeedbackQRCodeHeaderLabel');
    expect(qrCodeUri.uri).to.equal('pkg:/images/sendFeedback.webp');
    await utils.sleep(800);

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/678503
  it('C678503 When feedack panel is open, the content playback is NOT paused, @send_feedback', async () => {

    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    const playerState = videoPlayerScreen.state

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);
    expect(videoPlayerScreen.state).to.equal(playerState);
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574116
  it('C574116 User could NOT submit feedback during pre-roll ads playback, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(1600);
    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');

    if (videoPlayerScreen.adState == 'adsPlaying') {
      if (videoPlayerScreen.adTrackingObject !== undefined) {
        const adTrackingObject = videoPlayerScreen.adTrackingObject
        if (adTrackingObject !== undefined) {
          if (adTrackingObject.rendersequence !== undefined) {
            expect(adTrackingObject.rendersequence).to.equal('preroll');

            // Verify Send Feedback button exists and is visible in the transport area
            const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
            expect(sendFeedbackButton).to.exist;

            await testUtils.waitForElementToNotShowOnScreen('sendFeedBackButton');
          }
        }
      }
    }

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574117
  it('C574117 User could NOT submit feedback during mid-roll ads playback, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');

    // Wait for preroll to finish if it starts
    const waitForState = async (state: string, timeout = 30000) =>
      await testUtils.waitForElementFieldToEqual('videoPlayerScreen', 'adState', state, timeout).catch(() => undefined);

    // If preroll happens, wait it out
    const adState = await testUtils.getElementField('videoPlayerScreen', 'adState');
    if (adState === 'adsPlaying' || adState === 'adsPending' || adState === 'fetching') {
      await waitForState('adsCompleted', 45000);
    }

    if (videoPlayerScreen.adState == "adsCompleted" || videoPlayerScreen.state == "playing") {
      // Try to trigger a mid-roll: seek forward in chunks until ads start (best-effort)
      const tries = 5
      for (let i = 0; i < tries; i++) {
        // jump ahead 2 minutes each attempt
        await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 120000, 'current');
        await utils.sleep(1000);

        // brief wait for transition adsPending -> adsPlaying
        await utils.sleep(3000);
        if ((await testUtils.getElementField('videoPlayerScreen', 'adState')) === 'adsPlaying') {
          // Verify Send Feedback button exists and is visible in the transport area
          const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
          expect(sendFeedbackButton).to.exist;

          await testUtils.waitForElementToNotShowOnScreen('sendFeedBackButton');
          break;
        }
      }

    }
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574118
  it('C574118 The feedback icon should be hidden in kids mode, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await openKidsMode();
    await utils.sleep(800);

    // Navigate right to home page focus
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Play);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);

    // Navigate to transport buttons and verify sendFeedback button is not reachable
    await navigateToTransportButtons();
    let foundButton = false;
    try {
      await navigateToSendFeedbackButton();
      foundButton = true;
    } catch (e) {
      // Expected: button not found
    }
    expect(foundButton).to.equal(false, 'sendFeedBackButton should not be reachable in kids mode');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/574119
  it('C574119 The feedback icon should be hidden when turns on parent control, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');
    await ecp.sendKeypress(ecp.Key.Down);

    // On Settings Page?
    const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
    expect(parentalControlsHeader.text).to.equal('Content Settings');

    // Set PC
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(800);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await utils.sleep(800);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Verify Little Kids PC Settings Change dialog
    const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');

    expect(parentalControlsSettingsLittleKids.text).to.contains('You will be directed to Tubi Kids.');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Back to home
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate right to home page focus
    await ecp.sendKeypress(ecp.Key.Right, { wait: 1500 });

    await utils.sleep(2500);

    await ecp.sendKeypress(ecp.Key.Play);

    // Verify that video is still playing
    // await testUtils.waitForPlayerStateToEqual('previewVideoPlayer','playing', 5000);
    await utils.sleep(2500);

    // Navigate to transport buttons and verify sendFeedback button is not reachable
    await navigateToTransportButtons();
    let foundButton = false;
    try {
      await navigateToSendFeedbackButton();
      foundButton = true;
    } catch (e) {
      // Expected: button not found
    }
    expect(foundButton).to.equal(false, 'sendFeedBackButton should not be reachable with parental controls on');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/749378
  it('C749378 When "Close" button is in focus, press a navigational button, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    const playerState = videoPlayerScreen.state

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Down);

    await utils.sleep(500);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(500);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);
    await utils.sleep(800);

    const headerLabel = await testUtils.getNodeForElement('sendFeedbackQRCodeHeaderLabel');
    expect(headerLabel.title).to.equal('Thank you!');
    await utils.sleep(800);

    const closeButton = await testUtils.getNodeForElement('closeButton');
    expect(closeButton.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(800);

    // Close button has focus after press up
    await testUtils.elementHasFocus('closeButton');

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(800);

    // Close button has focus after press down
    await testUtils.elementHasFocus('closeButton');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/749379
  it('C749379 When user selects an issue, the Thank You/QR Code page is shown, @send_feedback', async () => {
    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    const playerState = videoPlayerScreen.state

    // Navigate to sendFeedback button
    await navigateToTransportButtons();
    await navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Down);

    await utils.sleep(500);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(500);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);
    await utils.sleep(800);

    const headerLabel = await testUtils.getNodeForElement('sendFeedbackQRCodeHeaderLabel');
    expect(headerLabel.title).to.equal('Thank you!');
    await utils.sleep(800);

    const closeButton = await testUtils.getNodeForElement('closeButton');
    expect(closeButton.visible).to.equal(true);

  });

});

async function selectMovieTitle() {
  await testUtils.goToPage('movies');
  await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Movie screen row not found', 15000);
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('playButton', 'Play button not found', 15000);
  await ecp.sendKeypress(ecp.Key.Ok);
}

async function selectSeriesTitle() {
  await testUtils.goToPage('series');
  await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'TV screen row not found', 15000);
  await ecp.sendKeypress(ecp.Key.Play);
}

async function verifySendFeedbackNavigation() {

  // Verify columns only, navigate vertically
  await utils.sleep(1000);
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(1000);

  // Are we still on the 4th title after navigating right more than 3 times?
  const sendFeedbackSelectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlay');
  expect(sendFeedbackSelectionOverlay.currFocusColumn).to.equal(3);

}

async function openKidsMode() {
  await ecp.sendKeypress(ecp.Key.Left);
  await ecp.sendKeypress(ecp.Key.Up);
  await ecp.sendKeypress(ecp.Key.Up);
  // IMPROVEMENT remove need for this by addressing the weird behavior when animation ends
  await utils.sleep(500); // Adding sleeps temporary
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('exitKidsOption');
  await ecp.sendKeypress(ecp.Key.Right);
}

async function enterPasswordSettingsChange() {
  // Enter Password for PC Settings Change
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendText('111111');
  await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
  await utils.sleep(4000);
  await ecp.sendKeypress(ecp.Key.Right);
  await ecp.sendKeypress(ecp.Key.Left);
  await ecp.sendKeypress(ecp.Key.Ok);
}
