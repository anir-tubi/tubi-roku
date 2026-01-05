import { createHash, createHmac, BinaryLike } from 'crypto';
import { expect } from 'chai';
import type { MediaPlayerResponse, NodeRepresentation, ComparableValueTypes } from 'roku-test-automation';
import { ecp, odc, utils } from 'roku-test-automation';
import * as needle from 'needle';
import * as querystring from 'needle/lib/querystring';

import type { ElementOrElementId, Element } from '../../automated-tests-config/elements';
import { elements } from '../../automated-tests-config/elements';


const clientVersion = '2.21.0';


const platform = 'roku';


enum ContentTypes {
  'series' = 'series',
  'movie' = 'movie',
  'linear' = 'linear',
  'category' = 'category',
  'channel' = 'channel',
  'sports_event' = 'sports_event',
  // Include short versions as well
  'c' = 'category',
  'v' = 'movie',
  's' = 'series',
  'l' = 'linear',
  'se' = 'sports_event'
}


enum SideNavMenuItems {
  'profile' = 'profile',
  'kidsMode' = 'kidsMode',
  'exitKids' = 'exitKids',
  'search' = 'search',
  'home' = 'home',
  'myList' = 'myList',
  'categories' = 'categories',
  'channels' = 'channels',
  'linearEPG' = 'linearEPG',
  'espanol' = 'espanol',
  'settings' = 'settings',
  'exit' = 'exit'
}


enum ScreenIds {
  'homeScreen' = 'homeScreen',
  'searchScreen' = 'searchScreen',
  'settingsScreen' = 'settingsScreen',
  'categoryDetailsScreen' = 'categoryDetailsScreen',
  'channelListScreen' = 'channelListScreen',
  'categoryListScreen' = 'categoryListScreen',
  'espanolScreen' = 'espanolScreen',
  'movieScreen' = 'movieScreen',
  'myStuffScreen' = 'myStuffScreen',
  'tvScreen' = 'tvScreen',
  'detailScreen' = 'detailScreen',
  'vodDetailScreen' = 'vodDetailScreen',
  'episodeScreen' = 'episodeScreen',
  'emailInputScreen' = 'emailInputScreen',
  'signInScreen' = 'signInScreen',
  'videoPlayerScreen' = 'videoPlayerScreen',
  'linearVideoPlayerScreen' = 'linearVideoPlayerScreen',
  'adPlayerScreen' = 'adPlayerScreen',
  'epgScreen' = 'epgScreen',
  'emailVerificationScreen' = 'emailVerificationScreen',
  'forgotPasswordProcessingScreen' = 'forgotPasswordProcessingScreen',
  'consentScreen' = 'consentScreen',
  'managePreferencesScreen' = 'managePreferencesScreen'
}


type VideoPlayerStates = '' | 'none' | 'buffering' | 'playing' | 'paused' | 'stopped' | 'finished' | 'error'


const abbreviatedContentTypeConversion = {
  c: ContentTypes.category,
  v: ContentTypes.movie,
  s: ContentTypes.series,
  channel: ContentTypes.channel,
  l: ContentTypes.linear,
  se: ContentTypes.sports_event
} as { [key: string]: ContentTypes };


class TestUtils {
  private userAgent = 'Roku/DVP-11.5 (11.5.0.4312-46)';

  public testsOutputFolder = 'out/ui-tests-output';

  /**
   * You can use this to get an element for the key the provided. Can also take an element to allow easier usage
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param baseArgs - allows you pass in additional arguments if you are passing it directly to another rta function
   */
  public getElementKeyPath<T>(elementOrElementId: ElementOrElementId, baseArgs?: T) {
    if (typeof elementOrElementId === 'string') {
      const elementId = elementOrElementId;
      // If an id was passed in then we need to get the element for it
      elementOrElementId = elements[elementId];
      if (!elementOrElementId) {
        throw new Error(`Could not find element named ${elementId}`);
      }

      elementOrElementId.id = elementId;
    }

    return {
      ...baseArgs,
      ...elementOrElementId
    };
  }



  /**
   * This gives an easy way to get a node for the given element
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getNodeForElement(elementOrElementId: ElementOrElementId, timeout = 15000) {
    const element = this.getElementKeyPath(elementOrElementId) as Element;
    let result;
    await testUtils.untilTrue(async () => {
      result = await odc.getValue(element);
      return result.found;
    }, `Could not get node for element '${element.id}'`, timeout);

    return result.value as NodeRepresentation;
  }


  /**
   * Get a node using a dynamically constructed element object with custom keyPath
   * Useful for elements with dynamic row indices or other runtime-determined paths
   * @param element - The element object with keyPath, xpath, and optional base/id
   * @param timeout - How long we will wait for this operation before considering it to have failed
   * @returns The node representation
   *
   * @example
   * // For guest user CW tile at dynamically found row index 5:
   * const rowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Continue Watching');
   * const element = {
   *   keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#FeaturedRowList.${rowIndex}.items.0.#contentSection.#title`,
   *   xpath: '//GuestUserContinueWatchingTile//Label[@name="title"]'
   * };
   * const titleNode = await testUtils.getNodeWithDynamicPath(element);
   */
  public async getNodeWithDynamicPath(element: Element, timeout = 15000) {
    let result;
    await testUtils.untilTrue(async () => {
      result = await odc.getValue(element);
      return result.found;
    }, `Could not get node for dynamic element with keyPath '${element.keyPath}'`, timeout);

    return result.value as NodeRepresentation;
  }


