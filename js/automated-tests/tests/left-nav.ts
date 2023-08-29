import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import exp = require('constants');

describe('Left Nav', function () {
    before(async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    });

    //https://tubi.testrail.io/index.php?/tests/view/23314
    it('C23314 - From Titles Detail Page > Categories Detail Page > Categories > Exit App @leftnav', async () => {

        // Open the Side nav and select Categories
        await ecp.sendKeyPress(ecp.Key.Left);

        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Categories
        await ecp.sendKeyPress(ecp.Key.Down, { count: 2 });
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Are we on Categories page?
        await utils.sleep(2000);
        const categoryPageCategory = testUtils.getNodeForElement('categoryPageCategory');
        expect((await categoryPageCategory).visible).to.be.true;

        // Choose a Category
        await ecp.sendKeyPress(ecp.Key.Ok);


        // Verify Category Details page

        await testUtils.retryWithTimeOut(async () => {
            const recommendedScreenCallToAction = await testUtils.getNodeForElement('recommendedScreenCallToAction');
            expect(recommendedScreenCallToAction.visible).to.be.true;
        });

        // Select title
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);
       


        // Once in detail page press the back button 5x
        await testUtils.retryWithTimeOut(async () => {
            const detailScreenTitle = testUtils.getNodeForElement('detailScreenTitle');
            expect((await detailScreenTitle).visible).to.be.true;
        });

        await ecp.sendKeyPress(ecp.Key.Back, { count: 5 });

        // Is the left Nav open?
        await testUtils.retryWithTimeOut(async () => {
            await testUtils.elementHasFocus('leftNavHomeButton');
        });

        // Verify that the Exit modal dialog is displayed
        const exitPrompt = testUtils.getNodeForElement('exitPrompt');
        expect((await exitPrompt).visible).to.be.true;
    });




    // https://tubi.testrail.io/index.php?/cases/view/23315
    it('C23315 - From Titles Detail Page > Home > Side Nav > Exit App, @leftnav', async () => {

        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForAppLaunchBeaconToFire();

        // Choose a title in the home screen and go into the details page
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Once in detail page press the back button 4x

        await testUtils.retryWithTimeOut(async () => {
            const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
            expect(detailScreenYearAndDuration.visible).to.equal(true);
        });


        await ecp.sendKeyPress(ecp.Key.Back, { count: 4 });

        // Verify that the Exit modal dialog is displayed
        const exitPrompt = testUtils.getNodeForElement('exitPrompt');
        expect((await exitPrompt).visible).to.be.true;

    });


    // https://tubi.testrail.io/index.php?/cases/view/23316
    it('C23316 - From Titles Detail Page > Search > Side Nav > Exit App, @leftnav', async () => {

        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForAppLaunchBeaconToFire();

        // Open the Side nav and select Search
        await testUtils.goToPage('search');

        // Search for a title and enter the details page
        await ecp.sendText('zapped');
        // Navigate right until the grid is in focus
        await testUtils.untilTrue(async () => {
            await ecp.sendKeyPress(ecp.Key.Right);
            const { value: id } = await odc.getValue({
                base: 'focusedNode',
                keyPath: 'id'
            });
            return id === 'ResultGrid';
        }, 'ResultGrid never obtained focus');

        // Wait until our content is loaded
        await odc.onFieldChangeOnce({
            base: 'focusedNode',
            keyPath: 'content',
            match: {
                base: 'focusedNode',
                keyPath: 'content.0.title',
                value: 'Zapped'
            }
        });

        // Go to the detail page
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Once in detail page press the back button 3x
        await testUtils.retryWithTimeOut(async () => {
            const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
            expect(detailScreenYearAndDuration.visible).to.equal(true);
        });

        await ecp.sendKeyPress(ecp.Key.Back, { count: 5 });

        // Verify that the Exit modal dialog is displayed
        const exitPrompt = testUtils.getNodeForElement('exitPrompt');
        expect((await exitPrompt).visible).to.be.true;

    });




    // https://tubi.testrail.io/index.php?/cases/view/23317
    it('C23317- From Titles Detail Page > Channel Detail Page > Channel > Side Nav > Exit App, @leftnav', async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
        await testUtils.waitForAppLaunchBeaconToFire();

        // Open the Side nav and select Categories
        await ecp.sendKeyPress(ecp.Key.Left);

        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');

        // Select Channel
        await ecp.sendKeyPress(ecp.Key.Down, { count: 3 });
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);

        // Are we on Channels page?
        await utils.sleep(2000);
        const channelPoster = testUtils.getNodeForElement('channelPoster');
        expect((await channelPoster).visible).to.be.true;

        // Choose a Channel
        await utils.sleep(2000);
        await ecp.sendKeyPress(ecp.Key.Ok);


        // Verify Channels Details page
        await testUtils.retryWithTimeOut(async () => {
            const recommendedScreenCallToAction = await testUtils.getNodeForElement('recommendedScreenCallToAction');
            expect(recommendedScreenCallToAction.visible).to.be.true;
        });

        // Select title
        await utils.sleep(2000); // Improvement
        await ecp.sendKeyPress(ecp.Key.Ok);


        // Once in detail page press the back button 5x
        await testUtils.retryWithTimeOut(async () => {
            const detailScreenYearAndDuration = await testUtils.getNodeForElement('detailScreenYearAndDuration');
            expect(detailScreenYearAndDuration.visible).to.equal(true);
        });

        await ecp.sendKeyPress(ecp.Key.Back, { count: 5 });

        // Verify that the Exit modal dialog is displayed
        const exitPrompt = testUtils.getNodeForElement('exitPrompt');
        expect((await exitPrompt).visible).to.be.true;

    });
});
