import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { waitForDebugger } from 'inspector';

describe('Autoplay Movies', function () {
    before(async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/105693
    it('105693 - Autoplay - Movie - When movie reaches the credit cue point then autoplay triggers @autoplay,@smoke', async () => {
        // Are we on the series page?
        const movieScreenRowList = await testUtils.getNodeForElement('movieScreenRowList');
        expect(movieScreenRowList.visible).to.equal(true);

        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeyPress(ecp.Key.Play);
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
        await utils.sleep(60000);

        // Play to trigger autoplay
        await ecp.sendKeyPress(ecp.Key.Play);

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

    });
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/70395
    it('C70395 - Autoplay - Movie - Timer resets as users navigates within the titles in autoplay UI @autoplay,@smoke', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the movies page?
        const movieScreenRowList = await testUtils.getNodeForElement('movieScreenRowList');
        expect(movieScreenRowList.visible).to.equal(true);

        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeyPress(ecp.Key.Play);
        const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
        expect(videoPlayerActual.visible).to.equal(true);
        await utils.sleep(500); //Improvement
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
        await utils.sleep(60000);

        // Play to trigger autoplay
        await ecp.sendKeyPress(ecp.Key.Play);

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Scroll to next selection
        await utils.sleep(10000);
        await ecp.sendKeyPress(ecp.Key.Right);

        // Timer restarts?
        await utils.sleep(1000);
        expect(countDownMovieAutoPlay.text).does.not.contain('1');

    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25123
    it('C25123 - Autoplay - Movie - When user chooses last title on the list then movie plays @autoplay,@smoke', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        // Are we on the series page?
        const movieScreenRowList = await testUtils.getNodeForElement('movieScreenRowList');
        expect(movieScreenRowList.visible).to.equal(true);

        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeyPress(ecp.Key.Play);
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
        await utils.sleep(60000);

        // Play to trigger autoplay
        await ecp.sendKeyPress(ecp.Key.Play);
        await utils.sleep(1000);

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Scroll to last selection
        await utils.sleep(1000);
        await ecp.sendKeyPress(ecp.Key.Right, { count: 10 });

        // Press OK, does movie start?
        await ecp.sendKeyPress(ecp.Key.Ok);
        expect(videoPlayerActual.visible).to.equal(true);
        await testUtils.expectPlayerStateToEventuallyEqual('play');


    });
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76105
    it('C76105 - Autoplay - Movie - When user chooses first title on the list then movie plays @autoplay,@smoke', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the series page?
        const movieScreenRowList = await testUtils.getNodeForElement('movieScreenRowList');
        expect(movieScreenRowList.visible).to.equal(true);

        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeyPress(ecp.Key.Play);
        const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
        expect(videoPlayerActual.visible).to.equal(true);
        await testUtils.expectPlayerStateToEventuallyEqual('play');
        await utils.sleep(500);
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
        await utils.sleep(60000);

        // Play to trigger autoplay
        await ecp.sendKeyPress(ecp.Key.Play);

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Press OK for 1st movie title, does movie start?
        await ecp.sendKeyPress(ecp.Key.Ok);
        expect(videoPlayerActual.visible).to.equal(true);
        await testUtils.expectPlayerStateToEventuallyEqual('play');

    });
    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76115
    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76116
    it('C76115 - Autoplay - Movie - When content focused then year and duration displayed @autoplay,@smoke', async () => {

        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });

        // Are we on the series page?
        const movieScreenRowList = await testUtils.getNodeForElement('movieScreenRowList');
        expect(movieScreenRowList.visible).to.equal(true);

        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeyPress(ecp.Key.Play);
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
        await utils.sleep(100000);

        // Play to trigger autoplay
        await ecp.sendKeyPress(ecp.Key.Play);

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Is the Year displayed on the autoplay option?
        const autoPlayYearAndDuration = testUtils.getNodeForElement('autoPlayYearAndDuration');
        expect((await autoPlayYearAndDuration).visible).to.be.true;


    });
    //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76116
    it('C148692 - Autoplay - Movie - When user searches for a movie and initiates playback, Autoplay should work @autoplay,@smoke', async () => {

        // Search for a Movie title
        await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
        await ecp.sendText('zapp');

        // Call function to navigate right to search results grid
        await shared.navigateRightToGrid();

        await testUtils.retryWithTimeOut(async () => {
            const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
            expect(searchResultsText.text).to.equal('Zapped');
        });

        //Play title, pause to open player, move right to FF button and press, verify state
        await ecp.sendKeyPress(ecp.Key.Play);
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

        // Press FF button three times
        await ecp.sendKeyPress(ecp.Key.Ok, { count: 3 });

        // FF until cue point
        await utils.sleep(60000);

        // Play to trigger autoplay
        await ecp.sendKeyPress(ecp.Key.Play);

        // Autoplay triggered?
        const countDownMovieAutoPlay = await testUtils.getNodeForElement('countDownMovieAutoPlay');
        expect(countDownMovieAutoPlay.visible).to.equal(true);

        // Is the Year displayed on the autoplay option?
        const autoPlayYearAndDuration = testUtils.getNodeForElement('autoPlayYearAndDuration');
        expect((await autoPlayYearAndDuration).visible).to.be.true;


    });
});