  /**
   * This gives an easy way to get a node field for the given element. This is more efficient than getNodeForElement if all we care about is one field. It can also be used to use the element key path as a base that you can add on to as well.
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getElementField(elementOrElementId: ElementOrElementId, field: string, timeout = 15000) {
    const element = this.getElementKeyPath(elementOrElementId) as Element;
    element.keyPath += '.' + field;
    let result;
    await testUtils.untilTrue(async () => {
      result = await odc.getValue(element);
      return result.found;
    }, `Could not get node for element '${element.id}'`, timeout);

    return result.value;
  }


  /**
   * Use this to wait for an element field to match a known value. If a simple known value isn't available you can use waitForElementFieldChange
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param toEqual - What we are expecting the value to equal
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async waitForElementFieldToEqual(elementOrElementId: ElementOrElementId, field: string, toEqual: ComparableValueTypes, timeout = 15000) {
    const element = this.getElementKeyPath(elementOrElementId) as Element;
    return await odc.onFieldChangeOnce({
      keyPath: element.keyPath + '.' + field,
      match: toEqual
    }, {
      timeout: timeout
    });
  }


  /**
   * Use this to wait for an element field to change
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async waitForElementFieldChange(elementOrElementId: ElementOrElementId, field: string, timeout = 15000) {
    const element = this.getElementKeyPath(elementOrElementId) as Element;
    return await odc.onFieldChangeOnce({
      keyPath: element.keyPath + '.' + field
    }, {
      timeout: timeout
    });
  }


  // Helper to wait until application has started up. Not necessarily fully loaded though
  public async waitForApplicationStartup() {
    await odc.onFieldChangeOnce({
      keyPath: '#ContentController.removeStartUpScreens',
      match: true
    }, { timeout: 20000 });
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
    // Check if the application is already not running
    let applicationIsRunning = false;
    try {
      applicationIsRunning = await this.isApplicationRunning();
    } catch (e) {
      // If we can't communicate with the device, assume app is not running or device is unresponsive
      // In this case, we can't exit the app, so just return
      console.warn('Could not check if application is running (device may be unresponsive):', e.message);
      return;
    }

    if (!applicationIsRunning) {
      // If so then we can just exit here
      return;
    }

    // wait for content controller to get added. This is needed in the case that the application is still launching and then the next test tries to close the application again. Without this the setValue would fail because ContentController does not exist yet.
    try {
      await this.getNodeForElement('contentControllerId');
    } catch (e) {
      // If we can't get the content controller, the app may already be shutting down or device is unresponsive
      console.warn('Could not get content controller (app may already be shutting down):', e.message);
      return;
    }

    try {
      await odc.setValue({
        base: 'scene',
        keyPath: '',
        field: 'exitApp',
        value: true
      }, { timeout: 1000 });
    } catch (e) {
      // We don't care if it does not return since this can be expected behavior since we're stopping the application
    }

    // Wait until application no longer shows as running
    try {
      await this.waitForApplicationShutdown();
    } catch (e) {
      // If we can't verify shutdown, device may be unresponsive - log but don't fail
      console.warn('Could not verify application shutdown (device may be unresponsive):', e.message);
    }
  }


  // Waits for application to shutdown but does not take any steps to make it do so
  public async waitForApplicationShutdown() {
    await this.untilTrue(async () => {
      try {
        const isApplicationRunning = await this.isApplicationRunning();
        return !isApplicationRunning;
      } catch (e) {
        // If device is unresponsive, assume app is not running
        console.warn('Could not check application status during shutdown (device may be unresponsive):', e.message);
        return true;
      }
    }, 'Active app never switched from dev');
  }


  public async isApplicationRunning() {
    const result = await ecp.getActiveApp();
    return result.app.id === 'dev';
  }


  public async sendNetworkRequest(requestOptions: needle.NeedleOptions & {
    url: string;
    method: needle.NeedleHttpVerbs;
    params?: { [key: string]: any };
    body?: any
  }) {
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
  public async startApplicationAtPage(page: DeeplinkPage | NonDeeplinkPage, args: StartApplicationArgs = {}) {
    let deeplink;
    const isNonDeeplinkPage = nonDeeplinkPages.includes(page);
    if (!isNonDeeplinkPage) {
      deeplink = {
        page: page
      };
    }

    await this.startApplicationWithDeeplink(deeplink, args);

    if (isNonDeeplinkPage) {
      await this.goToPage(page);
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

    let constantsUpdates = {};

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
      constantsUpdates = {
        'deviceInfo.locale': locale,
        'deviceInfo.language': language
      };
    }

    if (args.hideStartupModals !== undefined) {
      constantsUpdates['settings.hideStartupModals'] = args.hideStartupModals;
    }

    if (args.noAds !== undefined) {
      constantsUpdates['settings.noAds'] = args.noAds;
    }

    if (args.triggerFailSafe === 'gameDayExperience') {
      constantsUpdates['settings.enableFailSafe'] = true;
    }

    if (args.isAutoplayEnabled !== undefined) {
      constantsUpdates['deviceInfo.isAutoplayEnabled'] = args.isAutoplayEnabled;
    }

    if (args.disableSkinAds !== undefined) {
      constantsUpdates['settings.disableSkinAds'] = args.disableSkinAds;
    }

    if (constantsUpdates && Object.keys(constantsUpdates).length > 0) {
      deeplink['constantsUpdates'] = JSON.stringify(constantsUpdates);
    }

    await this.restartApplication({
      params: deeplink
    });

    await this.waitForApplicationStartup();
  }


  public async createRegisteredUser() {
    const user = new RegisteredUser();
    const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    const credentials = {
      birthday: '2000-01-01',
      email: email,
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


  public async loginAsUser(credentials: { email: string, password: string }) {
    const user = new RegisteredUser();
    await user.login(credentials);
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
  public async goToPage(page: DeeplinkPage | NonDeeplinkPage) {

    const pageTileMapping = {
      'movies': 'Movies',
      'home': 'Home',
      'search': 'Search',
      'settings': 'Settings',
      'myStuff': 'My Stuff',
      'series': 'TV Shows',
      'livefeed': 'Live TV',
      'espanol': 'Español'
    };

    const selectedPage = pageTileMapping[page];
    if (selectedPage) {
      // We don't have a deeplink for these so we access it on the side nav menu instead
      await this.selectMenuItem('sideNavMenu', selectedPage, undefined);
    } else {
      await ecp.sendInput({
        params: {
          page: page
        }
      });
    }
  }


  /**
   * This function is deprecated. Use waitForPlayerStateToEqual instead
   */
  public async expectPlayerStateToEventuallyEqual(state: MediaPlayerResponse['state'], timeout = 5000) {
    console.log('This function is deprecated. Use waitForPlayerStateToEqual instead');
    await utils.sleep(5000);
    return await testUtils.retryWithTimeOut(async () => {
      const player = await ecp.getMediaPlayer();
      expect(player.state).to.equal(state);
      return player;
    }, timeout);
  }



  /**
   * Helper to check player state eventually equals the specified state
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @param expectedState - The state we are waiting for
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async waitForPlayerStateToEqual(videoPlayerElementId: VideoPlayerElementId, expectedState: VideoPlayerStates | VideoPlayerStates[], timeout = 15000) {
    // check if expectedState is a string and convert to array
    const expectedStates: VideoPlayerStates[] = typeof expectedState === 'string' ? [expectedState] : expectedState;

    const element = this.getElementKeyPath(videoPlayerElementId);
    return await testUtils.retryWithTimeOut(async () => {
      const state = await this.getElementField(videoPlayerElementId, 'state', timeout);
      expect(state).to.be.oneOf(expectedStates);
    }, timeout);
  }


  /**
   * Helper to wait for the position of the specified video player to be within before continuing
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @param position - The position in milliseconds that we want to wait for the player to be within before continuing
   * @param precision - How close in milliseconds the current player position has to be to `position` in order to be considered valid
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async waitForPlayerPositionToEqual(videoPlayerElementId: VideoPlayerElementId, position: number, precision = 10000, timeout = 15000) {
    return await testUtils.retryWithTimeOut(async () => {
      const actualPlayerPosition = await testUtils.getPlayerPosition(videoPlayerElementId);
      expect(actualPlayerPosition).to.be.greaterThanOrEqual(position - precision).and.lessThanOrEqual(position + precision);
    }, timeout);
  }


  /**
   * Helper to get the current position of the video player. If videoPlayerElementId is supplied we pull the position for that specific element vs using the ECP query/media-player endpoint
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @returns current position in milliseconds
   */
  public async getPlayerPosition(videoPlayerElementId?: VideoPlayerElementId) {
    if (videoPlayerElementId) {
      const element = this.getElementKeyPath(videoPlayerElementId);
      const { value } = await odc.getValue({
        keyPath: `${element.keyPath}.#VideoNode.position`
      });
      // position is in seconds but we want to convert to milliseconds to match ECP units
      return value * 1000;
    } else {
      const player = await ecp.getMediaPlayer();
      return player.position.number;
    }
  }


