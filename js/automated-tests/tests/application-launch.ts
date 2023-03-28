import { expect } from 'chai';
import { odc, ecp } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Application Launch', function () {
    before(async () => {
      await testUtils.signIntoAccount();
    });


    it('C4146 User Signed in - Homescreen Display @registered_user,@smoke,@application_launch', async () => {
      await testUtils.restartApplication();
      const sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
      expect(sideNavSignedInLabel.text).to.contain('Hi');
    });
});
