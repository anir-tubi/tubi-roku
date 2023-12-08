import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from './test-utils';




// Placeholder for possible file to hold all functions written and used by QA in the >tests folder

class Shared {

    // Copy all global function within here


    // Create history function
    public async createHistory() {
        await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
        await ecp.sendKeypress(ecp.Key.Forward, { count: 3 });
        await utils.sleep(3000);
        await ecp.sendKeypress(ecp.Key.Play);
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
        await ecp.sendKeypress(ecp.Key.Play);// PLay to create history
        await this.createHistory(); // Create history function
        const currentposition = await testUtils.getPlayerPosition();
        await utils.sleep(2000);
        await ecp.sendKeypress(ecp.Key.Back);


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
      await ecp.sendKeypress(ecp.Key.Left);
      await ecp.sendKeypress(ecp.Key.Up, {count:3});
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
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Up, {count:3});
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);
    }


    async selectOlderKidsFromParentalSettings() {
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Up, {count:2});
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);
    }

    async selectTeensFromParentalSettings() {
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Up, {count:1});
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);
    }

    async enterPasswordSettingsChange() {
      // Enter Password for PC Settings Change
      // const // need to expect and await the Sign In screen

      await ecp.sendKeypress(ecp.Key.Ok);
      await ecp.sendText('111111');
      await ecp.sendKeypress(ecp.Key.Down, {count:4});
      await utils.sleep(4000);
      await ecp.sendKeypress(ecp.Key.Right);
      await ecp.sendKeypress(ecp.Key.Left);
      await ecp.sendKeypress(ecp.Key.Ok);
  }

    // openSettings function
    public async  openSettings() {
      await testUtils.goToPage('settings');
      }



    // Navigate right until the grid is in focus
    // This is specifice to the Search screen
    public async  navigateRightToGrid() {
        await testUtils.untilTrue(async () => {
        await ecp.sendKeypress(ecp.Key.Right);
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
