import { expect } from 'chai';
import type { MediaPlayerResponse, NodeRepresentation } from 'roku-test-automation';
import { ecp, odc, utils, device, BaseType } from 'roku-test-automation';

class TestUtils {
  private convertedElementKeyPaths: {
    [key: string]: KeyPathElement
  };

  private elementKeyPaths: {
    [key: string]: KeyPathElement
  };


  // You can use this get the key path for the given element
  // elementName is the key that was used when defining in the element-keypaths file.
  // Example 'homeScreenRowList' would provide the key path to the HomeScreen RowList component.
  // baseArgs allows you pass in additional arguments if you are passing it directly to another rta function
  public getElementKeyPath<T>(elementName: string, baseArgs?: T) {
    if (!this.elementKeyPaths) {
      this.elementKeyPaths = require('../../automated-tests-config/element-keypaths.json');
    }

    if (!this.convertedElementKeyPaths) {
      this.convertedElementKeyPaths = require('../../automated-tests-config/converted-element-keypaths');
    }

    let element: KeyPathElement;
    element = this.elementKeyPaths[elementName];
    if (!element) {
      element = this.convertedElementKeyPaths[elementName];
    }

    if (!element) {
      throw new Error(`Could not find element named ${elementName}`);
    }

    return {
      ...baseArgs,
      base: BaseType.scene,
      keyPath: element.keyPath
    };
  }


  // This gives an easy way to get a node for the given element
  // elementName is the key that was used when defining in the element-keypaths file
  public async getNodeForElement(elementName: string, timeout = 10000) {
    let result;
    await testUtils.untilTrue(async () => {
      result = await odc.getValue(this.getElementKeyPath(elementName));
      return result.found;
    }, `Could not get node for element '${elementName}'`, timeout);

    return result.value as NodeRepresentation;
  }


  // Helper to wait until application has started up. Not necessarily fully loaded though
  public async waitForApplicationStartup() {
    await odc.onFieldChangeOnce({
      keyPath: '#ContentController.removeStartUpScreens',
      match: true
    });
  }


  // Helper to wait until we have fired the app launch beacon which should mean application is fully loaded at this point
  public waitForAppLaunchBeaconToFire() {
    return odc.onFieldChangeOnce({
      base: 'global',
      keyPath: 'trackingLoggingTask.logMsg',
      match: {
        base: 'global',
        keyPath: 'trackingLoggingTask.logMsg.subtype',
        value: 'time-to-load'
      }
    });
  }


  // Helper to fully shutdown the application
  public async exitApplication() {
    try {
      await odc.setValue({
        base: 'scene',
        keyPath: '#ContentController.exitApp',
        value: true
      }, {timeout: 1000});
    } catch (e) {
      // We don't care if it does not return since this can be expected behavior since we're stopping the application
    }

    // Wait until application no longer shows as running
    await this.waitForApplicationShutdown();
  }


  // Waits for application to shutdown but does not take any steps to make it do so
  public async waitForApplicationShutdown() {
    await this.untilTrue(async () => {
      const result = await ecp.getActiveApp();
      return result.app.id !== 'dev';
    }, 'Active app never switched from dev');
  }


  public async restartApplication(launchArgs: Parameters<typeof ecp.sendLaunchChannel>[0] = undefined) {
    // Leaving commented out for now to see if it is needed
    // const randomString = utils.randomStringGenerator();
    // We set a field on scene so we know the scene has been rebuilt
    // await odc.setValue({
    //   keyPath: 'checkSceneReset',
    //   value: randomString
    // });

    if (!launchArgs) {
      launchArgs = {
        launchParameters: {
          willNotRestartWithout: 1
        }
      };
    }

    await this.exitApplication();

    await ecp.sendLaunchChannel(launchArgs);

    // Leaving commented out for now to see if it is needed
    // Don't proceed until the scene has reset
    // await this.untilTrue(async () => {
    //   const {found} = await odc.getValue({
    //     keyPath: 'checkSceneReset'
    //   });
    //   return !found;
    // });
  }


  // Helper to sign in to an account in the application using the testing shortcut method
  public async signIntoAccount() {
    // Check if we're already signed in
    if (await this.isUserSignedIn()) {
      // If we're already signed in then we're done now
      return;
    }

    // Make sure we're signed in
    const authInfoPromise = odc.onFieldChangeOnce({
      base: 'global',
      keyPath: 'authInfo'
    });

    // Selecting login item to automatically log us in
    await this.selectMenuItem('mainMenu', 'Sign In');

    const {value: authInfo} = await authInfoPromise;
    expect(authInfo.userid, 'User was not signed in properly').to.not.be.empty;
  }


  private async isUserSignedIn() {
    const {value: authInfo} = await odc.getValue({
      base: 'global',
      keyPath: 'authInfo'
    });

    // Check both our global state and the registry to confirm we're signed in
    if (authInfo && authInfo.userid) {
      const userId = await odc.readRegistry({values: {
        'auth': 'userid'
      }});
      if (userId) {
        return true;
      }
    }
    return false;
  }


