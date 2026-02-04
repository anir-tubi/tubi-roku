import { expect } from 'chai';
import { ecp, utils, proxy, odc } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';

/**
 * Helper function to get the currently airing program from a linear content item
 * Mimics the getCurrentLiveProgram logic from ExpandedTilePosterOverlay.brs
 */
export function getCurrentLiveProgram(content: any): any {
  if (!content.programs || content.programs.length === 0) {
    return null;
  }

  const now = new Date();

  // Find program that is currently airing (start_time <= now < end_time)
  for (const program of content.programs) {
    if (!program.start_time || !program.end_time) {
      continue;
    }

    const startTime = new Date(program.start_time);
    const endTime = new Date(program.end_time);

    if (startTime <= now && now < endTime) {
      return program;
    }
  }

  // No currently airing program found
  return null;
}

/**
 * Helper function to safely resume proxy
 * If proxy is not started, it will start it first before resuming
 */
export async function safeResumeProxy(): Promise<void> {
  try {
    proxy.resume();
  } catch (e) {
    console.error('Error resuming proxy: ', e);
    await proxy.start();
  }
}

/**
 * Helper function to set up ad mock and launch app
 * @param adTypes - Array of ad types to mock (default: [AdType.Wrapper])
 * @param additionalOptions - Optional additional fields to pass to startApplicationAtPage
 * @returns Promise that resolves when proxy setup is complete
 */
export async function setupAdMockAndLaunchApp(
  adTypes: AdType[] = [AdType.Wrapper],
  additionalOptions: any = {}
): Promise<{ cleanup?: () => void }> {
  await safeResumeProxy();

  // Extract valid_duration and persistCallback if provided
  const { validDuration, persistCallback, ...launchOptions } = additionalOptions;

  // Pass validDuration and persistCallback to mockAds
  const mockOptions: any = {};
  if (validDuration !== undefined) mockOptions.validDuration = validDuration;
  if (persistCallback !== undefined) mockOptions.persistCallback = persistCallback;

  const proxyPromise = adTestHelpers.mockAds(adTypes, Object.keys(mockOptions).length > 0 ? mockOptions : undefined);

  // Create registered user
  const user = await testUtils.createRegisteredUser();
  await testUtils.startApplicationAtPage('home', {
    user,
    clearRegistry: false,
    disableSkinAds: false,
    ...launchOptions
  });
  const result = await utils.promiseTimeout(proxyPromise, 50000);

  // Determine which element to wait for based on ad type
  const waitElement = adTypes.includes(AdType.Wrapper) ? 'skinAdRow' : 'videoTitlesRowList';
  await testUtils.waitForElementToHaveFocus(waitElement, `Timed out waiting for ${waitElement}`, 15000);

  return result;
}

/**
 * Helper function to verify ad player screen is displayed and ad is playing
 */
export async function verifyAdPlayerIsPlaying(): Promise<void> {
  // Verify ad player screen is displayed
  await testUtils.waitForCurrentScreenToEqual('adPlayerScreen', 10000);

  // Verify the ad is playing in fullscreen mode
  await testUtils.untilTrue(async () => {
    const videoPlayer = await testUtils.getNodeForElement('adPlayerVideo');
    return videoPlayer.state === 'playing';
  }, 'Wrapper ad should be playing in fullscreen', 10000);
}

/**
 * Helper function to verify ad player skin elements are visible in fullscreen
 */
export async function verifyAdPlayerElements(): Promise<void> {
  await testUtils.waitForElementToShowOnScreen('adPlayerSkinAdLogo', 'Ad player logo should be visible', 3000);
  const adPlayerLogoUri = await testUtils.getElementField('adPlayerSkinAdLogo', 'uri');
  expect(adPlayerLogoUri).to.not.be.empty;

  await testUtils.waitForElementToShowOnScreen('adPlayerSkinAdDescription', 'Ad player description should be visible', 3000);
  const adPlayerDescText = await testUtils.getElementField('adPlayerSkinAdDescription', 'text');
  expect(adPlayerDescText).to.not.be.empty;
}

/**
 * Helper function to reset Audio Description options to default
 * Used after audio/subtitle tests to clean up state
 */
export async function resetAudioOptions(): Promise<void> {
  await ecp.sendKeypress(ecp.Key.Up);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
  await ecp.sendKeypress(ecp.Key.Ok);
}

/**
 * Helper function to navigate to Privacy Center
 * Opens side nav, navigates to Settings, then to Privacy Center
 */
export async function goToPrivacyCenter(): Promise<void> {
  // Navigate to Settings using existing helper
  await testHelpers.openSettings();
  await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

  // Navigate to Privacy Center
  await testUtils.jumpToRowWithTitle('settingsMenu', 'Privacy Center');
  await ecp.sendKeypress(ecp.Key.Ok);
}

/**
 * Re-export shared and testHelpers for convenience
 */
export { testHelpers };
