import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';


describe('Search', function () {
  describe('Linear Search', function () {
    it('C244256 When a user searches for a channel, the channel is shown in the search results @linearsearch', async () => {
      await testUtils.startApplicationAtPage('search',true);
      await ecp.sendText('abc');

      // Navigate right until the grid is in focus
      await testUtils.untilTrue(async () => {
        await ecp.sendKeyPress(ecp.Key.Right);
        const {value: id} = await odc.getValue({
          base: 'focusedNode',
          keyPath: 'id'
        });
        return id === 'ResultGrid';
      }, 'ResultGrid never obtained focus');

      await testUtils.retryWithTimeOut(async () => {
        const searchResultsABC = await testUtils.getNodeForElement('searchResultsABC');
        expect(searchResultsABC.text).to.equal('ABC News Live');
      });

      const searchResultsLiveIcon = await testUtils.getNodeForElement('searchResultsLiveIcon');
      expect(searchResultsLiveIcon.uri).to.equal('pkg:/images/live-icon.webp');
    });

  });
});
