import { createHash, createHmac } from 'crypto';
import { expect } from 'chai';
import type { MediaPlayerResponse, NodeRepresentation } from 'roku-test-automation';
import { ecp, odc, utils, device, BaseType } from 'roku-test-automation';
import * as needle from 'needle';
import * as querystring from 'needle/lib/querystring';

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
    await this.getNodeForElement('contentController');
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
    body?: string}) {
    requestOptions.proxy = '127.0.0.1:8888'; // useful for debugging

    requestOptions.headers['user-agent'] = this.userAgent;

    const params = requestOptions.params;
    let url = requestOptions.url;
    if (params && Object.keys(params).length) {
      url = url.replace(/\?.*|$/, '?' + querystring.build(params));
    }

    if (requestOptions.body) {
      const response = await needle(requestOptions.method, url, requestOptions.body, requestOptions);
      return response.body;
    }

    const response = await needle(requestOptions.method, url, requestOptions);
    return response.body;
  }


  public async createTestUser() {
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
    const user = await auth.userSignup(credentials);
    return user;
  }


  // Starts the application at the specified page.
  // If asSignedInUser is true we will log them in else we will log them out
  public async startApplicationAtPage(page: DeeplinkPage, asSignedInUser = false) {
    const deeplink = {
      page: page
    };

    await this.startApplicationWithDeeplink(deeplink, asSignedInUser);
  }


  // Starts the application at the specified page.
  // If asSignedInUser is true we will log them in else we will log them out
  // deeplink: this is an object with the list of starting params sent to the application. Common fields include contentId, mediaType and page but other values may be passed as needed.
  public async startApplicationWithDeeplink(deeplink = {}, asSignedInUser = false) {
    deeplink['clearRegistry'] = true;
    if (asSignedInUser) {
      const user = await this.createTestUser();
      deeplink['setRegistry'] = JSON.stringify({
        auth: {
          refreshtoken: user.refresh_token,
          userid: `${user.user_id}`,
          expiretime: '0'
        }
      });
    }


    await this.restartApplication({
      params: deeplink
    });

    await this.waitForApplicationStartup();
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
    await testUtils.retryWithTimeOut(async () => {
      const player = await ecp.getMediaPlayer();
      expect(player.state).to.equal(state);
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


  // Used to select an item in detail page menu and verify that the action has been completed successfully
  public async selectAndVerifyDetailPageMenuItem(item: 'play' | 'resume' | 'addToMyList' | 'removeFromMyList' | 'removeFromHistory', timeout = 10000) {
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
      case 'resume':
        await this.selectMenuItem(elementName, 'Resume', timeout);
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
  private platform = 'roku';
  private applicationVersion = '2.20.19';
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
      'x-client-platform': this.platform,
      'x-client-version': this.applicationVersion,
      ...additionalHeaders
    };
  }


  private async getDeviceId() {
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
    const challenge = createHash('sha256').update(verifier).digest('base64').replace('+', '-').replace('/', '_');

    const body = JSON.stringify({
      challenge: challenge,
      device_id: await this.getDeviceId(),
      platform: this.platform,
      version: this.applicationVersion
    });

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


  public async getAnonymousToken() {
    if (this.anonymousTokenInfo) {
      return this.anonymousTokenInfo;
    }

    const signingKey = await this.getSigningKey();

    const body = JSON.stringify({
      device_id: await this.getDeviceId(),
      id: signingKey.id,
      platform: this.platform,
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
    const anonymousToken = await this.getAnonymousToken();
    const body = JSON.stringify({
      device_id: await this.getDeviceId(),
      platform: this.platform,
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

    return user as {
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
    }
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


  private appendSignatureInfo(requestOptions: Parameters<typeof this.sendSignedTubiNetworkRequest>[0]) {
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


  private constructCanonicalRequest(requestOptions: Parameters<typeof this.sendSignedTubiNetworkRequest>[0]) {
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

const testUtils = new TestUtils();
const auth = new Auth();

export {
  testUtils
};

type KeyPathElement = {
  description?: string;
  elementId?: string;
  xpath?: string;
  keyPath: string;
};

type DeeplinkPage = 'movies' | 'livefeed' | 'genre' | 'network' | 'tv' | 'espanol' | 'kids' | 'home'
