import { expect } from 'chai';
import { odc, ecp } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Playback', function () {
    before(async () => {
      await testUtils.signIntoAccount();
      await testUtils.restartApplication({
        launchParameters: {
          mediaType: 'episode',
          contentId: 111770
        }
      });
    });


    it('C4163/C4162- Pause Playback @playback_1,@registered_user,@smoke', async () => {
      // Make helper to wait until set
      await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
      await ecp.sendKeyPress(ecp.Key.Play);
      await testUtils.expectPlayerStateToEventuallyEqual('pause');
    });
});
