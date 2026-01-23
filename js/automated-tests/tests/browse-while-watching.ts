import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { ParentalRating, testUtils } from '../test-utils';
import { shared } from '../test-helpers';

describe('Browse While Watching', function () {
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611427
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/781339
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/833541
    it('C611427 - BWW is shown below transport controls during movie playback @browse_watching', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not visible', 10000);
        await ecp.sendKeypress(ecp.Key.Down, { wait: 1000 });
        await utils.sleep(1000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611428
    it('C611428 - BWW is shown below transport controls during series playback @browse_watching', async () => {
        await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });
        await utils.sleep(2000);
        await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls during series playback', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611429
    it('C611429 - With transport controls displayed, pressing "down" expands the BWW section @regression @guest', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(1000);

        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);

        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW section did not expand', 10000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingRowList', 'BWW row list not visible', 10000);

        const bwwRowList = await testUtils.getNodeForElement('browseWhileWatchingRowList');
        expect(bwwRowList.visible).to.equal(true, 'BWW section should be visible after pressing down');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611433
    it('C611433 - When BWW is expanded, tapping "back" minimizes it @browse_watching', async () => {
        await testUtils.goToPage('movies');
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Movie screen row not found', 15000);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForElementToFullyShowOnScreen('playButton', 'Play button not found', 15000);
        await ecp.sendKeypress(ecp.Key.Ok);

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'player controls not present', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down, { wait: 1000 });
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW rows not shown', 10000);

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await ecp.sendKeypress(ecp.Key.Back);

        await testUtils.waitForElementToNotShowOnScreen('transportButtons', 'Transport section is still displayed', 10000);

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611434
    it('C611434 - When BWW is expanded, tapping "up" minimizes it @browse_watching', async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

        await testUtils.goToPage('movies');
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Movie screen row not found', 15000);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForElementToFullyShowOnScreen('playButton', 'Play button not found', 15000);
        await ecp.sendKeypress(ecp.Key.Ok);

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await ecp.sendKeypress(ecp.Key.Up);

        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown after pressing up', 10000);
        await testUtils.waitForElementToNotShowOnScreen('browseWhileWatchingHeader', 'BWW still visible after pressing up', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611432
    it('C611432 - When title in BWW is in focus, tapping "ok" will begin playback of that title @browse_watching', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);

        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown', 10000);

        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingMetadata', 'BWW title not visible', 15000);
        const bwwTitle = await testUtils.getNodeForElement('browseWhileWatchingMetadata');
        const originalBwwTitleText = bwwTitle.text;

        await ecp.sendKeypress(ecp.Key.Ok);

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Back);
        await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

        await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 10000);
        const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');

        expect(detailScreenTitle.text).to.equal(originalBwwTitleText);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611438
    it('C611438 - When title in BWW is in focus, tapping "play/pause" button will play/pause current playing title @browse_watching', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);

        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused', 5000);

        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611435
    it('C611435 - X seconds of inactivity hides BWW row and transport controls @browse_watching', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);

        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW section not shown', 10000);

        await utils.sleep(5000);
        await testUtils.waitForElementToNotShowOnScreen('browseWhileWatchingHeader', 'BWW header still visible after inactivity', 3000);
        await testUtils.waitForElementToNotShowOnScreen('transportButtons', 'Transport controls still visible after inactivity', 3000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611443
    it('C611443 - BWW is NOT shown below transport controls when in Kids Mode @browse_watching @kids_mode', async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

        // Open Kids Mode from left nav
        await ecp.sendKeypress(ecp.Key.Left);
        await ecp.sendKeypress(ecp.Key.Up);
        await ecp.sendKeypress(ecp.Key.Up);
        await utils.sleep(500);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForElementToFullyShowOnScreen('exitKidsOption');

        // Navigate back to home screen content
        await ecp.sendKeypress(ecp.Key.Right);
        await utils.sleep(2000);
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist focus');

        // Play any VOD
        await ecp.sendKeypress(ecp.Key.Play);

        // Wait for playback to start
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);

        // Display transport controls
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        await utils.sleep(1000);

        // Press Down again to attempt to navigate to BWW
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        // Verify BWW is NOT shown below transport controls
        await testUtils.waitForElementToNotShowOnScreen('browseWhileWatchingHeader', 'BWW should not be shown in Kids Mode', 5000);
    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611444
    it('C611444 - YMAL is NOT shown below transport controls when PC = Little Kids, @browse_watching', async () => {
        // Create registered user, set PC to little Kids
        const user = await testUtils.createRegisteredUser();
        await user.changeParentalRating(ParentalRating.littleKids);
        // Launch to home page
        await testUtils.startApplicationAtPage('home', { user: user });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play);
        // Verify YMAL row NOT in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToNotShowOnScreen('browseWhileWatchingHeader', 'BWW should not be shown on screen', 3000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/711429
    it('C711429 - BWW is NOT shown below transport controls when Parental Controls = Older Kids, @browse_watching', async () => {
        // Create registered user, set PC to older Kids
        const user = await testUtils.createRegisteredUser();
        await user.changeParentalRating(ParentalRating.olderKids);

        // Launch to home page
        await testUtils.startApplicationAtPage('home', { user: user });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play);
        // Verify YMAL row NOT in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToNotShowOnScreen('browseWhileWatchingHeader', 'BWW should not be shown on screen', 3000);
    });

    //  Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611442
    it('C611442 - When Parental Controls = Teen, BWW screen does NOT have content over TV-14 or PG-13, @browse_watching', async () => {
        // Create registered user, set PC to Teens
        const user = await testUtils.createRegisteredUser();
        await user.changeParentalRating(ParentalRating.teens);
        await testUtils.startApplicationAtPage('home', { user: user });
        await testUtils.waitForApplicationStartup();
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
        // Ensure we're focused on playable content before pressing Play
        await shared.ensurePlayableContentFocused();
        // Select a movie title and Play
        await ecp.sendKeypress(ecp.Key.Play);
        // Verify YMAL row in player
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW is not shown on screen', 4000);
        const rowItemsContent = await testUtils.getAllGridItemsContent('browseWhileWatchingRowList');
        for (const itemContent of rowItemsContent) {
            expect(['R', 'MA', 'TV-MA', 'NR'].includes(itemContent.type)).to.be.false;
        }
    });

    // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/611441
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/794353
    it('C611441 - BWW is shown below transport controls when in Español mode @browse_watching @espanol', async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen');

        await ecp.sendKeypress(ecp.Key.Left);
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down, { count: 6 });
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForElementToHaveFocus('espanolScreenRowList', 'Failed to navigate to Español screen');
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not displayed', 10000);
        await utils.sleep(3500);
        await ecp.sendKeypress(ecp.Key.Down, { wait: 1000 });
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);
        const bwwHeader = await testUtils.getNodeForElement('browseWhileWatchingHeader');
        expect(bwwHeader.visible).to.equal(true);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/685432
    it('C685432 - Metadata area should NOT show Starring/Directed By info @browse_watching @guest', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movie row list focus');
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW section not shown', 10000);
        await utils.sleep(1000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingMetadata', 'BWW metadata not visible', 10000);
        const metadata = await testUtils.getNodeForElement('browseWhileWatchingMetadata');
        const starringPattern = /starring|star:|cast:/i;
        const directedByPattern = /directed by|director:|directed:/i;
        expect(metadata.text).to.not.match(starringPattern, 'Metadata should NOT contain Starring information');
        expect(metadata.text).to.not.match(directedByPattern, 'Metadata should NOT contain Directed By information');

        const metadataDescription = await testUtils.getNodeForElement('browseWhileWatchingMetadataDescription');
        expect(metadataDescription.text).to.not.match(starringPattern, 'Metadata should NOT contain Starring information');
        expect(metadataDescription.text).to.not.match(directedByPattern, 'Metadata should NOT contain Directed By information');

        const metadataSubtitleLine1 = await testUtils.getNodeForElement('browseWhileWatchingMetadataSubtitleLine1');
        expect(metadataSubtitleLine1.text).to.not.match(starringPattern, 'Metadata should NOT contain Starring information');
        expect(metadataSubtitleLine1.text).to.not.match(directedByPattern, 'Metadata should NOT contain Directed By information');

        const metadataSubtitleLine2 = await testUtils.getNodeForElement('browseWhileWatchingMetadataSubtitleLine2');
        expect(metadataSubtitleLine2.text).to.not.match(starringPattern, 'Metadata should NOT contain Starring information');
        expect(metadataSubtitleLine2.text).to.not.match(directedByPattern, 'Metadata should NOT contain Directed By information');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611448
    it('C611448 - Details page of the currently playing title should be shown when backing out of playback, @browse_watching', async () => {
        // Step 1: Launch app
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
        // Step 2: Play any VOD (Title A)
        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(3000);
        // Get Title A name
        const titleAContent = await testUtils.getElementField('videoPlayerScreen', 'content');
        const titleA = titleAContent.title;
        // Step 3: Display transport controls
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        // Step 4: Press down to expand BWW section
        await utils.sleep(3500);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown', 10000);
        // Step 5: Play any VOD in BWW (Title B)
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(3000);
        // Get Title B name
        const titleBContent = await testUtils.getElementField('videoPlayerScreen', 'content');
        const titleB = titleBContent.title;
        // Verify Title B is different from Title A
        expect(titleB).to.not.equal(titleA, 'Title B should be different from Title A');
        // Step 6: Display transport controls
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        // Step 7: Press down to expand BWW section
        await utils.sleep(3500);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown', 10000);
        // Step 8: Play any VOD in BWW (Title C)
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(3000);
        // Get Title C name
        const titleCContent = await testUtils.getElementField('videoPlayerScreen', 'content');
        const titleC = titleCContent.title;
        // Verify Title C is different from Title B
        expect(titleC).to.not.equal(titleB, 'Title C should be different from Title B');
        // Step 9: FFWD to at least 5 min mark
        await ecp.sendKeypress(ecp.Key.Forward, { count: 10, wait: 500 });
        await ecp.sendKeypress(ecp.Key.Play);
        await utils.sleep(2000);
        // Step 10: Press back on remote
        await ecp.sendKeypress(ecp.Key.Back);
        await utils.sleep(2000);
        await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
        // Verify details page is for Title C (currently playing title)
        await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not shown', 10000);
        const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
        expect(detailScreenTitle.text).to.equal(titleC);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611439
    it('C611439 - BWW is shown below transport controls when deeplinking to movie @browse_watching', async () => {
        await testUtils.startApplicationWithDeeplink({ mediaType: 'movie', contentID: '342067', shouldCreateNewUser: true });
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not displayed', 10000);
        await utils.sleep(3500);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611440
    it('C611440 - BWW is shown below transport controls when deeplinking to series @browse_watching', async () => {
        // Deeplink to a series
        await testUtils.startApplicationWithDeeplink({ mediaType: 'episode', contentID: '200051058', shouldCreateNewUser: true });
        // Wait for episode to start playing
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        // Display transport controls
        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        // Navigate down to BWW section
        await utils.sleep(3500);
        await ecp.sendKeypress(ecp.Key.Down);
        // Verify BWW is shown below transport controls
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611446
    it('C611446 - BWW is shown below transport controls for Guest User @browse_watching', async () => {
        await testUtils.startApplicationWithDeeplink({ mediaType: 'movie', contentID: '342067', shouldCreateNewUser: false });

        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);

        await utils.sleep(3500);
        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/833542
    it('C833542 - YMAL BWW has 20 titles max @regression @guest @manual_regression', async () => {
        await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
        await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

        await ecp.sendKeypress(ecp.Key.Play);
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
        await utils.sleep(1000);

        await ecp.sendKeypress(ecp.Key.Down);
        await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls not shown', 10000);
        await utils.sleep(1000);

        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(1000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW section not shown', 10000);
        await testUtils.waitForElementToShowOnScreen('browseWhileWatchingRowList', 'BWW row list not visible', 10000);

        const rowItemsContent = await testUtils.getAllGridItemsContent('browseWhileWatchingRowList');
        expect(rowItemsContent.length).to.be.at.most(20, 'BWW YMAL section should have maximum 20 titles');
    });
});