import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { User, testUtils } from '../test-utils';
import { shared } from '../shared';
import { count, timeEnd } from 'console';

describe('Multiple Audio', function () {
  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/403409
  it('C403409 - Video Player - New Audio / subtitle icon @multiple_audio', async () => {
    await testUtils.startApplicationWithDeeplink({mediaType: 'episode', contentID: '526358', shouldCreateNewUser: true });

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Closed Caption audio button present?
    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-subtitles');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/403413
  it('C403413 - Video Player - New Audio / subtitle menu selection @multiple_audio, @smoke', async () => {
    await testUtils.startApplicationWithDeeplink({mediaType: 'episode', contentID: '526358', shouldCreateNewUser: true });
    

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Up);

    // Closed Caption audio button present?
    await utils.sleep(800);
    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-subtitles');

    // Navigate right to open Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Validate options

    // CC Section Header present?
    const closedCaptionSectionHeaderLabel = await testUtils.getNodeForElement('closedCaptionSectionHeaderLabel');
    expect (closedCaptionSectionHeaderLabel.text).to.equal('Subtitles');


    // Audio Section header present?
    const audioTracksSectionHeaderLabel = await testUtils.getNodeForElement('audioTracksSectionHeaderLabel');
    expect(audioTracksSectionHeaderLabel.text).to.equal('Audio');

    // Reset AD controls to default
    await resetAudioOptions();

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/424863
  it('C424863 - Registered User: AD selection persists between sessions on same device (logout / login). @multiple_audio', async () => {
    
    const user = await testUtils.createRegisteredUser();
    await testUtils.startApplicationWithDeeplink({mediaType: 'episode', contentID: '526358'}, {user: user});
    
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Closed Caption audio button present?
    await ecp.sendKeypress(ecp.Key.Ok);
    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-subtitles');

    // Navigate right to open Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Validate options
    // CC Section Header present?
    const closedCaptionSectionHeaderLabel = await testUtils.getNodeForElement('closedCaptionSectionHeaderLabel');
    expect (closedCaptionSectionHeaderLabel.text).to.equal('Subtitles');


    // Audio Section header present?
    const audioTracksSectionHeaderLabel = await testUtils.getNodeForElement('audioTracksSectionHeaderLabel');
    expect(audioTracksSectionHeaderLabel.text).to.equal('Audio');

    // Enable AD
    // Adding a slight delay between key downs.
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 100 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Start app user
    await testUtils.startApplicationWithDeeplink({mediaType: 'episode', contentID: '526358'}, {user: user});

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Open player controls
    await ecp.sendKeypress(ecp.Key.Up);

    // Navigate right to open Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok, {wait:2500});

    // Verify that AD is still enabled
    await testUtils.waitForElementToFullyShowOnScreen('audioDescriptionItemChecked');

    // Reset AD controls to default
    await resetAudioOptions();


  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/426763
  it('C426763 - Video Player: Ensure that user is able view and toggle available audio and subtitle language options for each title @multiple_audio', async () => {
    await testUtils.startApplicationWithDeeplink({mediaType: 'episode', contentID: '526358', shouldCreateNewUser: true });

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);

    // Navigate right to open Options
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Validate CC and MA options

    // Subtitles toggle
    const closedCaptionSection = await testUtils.getNodeForElement('closedCaptionSection');
    expect(closedCaptionSection.visible).to.be.true;

    // Subtitles enabled?
    await ecp.sendKeypress(ecp.Key.Down, {count:2} ); // navigate to Subtitle language
    await ecp.sendKeypress(ecp.Key.Ok); // Select

    // Verify
    const subTitleEnabled = await testUtils.getNodeForElement('subTitleEnabled');

    // Audio tracks section
    const audioTracksSection = await testUtils.getNodeForElement('audioTracksSection');
    expect(audioTracksSection.visible).to.be.true;
    await utils.sleep(3000);

    // Audio enabled?
    await ecp.sendKeypress(ecp.Key.Down, { count: 2 }); // navigate to Audio language
    await ecp.sendKeypress(ecp.Key.Ok); // Select
    await utils.sleep(3000);
    const audioEnabled = await testUtils.getNodeForElement('audioEnabled');
    expect(audioEnabled.visible).to.be.true;

    // Audio Description enabled?
    await ecp.sendKeypress(ecp.Key.Down); // navigate to Subtitle language
    await ecp.sendKeypress(ecp.Key.Ok); // Select
    const audioDescriptionEnabled = await testUtils.getNodeForElement('audioDescriptionEnabled');
    expect(audioDescriptionEnabled.visible).to.be.true;

    // Reset AD controls to default
    await resetAudioOptions();

  });
});

async function resetAudioOptions() {
  await ecp.sendKeypress(ecp.Key.Up);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendKeypress(ecp.Key.Down, {count: 3});
  await ecp.sendKeypress(ecp.Key.Ok);
}