  // Starts the application at the specified page.
  // If asSignedInUser is true we will log them in else we will log them out
  public async startApplicationAtPage(page: DeeplinkPage | 'home', asSignedInUser = false) {
    if (asSignedInUser) {
      await this.waitForApplicationStartup();
      await this.signIntoAccount();
    } else {
      await odc.deleteEntireRegistry();
    }

    let launchParameters;
    // Home is default and there is no deeplink to it so we just don't pass a page
    if (page !== 'home') {
      launchParameters = {
        page: page
      };
    }
    await this.restartApplication({
      launchParameters: launchParameters
    });

    await this.waitForApplicationStartup();
  }


  // Helper for going to a different page in the application
  public async goToPage(page: DeeplinkPage | 'search') {
    if (page === 'search') {
      // We don't have a deeplink for these so we access it on the mainmenu instead
      await this.selectMenuItem('mainMenu', 'Search');
    } else {
      await device.sendECP('input', {
        page: page
      }, '');
    }
  }


  // Helper to check player state eventually equals the specified state
  public async expectPlayerStateToEventuallyEqual(state: MediaPlayerResponse['state'], timeout = 5000) {
    await testUtils.retryWithTimeOut(async () => {
      const player = await ecp.getMediaPlayer();
      expect(player.state).to.equal(state);
    }, timeout);
  }


  /**
   * Because we store the json object at the row level, trying to access RowList content the normal way with RTA can result in huge responses (21 MB). This helps work around that
   */
  // elementName is the key that was used when defining in the element-keypaths file
  public async findRowIndexWithTitle(elementName: string, title: string, timeout = 10000): Promise<number> {
    const element = this.getElementKeyPath(elementName);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    return await this.retryWithTimeOut(async () => {
      // First count how many rows of content there are
      const {found, value: rowCount} = await odc.getValue({
        base: element.base,
        keyPath: `${baseKeyPath}.getChildCount()`
      });
      if (!found) {
        throw new Error(`Can't find row count`);
      }

      // Now request each row's title
      const requests = {};
      for (let i = 0; i < rowCount; i++) {
        requests[i] = {
          base: element.base,
          keyPath: `${baseKeyPath}.${i}.TITLE`
        };
      }

      const {results} = await odc.getValues({
        requests: requests
      });

      // Once we find the row that matches the title return the index for it
      for (const key in results) {
        if (results[key].value === title) {
          return +key;
        }
      }
      throw new Error(`Could not find row with title ${title}`);
    }, timeout);
  }

  // Used to jump to a row with the title provided
  // elementName is the key that was used when defining in the element-keypaths file
  public async jumpToRowWithTitle(elementName: string, title: string, timeout = 10000) {
    const index = await this.findRowIndexWithTitle(elementName, title, timeout);
    await odc.setValue(this.getElementKeyPath(elementName, {
      field: 'jumpToItem',
      value: index
    }));
    return index;
  }


  // Used to select the item in the provided elementName that matches title provided.
  // elementName is the key that was used when defining in the element-keypaths file
  public async selectMenuItem(elementName: string, title: string) {
    const index = await this.findRowIndexWithTitle(elementName, title);
    await odc.setValue(this.getElementKeyPath(elementName, {
      field: 'itemSelected',
      value: index
    }));
  }


  // Helper to retry `func` until timeout has been reached or `func` does not throw an error.
  // `func` can return any value including void. If `func` throws an error, it will be retried.
  // If it does not throw an error, it will not be retried.
  // Useful to avoid need for sleep in tests
  public async retryWithTimeOut<T>(func: () => Promise<T>, timeout = 10000) {
    const start = Date.now();
    let lastError;
    while (timeout > Date.now() - start) {
      try {
        return await func();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError;
  }


  // Helper to retry `func` until timeout has been reached or `func` returns true
  // Useful to avoid need for sleep in tests
  // Since this does not need to create or throw an error on each iteration, unlike retryWithTimeOut,
  // it is more performant and may be better to use in some cases
  public async untilTrue(func: () => boolean | Promise<boolean>, errorMessage?: string, timeout = 10000) {
    const start = Date.now();
    while (timeout > Date.now() - start) {
      if(await func()) {
        return;
      }
    }

    if (!errorMessage) {
      errorMessage = `untilTrue failed to return true in ${timeout}ms`;
    }

    throw new Error(errorMessage);
  }

  // Helper to both print out the result from an async function and return its contents
  public async printAsyncResponse<T>(promise: Promise<T>) {
    const result = await promise;
    console.log(result);
    return result as T;
  }
}

const testUtils = new TestUtils();

export {
  testUtils
};

type KeyPathElement = {
  description?: string;
  elementId?: string;
  xpath?: string;
  keyPath: string;
};

type DeeplinkPage = 'movies' | 'livefeed' | 'genre' | 'network' | 'tv' | 'espanol' | 'kids'
