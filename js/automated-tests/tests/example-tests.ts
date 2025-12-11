import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';

// Not used for actual application testing but serves as example of how to write tests with specific functionality
describe.skip('Example Tests', function () {
  before(async () => {
    // Proxy testing related
    await proxy.start();
    // End proxy testing related
  });


  after(async () => {
    // Proxy testing related
    await proxy.stop();
    // End proxy testing related
  });

  // https://tubi.testrail.io/index.php?/cases/view/535807
  it('Proxy network request: Should be able to intercept the homescreen response', async () => {
    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('tensor-cdn.production-public.tubi.io/api/v5/homescreen');
        },
        processResponse(args) {
          const responseJson = JSON.parse(args.responseBuffer.toString());
          console.log('Response intercepted', args.url);

          // We are only going to send back the first two rows
          responseJson.containers = responseJson.containers.slice(0, 2);
          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        },
      });
    });
    await testUtils.startApplicationAtPage('home', {
      clearRegistry: false
    });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    const content = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    expect(content).to.have.lengthOf(2);
  });

  it('Proxy network request: Should be able to intercept active analytics event request', async () => {
    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('analytics-ingestion.staging-public.tubi.io/analytics-ingestion/v2/single-event');
        },
        processRequest(args) {
          console.log('Request intercepted', args.url);
          if (args.requestBody.event.active !== undefined) {
            args.removeCallback();
            resolve(null);
          }
        }
      });
    });
    await testUtils.startApplicationAtPage('home', {
      clearRegistry: false
    });
    await utils.promiseTimeout(proxyPromise, 5000);
  });
});
