import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from './test-utils';




// Placeholder for possible file to hold all functions written and used by QA in the >tests folder

class Shared {

    // Copy all global function within here


    // Create history function
    public async createHistory() {
        await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
        await ecp.sendKeyPress(ecp.Key.Forward, { count: 3 });
        await utils.sleep(3000);
        await ecp.sendKeyPress(ecp.Key.Play);
  }

    // Play from Beginning check function
    public async verifyPlayFromBeginning() {

        // Press Play and check playback
        await testUtils.selectAndVerifyDetailPageMenuItem('play');
        await testUtils.expectPlayerStateToEventuallyEqual('play', 5000);

        // Verify Movie title playback starts from beginning
        const position = await testUtils.getPlayerPosition();
        expect(position).to.be.greaterThanOrEqual(0);
        expect(position).to.be.lessThan(1000); //changed this value from original of 5000
  }

    public async  verifyResumeWithinRange() {
        await ecp.sendKeyPress(ecp.Key.Play);// PLay to create history
        await this.createHistory(); // Create history function
        const currentposition = await testUtils.getPlayerPosition();
        await utils.sleep(2000);
        await ecp.sendKeyPress(ecp.Key.Back);


        // Select Resume and check for playback
        await testUtils.selectAndVerifyDetailPageMenuItem('resume');
        await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);

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
      await ecp.sendKeyPress(ecp.Key.Left);
      await ecp.sendKeyPress(ecp.Key.Up, {count:3});
      await ecp.sendKeyPress(ecp.Key.Ok);
    }

    // openSettings function
    public async  openSettings() {
      await testUtils.goToPage('settings');
      }



    // Navigate right until the grid is in focus
    // This is specifice to the Search screen
    public async  navigateRightToGrid() {
        await testUtils.untilTrue(async () => {
        await ecp.sendKeyPress(ecp.Key.Right);
        const {value: id} = await odc.getValue({
            base: 'focusedNode',
            keyPath: 'id'
        });
        return id === 'ResultGrid';
        }, 'ResultGrid never obtained focus');
  }


}

    const shared = new Shared();


    export {
      shared
    };
