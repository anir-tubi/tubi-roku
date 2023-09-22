import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import exp = require('constants');



describe('Side Navigation', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });

    it('C3729 - Side Navigation - Home - When user presses the Back button then side nav should expand from collapsed state, @sidenav', async () => {


        // await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForAppLaunchBeaconToFire();

        // Press back twice
        await ecp.sendKeyPress(ecp.Key.Back, {count:2});

       
        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');
        expect(leftNavHomeButton.text).to.be.equal('Home');
       

    
      });



});
  