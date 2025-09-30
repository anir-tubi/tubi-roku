import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';



describe('MyStuff', function () {


  // https://tubi.testrail.io/index.php?/cases/view/421096
  it('C421096 Guest User - My Stuff menu item available with Label, @mystuff', async () => {

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

  });

  // https://tubi.testrail.io/index.php?/cases/view/421097 - https://tubi.testrail.io/index.php?/cases/view/423509
  it('C421097 Guest User - Selecting the my stuff menu item displays the "unlock" screen, @mystuff', async () => {

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check unlock button and screen text for Guest user
    await testUtils.waitForElementToFullyShowOnScreen('myStuffEmptyScreen');
    const unlockNowForMyStuff = await testUtils.getNodeForElement('unlockNowForMyStuff');
    expect(unlockNowForMyStuff.text).to.equal('Unlock Now');
    const myStuffGuestScreenTextTitle = await testUtils.getNodeForElement('myStuffGuestScreenTextTitle');
    expect(myStuffGuestScreenTextTitle.text).to.equal('Make Tubi Yours for Free (Forever)');
    const myStuffGuestScreenTextSubTitle = await testUtils.getNodeForElement('myStuffGuestScreenTextSubTitle');
    expect(myStuffGuestScreenTextSubTitle.text).to.equal('Find your favorites fast, pick up where you left off–all in one place.');
    const myStuffGuestScreenTextBlurb = await testUtils.getNodeForElement('myStuffGuestScreenTextBlurb');
    expect(myStuffGuestScreenTextBlurb.text).to.equal('And always free.');

  });

  // https://tubi.testrail.io/index.php?/cases/view/148846
  it('C148846 Guest User - Selects register from Continue Watching row and creates account, @mystuff @registration', async () => {

    // Start app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Continue Watching row as guest user - should show "Sign Up to Save Your Progress"
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');

    // Verify the Continue Watching row shows registration prompt content
    await testUtils.waitForElementToFullyShowOnScreen('signUpToSaveProgressDescription');

    // Check CW row shows the registration prompt
    const continueWatchingRowContent = await testUtils.getCurrentlyFocusedGridItemContent('homeScreenRowList');
    expect(continueWatchingRowContent.title).to.equal('Sign Up to Save Your Progress');

    // Select the Continue Watching item - this should trigger registration flow
    await ecp.sendKeypress(ecp.Key.Ok);

    // Select register/unlock button to start registration flow
    await shared.completeGuestUserRegistrationFlow()

    // Verify Age Gate Screen
    await testUtils.waitForElementToFullyShowOnScreen('ageVerificationPad', 'age verification keypad not found', 10000);


    // For automation emails (@tubi.tv), the backend automatically processes the magic link
    // Wait for the automatic verification and transition to age gate
    await utils.sleep(5000); // Allow time for backend magic link processing

    // Age gate should appear after automatic magic link verification
    await testUtils.waitForElementToFullyShowOnScreen('ageVerificationPageHeader');

    // Enter valid age (over 13)
    await ecp.sendText('20');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Click "Start Watching" button on age gate completion
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingConsentPageAcceptButton');
    await ecp.sendKeypress(ecp.Key.Ok); // Click "Start Watching"

    // Should return to home screen as registered user
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for home screen after registration');
  });

  // https://tubi.testrail.io/index.php?/cases/view/421098 - https://tubi.testrail.io/index.php?/cases/view/423511
  it.skip('C421098 Guest User - Selecting the my stuff menu item and registering will display the empty my stuff page, @mystuff', async () => {

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check empty My Stuff page for Guest
    await testUtils.waitForElementToFullyShowOnScreen('myStuffEmptyScreen');

    // Select Unlock button
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(4000); //Sleep for Roku modal

    // Click Down, Ok to Cancel
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Create user
    const user = await testUtils.createRegisteredUser();
    const userInfo = user['userInfo'];

    // Are we on the Enter Email Address page? // Here
    await testUtils.waitForElementToFullyShowOnScreen('emailTextEditBox');

    // Enter user info email
    await ecp.sendText(userInfo.email);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Sign In, enter PW - Need to add automation account here
    await testUtils.waitForElementToFullyShowOnScreen('signInScreenPasswordBox');
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('111111');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Check empty My Stuff Page elements and text for Registered user
    await checkEmptyMyStuffScreenRegistered();

  });

  // https://tubi.testrail.io/index.php?/cases/view/421101
  it('C421101 Registered User - View My Stuff page when Continue Watching has titles and My List is empty, @mystuff', async () => {

    // Create user with history only
    const user = await testUtils.createRegisteredUser();
    await createHistory(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check that CW displays titles with history
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    const continueWatchingRowPoster = await testUtils.getNodeForElement('continueWatchingRowPoster');
    expect(continueWatchingRowPoster.id).to.equal('gradientPoster');
    expect(continueWatchingRowPoster.width).to.equal(520);

    // Check the My List displays no titles and displays correct indicators and text
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToFullyShowOnScreen('myListScreenTitle');
    await utils.sleep(2000);
    const emptyMyListContainerContent2 = await testUtils.getCurrentlyFocusedRowListRowItemsContent('emptyMyStuffContainer');
    expect(emptyMyListContainerContent2[0].title).to.equal('Your My List Is Empty');
    expect(emptyMyListContainerContent2[0].description).to.equal('Use the bookmark button to save favorite series and movies. They’ll show up here.');

  });

  // https://tubi.testrail.io/index.php?/cases/view/421103
  it('C421103 Registered User - Watching a title updates the continue watching section of the My Stuff page, @mystuff', async () => {

    // Create user with history (2 titles)
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // See that CW Row is empty
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    const emptyMyListContainerContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('emptyMyStuffContainer');
    expect(emptyMyListContainerContent[0].title).to.equal('You\'re All Caught Up!');
    expect(emptyMyListContainerContent[0].description).to.equal('Movies and series you haven’t finished will show up here.');

    // Select a title from home page, let it stream for more than > 1 minute
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await ecp.sendKeypress(ecp.Key.Ok);
    const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
    const detailScreenTitle1 = detailScreenTitle.text;
    await ecp.sendKeypress(ecp.Key.Play);
    await createHistoryForPlayingTitle();
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Go To My Stuff page
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Back);
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that the title appears in CW section of My Stuff page
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    const continueWatchingRowPoster = await testUtils.getNodeForElement('continueWatchingRowPoster');
    expect(continueWatchingRowPoster.id).to.equal('gradientPoster');
    expect(continueWatchingRowPoster.width).to.equal(520);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    const detailScreenTitle2 = await testUtils.getNodeForElement('detailScreenTitle');
    const detailScreenTitleMatch = detailScreenTitle2.text;
    expect(detailScreenTitleMatch).to.equal(detailScreenTitle1);

  });

  // https://tubi.testrail.io/index.php?/cases/view/421107
  it('C421107 Registered User - removing the last title in my list displays empty My Stuff page, @mystuff', async () => {

    // Create user with history (2 titles)
    const user = await testUtils.createRegisteredUser();
    await createWatchListOneTitle(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // See that CW Row is empty
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await testUtils.getCurrentlyFocusedRowListRowItemsContent('emptyMyStuffContainer');

    // Navigate to My List, select My List title and remove it
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToFullyShowOnScreen('myListScreenTitle');
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
    await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Add to My List');

    // Back to My Stuff Screen and verify the My List row is empty
    await ecp.sendKeypress(ecp.Key.Back);

    // Check the My Stuff page displays no titles and displays correct indicators and text
    await checkEmptyMyStuffScreenRegistered();

  });

  // https://tubi.testrail.io/index.php?/cases/view/421108
  it('C421108 Registered User - removing the last title in CW, displays empty My Stuff page, @mystuff', async () => {

    // Create user with history (1 title)
    const user = await testUtils.createRegisteredUser();
    await createHistoryOneTitle(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);


    // Check the My List displays no titles and displays correct indicators and text
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    await testUtils.waitForElementToFullyShowOnScreen('myListScreenTitle');
    const emptyMyListContainerContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('emptyMyStuffContainer');
    expect(emptyMyListContainerContent[0].title).to.equal('Your My List Is Empty');
    expect(emptyMyListContainerContent[0].description).to.equal('Use the bookmark button to save favorite series and movies. They’ll show up here.');

    // Verify that the title appears in CW section of My Stuff page
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    const continueWatchingRowPoster = await testUtils.getNodeForElement('continueWatchingRowPoster');
    expect(continueWatchingRowPoster.id).to.equal('gradientPoster');
    expect(continueWatchingRowPoster.width).to.equal(520);

    // Select the title and remove from history
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    await testUtils.waitForElementToFullyShowOnScreen('addToMyListButtonFocused', 'Button not found', 150000);


    // Check the My Stuff page displays no titles and displays correct indicators and text
    await ecp.sendKeypress(ecp.Key.Back);
    await checkEmptyMyStuffScreenRegistered();

  });

  // https://tubi.testrail.io/index.php?/cases/view/421109
  it('C421109 Registered User - after removing the rightmost title in my list, the focus is on the leftmost title (title to left for Roku), @mystuff', async () => {

    // Create user with history (3 titles)
    const user = await testUtils.createRegisteredUser();
    await createWatchListThreeTitles(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);

    // Check the My List displays no titles and displays correct indicators and text
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    await testUtils.waitForElementToFullyShowOnScreen('myListScreenTitle');

    // Select the 2nd title and check the title name
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
    const detailScreenTitle1 = detailScreenTitle.text;

    // Back to My List to remove the 3rd title
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await utils.sleep(2000);
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromMyList');
    await testUtils.waitForElementToNotShowOnScreen('removeFromMyListButton', 'Button not shown on screen', 15000);

    // Verify that the focus has moved to 2nd title and check title
    await utils.sleep(2000); // had to add sleep to get next line to work
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToFullyShowOnScreen('myListScreenTitle');
    const myListScreenTitle = await testUtils.getNodeForElement('myListScreenTitle');
    const myListScreenTitle2 = myListScreenTitle.text;
    expect(detailScreenTitle1).to.equal(myListScreenTitle2);

  });
  // https://tubi.testrail.io/index.php?/cases/view/421112
  it('C421112 Registered User - Selecting the back button twice on the My Stuff page expands the left menu and goes to the home menu item, @mystuff', async () => {

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check that user is on My Stuff Screen (empty)
    await testUtils.waitForElementToFullyShowOnScreen('myStuffRegUserEmptyScreen');

    // Press back twice
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Expect Home Side Nav item to be highlighted and on Home page
    await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButtonLabel');

  });
  // https://tubi.testrail.io/index.php?/cases/view/421262 - https://tubi.testrail.io/index.php?/cases/view/423512
  it('C421262 Registered User - Pressing Go to Home button from empty My Stuff page takes you to Home, @mystuff', async () => {

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check that user is on My Stuff Screen (empty)
    await testUtils.waitForElementToFullyShowOnScreen('myStuffRegUserEmptyScreen');
    await testUtils.waitForElementToFullyShowOnScreen('goHomeButtonMyStuff');

    // Press the Go Home button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Expect redirect to Home page
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

  });

  // https://tubi.testrail.io/index.php?/cases/view/421263 - https://tubi.testrail.io/index.php?/cases/view/423515
  it('C421263 Registered User - View My Stuff page when Continue Watching is empty and My List has titles, @mystuff', async () => {

    // Create user with history only
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Check that CW displays no titles and has correct text for empty row
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await utils.sleep(2000);
    const emptyMyStuffContainerContent1 = await testUtils.getCurrentlyFocusedRowListRowItemsContent('emptyMyStuffContainer');
    expect(emptyMyStuffContainerContent1[0].title).to.equal('You\'re All Caught Up!');
    expect(emptyMyStuffContainerContent1[0].description).to.equal('Movies and series you haven’t finished will show up here.');


    // Check that My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

  });

  // https://tubi.testrail.io/index.php?/cases/view/421264
  it('C421264 Registered User - View My Stuff page when Continue Watching and My List both have titles, @mystuff', async () => {

    // Create user with watch list and history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);
    await createHistory(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open side nav and navigate to My Stuff item
    await highlightMyStuffMenuItem();

    // Select My Stuff
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that the title appears in CW section of My Stuff page
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    const continueWatchingRowPoster = await testUtils.getNodeForElement('continueWatchingRowPoster');
    expect(continueWatchingRowPoster.id).to.equal('gradientPoster');
    expect(continueWatchingRowPoster.width).to.equal(520);

    // Check the My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

  });

  // My Stuff pre-populated tests
  // https://tubi.testrail.io/index.php?/cases/view/439698
  it('C439698 - Registered User - Video Preview does not play when Autoplay Previews is Off @mystuff', async () => {

    // Create user with watch list and history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);
    await createHistory(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Are we on Settings page?
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    // Waiting until the autoplay preview section is fully shown on screen.
    await testUtils.waitForElementToFullyShowOnScreen('autoplayPreviewOn');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to My Stuff screen
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Expect Home Side Nav item to be highlighted and on Home page
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'stopped');

    // Move down and check My List
    // Check the My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

    // Check that video preview is not playing when autoplay preview is turned off on My List Row
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'stopped');
  });

  // https://tubi.testrail.io/index.php?/cases/view/439694
  it('C439694 - Registered User - Video Preview for Continue Watching Movie @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryOneTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');
  });

  // https://tubi.testrail.io/index.php?/cases/view/439695
  it('C439695 - Registered User - Video Preview for Continue Watching Series @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryOneTitleSeries(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
  });

  //https://tubi.testrail.io/index.php?/cases/view/439696
  it('C439696 - Registered User - Video Preview for My List Movie @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createWatchListOneTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');


    // Move down and check My List
    // Check the My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

    // Check that video preview is playing when autoplay preview is turned on -  My List Row
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');
  });
  //https://tubi.testrail.io/index.php?/cases/view/439697
  it('C439697 - Registered User - Video Preview for My List Series @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createWatchListOneTitleSeries(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');


    // Move down and check My List
    // Check the My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

    // Check that video preview is playing when autoplay preview is turned on -  My List Row
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');
  });

  //https://tubi.testrail.io/index.php?/cases/view/439700 - https://tubi.testrail.io/index.php?/cases/view/439701
  it('C439700 - Registered User - Video Preview plays when switching titles in My List, title plays after preview @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');


    // Move down and check My List
    // Check the My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

    // Check that video preview is playing when autoplay preview is turned on -  My List Row
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Switch focus to another title and verify preview is playing
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);


  });

  //https://tubi.testrail.io/index.php?/cases/edit/439702
  it('C439702 - Registered User - Continue Watching Details Page for a Movie @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryEvergreenMovieTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');

    // Navigate to Details page of title and check Resume button and title
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');
    const correctTitle = await testUtils.getNodeForElement('titleMovieDetailsTitle');
    expect(correctTitle.text).to.equal('Zapped');

  });

  //https://tubi.testrail.io/index.php?/cases/edit/439703
  it('C439703 - Registered User - Continue Watching Details Page for a Series Title @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryEvergreenSeriesTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');

    // Navigate to Details page of title and check Resume button and title
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');
    const correctTitle = await testUtils.getNodeForElement('titleMovieDetailsTitle');
    expect(correctTitle.text).to.equal('The Masked Singer');

  });

  //https://tubi.testrail.io/index.php?/cases/edit/439704
  it('C439704 - Registered User - My List Details Page for a Movie @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryEvergreenMovieTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');

    // Navigate to My List row
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.id).is.equal('poster');

    // Navigate to Details page of title and check Resume button and title
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton', 'Resume button not found', 5000);
    const correctTitle = await testUtils.getNodeForElement('titleMovieDetailsTitle');
    expect(correctTitle.text).to.equal('Zapped');

  });

  //https://tubi.testrail.io/index.php?/cases/edit/439742
  it('C439742 - Registered User - Kids Mode - Video Preview for Continue Watching Movie @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryEvergreenMovieTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('kids', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');

    // Navigate to Details page of title and check Resume button and title
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');
    const correctTitle = await testUtils.getNodeForElement('titleMovieDetailsTitle');
    expect(correctTitle.text).to.equal('Zapped');

  });

  //https://tubi.testrail.io/index.php?/cases/edit/439744
  it('C439744 - Registered User - Kids Mode - Video Preview for My List Movie @mystuff', async () => {

    // Create user with history
    const user = await testUtils.createRegisteredUser();
    await createHistoryEvergreenMovieTitle(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('kids', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');

    // Navigate to Details page of title and check Resume button and title
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('resumePlayingButton');
    const correctTitle = await testUtils.getNodeForElement('titleMovieDetailsTitle');
    expect(correctTitle.text).to.equal('Zapped');

  });
  // https://tubi.testrail.io/index.php?/cases/view/439646
  it('C439646 - Kids - Registered User - Video Preview does not play when Autoplay Previews is Off @mystuff', async () => {

    // Create user with watch list and history
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);
    await createHistory(user);

    // Launch app on Home page
    await testUtils.startApplicationAtPage('kids', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Are we on Settings page?
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    // Waiting until the autoplay preview section is fully shown on screen.
    await testUtils.waitForElementToFullyShowOnScreen('autoplayPreviewOn');
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000); // Improvement
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('previewOff');

    // Navigate to My Stuff screen
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });

    // Expect Home Side Nav item to be highlighted and on Home page
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff Screen
    await highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', ['stopped', '']);

    // Move down and check My List
    // Check the My List displays titles 
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);
    const myListPosterContent = await testUtils.getNodeForElement('myListPoster');
    expect(myListPosterContent.height).is.equal(360);

    // Check that video preview is not playing when autoplay preview is turned off on My List Row
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', ['stopped', '']);
  });

  // https://tubi.testrail.io/index.php?/cases/view/439741
  it('439741- Registered User - Kids Mode - My Stuff should show Kids rated titles, @mystuff @kidsmode', async () => {

    // Create user and add BOTH kids and adult content to watch list and viewing history
    const user = await testUtils.createRegisteredUser();
    await createMixedKidsAndAdultContent(user);

    // Start app in Kids Mode with the pre-configured user
    await testUtils.startApplicationAtPage('kids', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to My Stuff
    await highlightMyStuffMenuItem();
    await utils.sleep(800);

    // Verify we're in Kids Mode by checking for Exit Kids option
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to My List section  
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(800);
    await testUtils.waitForElementToFullyShowOnScreen('myListScreenTitle');
    await utils.sleep(2000);

    // Verify My List shows only kids-appropriate content
    const myListPoster = await testUtils.getNodeForElement('myListPoster');
    expect(myListPoster.visible).to.equal(true);

    // Get all content items in My List and verify each has kids-appropriate rating
    const myListContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('queueRowList');
    expect(myListContent.length).to.be.greaterThan(0, 'My List should have kids content');

    for (const itemContent of myListContent) {
      if (itemContent.ratings && itemContent.ratings.length > 0) {
        const rating = itemContent.ratings[0].value;
        await verifyKidsAppropriatRating(rating);
      }
    }

    await utils.sleep(2000);

    // Verify that we have fewer total items than we originally created
    // (proving adult content was filtered out)
    const totalKidsItems = myListContent.length;
    expect(totalKidsItems).to.be.lessThan(21);  // Less than total created (11 kids + 10 adult)
    expect(totalKidsItems).to.be.greaterThan(5); // Should have most of the 11 kids items

  });


});

