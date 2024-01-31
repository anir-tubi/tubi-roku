import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import { ecp, utils } from 'roku-test-automation';
import {
	verifyC374770,
	verifyC374776,
	verifyC374775,
	verifyC374771,
	verifyC374777,
	verifyC374774,
	verifyC374784,
	verifyC374778,
	verifyC374785,
	verifyC374779,
	verifyC374787,
	verifyC374783,
	verifyC374790,
	verifyC374782,
} from '../verification/componentInteraction';
import { addMrPostmanTitleToHistory } from '../utils/userManipulations';

import {
	verifyC425242,
	verifyC425243,
	verifyC374780,
	verifyC374781,
} from '../verification/navigateWithinPageVerification';

import {
	verifyC374784ExplicitFeedback,
	verifyC374785ExplicitFeedback,
	verifyC374787ExplicitFeedback,
	verifyC374790ExplicitFeedback,
	verifyC374793,
	verifyC374794,
	verifyC374795,
} from '../verification/explicitFeedback';
import SearchPage from '../pages/searchPage';

describe('Like Dislike events', function () {
	beforeEach(async () => {
		this.timeout(300000);
		await createNewTestInProxy();
	});

	it('Navigate to the “Like or Dislike” button on the Movie detail page and see the secondary menu with two buttons: “Like” / “Dislike” C374770 and C374772 and C374775 and C374776 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectLike();
		await ecp.sendKeypress(ecp.Key.Up, { wait: 700 });
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 700 });
		await verifyC374770(titleId);
		await verifyC374776(titleId);
		await verifyC374775(titleId);
	});

	it('Registered User - Analytics -Navigate to the “Like or Dislike” button on a Series detail page and see the secondary menu with two buttons: “Like” / “Dislike” C374771 and C374773 and C374774 and C374777 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.selectLike();
		await ecp.sendKeypress(ecp.Key.Up, { wait: 700 });
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 700 });
		await verifyC374771(tvShowId);
		await verifyC374777(tvShowId);
		await verifyC374774(tvShowId);
	});

	it('Registered User - Analytics - Select Like on Movie detail page C374784 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectLike();
		await ecp.sendKeypress(ecp.Key.Up, { wait: 700 });
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 700 });
		await verifyC374784(titleId);
		await verifyC374784ExplicitFeedback(titleId);
	});

	it('Registered User - Analytics - De-select Like from Movie detail page C374778 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectLikeOrDislike();
		await ecp.sendKeypress(ecp.Key.Left);
		await verifyC374778(titleId);
	});
	it('Registered User - Analytics - De-select Like from Movie detail page C425242 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectTitleAddToMyList();
		await utils.sleep(1500);
		await ecp.sendKeypress(ecp.Key.Up, { wait: 500 });
		await verifyC425242(titleId);
	});

	it('When user navigates between menu options - REMOVE_FROM_HISTORY C425243 @analytics,@analyticsLikeDislike', async () => {
		const user = await testUtils.createRegisteredUser();
		await addMrPostmanTitleToHistory(user);
		await testUtils.startApplicationAtPage('search', { user: user });
		const searchPage = SearchPage();
		await searchPage.enterSearch('hey mr. postman');
		await searchPage.goToTitleInPosition(1);
		const details = await searchPage.selectFocusedTitle();
		const videoId = details.getTitleId();
		await ecp.sendKeypress(ecp.Key.Down, { wait: 900, count: 5 });
		await verifyC425243(videoId);
	});
	it('Registered User - Analytics - Select Like on Series detail page C374785 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.selectLike();
		await ecp.sendKeypress(ecp.Key.Up, { wait: 700 });
		await verifyC374785(tvShowId);
		await verifyC374785ExplicitFeedback(tvShowId);
	});

	it('Registered User - Analytics - De-select Like from Series detail page C374779 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.selectLikeOrDislike();
		await ecp.sendKeypress(ecp.Key.Left, { wait: 700 });
		await verifyC374779(tvShowId);
	});

	it('Registered User - Analytics - Select Dislike from Movie detail page C374780 and Registered User - Analytics - Select Dislike on Movie detail page C374787 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectDislike();
		await verifyC374780(titleId);
		await verifyC374787ExplicitFeedback(titleId);
		await verifyC374787(titleId);
	});
	it('Registered User - Analytics - Navigate away from Dislike on Movie detail page C374783 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.focusButDontSelectDislike();
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Left);
		await utils.sleep(1000);
		await verifyC374783(titleId);
	});

	it('Registered User - Analytics - Select Dislike from Series detail page C374781 and Registered User - Analytics - Select Dislike on Series detail page C374790 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.selectDislike();
		await verifyC374781(tvShowId);
		await verifyC374790(tvShowId);
		await verifyC374790ExplicitFeedback(tvShowId);
	});

	it('Registered User - Analytics - Navigate away from Dislike on Series detail page C374782 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.focusButDontSelectDislike();
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Left);
		await utils.sleep(1000);
		await verifyC374782(tvShowId);
	});

	it('Registered User - Analytics - Undo Like on Series detail page C374793 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.selectLike();
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC374793(tvShowId);
	});

	it('Registered User - Analytics - Undo Dislike on Movie detail page C374794 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectDislike();
		await utils.sleep(2500);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC374794(titleId);
	});
	it('Registered User - Analytics - Undo Dislike on Series detail page C374795 @analytics,@analyticsLikeDislike', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: true,
		});
		const homePage = HomePage();
		const tvShowId = await homePage.getTVShowTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleTVShow();
		await movieDetailsPage.selectDislike();
		await utils.sleep(2500);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC374795(tvShowId);
	});
});
