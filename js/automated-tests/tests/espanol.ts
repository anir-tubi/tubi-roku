import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Espanol', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

  });

        // https://tubi.testrail.io/index.php?/cases/view/115396
        it('C115396 - Tubi Latino is not accessible if parental controls are set to: Little Kids, @espanol', async () => {
        
          // Set Parental Controls to Little Kids
          await testUtils.goToPage('settings');

          // On Settings Page?
          const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
          expect(parentalControlsHeader.text).to.equal('Parental Controls');

          // Set PC
          await shared.selectLittleKidsFromParentalSettings();
          await enterPasswordSettingsChange();

          // Verify Little Kids PC Settings Change dialog
          const parentalControlsSettingsLittleKids = await testUtils.getNodeForElement('parentalControlsSettingsLittleKids');
          expect(parentalControlsSettingsLittleKids.text).to.equal('Parental controls setting has changed to Little Kids. Parental controls will be password protected after 5 minutes.');
          await ecp.sendKeyPress(ecp.Key.Ok);

          // Back to home
          await testUtils.goToPage('home');
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
            
          // Select Espanol from Left Nav
          await ecp.sendKeyPress(ecp.Key.Left);
          await utils.sleep(2000);
          await ecp.sendKeyPress(ecp.Key.Down, { count: 4});
          await ecp.sendKeyPress(ecp.Key.Ok);
        
          // Verify Espanol Disabled for Little Kids
          await verifyEspanolDisabledKids();
          
      
      });

      // https://tubi.testrail.io/index.php?/cases/view/115397
      it('C115397 - Tubi Latino is not accessible if a user is in Kids Mode, @espanol', async () => {

          await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
          
          await shared.openKidsMode();

          // In Kids Mode? 
          const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
          expect(exitKidsOption.visible).to.be.true;

          // Select Espanol from Left Nav
          await ecp.sendKeyPress(ecp.Key.Down, { count: 4});
          await ecp.sendKeyPress(ecp.Key.Ok);
          
          // Verify Espanol Disabled for Kids mode
          await verifyEspanolDisabledKids();

      
      });
      
      //https://tubi.testrail.io/index.php?/tests/view/115398
      it('C115398 - Latino mode is not persistent between sessions @espanol', async () => {

          await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

          // Open the Side nav 
          await ecp.sendKeyPress(ecp.Key.Left);

          // Is the left Nav open?
          const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
          await testUtils.elementHasFocus('leftNavHomeButton'); 

          // Select Espanol
          await ecp.sendKeyPress(ecp.Key.Down, { count: 4});
          await utils.sleep(2000); // Improvement
          await ecp.sendKeyPress(ecp.Key.Ok);

          // Are we in Espanol mode? 
          await testUtils.waitForElementToHaveFocus('espanolScreenRowList', 'Timed out waiting for Espanol screen to have focus');

          //Relaunch app and verify we are no longer in Espanol mode
          await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
      });

      // https://tubi.testrail.io/index.php?/cases/view/116489
      it('C116489 - Tubi Latino is not accessible if parental controls are set to: Older Kids, @espanol', async () => {
          
          
          await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

          // Set Parental Controls to Little Kids
          await testUtils.goToPage('settings');

          // On Settings Page?
          const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
          expect(parentalControlsHeader.text).to.equal('Parental Controls');

          // Set PC
          await shared.selectOlderKidsFromParentalSettings();
          await enterPasswordSettingsChange();

          // Verify Little Kids PC Settings Change dialog
          const parentalControlsSettingsOlderKids = await testUtils.getNodeForElement('parentalControlsSettingsOlderKids');
          expect(parentalControlsSettingsOlderKids.text).to.equal('Parental controls setting has changed to Older Kids. Parental controls will be password protected after 5 minutes.');
          await ecp.sendKeyPress(ecp.Key.Ok);

          // Back to home
          await testUtils.goToPage('home');
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
            
          // Select Espanol from Left Nav
          await ecp.sendKeyPress(ecp.Key.Left);
          await utils.sleep(2000);
          await ecp.sendKeyPress(ecp.Key.Down, { count: 4});
          await ecp.sendKeyPress(ecp.Key.Ok);
        
          // Verify Espanol Disabled for Older Kids
          await verifyEspanolDisabledKids();
      
      });

     // https://tubi.testrail.io/index.php?/cases/view/116490
     it('C116490 - Tubi Latino is not accessible if parental controls are set to: Teens, @espanol', async () => {
        
          await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus'); 

          // Set Parental Controls to Little Kids
          await testUtils.goToPage('settings');

          // On Settings Page?
          const parentalControlsHeader = await testUtils.getNodeForElement('parentalControlsHeader');
          expect(parentalControlsHeader.text).to.equal('Parental Controls');

          // Set PC
          await shared.selectTeensFromParentalSettings();
          await enterPasswordSettingsChange();

          // Verify Little Kids PC Settings Change dialog
          const parentalControlsSettingsTeens = await testUtils.getNodeForElement('parentalControlsSettingsTeens');
          expect(parentalControlsSettingsTeens.text).to.equal('Parental controls setting has changed to Teens. Parental controls will be password protected after 5 minutes.');
          await ecp.sendKeyPress(ecp.Key.Ok);

          // Back to home
          await testUtils.goToPage('home');
          await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
            
          // Select Espanol from Left Nav
          await ecp.sendKeyPress(ecp.Key.Left);
          await utils.sleep(2000);
          await ecp.sendKeyPress(ecp.Key.Down, { count: 4});
          await ecp.sendKeyPress(ecp.Key.Ok);
        
          // Verify Espanol Disabled for Teens
          await verifyEspanolDisabledTeens();
      
    });


  });

      async function enterPasswordSettingsChange() {
        await utils.sleep(1000);
        await ecp.sendKeyPress(ecp.Key.Ok);
        await ecp.sendText('111111');
        await ecp.sendKeyPress(ecp.Key.Down, {count:4});
        await utils.sleep(2000);
        await ecp.sendKeyPress(ecp.Key.Ok);
    }

    async function verifyEspanolDisabledKids() {
      const espanolDisabledTitle = await testUtils.getNodeForElement('espanolDisabledTitle');
      expect(espanolDisabledTitle.text).to.equal('Español Disabled');
      const espanolDisabledMessage = await testUtils.getNodeForElement('espanolDisabledMessage');
      expect(espanolDisabledMessage.text).to.equal('Please exit Tubi Kids to use this feature.');
      const espanolDisabledButton = await testUtils.getNodeForElement('espanolDisabledButton');
      expect(espanolDisabledButton.text).to.equal('OK');
    }

    async function verifyEspanolDisabledTeens() {
      const espanolDisabledTitleTeens = await testUtils.getNodeForElement('espanolDisabledTitleTeens');
      expect(espanolDisabledTitleTeens.text).to.equal('Español Disabled');
      const espanolDisabledMessageTeens = await testUtils.getNodeForElement('espanolDisabledMessageTeens');
      expect(espanolDisabledMessageTeens.text).to.equal('Please turn off parental controls to use this feature.');
      const espanolDisabledButtonTeens = await testUtils.getNodeForElement('espanolDisabledButtonTeens');
      expect(espanolDisabledButtonTeens.text).to.equal('OK');
    }