  /**
   * Gets the duration of the current content for the specified video player element
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @returns content duration in milliseconds
   */
  public async getPlayerDuration(videoPlayerElementId: VideoPlayerElementId) {
    const element = this.getElementKeyPath(videoPlayerElementId);
    const { value } = await odc.getValue({
      keyPath: `${element.keyPath}.#VideoNode.duration`
    });
    return value * 1000;
  }


  /**
   * Helper to get the current content for the specified player
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getPlayerContent(videoPlayerElementId: VideoPlayerElementId, timeout = 10000) {
    return await this.getElementField(videoPlayerElementId, 'content', timeout) as NodeRepresentation & {
      ACTORS: string[];
      CATEGORIES: string[];
      DESCRIPTION: string;
      DIRECTORS: string[];
      LENGTH: string;
      RATING: string;
      TITLE: string;
      URL: string;
      availabilityEnds: string;
      codec: string;
      country: string;
      creditCuePoints: { [key: string]: number };
      cuepoints: number[];
      drmType: string;
      genres: string[];
      language: string;
      needsLogin: string;
      releaseDate: string;
    };
  }


  /**
   * Seeks the specified video player to the absolute position specified and checks to make sure it was set correctly
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @param absolutePosition - the absolute position where we want to seek to in milliseconds
   * @param precision - How close in milliseconds the current player position has to be to `position` in order to be considered valid
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async seekPlayerToAbsolutePosition(videoPlayerElementId: VideoPlayerElementId, absolutePosition: number, precision = 10000, timeout = 10000) {
    const element = this.getElementKeyPath(videoPlayerElementId);
    // Improvement we might eventually want to investigate using seekMode=accurate to allow for tighter tolerances
    await odc.setValue({
      keyPath: `${element.keyPath}.seekTo`,
      value: [absolutePosition / 1000]
    });
    await this.waitForPlayerPositionToEqual(videoPlayerElementId, absolutePosition, precision, timeout);
  }


  /**
   * Seeks the specified video player to the relative position specified and checks to make sure it was set correctly
   * @param videoPlayerElementId - Element id for the video player node we want to use for this helper
   * @param relativePosition - the relative position where we want to seek to in milliseconds
   * @param relativeTo - What `relativePosition` is relative to. Currently either from the end of the content based off its duration or from the current video player position
   * @param precision - How close in milliseconds the current player position has to be to `position` in order to be considered valid
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async seekPlayerToRelativePosition(videoPlayerElementId: VideoPlayerElementId, relativePosition: number, relativeTo: 'end' | 'current', precision = 10000, timeout = 10000) {
    let absolutePosition: number;
    if (relativeTo === 'current') {
      absolutePosition = await this.getPlayerPosition(videoPlayerElementId) + relativePosition;
    } else if (relativeTo === 'end') {
      absolutePosition = await this.getPlayerDuration(videoPlayerElementId) + relativePosition;
    }

    await this.seekPlayerToAbsolutePosition(videoPlayerElementId, absolutePosition, precision, timeout);
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
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param title - The title we are searching for
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async findRowIndexWithTitle(elementOrElementId: ElementOrElementId, title: string, timeout = 10000): Promise<number> {
    const element = this.getElementKeyPath(elementOrElementId);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    return await this.retryWithTimeOut(async () => {
      // First count how many rows of content there are
      const { found, value: rowCount } = await odc.getValue({
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

      const { results } = await odc.getValues({
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

  /**
   * Because we store the json object at the row level, trying to access RowList content the normal way with RTA can result in huge responses (21 MB). This helps work around that
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param slug - The slug we are searching for
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async findRowIndexWithSlug(elementOrElementId: ElementOrElementId, slug: string, timeout = 10000): Promise<number> {
    const element = this.getElementKeyPath(elementOrElementId);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    return await this.retryWithTimeOut(async () => {
      // First count how many rows of content there are
      const { found, value: rowCount } = await odc.getValue({
        base: element.base,
        keyPath: `${baseKeyPath}.getChildCount()`
      });
      if (!found) {
        throw new Error(`Can't find row count`);
      }

      // Now request each row's slug
      const requests = {};
      for (let i = 0; i < rowCount; i++) {
        requests[i] = {
          base: element.base,
          keyPath: `${baseKeyPath}.${i}.slug`
        };
      }

      const { results } = await odc.getValues({
        requests: requests
      });

      // Once we find the row that matches the slug return the index for it
      for (const key in results) {
        if (results[key].value === slug) {
          return +key;
        }
      }
      throw new Error(`Could not find row with slug ${slug}`);
    }, timeout);
  }


  /**
   * Used to jump to a row with the title provided
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param title - The title we are searching for
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async jumpToRowWithTitle(elementOrElementId: ElementOrElementId, title: string, timeout = 10000) {
    const rowIndex = await this.findRowIndexWithTitle(elementOrElementId, title, timeout);
    await this.jumpToRowIndex(elementOrElementId, rowIndex, timeout);
    return rowIndex;
  }


  /**
   * Used to find the index of a grid/list item by its title
   * Works for both MarkupGrid and MarkupList components
   * @param elementOrElementId - The grid/list element or element id from elements.ts
   * @param title - The title we are searching for
   * @param timeout - How long we will wait before considering it failed
   */
  public async findGridItemIndexWithTitle(elementOrElementId: ElementOrElementId, title: string, timeout = 10000): Promise<number> {
    return await this.retryWithTimeOut(async () => {
      // Grid and list items can be retrieved using the same method
      const items = await this.getAllGridItemsContent(elementOrElementId, timeout);

      // Find the index where title matches
      for (let i = 0; i < items.length; i++) {
        if (items[i].title === title) {
          return i;
        }
      }
      throw new Error(`Could not find grid/list item with title "${title}"`);
    }, timeout);
  }


