import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from './test-utils';
import { moveToGrid } from './analytics/utils/helpers';



// Placeholder for possible file to hold all functions written and used by QA in the >tests folder

class Shared {

  // Copy all global function within here


  // Create history function
  public async createHistory() {
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    await ecp.sendKeypress(ecp.Key.Forward, { count: 3 });
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Play);
  }



  public async verifyResumeWithinRange() {
    await ecp.sendKeypress(ecp.Key.Play);// PLay to create history
    await this.createHistory(); // Create history function
    const currentposition = await testUtils.getPlayerPosition();
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);


    // Select Resume and check for playback
    await testUtils.selectAndVerifyDetailPageMenuItem('resume');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Find resume position
    const resumeposition = await testUtils.getPlayerPosition();
    const difference = (resumeposition - currentposition);

    // Find out if current postion and resume postion are within range
    const min = 0;
    const max = 5000;
    expect(difference).greaterThanOrEqual(min);
    expect(difference).lessThanOrEqual(max);
  }
  // Sign in from Home screen

  public async selectSignInFromHomeScreen() {
    // Sign in
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  public async openKidsMode() {

    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(3000); // Adding sleeps temporary
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.be.true;
  }


  async selectLittleKidsFromParentalSettings() {
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
    await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
    await ecp.sendKeypress(ecp.Key.Up, { count: 3, wait: 200 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }


  async selectOlderKidsFromParentalSettings() {
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
    await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
    await ecp.sendKeypress(ecp.Key.Up, { count: 2, wait: 200 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  async selectTeensFromParentalSettings() {
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Up, { count: 1 });
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  async enterPasswordSettingsChange() {
    // Enter Password for PC Settings Change
    // const // need to expect and await the Sign In screen

    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText('111111');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 200 });
    const keyboardBackButton = await testUtils.getNodeForElement('keyboardBackButton');
    if (keyboardBackButton.opacity == 1) {
      await ecp.sendKeypress(ecp.Key.Right);
    }
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  // openSettings function
  public async openSettings() {
    await testUtils.goToPage('settings');
  }

  // Navigate right until the grid is in focus
  // This is specifice to the Search screen
  public async navigateRightToGrid() {
    // We have to wait for ResultGrid to be showing first else we can get into an edge case bug that I decided not to fix since a user will never go as fast as the automation
    await testUtils.waitForElementToShowOnScreen('searchResultGrid');
    await testUtils.untilTrue(async () => {
      await ecp.sendKeypress(ecp.Key.Right);
      const { value: id } = await odc.getValue({
        base: 'focusedNode',
        keyPath: 'id'
      });
      return id === 'ResultGrid';
    }, 'ResultGrid never obtained focus');
  }


  public async findContentPositionInGridByTitle({ title, gridId }) {
    let position = -1;
    const content = await testUtils.getAllGridItemsContent(
      gridId
    );

    for (const [index, item] of content.entries()) {
      if (item.title === title) {
        position = index;
        break;
      }
      }
    
    return position > -1 ? this.positionToRowCol(position) : [];
  }

  async navigateToContentInSearchResults({ title }) {
    await this.navigateRightToGrid();
    const position = await this.findContentPositionInGridByTitle({ title: title, gridId: 'searchResultGrid' });
    if (position.length > 0) {
      await moveToGrid({grid: {row: 0, col: 0}, destRow: position[0], destCol: position[1]});
    }
  }

  public positionToRowCol(position: number, columns: number = 5): [number, number] {
    const row = Math.floor(position / columns);
    const col = position % columns;
    return [row, col];
  }

  public async findContentPositionInGridThatContainsVideoPreview(gridId, hasVideoPreview: boolean = true, columnsPerRow: number = 5) {
    let position = -1;
    const content = await testUtils.getAllGridItemsContent(
      gridId
    );

    for (const [index, item] of content.entries()) {
      if (hasVideoPreview && item.videoPreviewUrl?.trim().length > 0) {
        position = index;
        break;
      } else if (!hasVideoPreview && (!item.videoPreviewUrl || item.videoPreviewUrl?.trim().length === 0)) {
        position = index;
        break;
      }
    }
    
    return position > -1 ? this.positionToRowCol(position, columnsPerRow) : [];
  }


  async turnOnAutoplay() {
    //Open left nav
    await ecp.sendKeypress(ecp.Key.Left);
  
    // Open settings
    await this.openSettings();
  
    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    await ecp.sendKeypress(ecp.Key.Down);
    const { node } = await odc.getFocusedNode();
    if (node.id === 'AutoplayPreviewMenu') {
      await ecp.sendKeypress(ecp.Key.Down);
    }
    await testUtils.waitForElementToHaveFocus('autoplayNextVideoMenu', 'Timed out waiting for Autoplay Next Video Menu to have focus', 15000);

    await testUtils.jumpToRowIndex('autoplayNextVideoMenu', 0);
    await ecp.sendKeypress(ecp.Key.Ok);
    // Provide some time for the request to complete before restarting the app.
    await utils.sleep(3000);
    // Go back to home page and verify that autoplay is off
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
  }

  async turnOffAutoplay() {
    //Open left nav
    await ecp.sendKeypress(ecp.Key.Left);

    // Open settings
    await this.openSettings();

    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    await ecp.sendKeypress(ecp.Key.Down);
    const { node } = await odc.getFocusedNode();
    if (node.id === 'AutoplayPreviewMenu') {
      await ecp.sendKeypress(ecp.Key.Down);
    }

    await testUtils.waitForElementToHaveFocus('autoplayNextVideoMenu', 'Timed out waiting for Autoplay Next Video Menu to have focus', 15000);
    await testUtils.jumpToRowIndex('autoplayNextVideoMenu', 1);
    await ecp.sendKeypress(ecp.Key.Ok);
    // Provide some time for the request to complete before restarting the app.
    await utils.sleep(3000);
    // Go back to home page and verify that autoplay is off
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
  }

  public async openMovies() {
    await testUtils.goToPage('movies');
  }

  public async openSeries() {
    await testUtils.goToPage('series');
  }

}

const shared = new Shared();


export {
  shared
};
