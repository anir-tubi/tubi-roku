import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Autoplay TV', function () {
    before(async () => {
        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });

    });
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/70577
    it('C70577 - Autoplay - Series - When series reaches the credit cue point then autoplay triggers @autoplay,@smoke', async () => {

        // Are we on the Series page?
        const tvScreenRowList = await testUtils.getNodeForElement('tvScreenRowList');
        expect(tvScreenRowList.visible).to.equal(true);

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535750
    it('C535750 - Autoplay - Series - When autoplay timer expires then next episode autoplays @autoplay,@smoke', async () => {

        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });

        // Are we on the Series page?
        const tvScreenRowList = await testUtils.getNodeForElement('tvScreenRowList');
        expect(tvScreenRowList.visible).to.equal(true);

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();


        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Let it expire
        await utils.sleep(16000);

        // Is next episode playing?
        const videoPlayerActual = testUtils.getNodeForElement('videoPlayerActual');
        expect((await videoPlayerActual).visible).to.be.true;
        await testUtils.expectPlayerStateToEventuallyEqual('play');

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535854
    it('C535854 - Autoplay - Series - Next episode plays after multiple consecutive autoplays @autoplay,@smoke', async () => {

        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });


        // Are we on the Series page?
        const tvScreenRowList = await testUtils.getNodeForElement('tvScreenRowList');
        expect(tvScreenRowList.visible).to.equal(true);
        await utils.sleep(2000);
        await ecp.sendKeyPress(ecp.Key.Right);

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Is next episode playing?
        const videoPlayerActual = testUtils.getNodeForElement('videoPlayerActual');
        expect((await videoPlayerActual).visible).to.be.true;
        await testUtils.expectPlayerStateToEventuallyEqual('play');

        // Play Next Episode
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Is next episode playing?
        expect((await videoPlayerActual).visible).to.be.true;
        await testUtils.expectPlayerStateToEventuallyEqual('play');

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535749
    it('C535749 - Autoplay - Series - When user presses the Back button then series autoplay UI is dismissed @autoplay,@smoke', async () => {

        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });

        // Are we on the Series page?
        const tvScreenRowList = await testUtils.getNodeForElement('tvScreenRowList');
        expect(tvScreenRowList.visible).to.equal(true);

        // Trigger Series Autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        let autoplayUpNextUI = await testUtils.getNodeForElement('autoplayUpNextUI');
        expect(autoplayUpNextUI.opacity).to.be.greaterThan(0);

        // Press Back
        await ecp.sendKeyPress(ecp.Key.Back);

        // Is Autoplay dismissed?
        autoplayUpNextUI = await testUtils.getNodeForElement('autoplayUpNextUI');
        expect(autoplayUpNextUI.opacity).to.be.greaterThan(0);

    });

    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/148693
    it('C148693 - Autoplay - Series- When user searches for a Series and initiates playback, Autoplay should work @autoplay,@smoke', async () => {

        // Search for a Series title
        await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
        await ecp.sendText('lego masters uk');

        // Call function to navigate right to search results grid
        await shared.navigateRightToGrid();

        await testUtils.retryWithTimeOut(async () => {
            const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
            expect(searchResultsText.text).to.equal('Lego Masters UK');
        });

        //Play title, trigger autoplay
        await triggerSeriesAutoplay();

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

    });
});

async function triggerSeriesAutoplay() {
    //Play title, pause to open player, move right to FF button and press, verify state
    await utils.sleep(3000);
    await ecp.sendKeyPress(ecp.Key.Play);
    await utils.sleep(3000);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeyPress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await ecp.sendKeyPress(ecp.Key.Right, { count: 2 });

    // FF button highlighted
    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);

    // Press FF button 3 times
    await ecp.sendKeyPress(ecp.Key.Ok, { count: 3 });

    // FF until cue point
    await utils.sleep(33000);

    // Play to trigger autoplay
    await ecp.sendKeyPress(ecp.Key.Play);
}
