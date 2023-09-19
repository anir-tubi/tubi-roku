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


    describe('loginAsUser', function () {
      it('should be able to login to an existing user account', async () => {
        const user = await testUtils.loginAsUser({email: existingUser['userInfo'].email, password: existingUser['userInfo'].password});
        expect(user['accessToken']).to.not.be.empty;
        expect(user['userInfo'].password).to.not.be.empty;
        expect(user['userInfo'].user_id).to.be.greaterThan(0);
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