async function highlightMyStuffMenuItem() {

  // Press left
  await ecp.sendKeypress(ecp.Key.Left);

  // Is the left Nav open and Home selected?
  await testUtils.waitForElementToFullyShowOnScreen('leftNavHomeButtonLabel');

  // Highlight My Stuff Menu item
  await ecp.sendKeypress(ecp.Key.Down);
  await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButtonSelected');
  await utils.sleep(500); // NEED TO ADD SLEEP HERE, otherwise it selects Sign In button! 
  await ecp.sendKeypress(ecp.Key.Down);
  await testUtils.waitForElementToFullyShowOnScreen('myStuffSelected');

}

async function createHistory(user) {

  // Create a user with mix of little kids and non-little kid rated titles with history

  const ContentG = await user.getContent().withRating('G').ofContentType('movie').retrieve({ limit: 10 });
  await user.addContentToViewHistory(ContentG, 600);
  const ContentTVY7 = await user.getContent().withRating('TV-Y7').ofContentType('series').retrieve({ limit: 3 });
  await user.addContentToViewHistory(ContentTVY7, 600);
  const movieContentTVMA = await user.getContent().withRating('TV-MA').ofContentType('series').retrieve({ limit: 3 });
  await user.addContentToViewHistory(movieContentTVMA, 600);
  const movieContentR = await user.getContent().withRating('R').ofContentType('movie').retrieve({ limit: 2 });
  await user.addContentToViewHistory(movieContentR, 500);
  const movieContentPG = await user.getContent().withRating('PG').ofContentType('movie').retrieve({ limit: 2 });
  await user.addContentToViewHistory(movieContentPG, 500);

}
async function createWatchList(user) {

  // Create a user with mix of little kids and non-little kid rated titles with history

  const ContentTVG = await user.getContent().ofContentType('series').withRating('TV-G').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentTVG);
  const ContentG = await user.getContent().ofContentType('movie').withRating('G').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentG);

}
async function createWatchListOneTitle(user) {

  // Create a watch list one title movie

  await user.addContentToWatchList({
    id: '342067',
    type: 'movie'

  });

}

