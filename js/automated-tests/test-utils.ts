import { createHash, createHmac } from 'crypto';
import { expect } from 'chai';
import type { MediaPlayerResponse, NodeRepresentation } from 'roku-test-automation';
import { ecp, odc, utils, device, BaseType } from 'roku-test-automation';
import * as needle from 'needle';
import * as querystring from 'needle/lib/querystring';

const clientVersion = '2.21.0';


const platform = 'roku';


enum ContentTypes {
  'series' = 'series',
  'movie' = 'movie',
  'linear' = 'linear',
  'category' = 'category',
  'channel' = 'channel',
  'sports_event' = 'sports_event'
}

const abbreviatedContentTypeConversion = {
  c: ContentTypes.category,
  v: ContentTypes.movie,
  s: ContentTypes.series,
  channel: ContentTypes.channel,
  l: ContentTypes.linear,
  se: ContentTypes.sports_event
} as {[key: string]: ContentTypes};


class TestUtils {
  private convertedElementKeyPaths: {
    [key: string]: KeyPathElement
  };

  private elementKeyPaths: {
    [key: string]: KeyPathElement
  };

  private userAgent = 'Roku/DVP-11.5 (11.5.0.4312-46)';


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
  public async getNodeForElement(elementName: string, timeout = 15000) {
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
    }, {timeout: 20000});
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
    // wait for content controller to get added. This is needed in the case that the application is still launching and then the next test tries to close the application again. Without this the setValue would fail because ContentController does not exist yet.
    await this.getNodeForElement('contentControllerId');
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


  public async sendNetworkRequest(requestOptions: needle.NeedleOptions & {
    url: string;
    method: needle.NeedleHttpVerbs;
    params?: {[key: string]: any};
    body?: any}) {
    // requestOptions.proxy = '127.0.0.1:8888'; // useful for debugging

    requestOptions.headers = requestOptions.headers ?? {};
    requestOptions.headers['user-agent'] = this.userAgent;

    const params = requestOptions.params;
    let url = requestOptions.url;
    if (params && Object.keys(params).length) {
      url = url.replace(/\?.*|$/, '?' + querystring.build(params));
    }

    let response: Awaited<ReturnType<typeof needle>>;
    if (requestOptions.body) {
      if (typeof requestOptions.body !== 'string') {
        requestOptions.body = JSON.stringify(requestOptions.body);
        requestOptions.headers['content-type'] = 'application/json';
      }
      response = await needle(requestOptions.method, url, requestOptions.body, requestOptions);
    } else {
      response = await needle(requestOptions.method, url, requestOptions);
    }

    if (response.statusCode >= 400) {
      throw new Error(`Received invalid response code ${response.statusCode} for url ${url}: ${response.body}`);
    }

    return response.body;
  }


  // Starts the application at the specified page.
  // args: options to modify starting application state such as wether a user is logged in or not
  public async startApplicationAtPage(page: DeeplinkPage | 'search', args: StartApplicationArgs = {}) {
    let deeplink;
    if (page !== 'search') {
      deeplink = {
        page: page
      };
    }

    await this.startApplicationWithDeeplink(deeplink, args);

    if (page === 'search') {
      await this.goToPage('search');
    }
  }


  // Starts the application at the specified page.
  // deeplink: this is an object with the list of starting params sent to the application. Common fields include contentId, mediaType and page but other values may be passed as needed.
  // args: options to modify starting application state such as wether a user is logged in or not
  public async startApplicationWithDeeplink(deeplink = {}, args: StartApplicationArgs = {}) {
    if (args.clearRegistry !== false) {
      deeplink['clearRegistry'] = true;
    }

    let user = args.user;
    if (args.shouldCreateNewUser === true) {
      user = await this.createRegisteredUser();
    }

    if (user) {
      deeplink['setRegistry'] = JSON.stringify(user.getRegistryAuthValues());
    }

    if (args.language) {
      let locale: string;
      switch (args.language) {
        case 'english':
          locale = 'en_US';
          break;
        case 'spanish':
          locale = 'es_ES';
          break;
      }
      const language = locale.slice(0, 2);
      deeplink['constantsUpdates'] = JSON.stringify({
        'deviceInfo.locale': locale,
        'deviceInfo.language': language
      });
    }

    await this.restartApplication({
      params: deeplink
    });

    await this.waitForApplicationStartup();
  }


  public async createRegisteredUser() {
    const user = new RegisteredUser();
    const credentials = {
      birthday: '2000-01-01',
      email: `build_roku_${Math.floor(Date.now() / 1000)}@tubi.tv`,
      email_type: 'manual',
      first_name: 'Automation',
      gender: '',
      last_name: '',
      password: '111111',
      temporary_name: true
    };
    await user.create(credentials);
    return user;
  }


  public async createAnonymousUser() {
    const user = new AnonymousUser();
    await user.create();
    return user;
  }


  public async restartApplication(args: Parameters<typeof ecp.sendLaunchChannel>[0] = undefined) {
    await this.exitApplication();
    await ecp.sendLaunchChannel(args);
  }


  // Helper for going to a different page in the application
  public async goToPage(page: DeeplinkPage | 'search' | 'settings') {
    if (page === 'search') {
      // We don't have a deeplink for these so we access it on the mainmenu instead
      await this.selectMenuItem('mainMenu', 'Search', undefined);
    } else if (page === 'settings') {
      // We don't have a deeplink for these so we access it on the mainmenu instead
      await this.selectMenuItem('mainMenu', 'Settings', undefined);
    } else {
      await ecp.sendInput({
        params: {
          page: page
        }
      });
    }
  }


  // Helper to check player state eventually equals the specified state
  public async expectPlayerStateToEventuallyEqual(state: MediaPlayerResponse['state'], timeout = 5000) {
    return await testUtils.retryWithTimeOut(async () => {
      const player = await ecp.getMediaPlayer();
      expect(player.state).to.equal(state);
      return player;
    }, timeout);
  }


   // Helper to get the current position of the video player
  public async getPlayerPosition() {
    const player = await ecp.getMediaPlayer();
    return player.position.number;
  }


  // Temporary helper to wait until ads are done playing to proceed until we hook in proxy to override ads
  public async waitForAdsToFinish() {
    const maxExpectedAdBreakDuration = 180 * 1000;
    const maxExpectedIndividualAdDuration = 120 * 1000;
    await this.untilTrue(async () => {
      const player = await ecp.getMediaPlayer();
      return player.state === 'play' && player.duration.number > maxExpectedIndividualAdDuration;
    }, 'Timed out while waiting for ads to finish playing', maxExpectedAdBreakDuration);
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


  /**
   * Used to retrieve all content in row specified by `rowIndex` from the specified RowList element
   * elementName is the key that was used when defining in the element-keypaths file. Should have `RowList` in its name
   */
  public async getRowListRowItemsContent(elementName: string, rowIndex: number, timeout = 10000) {
    const element = this.getElementKeyPath(elementName);

    const baseKeyPath = `${element.keyPath}.content.${rowIndex}`;

    const node = await testUtils.retryWithTimeOut(async () => {
      const {value, found} = await odc.getValue({
          keyPath: baseKeyPath,
          responseMaxChildDepth: 1
      });

      if(!found) {
        throw new Error(`Could not retrieve item content for rowIndex ${rowIndex}`);
      }

      return value;
    }, timeout);

    const rowItemsContent = [];

    if (node.json) {
      const json = JSON.parse(node.json);
      for (const child of node.children) {
        rowItemsContent.push(json[child.id]);
      }
    } else {
      for (const child of node.children) {
        rowItemsContent.push(child);
      }
    }
    return rowItemsContent;
  }


  /**
   * Used to retrieve all content in the currently focused row from the specified RowList element
   * elementName is the key that was used when defining in the element-keypaths file. Should have `RowList` in its name
   */
  public async getCurrentlyFocusedRowListRowItemsContent(elementName: string, timeout = 10000) {
    const grid = await this.getNodeForElement(elementName, timeout);
    if (!grid.rowItemFocused) {
      throw new Error('This function should only be used on RowList elements');
    }

    const index = grid.rowItemFocused[0];
    return await this.getRowListRowItemsContent(elementName, index, timeout);
  }


  /**
   * Used to retrieve all content in the specified RowList element
   * elementName is the key that was used when defining in the element-keypaths file. Should have `RowList` in its name
   */
  public async getAllRowListItemsContent(elementName: string, timeout = 10000) {
    const element = this.getElementKeyPath(elementName);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    const rowCount = await this.retryWithTimeOut(async () => {
      const {found, value: rowCount} = await odc.getValue({
        base: element.base,
        keyPath: `${baseKeyPath}.getChildCount()`
      });
      if (!found) {
        throw new Error(`Can't find row count`);
      }
      return rowCount;
    });

    const gridItemsContent = [];
    for (let rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      const rowItemsContent = await this.getRowListRowItemsContent(elementName, rowIndex, timeout);
      for (const itemContent of rowItemsContent) {
        gridItemsContent.push(itemContent);
      }
    }
    return gridItemsContent;
  }


  // Used to retrieve grid item content for the item specified by the index
  // elementName is the key that was used when defining in the element-keypaths file
  public async getGridItemContent(elementName: string, index: number | number[], timeout = 10000) {
    const element = this.getElementKeyPath(elementName);
    if (!Array.isArray(index)) {
      index = [index];
    }

    // Required to ensure index is typed as array in retryWithTimeOut
    const arrayIndex = index;

    const baseKeyPath = `${element.keyPath}.content.${index[0]}`;

    if (index.length > 1) {
      // If we have a row and column index we need to check if we have a json object that we will reference instead
      const results = await testUtils.retryWithTimeOut(async () => {
        const requests = {
          requests: {
            rowJson: {
              keyPath: `${baseKeyPath}.json`
            },
            itemContent: {
              keyPath: `${baseKeyPath}.${index[1]}`
            }
          }
        };
        const {results} = await odc.getValues(requests);

        if(!results.itemContent.found) {
          throw new Error(`Could not retrieve item content for index ${arrayIndex.join(':')}`);
        }

        return results;
      }, timeout);

      if (results.rowJson.found) {
        const json = JSON.parse(results.rowJson.value);
        const content = json[results.itemContent.value.id];
        return content;
      } else {
        return results.itemContent.value;
      }
    } else {
      return await testUtils.retryWithTimeOut(async () => {
        const {value, found} = await odc.getValue({
            keyPath: baseKeyPath
        });

        if(!found) {
          throw new Error(`Could not retrieve item content for index ${arrayIndex[0]}`);
        }

        return value;
      }, timeout);
    }
  }


  // Used to get the grid item content for the currently focused grid item
  // elementName is the key that was used when defining in the element-keypaths file
  public async getCurrentlyFocusedGridItemContent(elementName: string, timeout = 10000) {
    const grid = await this.getNodeForElement(elementName, timeout);
    let index;
    if (grid.rowItemFocused) {
      index = grid.rowItemFocused;
    } else {
      index = grid.itemFocused;
    }

    return await this.getGridItemContent(elementName, index, timeout);
  }


  // Used to select an item in detail page menu and verify that the action has been completed successfully
  public async selectAndVerifyDetailPageMenuItem(item: DetailPageMenuItemType, timeout = 10000) {
    // If a network request is still happening then we need to wait for it to complete before proceeding
    const args = this.getElementKeyPath('detailScreen');
    args.keyPath += '.isWaitingForServerResponse';
    args['match'] = false;
    await odc.onFieldChangeOnce(args);

    const elementName = 'detailScreenMenu';
    switch (item) {
      case 'play':
        await this.selectMenuItem(elementName, 'Play', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'playFromBeginning':
        await this.selectMenuItem(elementName, 'Play from Beginning', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'resume':
        await this.selectMenuItem(elementName, 'Resume Playing', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'addToMyList':
        await this.selectMenuItem(elementName, 'Add to My List', timeout);
        // We know we're good once the remove item shows up
        await this.findRowIndexWithTitle(elementName, 'Remove from My List', timeout);
        break;
      case 'removeFromMyList':
        await this.selectMenuItem(elementName, 'Remove from My List', timeout);
        // We know we're good once the add item shows up
        await this.findRowIndexWithTitle(elementName, 'Add to My List', timeout);
        break;
      case 'removeFromHistory':
        await this.selectMenuItem(elementName, 'Remove from history', timeout);
        // We know we're good once the Resume item goes away
        await this.untilTrue(async () => {
          try {
            await this.findRowIndexWithTitle(elementName, 'Remove from history', 0);
            return false;
          } catch(e) {
            return true;
          }
        }, 'Could not verify that Remove from history was removed');
        break;
      case 'episodesList':
        await this.selectMenuItem(elementName, 'Episodes list', timeout);
        await this.waitForElementToBeInFocusChain('episodesScreen');
        break;
      }
  }


  // Used to select the item in the provided elementName that matches title provided.
  // elementName is the key that was used when defining in the element-keypaths file
  public async selectMenuItem(elementName: string, title: string, timeout = 10000) {
    const index = await this.jumpToRowWithTitle(elementName, title, timeout);

    await odc.setValue(this.getElementKeyPath(elementName, {
      field: 'itemSelected',
      value: index
    }), {timeout: timeout});
  }


  // returns true if this element or one of its children currently has focus
  public elementIsInFocusChain(elementName: string) {
    return odc.isInFocusChain(this.getElementKeyPath(elementName));
  }


  // returns true if this element has focus
  public elementHasFocus(elementName: string) {
    return odc.hasFocus(this.getElementKeyPath(elementName));
  }


  // tries to wait until this element has focus
  public waitForElementToHaveFocus(elementName: string, errorMessage?: string, timeout = 10000) {
    return this.untilTrue(() => {
      return this.elementHasFocus(elementName);
    }, errorMessage, timeout);
  }


  // tries to wait until this element does not have focus
  public waitForElementToNotHaveFocus(elementName: string, errorMessage?: string, timeout = 10000) {
    return this.untilTrue(async () => {
      const result = await this.elementHasFocus(elementName);
      return !result;
    }, errorMessage, timeout);
  }


  // tries to wait until this element or one of its children has focus
  public waitForElementToBeInFocusChain(elementName: string, errorMessage?: string, timeout = 10000) {
    return this.untilTrue(() => {
      return this.elementIsInFocusChain(elementName);
    }, errorMessage, timeout);
  }


  // tries to wait until this element and none of its children has focus
  public waitForElementToNotBeInFocusChain(elementName: string, errorMessage?: string, timeout = 10000) {
    return this.untilTrue(async () => {
      const result = await this.elementIsInFocusChain(elementName);
      return !result;
    }, errorMessage, timeout);
  }


  // Helper to retry `func` until timeout has been reached or `func` does not throw an error.
  // `func` can return any value including void. If `func` throws an error, it will be retried.
  // If it does not throw an error, it will not be retried.
  // Useful to avoid need for sleep in tests
  public async retryWithTimeOut<T>(func: () => Promise<T>, timeout = 10000) {
    const start = Date.now();
    let lastError;
    while (timeout >= Date.now() - start) {
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
  public async untilTrue(func: () => boolean | Promise<boolean>, errorMessage?: string, timeout = 15000) {
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
  public async printAsyncResponse<T>(promise: Promise<T>, message?: string) {
    const result = await promise;
    if (message) {
      console.log(message, result);
    } else {
      console.log(result);
    }

    return result as T;
  }
}


class Auth {
  private baseAccountUrl = 'https://account.production-public.tubi.io';
  private deviceId: string;
  private anonymousTokenInfo: {
    access_token: string;
    expires_in: number;
    refresh_token: string;
    signingKey: {
      id: string;
      key: string;
      verifier: string;
    }
  };


  private getHeaders(additionalHeaders = {}) {
    return {
      'accept-language': 'en-US',
      'content-type': 'application/json',
      'x-client-platform': platform,
      'x-client-version': clientVersion,
      ...additionalHeaders
    };
  }


  public async getDeviceId() {
    if (this.deviceId) {
      return this.deviceId;
    }

    const {values} = await odc.readRegistry({
      values: {
        deviceinfo: 'deviceId'
      }
    });

    const deviceId = values.deviceinfo.deviceId;
    if (!deviceId) {
      throw new Error('Could not retrieve deviceId. Can not proceed.');
    }
    this.deviceId = deviceId;
    return deviceId;
  }


  public async getSigningKey() {
    const verifier = utils.randomStringGenerator(36);
    const challenge = createHash('sha256').update(verifier).digest('base64').replace(/\+/g, '-').replace(/\//g, '_');

    const body = {
      challenge: challenge,
      device_id: await this.getDeviceId(),
      platform: platform,
      version: clientVersion,
      verifier: verifier
    };

    const response = await testUtils.sendNetworkRequest({
      method: 'post',
      url: this.baseAccountUrl + '/device/anonymous/signing_key',
      body: body,
      headers: this.getHeaders()
    });
    response.verifier = verifier;

    return response as {
      id: string;
      key: string;
      verifier: string;
    };
  }


  // Used to get an anonymous token for use on API calls. If force = true then we will get a fresh token every time even if we have already retrieved one previously
  public async getAnonymousToken(force = false) {
    if (this.anonymousTokenInfo && !force) {
      return this.anonymousTokenInfo;
    }

    const signingKey = await this.getSigningKey();

    const body = JSON.stringify({
      device_id: await this.getDeviceId(),
      id: signingKey.id,
      platform: platform,
      verifier: signingKey.verifier,
    });

    const response = await this.sendSignedTubiNetworkRequest({
      method: 'post',
      url: this.baseAccountUrl + '/device/anonymous/token',
      body: body,
      headers: this.getHeaders(),
      signingKey: signingKey
    });

    response.signingKey = signingKey;

    this.anonymousTokenInfo = response;

    return this.anonymousTokenInfo;
  }


  public async userSignup(credentials: {
      birthday: string;
      email: string;
      email_type: string;
      first_name: string;
      gender: string;
      last_name: string;
      password: string;
      temporary_name: boolean;
    }) {
    const anonymousToken = await this.getAnonymousToken(true);
    const body = JSON.stringify({
      device_id: await this.getDeviceId(),
      platform: platform,
      credentials: credentials
    });

    const headers = this.getHeaders({
      authorization: 'Bearer ' + anonymousToken.access_token
    });

    const user = await testUtils.sendNetworkRequest({
      method: 'post',
      url: this.baseAccountUrl + '/user/signup',
      headers: headers,
      body: body
    });
    user.signingKey = anonymousToken.signingKey;

    return user as UserSignUpResponse;
  }


  // Returns a semicolon concatted string required for signing
  private constructSignedHeaders(requestOptions: Parameters<typeof this.sendSignedTubiNetworkRequest>[0]) {
    const headerKeys = Object.keys(requestOptions.headers);
    return headerKeys.join(';');
  }


  private async sendSignedTubiNetworkRequest(requestOptions: Parameters<typeof testUtils.sendNetworkRequest>[0] & {
    signingKey: {
      id: string;
      key: string;
    };
    body: string;
  }) {
    requestOptions = this.appendSignatureInfo(requestOptions);
    return testUtils.sendNetworkRequest(requestOptions);
  }


  private calculateSignature(stringToSign, secretKey, dateTime) {
    const date = dateTime.split('T')[0];

    const secret1 = Buffer.concat([Buffer.from('TUBI', 'utf-8'), Buffer.from(secretKey, 'base64')]);
    const secret2 = this.hmac(date, secret1);
    const secret3 = this.hmac('tubi_request', secret2);
    const signature = this.hmac(stringToSign, secret3);
    return signature;
  }


  private appendSignatureInfo(requestOptions: Parameters<typeof this.sendSignedTubiNetworkRequest>[0] & {
    body: string;
  }) {
    const canonicalRequest = this.constructCanonicalRequest(requestOptions);
    const hashedCanonicalRequest = createHash('sha256').update(canonicalRequest).digest('hex');

    const dateTime = new Date().toISOString().split('.').shift() + 'Z';
    const dateTimeFormatted = dateTime.replace(/-/g,'').replace(/:/g,'');

    const algorithm = 'TUBI-HMAC-SHA256';

    const stringToSign = [
      algorithm,
      dateTimeFormatted,
      hashedCanonicalRequest,
    ].join('\n');

    const secretKey = requestOptions.signingKey.key;
    const signature = this.calculateSignature(stringToSign, secretKey, dateTimeFormatted).toString('hex');

    requestOptions.params = {
      'X-Tubi-Signature': signature,
      'X-Tubi-Expires': 60,
      'X-Tubi-Date': dateTimeFormatted,
      'X-Tubi-SignedHeaders': this.constructSignedHeaders(requestOptions),
      'X-Tubi-Algorithm': algorithm
    };
    return requestOptions;
  }


  private constructCanonicalRequest(requestOptions: Parameters<typeof this.sendSignedTubiNetworkRequest>[0] & {
    body: string;
  }) {
    const hashedPayload = createHash('sha256').update(requestOptions.body).digest('hex');

    const headersArray = [];
    const headers = {...requestOptions.headers};

    for (const key in headers) {
      const headerValue = headers[key] as string;
      headersArray.push(`${key.toLowerCase()}:${headerValue}`);
    }

    const canonicalRequest = [
      requestOptions.method.toUpperCase(),
      new URL(requestOptions.url).pathname,
      '', // Query string not building out for now
      headersArray.join('\n'), // canonicalHeader
      '', // Note must have extra new line here
      this.constructSignedHeaders(requestOptions), //signedHeader
      hashedPayload
    ].join('\n');


    return canonicalRequest;
  }


  private hmac(contents, secret) {
    const result = createHmac('SHA256', secret).update(contents).digest();
    return result;
  }
}


abstract class User {
  protected accessToken = '';
  protected isNewUser?: boolean;


  // Used to create user of the class type
  abstract create(credentials);


  // Returns the contents that need to be set for this type of user in the registry
  abstract getRegistryAuthValues();


  // Used to specify if this is a new user or returning user when we launch the application
  public setIsNewUser(value: boolean) {
    this.isNewUser = value;
  }


  protected generateFirstVisitValue(date: Date) {
    const unixTimeStamp = date.getTime();
    const daysSinceEpoch = Math.floor(unixTimeStamp / 24 / 3600);
    return daysSinceEpoch;
  }


  // Send a network request requiring tubi authentication
  public async sendTubiAuthNetworkRequest(requestOptions: Parameters<typeof testUtils.sendNetworkRequest>[0]) {
    requestOptions.headers = requestOptions.headers ?? {};
    requestOptions.headers.authorization = 'Bearer ' + this.accessToken;

    return await testUtils.sendNetworkRequest(requestOptions);
  }


  public getContent() {
    return new FilterContent(this);
  }
}


class AnonymousUser extends User {
  public async create() {
    const result = await auth.getAnonymousToken();
    this.accessToken = result.access_token;
  }


  getRegistryAuthValues() {
    let firstVisit = -1;
    if (!this.isNewUser) {
      firstVisit = this.generateFirstVisitValue(new Date);
    }

    return {
      visit: {
        firstVisit: `${firstVisit}`
      }
    };
  }
}


class RegisteredUser extends User {
  private userInfo: UserSignUpResponse;


  public async create(credentials) {
    this.userInfo = await auth.userSignup(credentials);
    this.accessToken = this.userInfo.access_token;
  }


  getRegistryAuthValues() {
    let firstVisit = -1;
    if (!this.isNewUser) {
      firstVisit = this.generateFirstVisitValue(new Date);
    }

    return {
      auth: {
        refreshtoken: this.userInfo.refresh_token,
        userid: `${this.userInfo.user_id}`,
        expiretime: '0'
      },
      visit: {
        firstVisit: `${firstVisit}`
      }
    };
  }


  // contents: array of contents as returned by a call to getContents()
  public async addContentToWatchList(contents: {type: string; id: string}[] | {type: string; id: string}) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    const promises = [];
    for (const content of contents) {
      const contentType = abbreviatedContentTypeConversion[content.type];
      let contentId = content.id;
      if (contentType == ContentTypes.series) {
        // Have to add leading zero for series
        contentId = `0${contentId}`;
      } else if (contentType !== ContentTypes.movie && contentType !== ContentTypes.sports_event) {
        console.warn('Tried to add unsupported type to watchlist. Skipping...');
        continue;
      }

      const body = {
        content_id: contentId,
        content_type: contentType,
        type: 'watch_later'
      };

      const promise = this.sendTubiAuthNetworkRequest({
        method: 'post',
        url: 'https://user-queue.production-public.tubi.io/api/v2/queues',
        body: body
      });
      promises.push(promise);
    }
    return Promise.all(promises);
  }


  public async getWatchListContent() {
    const {queues} = await this.sendTubiAuthNetworkRequest({
      method: 'get',
      url: 'https://user-queue.production-public.tubi.io/api/v2/queues'
    });
    return queues as {
      content_id: number;
      content_type: ContentTypes;
    }[];
  }


  // contents: array of contents as returned by a call to getContents()
  public async removeContentFromWatchList(contents: {type: string; id: string}[] | {type: string; id: string}) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    const promises = [];
    for (const content of contents) {
      const body = {
        content_id: content.id,
        content_type: abbreviatedContentTypeConversion[content.type]
      };

      const promise = await this.sendTubiAuthNetworkRequest({
        method: 'delete',
        url: 'https://user-queue.production-public.tubi.io/api/v2/queues',
        body: body
      });
      promises.push(promise);
    }
    await Promise.all(promises);
  }


  // contents: array of contents returned from a call to getContents
  // positions: number or array of where in the content to mark the user's play history. If less values are provided than in contents then the last positions value is used
  public async addContentToViewHistory(contents: {type: string; id: string}[] | {type: string; id: string}, positions: number | number[]) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    if (Array.isArray(positions) && positions.length === 0) {
      throw new Error('Empty array passed for positions. Please supply at least one valid position value');
    } else if (typeof positions === 'number') {
      positions = [positions];
    }

    const promises = [];

    for (const [index, content] of contents.entries()) {
      const contentType = abbreviatedContentTypeConversion[content.type];
      const contentId = content.id;
      if (contentType !== ContentTypes.movie && contentType !== ContentTypes.series && contentType !== ContentTypes.sports_event) {
        console.warn('Tried to add unsupported type to view history. Skipping...');
        continue;
      }

      const body = {
        content_id: contentId,
        content_type: contentType as string,
        parent_id: null,
        position: positions[index] ?? positions.at(-1)
      };

      // For series we have to do an additional call to get the episodes for this series since the episodes are what have the progress
      if (contentType === ContentTypes.series) {
        // Have to add leading zero since it's a series
        const fullSeriesContent = await this.getContentById('0' + contentId);

        // For now we just always get the first episode
        const firstEpisode = fullSeriesContent.children[0].children[0];
        if (firstEpisode) {
          body.content_type = 'episode';
          body.content_id = firstEpisode.id;
          body.parent_id = contentId;
        } else {
          console.warn('Could not retrieve series episode. Skipping...');
          continue;
        }
      }

      const promise = await this.sendTubiAuthNetworkRequest({
        method: 'post',
        url: 'https://lishi.production-public.tubi.io/api/v2/view_history',
        body: body
      });
      promises.push(promise);
    }

    return await Promise.all(promises);
  }


  public async getViewHistoryContent() {
    const {items} = await this.sendTubiAuthNetworkRequest({
      method: 'get',
      url: 'https://lishi.production-public.tubi.io/api/v2/view_history'
    });

    return items as {
      content_id: number;
      content_length: number;
      content_type: ContentTypes;
      created_at: string;
      id: string;
      position: number;
      state: string;
      updated_at: string;
      user_id: number;
    }[];
  }


  // contents: array of contents returned from a call to getContents
  public async removeContentFromViewHistory(contents: {type: string; id: string}[] | {type: string; id: string}) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    // We have to get the user's view history as we can not remove content from the view history without knowing its history id
    const currentViewHistoryContent = await this.getViewHistoryContent();

    for (const content of contents) {
      // We have to search for a matching content id
      let id = '';
      for (const item of currentViewHistoryContent) {
        if (item.content_id === +content.id && item.content_type === content.type) {
          id = item.id;
          break;
        }
      }

      if (id) {
        await this.sendTubiAuthNetworkRequest({
          method: 'delete',
          url: `https://lishi.production-public.tubi.io/api/v2/view_history/${id}`,
          body: {}
        });
      } else {
        console.warn(`Could not find view history id for content with id ${content.id}. Skipping...`);
      }
    }
  }


  public async getContentById(contentId) {
    const params = {
      content_id: contentId,
      platform: platform,
      device_id: await auth.getDeviceId()
    };

    return await this.sendTubiAuthNetworkRequest({
      method: 'get',
      url: 'https://uapi.adrise.tv/cms/content',
      params: params
    });
  }
}


class FilterContent {
  private user: User;


  private cachedContents: {
    [key: string]: {
      id: string;
      title: string;
      video_preview_url: string;
      type: string;
      ratings: {
        value: string;
      }
    }
  };


  constructor(user) {
    this.user = user;
  }


  private filters = [] as {
    type: ContentFilterType;
    value: any;
  }[];


  public withRating(ratings: ContentRatings | ContentRatings[]) {
    if (typeof ratings === 'string') {
      ratings = [ratings];
    }

    this.filters.push({
      type: ContentFilterType.rating,
      value: ratings
    });
    return this;
  }


  public hasVideoPreview(value = true) {
    this.filters.push({
      type: ContentFilterType.videoPreview,
      value: value
    });
    return this;
  }


  public ofContentType(contentTypes: ContentTypes | ContentTypes[] | keyof typeof ContentTypes | (keyof typeof ContentTypes)[]) {
    if (typeof contentTypes === 'string') {
      contentTypes = [contentTypes];
    }

    // Go ahead and convert our content type over to make it simpler later to do our search
    for (let i = 0; i < contentTypes.length; i++) {
      for (const key in abbreviatedContentTypeConversion) {
        if (abbreviatedContentTypeConversion[key] === contentTypes[i]) {
          contentTypes[i] = key as any;
          break;
        }
      }
    }

    this.filters.push({
      type: ContentFilterType.contentType,
      value: contentTypes
    });
    return this;
  }


  // limit: how many items we want to retrieve
  public async retrieve({
      limit = 1,
      force = false,
      contentsLimit = 10
  } = {}) {
    if (!this.cachedContents || force) {
      const result = await this.user.sendTubiAuthNetworkRequest({
        method: 'get',
        url: 'https://tensor.production-public.tubi.io/api/v3/homescreen',
        params: {
          contents_limit: contentsLimit,
          include_channels: true,
          platform: platform
        }
      });

      this.cachedContents = result.contents;
    }

    const contents = {...this.cachedContents};

    for (const filter of this.filters) {
      switch (filter.type) {
        case ContentFilterType.videoPreview:
          for(const key in contents) {
            if (!!contents[key].video_preview_url !== filter.value) {
              delete contents[key];
            }
          }
          break;
        case ContentFilterType.rating:
          for(const key in contents) {
            if (!filter.value.includes(contents[key].ratings[0].value)) {
              delete contents[key];
            }
          }
          break;
        case ContentFilterType.contentType:
          for(const key in contents) {
            if (!filter.value.includes(contents[key].type)) {
              delete contents[key];
            }
          }
          break;
      }
    }

    return Object.values(contents).slice(0, limit);
  }
}


enum ContentFilterType {
  rating,
  videoPreview,
  contentType
}


type KeyPathElement = {
  description?: string;
  elementId?: string;
  xpath?: string;
  keyPath: string;
};


type DetailPageMenuItemType = 'play' | 'playFromBeginning' | 'resume' | 'addToMyList' | 'removeFromMyList' | 'removeFromHistory' | 'episodesList';


type UserSignUpResponse = {
  access_token: string;
  birthday: string;
  email: string;
  enable_video_preview: boolean;
  enabled: boolean;
  expires_in: number;
  first_name: string;
  has_age: boolean;
  has_password: boolean;
  is_confirmed: boolean;
  last_name?: string;
  name: string;
  parental_rating: number;
  profile_pic: string;
  refresh_token: string;
  user_id: number;
  signingKey: {
    id: string;
    key: string;
    verifier: string;
  }
};


type DeeplinkPage = 'movies' | 'livefeed' | 'genre' | 'network' | 'tv' | 'espanol' | 'kids' | 'home';


type ContentRatings = 'G' | 'PG' | 'PG-13' | 'R' | 'TV-Y' | 'TV-Y7_FV' | 'TV-Y7' | 'TV-G' | 'TV-PG'| 'TV-14' | 'TV-MA' | 'NR';


type StartApplicationArgs = {
  /** If true then we will create a new user account and start the application signed in as that user. */
  shouldCreateNewUser?: boolean;

  /** If we need to set user state (watchlist/history/etc) for the application then we can pass in a User after setting that state */
  user?: User;

  /** Clears out all of the saved registry making the application behave as if someone was opening it for the first time. If not explicitly false then the registry will be cleared */
  clearRegistry?: boolean;

  language?: 'english' | 'spanish'
}


const testUtils = new TestUtils();
const auth = new Auth();


export {
  testUtils,
  User,
  RegisteredUser,
  AnonymousUser
};