  /**
   * Used to jump to a grid/list item with the title provided
   * Works for both MarkupGrid and MarkupList components
   * @param elementOrElementId - The grid/list element or element id from elements.ts
   * @param title - The title we are searching for
   * @param timeout - How long we will wait before considering it failed
   */
  public async jumpToGridItemWithTitle(elementOrElementId: ElementOrElementId, title: string, timeout = 10000) {
    const itemIndex = await this.findGridItemIndexWithTitle(elementOrElementId, title, timeout);
    const element = this.getElementKeyPath(elementOrElementId);

    // Use jumpToItem to navigate to the found index
    await odc.setValue({
      base: element.base,
      keyPath: element.keyPath ? `${element.keyPath}.jumpToItem` : 'jumpToItem',
      value: itemIndex
    }, { timeout: timeout });

    return itemIndex;
  }


  /**
   * Used to jump to a row with the rowIndex provided
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param rowIndex - The row index we want to jump to
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async jumpToRowIndex(elementOrElementId: ElementOrElementId, rowIndex: number, timeout = 10000) {
    await odc.setValue(this.getElementKeyPath(elementOrElementId, {
      field: 'jumpToItem',
      value: rowIndex
    }), { timeout: timeout });
  }


  /**
   * Used to jump to a row item of the provided index
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param index - The index we want to jump to consisting of row in index 0 and item in index 1
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async jumpToRowItem(elementOrElementId: ElementOrElementId, index: number[], timeout = 10000) {
    await odc.setValue(this.getElementKeyPath(elementOrElementId, {
      field: 'jumpToRowItem',
      value: index
    }), { timeout: timeout });
  }


  /**
   * Used to retrieve all content in row specified by `rowIndex` from the specified RowList element
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param rowIndex - The row index we want to get the content for
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getRowListRowItemsContent(elementOrElementId: ElementOrElementId, rowIndex: number, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);

    const baseKeyPath = `${element.keyPath}.content.${rowIndex}`;

    const node = await testUtils.retryWithTimeOut(async () => {
      const { value, found } = await odc.getValue({
        keyPath: baseKeyPath,
        responseMaxChildDepth: 1
      });

      if (!found) {
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
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getCurrentlyFocusedRowListRowItemsContent(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const grid = await this.getNodeForElement(elementOrElementId, timeout);
    if (!grid.rowItemFocused) {
      throw new Error('This function should only be used on RowList elements');
    }

    const index = grid.rowItemFocused[0];
    return await this.getRowListRowItemsContent(elementOrElementId, index, timeout);
  }


  /**
   * Used to retrieve all content in the specified RowList element
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getAllRowListItemsContent(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const rowsContent = await this.getAllRowListItemsContentGroupedByRow(elementOrElementId, timeout);
    return rowsContent.flat();
  }


  /**
   * Used to retrieve all content in the specified RowList element grouped by row. This is useful for when you want to know which row each item came from
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getAllRowListItemsContentGroupedByRow(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    const rowCount = await this.retryWithTimeOut(async () => {
      const { found, value: rowCount } = await odc.getValue({
        keyPath: `${baseKeyPath}.getChildCount()`
      });
      if (!found) {
        throw new Error(`Can't find row count`);
      }
      return rowCount;
    }, timeout);

    const rowsContent = [];
    for (let rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      const rowItemsContent = await this.getRowListRowItemsContent(elementOrElementId, rowIndex, timeout);
      rowsContent.push(rowItemsContent);
    }
    return rowsContent;
  }


  /**
   * Used to retrieve all content in the specified grid element. getAllRowListItemsContent should be used instead if this is a RowList
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   * @returns array of NodeRepresentation with each item representing its respective position in the grid contents
   */
  public getAllGridItemsContent(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    return this.retryWithTimeOut(async () => {
      const { found, value } = await odc.getValue({
        base: element.base,
        keyPath: `${element.keyPath}.content`,
        responseMaxChildDepth: 1
      }, { timeout: timeout });

      if (!found) {
        throw new Error(`Can't retrieve grid content`);
      }
      return value.children as NodeRepresentation[];
    }, timeout);
  }


  /**
   * Used to help wait until content loads on a grid before trying to interact with it
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async waitForGridContentToLoad(elementOrElementId: ElementOrElementId, timeout = 15000) {
    const element = this.getElementKeyPath(elementOrElementId);
    element.keyPath += '.content';

    // TODO update when we either get multiple observer callback support or more advanced types
    await this.untilTrue(async () => {
      const { value } = await odc.getValue(element, { timeout: timeout });
      return !!value;
    });
  }


  /**
   * Used to retrieve grid item content for the item specified by the index
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param index - array or number of which item we are getting the content for. For RowLists this should a 2 item array and for Grids a single item array or number
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getGridItemContent(elementOrElementId: ElementOrElementId, index: number | number[], timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
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
        const { results } = await odc.getValues(requests);

        if (!results.itemContent.found) {
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
        const { value, found } = await odc.getValue({
          keyPath: baseKeyPath
        });

        if (!found) {
          throw new Error(`Could not retrieve item content for index ${arrayIndex[0]}`);
        }

        return value;
      }, timeout);
    }
  }


  /**
   * Used to get the index for the currently focused item in the grid
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   * @returns index of the currently focused grid item. For RowLists this will be a 2 item array and for Grids a number
   */
  public async getCurrentlyFocusedGridItemIndex(elementOrElementId: ElementOrElementId, timeout = 10000) {
    return await this.retryWithTimeOut(async () => {
      const grid = await this.getNodeForElement(elementOrElementId, timeout);
      if (grid.rowItemFocused?.length === 2) {
        return grid.rowItemFocused as number[];
      } else if (grid.itemFocused !== -1) {
        return grid.itemFocused as number;
      } else {
        throw new Error('Could not find focused grid item index');
      }
    }, timeout);
  }


  /**
   * Used to get the grid item content for the currently focused grid item
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getCurrentlyFocusedGridItemContent(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const index = await this.getCurrentlyFocusedGridItemIndex(elementOrElementId, timeout);
    return await this.getGridItemContent(elementOrElementId, index, timeout);
  }


  /**
   * Used to get the index of the grid item that matches the callback function provided
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param callbackFn - The function that will be used to determine if the grid item matches the criteria we are looking for
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getMatchingGridItemIndex(elementOrElementId: ElementOrElementId, callbackFn: (gridItemContent: any) => boolean, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);

    // First figure out if it is a grid or RowList
    const isRowList = await odc.isSubtype({
      ...element,
      subtype: 'RowList'
    });

    if (isRowList) {
      const content = await this.getAllRowListItemsContentGroupedByRow(element, timeout);
      for (const [rowIndex, rowContent] of content.entries()) {
        for (const [itemIndex, gridItemContent] of rowContent.entries()) {
          if (callbackFn(gridItemContent)) {
            return [rowIndex, itemIndex] as number[];
          }
        }
      }
    } else {
      const content = await this.getAllGridItemsContent(element, timeout);
      for (const [itemIndex, gridItemContent] of content.entries()) {
        if (callbackFn(gridItemContent)) {
          return [itemIndex];
        }
      }
    }

    throw new Error('Could not find matching grid item');
  }


  /**
     * Used to navigate to the grid item that matches the callback function provided
     * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
     * @param callbackFn - The function that will be used to determine if the grid item matches the criteria we are looking for
     * @param timeout - How long we will wait for this operation before considering it to have failed
     */
  public async navigateToGridItem(elementOrElementId: ElementOrElementId, callbackFn: (gridItemContent: any) => boolean, timeout = 10000) {
    const index = await this.getMatchingGridItemIndex(elementOrElementId, callbackFn, timeout);
    if (index.length === 1) {
      await this.jumpToRowIndex(elementOrElementId, index[0], timeout);
    } else {
      await this.jumpToRowItem(elementOrElementId, index, timeout);
    }
    return index;
  }


