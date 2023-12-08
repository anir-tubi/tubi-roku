// This file provides a spot to write tests to verify tooling helpers in test-utils.ts and other spots are functioning as anticipated before they get used in automated tests

import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import type { RegisteredUser } from './test-utils';
import { auth, testUtils } from './test-utils';

describe('test-utils', function () {
  let existingUser: RegisteredUser;
  before(async () => {
    existingUser = await testUtils.createRegisteredUser();
  });

  describe('TestUtils', function () {
    describe('startApplicationWithDeeplink', function () {
      it('should be able to override current device language', async () => {
        await testUtils.startApplicationWithDeeplink(undefined, {
          language: 'spanish'
        });

        const {value: deviceInfo} = await odc.getValue({
          base: 'global',
          keyPath: 'constants.deviceInfo'
        });

        expect(deviceInfo.locale).to.equal('es_ES');
        expect(deviceInfo.language).to.equal('es');
      });
    });


    describe('getAllGridItemsContent', function () {
      it('show be able to return correct grid item contents for a known value', async () => {
        await testUtils.startApplicationAtPage('genre');
        const content = await testUtils.getAllGridItemsContent('channelCategoryGrid');
        expect(content[0].id).to.equal('recommended_for_you');
      });
    });


    describe('verifyFocusedMainMenuItemEquals', function () {
      it('should not throw an error since we are currently on the homescreen', async () => {
        await testUtils.startApplicationAtPage('home');
        await testUtils.verifyFocusedSideNavMenuItemEquals('home');
      });

      it('should throw an error since we are not on the settings screen', async () => {
        try {
          await testUtils.verifyFocusedSideNavMenuItemEquals('settings');
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when it should have');
      });
    });


    describe('waitForSelectedMainMenuItemToEqual', function () {
      it('should wait for the the correct item to be focused and not throw an error after we focus the correct menu item', async () => {
        await testUtils.startApplicationAtPage('home');
        let promise = testUtils.verifyFocusedSideNavMenuItemEquals('search', 200);
        let threwError = false;
        try {
          await promise;
        } catch(e) {
          threwError = true;
        }

        // It should throw an error here since we didn't focus it yet
        expect(threwError).to.be.true;

        await ecp.sendKeypress(ecp.Key.Left);
        await ecp.sendKeypress(ecp.Key.Up);

        promise = testUtils.verifyFocusedSideNavMenuItemEquals('search', 1000);
        await ecp.sendKeypress(ecp.Key.Ok);
        // Should not throw an error this time
        await promise;
      });
    });


    describe('verifyCurrentScreenEquals', function () {
      before(async () => {
        await testUtils.startApplicationAtPage('home');
      });

      it('should not throw an error since we are already on the home screen', async () => {
        await testUtils.waitForCurrentScreenToEqual('homeScreen', 1000);
      });

      it('should wait for us to go to the search screen', async () => {
        await testUtils.waitForElementToHaveFocus('homeRowList');
        const promise = testUtils.waitForCurrentScreenToEqual('searchScreen', 2000);
        await ecp.sendKeypress(ecp.Key.Left);
        await utils.sleep(800); // There is a bug in our menu that requires us to wait until after animation to proceed up
        await ecp.sendKeypress(ecp.Key.Up);
        await ecp.sendKeypress(ecp.Key.Ok);
        await promise;
      });
    });


    describe('loginAsUser', function () {
      it('should be able to login to an existing user account', async () => {
        const user = await testUtils.loginAsUser({email: existingUser['userInfo'].email, password: existingUser['userInfo'].password});
        expect(user['accessToken']).to.not.be.empty;
        expect(user['userInfo'].password).to.not.be.empty;
        expect(user['userInfo'].user_id).to.be.greaterThan(0);
      });
    });


    describe('video helpers', function () {
      const videoNodeElement = 'videoPlayerScreen';
      beforeEach(async () => {
        await testUtils.startApplicationWithDeeplink({
          mediaType: 'movie',
          contentID: '100007133'
        });
        await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
      });


      describe('getPlayerDuration', function () {
        it('Should return the correct duration for a known piece of content', async () => {
          const duration = await testUtils.getPlayerDuration(videoNodeElement);
          expect(duration).to.equal(5233000);
        });
      });


      describe('seekPlayerToAbsolutePosition', function () {
        it('Should not throw an error seeking to the requested absolute position', async () => {
          await testUtils.seekPlayerToAbsolutePosition(videoNodeElement, 300000);
        });

        it('Should work for previewVideoPlayer as well', async () => {
          // Since we don't use the preview video player seek functionality anywhere except automated tests, we should should check that as well
          await testUtils.startApplicationAtPage('home');
          await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
          await testUtils.seekPlayerToAbsolutePosition('previewVideoPlayer', 40000);
        });
      });


      describe('seekPlayerToRelativePosition', function () {
        it('should seek to the correct position when relative to the current player position', async () => {
          // We're purposely seeking twice in order to easily test that position is relative to current player position vs just being from position 0
          await testUtils.seekPlayerToRelativePosition(videoNodeElement, 60000, 'current');
          await testUtils.seekPlayerToRelativePosition(videoNodeElement, 60000, 'current');
          const position = await testUtils.getPlayerPosition(videoNodeElement);
          expect(position).to.be.greaterThan(110000).and.lessThan(130000);
        });


        it('should not throw an error when seeking relative to the end player position', async () => {
          await testUtils.seekPlayerToRelativePosition(videoNodeElement, -60000, 'end');
        });
      });


      describe('getPlayerContent', function () {
        it('should seek to the correct position when relative to the current player position', async () => {
          // We're purposely seeking twice in order to easily test that position is relative to current player position vs just being from position 0
          const content = await testUtils.getPlayerContent(videoNodeElement);

          expect(content.id).to.equal('100007133');
          expect(content.LENGTH).to.equal(5234);
          expect(content.RATING).to.equal('R');
        });
      });
    });


    describe('getElementSize', function () {
      it('should be able to retrieve the size of a known element', async () => {
        const size = await testUtils.getElementSize('backgroundGroup');
        expect(size.width).to.equal(1920);
        expect(size.height).to.equal(1080);
        expect(size.x).to.equal(0);
        expect(size.y).to.equal(0);
      });

      it('should throw an error if the element does not currently exist in the nodetree', async () => {
        try {
          await testUtils.getElementSize('privacyPageScroller');
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when element did not exist');
      });
    });


    describe('getGridElementSize', function () {
      it('should be able to retrieve the size of a known grid child element', async () => {
        await utils.sleep(3000);
        const size = await testUtils.getGridElementSize('homeRowList', [0, 3]);
        expect(size.width).to.equal(504);
        expect(size.height).to.equal(282);
        expect(size.x).to.equal(1752);
        expect(size.y).to.equal(572);
      });
    });


    describe('waitForSideNavMenuToBeExpanded', function () {
      beforeEach(async () => {
        await testUtils.startApplicationAtPage('home');
        await testUtils.waitForElementToHaveFocus('homeRowList');
      });

      it('should not throw an Error if the main menu is expanded', async () => {
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.waitForSideNavMenuToBeExpanded();
      });

      it('should throw an error if the main menu is not expanded', async () => {
        try {
          await testUtils.waitForSideNavMenuToBeExpanded(500);
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when it should have');
      });
    });


    describe('waitForSideNavMenuToNotBeExpanded', function () {
      beforeEach(async () => {
        await testUtils.startApplicationAtPage('home');
        await testUtils.waitForElementToHaveFocus('homeRowList');
      });

      it('should not throw an Error if the main menu is not expanded', async () => {
        await testUtils.waitForSideNavMenuToNotBeExpanded();
      });

      it('should throw an error if the main menu is expanded', async () => {
        try {
          await ecp.sendKeypress(ecp.Key.Left);
          await testUtils.waitForSideNavMenuToNotBeExpanded(500);
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when it should have');
      });
    });



    describe('getElementColorField', function () {
      it('should be able to retrieve the specified element color field in the correct hex format', async () => {
        const color = await testUtils.getElementColorField('scene', 'backgroundColor');
        expect(color).to.equal('#232323FF');
      });
    });


    describe('getElementSize', function () {
      it('should be able to retrieve the size of a known element', async () => {
        const size = await testUtils.getElementSize('backgroundGroup');
        expect(size.width).to.equal(1920);
        expect(size.height).to.equal(1080);
        expect(size.x).to.equal(0);
        expect(size.y).to.equal(0);
      });

      it('should throw an error if the element does not currently exist in the nodetree', async () => {
        try {
          await testUtils.getElementSize('privacyPageScroller');
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when element did not exist');
      });
    });


    describe('waitForMainMenuToBeExpanded', function () {
      beforeEach(async () => {
        await testUtils.startApplicationAtPage('home');
        await testUtils.waitForElementToHaveFocus('homeRowList');
      });

      it('should not throw an Error if the main menu is expanded', async () => {
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.waitForMainMenuToBeExpanded();
      });

      it('should throw an error if the main menu is not expanded', async () => {
        try {
          await testUtils.waitForMainMenuToBeExpanded(500);
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when it should have');
      });
    });


    describe('waitForMainMenuToNotBeExpanded', function () {
      beforeEach(async () => {
        await testUtils.startApplicationAtPage('home');
        await testUtils.waitForElementToHaveFocus('homeRowList');
      });

      it('should not throw an Error if the main menu is not expanded', async () => {
        await testUtils.waitForMainMenuToNotBeExpanded();
      });

      it('should throw an error if the main menu is expanded', async () => {
        try {
          await ecp.sendKeypress(ecp.Key.Left);
          await testUtils.waitForMainMenuToNotBeExpanded(500);
        } catch (e) {
          // Failed as expected
          return;
        }
        throw new Error('Did not throw an error when it should have');
      });
    });


    describe('getElementColorField', function () {
      it('should be able to retrieve the specified element color field in the correct hex format', async () => {
        const color = await testUtils.getElementColorField('scene', 'backgroundColor');
        expect(color).to.equal('#232323FF');
      });
    });
  });


  describe('AnonymousUser', function () {
    let user: Awaited<ReturnType<typeof testUtils.createAnonymousUser>>;
    beforeEach(async () => {
      user = await testUtils.createAnonymousUser();
    });

    describe('setIsNewUser', function () {
      it('Should be able to start application as a new user', async () => {
        user.setIsNewUser(true);
        await testUtils.startApplicationWithDeeplink(undefined, {
          user: user
        });

        const {value: isNewUser} = await odc.getValue({
          base: 'global',
          keyPath: 'isNewUser'
        });

        expect(isNewUser).to.true;
      });

      it('Should be able to start application as a returning user', async () => {
        user.setIsNewUser(false);
        await testUtils.startApplicationWithDeeplink(undefined, {
          user: user
        });

        const {value: isNewUser} = await odc.getValue({
          base: 'global',
          keyPath: 'isNewUser'
        });

        expect(isNewUser).to.false;
      });
    });
  });

  describe('RegisteredUser', function () {
    const movieContent = {
      type: 'v' as const,
      id: '613766'
    };

    const expectedMovieContentType = 'movie';

    let user: Awaited<ReturnType<typeof testUtils.createRegisteredUser>>;
    beforeEach(async () => {
      user = await testUtils.createRegisteredUser();
    });

    describe('setIsNewUser', function () {
      it('Should be able to start application as a new user', async () => {
        user.setIsNewUser(true);
        await testUtils.startApplicationWithDeeplink(undefined, {
          user: user
        });

        const {value: isNewUser} = await odc.getValue({
          base: 'global',
          keyPath: 'isNewUser'
        });

        expect(isNewUser).to.true;
      });

      it('Should be able to start application as a returning user', async () => {
        user.setIsNewUser(false);
        await testUtils.startApplicationWithDeeplink(undefined, {
          user: user
        });

        const {value: isNewUser} = await odc.getValue({
          base: 'global',
          keyPath: 'isNewUser'
        });

        expect(isNewUser).to.false;
      });
    });

    describe('watchList', function () {
      describe('addContentToWatchList', function () {
        it('should properly add item to watch list', async () => {
          const result = await user.addContentToWatchList(movieContent);

          expect(Array.isArray(result)).to.be.true;
          expect(result.length).to.be.greaterThan(0);
          const item = result[0];
          expect(item.content_id).to.equal(+movieContent.id);
          expect(item.content_type).to.equal(expectedMovieContentType);
        });
      });


      describe('getWatchListContent', function () {
        it('should properly retrieve the user\'s watch list', async () => {
          await user.addContentToWatchList(movieContent);
          const result = await user.getWatchListContent();
          expect(Array.isArray(result)).to.be.true;
          expect(result.length).to.be.greaterThan(0);
          const item = result[0];
          expect(item.content_id).to.equal(+movieContent.id);
          expect(item.content_type).to.equal(expectedMovieContentType);
        });
      });


      describe('removeContentFromWatchList', function () {
        it('should properly remove content from view history', async () => {
          await user.addContentToWatchList(movieContent);
          await user.removeContentFromWatchList(movieContent);
          const result = await user.getWatchListContent();
          expect(Array.isArray(result)).to.be.true;
          expect(result.length).to.be.equal(0);
        });
      });
    });


    describe('viewHistory', function () {
      describe('addContentToViewHistory', function () {
        it('should properly add item to view history', async () => {
          const position = 500;
          const result = await user.addContentToViewHistory(movieContent, position);
          expect(Array.isArray(result)).to.be.true;
          expect(result.length).to.be.greaterThan(0);
          const item = result[0];
          expect(item.content_id).to.equal(+movieContent.id);
          expect(item.content_type).to.equal(expectedMovieContentType);
          expect(item.position).to.equal(position);
        });
      });


      describe('getViewHistoryContent', function () {
        it('should properly retrieve the user\'s watch list', async () => {
          const position = 500;
          await user.addContentToViewHistory(movieContent, position);
          const result = await user.getViewHistoryContent();
          expect(Array.isArray(result)).to.be.true;
          expect(result.length).to.be.greaterThan(0);
          const item = result[0];
          expect(item.content_id).to.equal(+movieContent.id);
          expect(item.content_type).to.equal(expectedMovieContentType);
          expect(item.position).to.equal(position);
        });
      });


      describe('removeContentFromViewHistory', function () {
        it('should properly remove content from view history', async () => {
          await user.addContentToViewHistory(movieContent, 500);
          await user.removeContentFromViewHistory(movieContent);
          const result = await user.getViewHistoryContent();
          expect(Array.isArray(result)).to.be.true;
          expect(result.length).to.be.equal(0);
        });
      });
    });
  });


  describe('Auth', function () {
    describe('userLogin', function () {
      it('Should be able to start application as a new user', async () => {
        const result = await auth.userLogin({
          email: existingUser['userInfo'].email,
          password: existingUser['userInfo'].password
        });
        expect(result.access_token).to.not.be.empty;
        expect(result.user_id).to.be.greaterThan(0);
      });
    });
  });
});