async function createHistoryEvergreenMovieTitle(user) {

  // Create a watch list one Evergreen title movie

  const contentId = await user.getContentById(342067);
  await user.addContentToViewHistory(contentId, 500);

}

async function createHistoryEvergreenSeriesTitle(user) {

  // Create a watch list one Evergreen title movie

  const contentId = await user.getContentById(300005163);
  await user.addContentToViewHistory(contentId, 500);

}

async function createWatchListOneTitleSeries(user) {

  // Create a user with one title series

  await user.addContentToWatchList({
    id: '03320',
    type: 'series'
  });



}

async function createWatchListThreeTitles(user) {

  // Create a user with 3 titles in watch list

  const ContentG = await user.getContent().ofContentType('movie').withRating('R').retrieve({ limit: 3 });
  await user.addContentToWatchList(ContentG);

}

async function createHistoryOneTitle(user) {

  // Create a user with one title in history, movie

  const movieContentPG = await user.getContent().withRating('PG').ofContentType('movie').retrieve({ limit: 1 });
  await user.addContentToViewHistory(movieContentPG, 500);

}

async function createHistoryOneTitleSeries(user) {

  const movieContent = await user.getContent().hasVideoPreview().ofContentType('series').retrieve({ limit: 1 });
  await user.addContentToViewHistory(movieContent, 500);

}


