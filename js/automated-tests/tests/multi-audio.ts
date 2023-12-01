import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { count, timeEnd } from 'console';

describe('Multiple Audio', function () {
  let user: RegisteredUser;
  before(async () => {
    user = await testUtils.createRegisteredUser();
    await testUtils.startApplicationAtPage('search', { user: user });
    await testUtils.waitForAppLaunchBeaconToFire();

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/403409
  it('C403409 - Video Player - New Audio / subtitle icon @multiple_audio', async () => {
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await ecp.sendText('fifth plane');

    // Call function to navigate right to search results grid
    await navigateRightToGrid();

    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text).to.contain('Fifth Plane');
    });

    // Select item and Play button
    await ecp.sendKeyPress(ecp.Key.Ok);
    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Closed Caption audio button present?

    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.equal('pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/403413
  it('C403413 - Video Player - New Audio / subtitle menu selection @multiple_audio', async () => {
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await ecp.sendText('fifth plane');

    // Call function to navigate right to search results grid
    await navigateRightToGrid();

    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text).to.contain('Fifth Plane');
    });

    // Select item and Play button
    await ecp.sendKeyPress(ecp.Key.Ok);
    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Closed Caption audio button present?
    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.equal('pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp');

    // Navigate right to open Options
    await ecp.sendKeyPress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Validate options
    // Audio tracks section
    const audioTracksSection = await testUtils.getNodeForElement('audioTracksSection');
    expect(audioTracksSection.visible).to.be.true;

    // CC Section
    const closedCaptionSection = await testUtils.getNodeForElement('closedCaptionSection');
    expect(closedCaptionSection.visible).to.be.true;

    // Audio Section header
    const audioTracksSectionHeader = await testUtils.getNodeForElement('audioTracksSectionHeader');
    expect(audioTracksSectionHeader.visible).to.be.true;

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/424863
  it('C424863 - Registered User: AD selection persists between sessions on same device (logout / login). @multiple_audio', async () => {
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await ecp.sendText('fifth plane');

    // Call function to navigate right to search results grid
    await navigateRightToGrid();

    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text).to.contain('Fifth Plane');
    });

    // Select item and Play button
    await ecp.sendKeyPress(ecp.Key.Ok);
    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Closed Caption audio button present?
    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.equal('pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp');

    // Navigate right to open Options
    await ecp.sendKeyPress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Validate options

    // Audio Section header
    const audioTracksSectionHeader = await testUtils.getNodeForElement('audioTracksSectionHeader');
    expect(audioTracksSectionHeader.visible).to.be.true;

    // Enable AD
    await ecp.sendKeyPress(ecp.Key.Down, { count: 3 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Start app with current user
    await testUtils.startApplicationAtPage('search', { user: user });
    await testUtils.waitForAppLaunchBeaconToFire();

    // Nav to AD container and playback any title
    await ecp.sendText('cosmo');

    // Call function to navigate right to search results grid
    await navigateRightToGrid();
    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text).to.contain('Cosmos');
    });

    // Verify AD is still enabled.
    // Select item and Play button
    await ecp.sendKeyPress(ecp.Key.Ok);
    await utils.sleep(2000);

    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Open player controls
    await ecp.sendKeyPress(ecp.Key.Play);


    // Navigate right to open Options
    expect(audioTracksSectionHeader.visible).to.be.true;
    await ecp.sendKeyPress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeyPress(ecp.Key.Ok);
    expect(audioTracksSectionHeader.text).to.include('Audio');

    // Verify that AD is still enabled
    await utils.sleep(3000);
    const audioDescriptionEnabledCheck = await testUtils.getNodeForElement('audioDescriptionEnabledCheck');
    expect(audioDescriptionEnabledCheck.visible).to.be.true;

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/426763
  it('C426763 - Video Player: Ensure that user is able view and toggle available audio and subtitle language options for each title @multiple_audio', async () => {
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await ecp.sendText('fifth plane');

    // Call function to navigate right to search results grid
    await navigateRightToGrid();

    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text).to.contain('Fifth Plane');
    });

    // Select item and Play button
    await ecp.sendKeyPress(ecp.Key.Ok);
    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeyPress(ecp.Key.Play);

    // Navigate right to open Options
    await testUtils.expectPlayerStateToEventuallyEqual('pause');
    await ecp.sendKeyPress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Validate CC and MA options

    // Subtitles toggle
    const closedCaptionSection = await testUtils.getNodeForElement('closedCaptionSection');
    expect(closedCaptionSection.visible).to.be.true;

    // Subtitles enabled?
    await ecp.sendKeyPress(ecp.Key.Down); // navigate to Subtitle language
    await ecp.sendKeyPress(ecp.Key.Ok); // Select

    // Verify
    const subTitleEnabled = await testUtils.getNodeForElement('subTitleEnabled');
    expect(subTitleEnabled.visible).to.be.true;

    // Audio tracks section
    const audioTracksSection = await testUtils.getNodeForElement('audioTracksSection');
    expect(audioTracksSection.visible).to.be.true;
    await utils.sleep(3000);


    // Audio enabled?
    await ecp.sendKeyPress(ecp.Key.Down, { count: 1 }); // navigate to Audio language
    await ecp.sendKeyPress(ecp.Key.Ok); // Select
    await utils.sleep(3000);
    const audioEnabled = await testUtils.getNodeForElement('audioEnabled');
    expect(audioEnabled.visible).to.be.true;

    // Audio Description enabled?
    await ecp.sendKeyPress(ecp.Key.Down); // navigate to Subtitle language
    await ecp.sendKeyPress(ecp.Key.Ok); // Select
    const audioDescriptionEnabled = await testUtils.getNodeForElement('audioDescriptionEnabled');
    expect(audioDescriptionEnabled.visible).to.be.true;
  });
});


// Navigate right until the grid is in focus
async function navigateRightToGrid() {
  await testUtils.untilTrue(async () => {
    await ecp.sendKeyPress(ecp.Key.Right);
    const { value: id } = await odc.getValue({
      base: 'focusedNode',
      keyPath: 'id'
    });
    return id === 'ResultGrid';
  }, 'ResultGrid never obtained focus');
}