  // Used to select an item in detail page menu and verify that the action has been completed successfully
  public async selectAndVerifyDetailPageMenuItem(item: DetailPageMenuItemType, timeout = 10000) {
    // If a network request is still happening then we need to wait for it to complete before proceeding
    const args = this.getElementKeyPath('detailScreen');
    args.keyPath += '.isWaitingForServerResponse';
    args['match'] = false;
    await odc.onFieldChangeOnce(args);


    const element = elements.detailScreenMenu;
    await this.waitForElementToHaveFocus(element);
    switch (item) {
      case 'play':
        await this.selectMenuItem(element, 'Play', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'playFromBeginning':
        await this.selectMenuItem(element, 'Play from Beginning', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'watchTrailer':
        await this.selectMenuItem(element, 'Watch Trailer', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'resume':
        await this.selectMenuItem(element, 'Resume Playing', timeout);
        await this.waitForElementToNotBeInFocusChain('detailScreen');
        break;
      case 'addToMyList':
        await this.selectMenuItem(element, 'Add to My List', timeout);
        // We know we're good once the remove item shows up
        await this.findRowIndexWithTitle(element, 'Remove From My List', timeout);
        break;
      case 'likeOrDislike':
        await this.selectMenuItem(element, 'Like or Dislike', timeout);
        await this.waitForElementToFullyShowOnScreen('secondaryMenu');
        break;
      case 'removeFromMyList':
        await this.selectMenuItem(element, 'Remove From My List', timeout);
        // We know we're good once the add item shows up
        await this.findRowIndexWithTitle(element, 'Add to My List', timeout);
        break;
      case 'removeFromHistory':
        await this.selectMenuItem(element, 'Remove from history', timeout);
        // We know we're good once the Resume item goes away
        await this.untilTrue(async () => {
          try {
            await this.findRowIndexWithTitle(element, 'Remove from history', 0);
            return false;
          } catch (e) {
            return true;
          }
        }, 'Could not verify that Remove from history was removed');
        break;
      case 'episodesList':
        await this.selectMenuItem(element, 'All Episodes', timeout);
        await this.waitForElementToBeInFocusChain('episodesScreen');
        break;
      case 'signUp':
        const observerPromise = odc.onFieldChangeOnce({
          base: 'global',
          'keyPath': 'trackingLoggingTask.trackEvent',
          'match': {
            base: 'global',
            keyPath: 'trackingLoggingTask.trackEvent.values.dialog_sub_type',
            value: 'email-prefill'
          }
        });

        await this.selectMenuItem(element, 'Sign Up to Save Progress', timeout);

        // Currently no way to verify the RFI prompt actually opens up since Roku doesn't expose that ability so the closest we can do is verify that the analytics call was made
        const { value } = await observerPromise;
        expect(value.type).to.equal('dialog');
        expect(value.values.dialog_type).to.equal('REGISTRATION');
        expect(value.values.dialog_action).to.equal('SHOW');
        break;
    }
  }


  /**
   * Used to select the item in the provided elementOrElementId that matches title provided.
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param title - Title of the menu item we want to select
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async selectMenuItem(elementOrElementId: ElementOrElementId, title: string, timeout = 10000) {
    const index = await this.jumpToRowWithTitle(elementOrElementId, title, timeout);

    await odc.setValue(this.getElementKeyPath(elementOrElementId, {
      field: 'itemSelected',
      value: index
    }), { timeout: timeout });
  }


  /**
   * Verifies that `expectedItem` equals the focused item for the side nav menu
   * @param expectedItem - the item we are expecting it equal
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async verifyFocusedSideNavMenuItemEquals(expectedItem: SideNavMenuItems | keyof typeof SideNavMenuItems, timeout = 10000) {
    const mainMenuElement = this.getElementKeyPath('sideNavMenu');
    const requestOptions = { timeout: timeout };
    const { value: currFocusRow } = await odc.getValue({
      keyPath: `${mainMenuElement.keyPath}.currFocusRow`
    }, requestOptions);

    const { value } = await odc.getValue({
      keyPath: `${mainMenuElement.keyPath}.content.${currFocusRow}.id`
    }, requestOptions);

    const itemId = value.replace('-select', '');
    if (expectedItem !== itemId) {
      throw new Error(`Current side nav menu item was expected to be ${expectedItem} but was actually ${itemId}`);
    }
  }


  /**
 * Wrapper around waitForFocusedMainMenuItemToEqual that will wait for the value to match or fail
 * @param expectedItem - the item we are expecting it equal
 * @param timeout - How long we will wait for this operation before considering it to have failed
 */
  public waitForFocusedSideNavMenuItemToEqual(expectedItem: SideNavMenuItems | keyof typeof SideNavMenuItems, timeout = 10000) {
    return this.retryWithTimeOut(async () => {
      await this.verifyFocusedSideNavMenuItemEquals(expectedItem);
    }, timeout);
  }


  /**
   * Checks if element isInFocusChain
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param failIfNot - If not undefined then the result of this function will be checked and fail if not equal to the value specified
   * @param timeout - How long we will wait for this operation before considering it to have failed
   * @returns true if this element or one of its children has focus or false otherwise
   */
  public async elementIsInFocusChain(elementOrElementId: ElementOrElementId, failIfNot?: boolean, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    const result = await odc.isInFocusChain(element, { timeout: timeout });
    if (failIfNot !== undefined) {
      if (failIfNot !== result) {
        throw new Error(`'${element.id}'isInFocusChain equaled ${result} when ${failIfNot} was expected`);
      }
    }
    return result;
  }


  /**
   * Checks if element has focus
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param failIfNot - If not undefined then the result of this function will be checked and fail if not equal to the value specified
   * @param timeout - How long we will wait for this operation before considering it to have failed
   * @returns true if this element has focus or false otherwise
   */
  public async elementHasFocus(elementOrElementId: ElementOrElementId, failIfNot?: boolean, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    const result = await odc.hasFocus(element, { timeout: timeout });
    if (failIfNot !== undefined) {
      if (failIfNot !== result) {
        throw new Error(`'${element.id}' hasFocus equaled ${result} when ${failIfNot} was expected`);
      }
    }
    return result;
  }


  /**
   * Waits for element to have focus within timeout period
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param failIfNot - If not undefined then the result of this function will be checked and fail if not equal to the value specified
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async waitForElementToHaveFocus(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    if (errorMessage === undefined) {
      errorMessage = `${elementOrElementId} failed to have focus in ${timeout}ms`;
    }
    await this.untilTrue(async () => {
      try {
        return await this.elementHasFocus(elementOrElementId);
      } catch (e) {
        return false;
      }
    }, errorMessage, timeout);
  }


  /**
  * Waits for element to not have focus within timeout period
  * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
  * @param errorMessage - A custom string to use for the error message
  * @param timeout - How long we will wait for this operation before considering it to have failed
  */
  public async waitForElementToNotHaveFocus(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    if (errorMessage === undefined) {
      errorMessage = `${elementOrElementId} failed to not have focus in ${timeout}ms`;
    }
    await this.untilTrue(async () => {
      try {
        const result = await this.elementHasFocus(elementOrElementId);
        return !result;
      } catch (e) {
        return false;
      }
    }, errorMessage, timeout);
  }


  /**
  * Waits for element to be in the focus chain within timeout period
  * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
  * @param errorMessage - A custom string to use for the error message
  * @param timeout - How long we will wait for this operation before considering it to have failed
  */
  public async waitForElementToBeInFocusChain(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    if (errorMessage === undefined) {
      errorMessage = `${elementOrElementId} failed to be in focus chain in ${timeout}ms`;
    }
    await this.untilTrue(async () => {
      try {
        return await this.elementIsInFocusChain(elementOrElementId);
      } catch (e) {
        return false;
      }
    }, errorMessage, timeout);
  }


  /**
  * Waits for element to not be in the focus chain within timeout period
  * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
  * @param errorMessage - A custom string to use for the error message
  * @param timeout - How long we will wait for this operation before considering it to have failed
  */
  public async waitForElementToNotBeInFocusChain(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    if (errorMessage === undefined) {
      errorMessage = `${elementOrElementId} failed to not be in focus chain in ${timeout}ms`;
    }
    await this.untilTrue(async () => {
      try {
        const result = await this.elementIsInFocusChain(elementOrElementId);
        return !result;
      } catch (e) {
        return false;
      }
    }, errorMessage, timeout);
  }


  /**
   * Allows knowing if an element is showing on screen (viewable by a user) as well as whether it is fully showing
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async isElementShowingOnScreen(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    try {
      return await odc.isShowingOnScreen(element, { timeout: timeout });
    } catch (e) {
      return {
        isShowing: false,
        isFullyShowing: false
      };
    }
  }


  /**
  * Waits for element to be at least partially showing on the screen (viewable by a user)
  * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
  * @param errorMessage - A custom string to use for the error message
  * @param timeout - How long we will wait for this operation before considering it to have failed
  */
  public async waitForElementToShowOnScreen(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    await this.untilTrue(async () => {
      const result = await this.isElementShowingOnScreen(elementOrElementId);
      return result.isShowing;
    }, errorMessage, timeout);
  }


  /**
  * Waits for element to be fully showing on the screen (viewable by a user)
  * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
  * @param errorMessage - A custom string to use for the error message
  * @param timeout - How long we will wait for this operation before considering it to have failed
  */
  public async waitForElementToFullyShowOnScreen(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    await this.untilTrue(async () => {
      const result = await this.isElementShowingOnScreen(elementOrElementId);
      return result.isFullyShowing;
    }, errorMessage, timeout);
  }


  /**
  * Waits for element to not be showing on the screen (viewable by a user)
  * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
  * @param errorMessage - A custom string to use for the error message
  * @param timeout - How long we will wait for this operation before considering it to have failed
  */
  public async waitForElementToNotShowOnScreen(elementOrElementId: ElementOrElementId, errorMessage?: string, timeout = 10000) {
    await this.untilTrue(async () => {
      const result = await this.isElementShowingOnScreen(elementOrElementId);
      return !result.isShowing;
    }, errorMessage, timeout);
  }


  /**
   * Allows getting the dimensions of a regular node. Use getGridElementSize for grid children items
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getElementSize(elementOrElementId: ElementOrElementId, timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    const { found, value } = await odc.getValue({
      keyPath: element.keyPath + '.sceneBoundingRect()'
    }, { timeout: timeout });

    if (!found) {
      throw new Error(`Could not retrieve size for element '${element.id}'`);
    }

    return value as {
      width: number;
      height: number;
      x: number;
      y: number;
    };
  }


  /**
 * Allows getting the dimensions of a grid item node
 * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file. This should be for the grid or RowList not the grid element itself
 * @param index - array or number of which item we are getting the size of. For RowLists this should a 2 item array and for Grids a single item array or number
 * @param timeout - How long we will wait for this operation before considering it to have failed
 */
  public async getGridElementSize(elementOrElementId: ElementOrElementId, index: number | number[], timeout = 10000) {
    if (!Array.isArray(index)) {
      index = [index];
    }

    const element = this.getElementKeyPath(elementOrElementId);
    let item = `item${index[0]}`;
    if (index.length > 1) {
      item += `_${index[1]}`;
    }
    const { found, value } = await odc.getValue({
      keyPath: element.keyPath + `.sceneSubBoundingRect(${item})`
    }, { timeout: timeout });

    if (!found) {
      throw new Error(`Could not retrieve size for element '${element.id}'`);
    }

    return value as {
      width: number;
      height: number;
      x: number;
      y: number;
    };
  }


  /**
   * Simple helper to wait for the side nav menu to be expanded
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public waitForSideNavMenuToBeExpanded(timeout = 10000) {
    return this.waitForElementToHaveFocus('sideNavMenu', `Side nav menu was not expanded within ${timeout}ms`, timeout);
  }


  /**
   * Simple helper to wait for the side nav menu to not be expanded
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public waitForSideNavMenuToNotBeExpanded(timeout = 10000) {
    return this.waitForElementToNotHaveFocus('sideNavMenu', `Side nav menu was still expanded after ${timeout}ms`, timeout);
  }


  private async getCurrentScreen(timeout = 10000) {
    const lastScreen = await this.getElementField('screenStack', '-1', timeout);
    return lastScreen as NodeRepresentation;
  }


  public async waitForCurrentScreenToEqual(screenId: ScreenIds | keyof typeof ScreenIds, timeout = 10000) {
    await this.untilTrue(async () => {
      const screen = await this.getCurrentScreen(timeout);
      return screen.id === screenId;
    }, `Screen did not equal '${screenId}' after ${timeout}ms`, timeout);
  }


  /**
   * Roku stores colors as integers which are difficult to work with. This helper returns a more usable hex version
   * @param elementOrElementId - The element or element id that we want to use for this function that is stored in the elements.ts file
   * @param colorFieldName - The field on the node that we are interested in converting from an integer to a hex representation
   * @param timeout - How long we will wait for this operation before considering it to have failed
   */
  public async getElementColorField(elementOrElementId: ElementOrElementId, colorFieldName = 'color', timeout = 10000) {
    const element = this.getElementKeyPath(elementOrElementId);
    const { value, found } = await odc.getValue({
      keyPath: `${element.keyPath}.${colorFieldName}`
    }, { timeout: timeout });

    if (!found || typeof value !== 'number') {
      throw new Error(`Could not retrieve valid color for element '${element.id}' with color field '${colorFieldName}'`);
    }

    // Have to convert from signed to unsigned and then convert to binary representation
    const unsignedInteger = value >>> 0;
    const binary = unsignedInteger.toString(2).padStart(32, '0');

    // Slice out each 8 bits for each rgba part value
    const rgb = {
      red: parseInt(binary.slice(0, 8), 2),
      green: parseInt(binary.slice(8, 16), 2),
      blue: parseInt(binary.slice(16, 24), 2),
      alpha: parseInt(binary.slice(24, 32), 2)
    };

    return `#${this.convertByteToHex(rgb.red)}${this.convertByteToHex(rgb.green)}${this.convertByteToHex(rgb.blue)}${this.convertByteToHex(rgb.alpha)}`;
  }


  private convertByteToHex(byte: number) {
    return byte.toString(16).padStart(2, '0').toUpperCase();
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
      if (await func()) {
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
  public baseAccountUrl = 'https://account.production-public.tubi.io';
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

    const { values } = await odc.readRegistry({
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


  // Creates device id similar to what Roku's looks like
  public generateDeviceId() {
    // Outputs string like 1d27bcd5-037e-56b3-bec0-f7c20f0edbdd
    return `${this.generateDeviceIdPart(8)}-${this.generateDeviceIdPart(4)}-${this.generateDeviceIdPart(4)}-${this.generateDeviceIdPart(4)}-${this.generateDeviceIdPart(12)}`;
  }


  private generateDeviceIdPart(length: number) {
    let result = '';
    for (let i = 0; i < length; i++) {
      result += Math.floor(Math.random() * 16).toString(16);
    }
    return result;
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
      authorization: `Bearer ${anonymousToken.access_token}`
    });



    let retriesLeft = 3;
    while (retriesLeft > 0) {
      try {
        const user = await testUtils.sendNetworkRequest({
          method: 'post',
          url: this.baseAccountUrl + '/user/signup',
          headers: headers,
          body: body
        });

        user.signingKey = anonymousToken.signingKey;
        return user as UserInfoResponse;
      } catch (e) {
        retriesLeft--;
        if (retriesLeft > 0 && e.message.includes('429')) {
          console.log('Failed to sign up user Due to 429 error. Retrying after 60 second delay');
          await utils.sleep(60000);
        } else {
          throw e;
        }
      }
    }
  }


  public async userLogin(credentials: {
    email: string;
    password: string;
  }) {
    const anonymousToken = await this.getAnonymousToken(true);
    const body = JSON.stringify({
      device_id: await this.getDeviceId(),
      platform: platform,
      type: 'email',
      credentials: credentials
    });

    const headers = this.getHeaders({
      authorization: 'Bearer ' + anonymousToken.access_token
    });

    const user = await testUtils.sendNetworkRequest({
      method: 'post',
      url: this.baseAccountUrl + '/user/login',
      headers: headers,
      body: body
    });
    user.signingKey = anonymousToken.signingKey;

    return user as UserInfoResponse;
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

    const secret1 = Buffer.concat([Buffer.from('TUBI', 'utf-8') as any, Buffer.from(secretKey, 'base64') as any]) as BinaryLike;
    const secret2 = this.hmac(date, secret1) as BinaryLike;
    const secret3 = this.hmac('tubi_request', secret2) as BinaryLike;
    const signature = this.hmac(stringToSign, secret3);
    return signature;
  }


  private appendSignatureInfo(requestOptions: Parameters<typeof this.sendSignedTubiNetworkRequest>[0] & {
    body: string;
  }) {
    const canonicalRequest = this.constructCanonicalRequest(requestOptions);
    const hashedCanonicalRequest = createHash('sha256').update(canonicalRequest).digest('hex');

    const dateTime = new Date().toISOString().split('.').shift() + 'Z';
    const dateTimeFormatted = dateTime.replace(/-/g, '').replace(/:/g, '');

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
    const headers = { ...requestOptions.headers };

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


  private hmac(contents: BinaryLike, secret: BinaryLike): Buffer {
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


  public async getDeviceSettings() {
    return await this.sendTubiAuthNetworkRequest({
      method: 'get',
      url: auth.baseAccountUrl + '/device/settings',
    }) as DeviceSettings;
  }


  public async updateDeviceSettings(deviceSettings: Partial<DeviceSettings>) {
    return await this.sendTubiAuthNetworkRequest({
      method: 'patch',
      url: auth.baseAccountUrl + '/device/settings',
      body: deviceSettings
    }) as DeviceSettings;
  }


  public getContent() {
    return new FilterContent(this);
  }


  protected convertAbbreviatedContentType(inputContentType) {
    // First check if the content type has already been resolved
    if (Object.values(abbreviatedContentTypeConversion).includes(inputContentType)) {
      return inputContentType;
    }

    return abbreviatedContentTypeConversion[inputContentType];
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
  private userInfo: UserInfoResponse;


  public async create(credentials) {
    this.userInfo = await auth.userSignup(credentials);
    this.userInfo.password = credentials.password;
    this.accessToken = this.userInfo.access_token;
  }


  public async changeParentalRating(parentalRating: ParentalRating) {
    await this.sendTubiAuthNetworkRequest({
      method: 'put',
      url: auth.baseAccountUrl + '/user/settings/parental_rating',
      body: {
        parental_rating: parentalRating,
        password: this.userInfo.password
      }
    });
  }


  public async enableVideoPreview(enabled: boolean) {
    return await this.updateUserSettings({
      enable_video_preview: enabled
    });
  }


  public async updateUserSettings(userSettings: Partial<UserInfoResponse>) {
    await this.sendTubiAuthNetworkRequest({
      method: 'patch',
      url: auth.baseAccountUrl + '/user/settings',
      body: userSettings
    });
  }


  public async getUserSettings() {
    return await this.sendTubiAuthNetworkRequest({
      method: 'get',
      url: auth.baseAccountUrl + '/user/settings',
    }) as UserInfoResponse;
  }


  public async login(credentials: { email: string, password: string }) {
    this.userInfo = await auth.userLogin(credentials);
    this.userInfo.password = credentials.password;
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
  public async addContentToWatchList(contents: { type: keyof typeof ContentTypes; id: string }[] | { type: keyof typeof ContentTypes; id: string }) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    const promises = [];
    for (const content of contents) {
      const contentType = this.convertAbbreviatedContentType(content.type);
      let contentId = content.id;
      if (contentType == ContentTypes.series) {
        // Have to add leading zero for series
        contentId = `0${contentId}`;
      } else if (contentType !== ContentTypes.movie && contentType !== ContentTypes.sports_event) {
        console.warn(`Tried to add unsupported type '${contentType}' to watchlist. Skipping...`);
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
    const { queues } = await this.sendTubiAuthNetworkRequest({
      method: 'get',
      url: 'https://user-queue.production-public.tubi.io/api/v2/queues'
    });
    return queues as {
      content_id: number;
      content_type: ContentTypes;
    }[];
  }


  // contents: array of contents as returned by a call to getContents()
  public async removeContentFromWatchList(contents: { type: keyof typeof ContentTypes; id: string }[] | { type: keyof typeof ContentTypes; id: string }) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    const promises = [];
    for (const content of contents) {
      const body = {
        content_id: content.id,
        content_type: this.convertAbbreviatedContentType(content.type)
      };

      const promise = this.sendTubiAuthNetworkRequest({
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
  public async addContentToViewHistory(contents: { type: keyof typeof ContentTypes; id: string }[] | { type: keyof typeof ContentTypes; id: string }, positions: number | number[]) {
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
      const contentType = this.convertAbbreviatedContentType(content.type);
      const contentId = content.id;
      if (contentType !== ContentTypes.movie && contentType !== ContentTypes.series && contentType !== ContentTypes.sports_event) {
        console.warn('Tried to add unsupported type to view history. Skipping...');
        continue;
      }
      // Using slice instead of at(-1) since at was introduced in ES2022.
      const body = {
        content_id: contentId,
        content_type: contentType as string,
        parent_id: null,
        position: positions[index] ?? positions.slice(-1)[0]
      };

      let promise;
      // For series we have to do an additional call to get the episodes for this series since the episodes are what have the progress
      if (contentType === ContentTypes.series) {
        // Using anonymous function here to allow running multiple requests in parallel
        promise = (async () => {
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
            return;
          }

          await this.sendTubiAuthNetworkRequest({
            method: 'post',
            url: 'https://lishi.production-public.tubi.io/api/v2/view_history',
            body: body
          });
        })();
      } else {
        promise = this.sendTubiAuthNetworkRequest({
          method: 'post',
          url: 'https://lishi.production-public.tubi.io/api/v2/view_history',
          body: body
        });
      }
      promises.push(promise);
    }

    return await Promise.all(promises);
  }


  public async getViewHistoryContent() {
    const { items } = await this.sendTubiAuthNetworkRequest({
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
  public async removeContentFromViewHistory(contents: { type: keyof typeof ContentTypes; id: string }[] | { type: keyof typeof ContentTypes; id: string }) {
    if (!Array.isArray(contents)) {
      contents = [contents];
    }

    // We have to get the user's view history as we can not remove content from the view history without knowing its history id
    const currentViewHistoryContent = await this.getViewHistoryContent();

    for (const content of contents) {
      // We have to search for a matching content id
      let id = '';
      for (const item of currentViewHistoryContent) {
        const contentType = this.convertAbbreviatedContentType(content.type);
        if (item.content_id === +content.id && item.content_type === contentType) {
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
      url: 'https://content-cdn.production-public.tubi.io/api/v2/content',
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
      type: ContentTypes;
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

    const contents = { ...this.cachedContents };

    for (const filter of this.filters) {
      switch (filter.type) {
        case ContentFilterType.videoPreview:
          for (const key in contents) {
            if (!!contents[key].video_preview_url !== filter.value) {
              delete contents[key];
            }
          }
          break;
        case ContentFilterType.rating:
          for (const key in contents) {
            if (!filter.value.includes(contents[key].ratings[0].value)) {
              delete contents[key];
            }
          }
          break;
        case ContentFilterType.contentType:
          for (const key in contents) {
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


type DetailPageMenuItemType = 'play' | 'playFromBeginning' | 'watchTrailer' | 'likeOrDislike' | 'resume' | 'addToMyList' | 'removeFromMyList' | 'removeFromHistory' | 'episodesList' | 'signUp';


type UserInfoResponse = {
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
  password: string | undefined;
};


type DeviceSettings = {
  enable_like_toast_notification: boolean | null;
  enable_dislike_toast_notification: boolean | null;
  second_session_linear_not_watched: boolean | null;
  subtitle_track: any;
  audio_track: {
    language: string,
    role: string
  } | null;
  pause_ad_device_cap: any;
};



type DeeplinkPage = 'movies' | 'genre' | 'network' | 'tv' | 'espanol' | 'kids' | 'home';
type NonDeeplinkPage = 'home' | 'search' | 'settings' | 'myStuff' | 'movies' | 'series' | 'livefeed';
const nonDeeplinkPages = ['home', 'search', 'settings', 'myStuff', 'movies', 'series', 'livefeed'];


/**
 * List of element ids that can be used with our video player helpers
 */
type VideoPlayerElementId = 'videoPlayerScreen' | 'previewVideoPlayer' | 'previewVideoPlayerScreen' | 'linearVideoPlayerScreen' | 'foxPLayerElementID' | 'inlineVideoTilesPreviewPlayer' | 'adPlayerScreen';


enum ContentRatings {
  'G' = 'G',
  'PG' = 'PG',
  'PG-13' = 'PG-13',
  'R' = 'R',
  'TV-Y' = 'TV-Y',
  'TV-Y7_FV' = 'TV-Y7_FV',
  'TV-Y7' = 'TV-Y7',
  'TV-G' = 'TV-G',
  'TV-PG' = 'TV-PG',
  'TV-14' = 'TV-14',
  'TV-MA' = 'TV-MA',
  'NR' = 'NR'
}

enum ParentalRating {
  'adults' = 3,
  'teens' = 2,
  'olderKids' = 1,
  'littleKids' = 0
}


type StartApplicationArgs = {
  /** If true then we will create a new user account and start the application signed in as that user. */
  shouldCreateNewUser?: boolean;

  /** If we need to set user state (watchlist/history/etc) for the application then we can pass in a User after setting that state */
  user?: User;

  /** Clears out all of the saved registry making the application behave as if someone was opening it for the first time. If not explicitly false then the registry will be cleared */
  clearRegistry?: boolean;

  language?: 'english' | 'spanish'

  /** No startup modals are shown unless false */
  hideStartupModals?: boolean;

  /** Sets the Roku system level autoplay setting */
  isAutoplayEnabled?: boolean;

  /** No ads are shown unless set to false */
  noAds?: boolean;

  triggerFailSafe?: 'gameDayExperience'

  /** Disables the skin ads feature */
  disableSkinAds?: boolean;
}


const testUtils = new TestUtils();
const auth = new Auth();


export {
  testUtils,
  auth,
  User,
  RegisteredUser,
  AnonymousUser,
  ContentTypes,
  ContentRatings,
  ParentalRating
};