// Create history function

async function createHistoryForPlayingTitle() {
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
  await ecp.sendKeypress(ecp.Key.Forward, { count: 3 });
  await utils.sleep(3000);
  await ecp.sendKeypress(ecp.Key.Play);

}


// Check Empty My Stuff Screen for Registered User

async function checkEmptyMyStuffScreenRegistered() {
  await testUtils.waitForElementToFullyShowOnScreen('myStuffRegUserEmptyScreen');
  await testUtils.waitForElementToFullyShowOnScreen('goHomeButtonMyStuff');
  const goHomeButtonMyStuff = await testUtils.getNodeForElement('goHomeButtonMyStuff');
  expect(goHomeButtonMyStuff.text).to.equal('Go Home');
  const myStuffRegisteredScreenTextTitle = await testUtils.getNodeForElement('myStuffRegScreenTitle');
  expect(myStuffRegisteredScreenTextTitle.text).to.equal('My Stuff is Empty');
  const myStuffRegScreenSubTitle = await testUtils.getNodeForElement('myStuffRegScreenSubTitle');
  expect(myStuffRegScreenSubTitle.text).to.equal('Find your favorites fast, pick up where you left off–all in one place.');
  const myStuffRegScreenSubTitle2 = await testUtils.getNodeForElement('myStuffRegScreenSubTitle2');
  expect(myStuffRegScreenSubTitle2.text).to.equal('Use the bookmark button to save series and movies to your My List.');

}

