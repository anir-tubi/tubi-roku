// This file provides a spot to write tests to verify tooling helpers in test-utils.ts and other spots are functioning as anticipated before they get used in automated tests

import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from './test-utils';

describe('test-utils', function () {
  describe('RegisteredUser', function () {
    const movieContent = {
      type: 'v',
      id: '613766'
    };

    const expectedMovieContentType = 'movie';

    let user: Awaited<ReturnType<typeof testUtils.createRegisteredUser>>;
    beforeEach(async () => {
      user = await testUtils.createRegisteredUser();
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
});
