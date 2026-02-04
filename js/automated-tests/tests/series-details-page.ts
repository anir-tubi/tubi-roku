import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';

describe('Details Page', function () {
  describe('Series Details Page', function () {
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/781850
    it('C781850 - Verify user sees Play button first in Default Guest Mode (Swap Always) @guest,@sdp_1', async () => {
      await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus');

      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen');

      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Title not shown', 10000);
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenMenu', 'Menu not shown', 10000);

      const firstButton = await testUtils.getGridItemContent('detailScreenMenu', 0);
      expect(firstButton.id).to.equal('PlayMenuItem');
    });

    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/781325
    it('C781325 - Verify user sees Play button first in Kids Mode (Swap Always) @guest,@sdp_1', async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

      await ecp.sendKeypress(ecp.Key.Left);
      await ecp.sendKeypress(ecp.Key.Rewind);
      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(500);
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForElementToFullyShowOnScreen('exitKidsOption', 'Kids mode toggle not shown', 10000);
      await testUtils.waitForElementToShowOnScreen('homeScreenRowList', 'video titles row list not shown', 10000);
      await ecp.sendKeypress(ecp.Key.Right);
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

      // Find and navigate to a series in the row list
      const { row, column } = await shared.findAndNavigateToContentType('s', 'homeScreenRowList');
      await testUtils.waitForElementFieldToEqual('homeScreenRowList', 'itemFocused', row, 10000);
      await testUtils.waitForElementFieldToEqual('homeScreenRowList', 'currFocusColumn', column, 10000);

      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen');

      await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Title not shown', 10000);
      await testUtils.waitForElementToFullyShowOnScreen('detailScreenMenu', 'Menu not shown', 10000);

      const firstButton = await testUtils.getGridItemContent('detailScreenMenu', 0);
      expect(firstButton.id).to.equal('PlayMenuItem');
    });
  });
});