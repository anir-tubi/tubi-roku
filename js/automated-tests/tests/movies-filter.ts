import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Homescreen Navigation', function () {
    before(async () => {
      await testUtils.startApplicationAtPage('home', {shouldCreateNewUser: true});
    });

    // Just a placholder example, create first home screen navigation test here
    it('C22020 - Movies Filter - When movie filter is triggered then only Movie Titles are present, @homescreen', async () => {

    });



});
