import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Autoplay TV', function () {
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/70577
    it('C70577 - Autoplay - Series - When series reaches the credit cue point then autoplay triggers @autoplay', async () => {
        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();
        

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535750
    it('C535750 - Autoplay - Series - When autoplay timer expires then next episode autoplays @autoplay', async () => {

        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();

        // Is next episode playing?
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 16000);

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535854
    it('C535854 - Autoplay - Series - Next episode plays after multiple consecutive autoplays @autoplay', async () => {

        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
    
        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();

        // Is next episode playing?
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 16000);
        await ecp.sendKeypress(ecp.Key.Play);

        // Play Next Episode
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();
        await ecp.sendKeypress(ecp.Key.Play);

        // Is next episode playing?
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535749
    it('C535749 - Autoplay - Series - When user presses the Back button then series autoplay UI is dismissed @autoplay', async () => {

        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();

        // Press Back
        await ecp.sendKeypress(ecp.Key.Back);

        // Is Autoplay dismissed?
        await testUtils.waitForElementToNotShowOnScreen('countDownSeriesAutoPlay');
       

    });

    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/148693
    it('C148693 - Autoplay - Series- When user searches for a Series and initiates playback, Autoplay should work @autoplay', async () => {

        // Search for a Series title
        await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
        await ecp.sendText('lego masters');

        // Call function to navigate right to search results grid
        await shared.navigateRightToGrid();

        await testUtils.retryWithTimeOut(async () => {
            const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
            expect(searchResultsText.text).to.equal('LEGO Masters');
        });

        //Play title, trigger autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        await checkForAutoPlayTrigger();
    });
});

async function triggerSeriesAutoplay() {
    //Play title, seek to autoplay cue point
    
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 15000);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','paused');
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');
}

async function checkForAutoPlayTrigger() {
    await testUtils.waitForElementToFullyShowOnScreen('countDownSeriesAutoPlay');
    const countDownSeriesAutoPlay = await testUtils.getNodeForElement('countDownSeriesAutoPlay');
    expect(countDownSeriesAutoPlay.text).to.contain('Starting');
}

