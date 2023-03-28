import { expect } from 'chai';
import { odc, ecp } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe.only('Details Page', function () {
  describe('Movie Details Page', function () {
    let itemData;

    before(async () => {
      await testUtils.signIntoAccount();
      await testUtils.goToPage('movies');

      // TODO make this into a helper
      // Wait until RowList is in focus so we know we're good to proceed
      await testUtils.untilTrue(async () => {
        const {value: id} = await odc.getValue({
          base: 'focusedNode',
          keyPath: 'id'
        });
        return id === 'RowList';
      }, 'Timed out waiting for Rowlist to have focus');

      // We now want to find a piece of content that doesn't have a video preview
      const rowListElement = testUtils.getElementKeyPath('movieScreenRowList');
      const result = await findIndexForFirstItemWithoutVideoPreview(rowListElement.keyPath);
      itemData = result.item;

      // If we found it go ahead and jump to it
      if (result.index) {
        await odc.setValue({
          keyPath: rowListElement.keyPath,
          field: 'jumpToRowItem',
          value: result.index
        });
      } else {
        console.error('Could not find a piece of content without video preview');
      }

      // Now select that content to land us on the detail page
      await ecp.sendKeyPress(ecp.Key.Ok);
    });


    it('C5829 - Movie Details - When Movie Details page is opened then Title Text is displayed @registered_user,@smoke,@mdp_2', async () => {
      const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
      expect(detailScreenTitle.visible).to.equal(true);
      expect(detailScreenTitle.text).to.equal(itemData.title);
    });


    it('C5830 - Movie Details - When Movie Details page is opened then background image is seen @registered_user,@smoke,@mdp_2', async () => {
      const backgroundGroup = await testUtils.getNodeForElement('backgroundGroup');
      expect(backgroundGroup.posterVisible).to.equal(true);

      for (const [index, url] of backgroundGroup.backgroundInfo.urilist.entries()) {
        expect(url).to.equal(itemData.backgrounds[index]);
      }
    });


    it('C5831 - Movie Details - When Movie Details page is opened then runtime and year is displayed @registered_user,@smoke,@mdp_3', async () => {
      const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');

      expect(detailScreenYearAndDuration.visible).to.equal(true);
      expect(detailScreenYearAndDuration.text).to.contain(itemData.year);
      // Improvement we could add check here to make sure the duration is also correct as well but this could get pretty complicated to cover all cases
    });
  });

});


async function findIndexForFirstItemWithoutVideoPreview(rowListKeyPath) {
  const contentBaseKeyPath = rowListKeyPath + '.content';
  const {value: totalRowCount} = await odc.getValue({
    keyPath: contentBaseKeyPath + '.getChildCount()'
  });


  for (let rowIndex = 0; rowIndex < totalRowCount; rowIndex++) {
    const {value: row} = await odc.getValue({
      keyPath: contentBaseKeyPath + `.${rowIndex}`,
      responseMaxChildDepth: 1
    });
    const json = JSON.parse(row.json);

    for (let itemIndex = 0; itemIndex < row.children.length; itemIndex++) {
      const item = row.children[itemIndex];
      const itemFullInfo = json[item.id];
      if (itemFullInfo && !itemFullInfo.video_preview_url) {
        return {
          index: [rowIndex, itemIndex],
          item: itemFullInfo
        };
      }
    }
  }
}
