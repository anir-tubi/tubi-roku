import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

import { shared } from '../shared';
import { waitForDebugger } from 'inspector';

describe('Autoplay Movies', function () {
    
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/105693
    it('105693 - Autoplay - Movie - When movie reaches the credit cue point then autoplay triggers @autoplay', async () => {
          
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
          
        // Are we on the Movies page?
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
        
        //Play title, seek to trigger cuepoint
        await ecp.sendKeypress(ecp.Key.Play);
        await seekToTriggerCuePoint();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();    

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/70395
    it('C70395 - Autoplay - Movie - Timer resets as users navigates within the titles in autoplay UI @autoplay', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the Movies page?
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
  
        //Play title, check cue point
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await seekToTriggerCuePoint();
        await ecp.sendKeypress(ecp.Key.Play);

        // Autoplay triggered?
        await checkForAutoPlayTrigger();

        
        // Scroll to next selection
        await ecp.sendKeypress(ecp.Key.Right);

        // Timer restarts?
        await testUtils.waitForElementToFullyShowOnScreen('countDownMovieAutoPlay');
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.text).does.not.contain('1');

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25123
    it('C25123 - Autoplay - Movie - When user chooses last title on the list then movie plays @autoplay', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the Movies page?
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
    
        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeypress(ecp.Key.Play);
        await seekToTriggerCuePoint();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();
     
        // Scroll to last selection
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right, { count: 10 });

        // Press OK, does movie start?
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing');


    });
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76105
    it('C76105 - Autoplay - Movie - When user chooses first title on the list then movie plays @autoplay', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the Movies page?
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

        //Play title, trigger autoplays
        await ecp.sendKeypress(ecp.Key.Play);
        await seekToTriggerCuePoint();
       
        // Autoplay triggered?
        await ecp.sendKeypress(ecp.Key.Play);
        await checkForAutoPlayTrigger();

        // Press OK for 1st movie title, does movie start?
        await testUtils.waitForElementToFullyShowOnScreen('autoPlayTitle');
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 16000);

    });
    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76115

    it('C76115 - Autoplay - Movie - When content focused then year and duration displayed @autoplay', async () => {

        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the Movies page?
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
        
        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeypress(ecp.Key.Play);
        await seekToTriggerCuePoint();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();

        // Is the Year displayed on the autoplay option?
        const autoPlayYearAndDuration = testUtils.getNodeForElement('autoPlayYearAndDuration');
        expect((await autoPlayYearAndDuration).text).contains('h');
    });

    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76116
    it('C148692 - Autoplay - Movie - When user searches for a movie and initiates playback, Autoplay should work @autoplay,@smoke', async () => {
        // Search for a Movie title
        await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
        await testUtils.waitForElementToFullyShowOnScreen('searchKeyPad');
        await ecp.sendText('zapped');
        await testUtils.waitForElementToFullyShowOnScreen('searchResultsText');

      // Navigate right until the grid is in focus
        await testUtils.untilTrue(async () => {
          await ecp.sendKeypress(ecp.Key.Right);
          const { value: id } = await odc.getValue({
              base: 'focusedNode',
              keyPath: 'id'
          });
          return id === 'ResultGrid';
        }, 'ResultGrid never obtained focus');

      // Wait until our content is loaded
      await odc.onFieldChangeOnce({
          base: 'focusedNode',
          keyPath: 'content',
          match: {
              base: 'focusedNode',
              keyPath: 'content.0.title',
              value: 'Zapped'
          }
      });
       

        //Play title, trigger autoplay
        await ecp.sendKeypress(ecp.Key.Play);
        await seekToTriggerCuePoint();
     
        // Autoplay triggered?
        await checkForAutoPlayTrigger();

        // Is the Year displayed on the autoplay option?
        await testUtils.waitForElementToFullyShowOnScreen('autoPlayYearAndDuration');
        
    });
});

async function seekToTriggerCuePoint() {
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing');
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');
}

async function checkForAutoPlayTrigger() {
    await testUtils.waitForElementToFullyShowOnScreen('countDownMovieAutoPlay');
    const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
    expect(countDownMovieAutoPlay.text).to.contain('Starting');
}