async function createMixedKidsAndAdultContent(user) {
  // Create KIDS-APPROPRIATE content for watch list and viewing history
  const kidsMoviesG = await user.getContent().ofContentType('movie').withRating('G').retrieve({ limit: 3, contentsLimit: 100 });
  await user.addContentToWatchList(kidsMoviesG);
  await user.addContentToViewHistory(kidsMoviesG, 300);

  const kidsSeriesTVY = await user.getContent().ofContentType('series').withRating('TV-Y').retrieve({ limit: 2, contentsLimit: 100 });
  await user.addContentToWatchList(kidsSeriesTVY);
  await user.addContentToViewHistory(kidsSeriesTVY, 400);

  const kidsSeriesTVY7 = await user.getContent().ofContentType('series').withRating('TV-Y7').retrieve({ limit: 2, contentsLimit: 100 });
  await user.addContentToWatchList(kidsSeriesTVY7);
  await user.addContentToViewHistory(kidsSeriesTVY7, 500);

  const kidsSeriesTVG = await user.getContent().ofContentType('series').withRating('TV-G').retrieve({ limit: 2, contentsLimit: 100 });
  await user.addContentToWatchList(kidsSeriesTVG);
  await user.addContentToViewHistory(kidsSeriesTVG, 600);

  const kidsMoviesPG = await user.getContent().ofContentType('movie').withRating('PG').retrieve({ limit: 2, contentsLimit: 100 });
  await user.addContentToWatchList(kidsMoviesPG);
  await user.addContentToViewHistory(kidsMoviesPG, 350);

  // Create ADULT content that should be FILTERED OUT in Kids Mode
  const adultMoviesR = await user.getContent().ofContentType('movie').withRating('R').retrieve({ limit: 3, contentsLimit: 100 });
  await user.addContentToWatchList(adultMoviesR);
  await user.addContentToViewHistory(adultMoviesR, 700);

  const adultMoviesPG13 = await user.getContent().ofContentType('movie').withRating('PG-13').retrieve({ limit: 3, contentsLimit: 100 });
  await user.addContentToWatchList(adultMoviesPG13);
  await user.addContentToViewHistory(adultMoviesPG13, 800);

  const adultSeriesTV14 = await user.getContent().ofContentType('series').withRating('TV-14').retrieve({ limit: 2, contentsLimit: 100 });
  await user.addContentToWatchList(adultSeriesTV14);
  await user.addContentToViewHistory(adultSeriesTV14, 900);

  const adultSeriesTVMA = await user.getContent().ofContentType('series').withRating('TV-MA').retrieve({ limit: 2, contentsLimit: 100 });
  await user.addContentToWatchList(adultSeriesTVMA);
  await user.addContentToViewHistory(adultSeriesTVMA, 1000);

  // Small delay to ensure content is synced
  await utils.sleep(1000);
}

async function verifyKidsAppropriatRating(rating) {
  // Define kids-appropriate ratings
  const kidsRatings = ['G', 'TV-Y', 'TV-Y7', 'TV-G', 'PG'];

  // Define adult-only ratings that should NOT appear in Kids Mode
  const adultRatings = ['R', 'PG-13', 'TV-14', 'TV-MA', 'NC-17'];

  // Verify the rating is kids-appropriate
  expect(kidsRatings).to.include(rating, `Rating "${rating}" is not appropriate for Kids Mode`);

  // Verify the rating is NOT an adult rating
  expect(adultRatings).to.not.include(rating, `Adult rating "${rating}" should not appear in Kids Mode`);
}
