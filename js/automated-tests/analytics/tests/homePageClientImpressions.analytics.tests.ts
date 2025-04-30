import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import { ecp, utils, proxy } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import { EventsValues } from '../utils/constants';
import { ImpressionEvent, ClientImpressionRequest, waitForClientImpressionEventsForTime, waitForClientImpressionEvent, waitForNumberClientImpressionEvents, waitForNumberClientImpressionEventsOrEmpty } from '../utils/network/clientImpression';
import Container from '../pages/container';

describe('Client Impressions events', function () {
  beforeEach(async () => {
    this.timeout(300000);
    await testUtils.startApplicationAtPage('home', {
      shouldCreateNewUser: false,
    });
    await proxy.start();
  });

  afterEach(async () => {
    await proxy.stop();
  });


  it('Home Tab - An impression event fires for all fully visible titles (3 titles) C681881 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent.home_page?.content_mode === 'CONTENT_MODE_UNKNOWN';
    };

    const home = HomePage();
    await home.pageDidLoad();
    const titleIds = await home.getTitleIdHomeScreenHorizontal({ row: 0, amount: 3 });
    const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
    await verifyNormalContainerContents({
      containerIds: ['featured'],
      impressionEvent,
      column: 1,
      titleIds: titleIds,
    });
    expect(impressionEvent.home_page).to.be.an('object');
  });

  it('Impression event fires when switching to a different screen C691943 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent.home_page?.content_mode === 'CONTENT_MODE_UNKNOWN';
    };

    const home = HomePage();
    await home.pageDidLoad();
    const titleIds = await home.getTitleIdHomeScreenHorizontal({ row: 0, amount: 3 });
    await home.selectSideNavTab(tabs.search);
    const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
    await verifyNormalContainerContents({
      containerIds: ['featured'],
      impressionEvent,
      column: 1,
      titleIds: titleIds,
    });
    expect(impressionEvent.home_page).to.be.an('object');
  });

  it('Home (Linear row) - An impression event fires for all fully visible live channels on linear row (3 titles)  C688852 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent?.containers?.some((container) => container.id === 'recommended_linear_channels');
    };

    const home = HomePage();
    await home.pageDidLoad();
    await home.navigateToLiveNews();
    await utils.sleep(3500);
    await home.navigateDown(1);
    const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
    await verifyNormalContainerContentsUnknownTitleIds({
      containerIds: ['recommended_linear_channels'],
      impressionEvent
    }, false);
    expect(impressionEvent.home_page).to.be.an('object');
  });

  it('Movies Tab - An impression event fires for all fully visible titles (3 titles) C681882  @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent?.home_page?.content_mode === EventsValues.conentModeMovie;
    };

    const home = HomePage();
    await home.pageDidLoad();
    const movies = await home.selectSideNavTab(tabs.movies);
    await movies.pageDidLoad();
    await utils.sleep(3500);
    const titleIds = await home.getTitleIdMoviesScreen({ row: 0, amount: 3 });
    const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
    await verifyNormalContainerContents({
      containerIds: ['featured'],
      impressionEvent,
      column: 1,
      titleIds: titleIds,
    });
    expect(impressionEvent.home_page.content_mode).equal(EventsValues.conentModeMovie);
    expect(impressionEvent.containers[0].contents.length).equal(
      3,
      `content.size===3, Event: \n ${JSON.stringify(impressionEvent)} \n`
    );
  });

  it('TVShows Tab - An impression event fires for all fully visible titles (3 titles) C681883  @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent?.home_page?.content_mode === EventsValues.conentModeTv;
    };

    const home = HomePage();
    await home.pageDidLoad();
    const tvShows = await home.selectSideNavTab(tabs.tvShows);
    await tvShows.pageDidLoad();
    await utils.sleep(3500);
    const titleIds = await home.getTitleIdTVShowsScreen({ row: 0, amount: 3 });
    const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
    await verifyNormalContainerContents({
      containerIds: ['featured'],
      impressionEvent,
      column: 1,
      titleIds: titleIds,
    });
    expect(impressionEvent.home_page.content_mode).equal(EventsValues.conentModeTv);
    expect(impressionEvent.containers[0].contents.length).equal(
      3,
      `content.size===3, Event: \n ${JSON.stringify(impressionEvent)} \n`
    );
  });

  it('Español Tab - An impression event fires for all fully visible titles (3 titles) C681884 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent?.home_page?.content_mode === EventsValues.conentModeLatino;
    };

    const home = HomePage();
    await home.pageDidLoad();
    const espanol = await home.selectSideNavTab(tabs.espanol);
    await espanol.pageDidLoad();
    await utils.sleep(5500);
    const titleIds = await home.getTitleIdEspanolScreenHorizontal({ row: 0, amount: 3 });
    const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
    await verifyNormalContainerContents({
      containerIds: ['featured'],
      impressionEvent,
      column: 1,
      titleIds: titleIds,
    });
    expect(impressionEvent.containers[0].contents.length).equal(
      3,
      `content.size===3, Event: \n ${JSON.stringify(impressionEvent)} \n`
    );
    expect(impressionEvent.home_page.content_mode).equal(EventsValues.conentModeLatino);
  });

  it('Navigate to the right 10x times and check titleIds C746885 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent?.containers?.some((container) => container.id === 'recommended_for_you');
    };
    const home = HomePage();
    await home.pageDidLoad();
    await home.navigateDown(1);
    const titleIds = await home.getTitleIdHomeScreenHorizontal({ row: 1, amount: 10 });
    await ecp.sendKeypress(ecp.Key.Right, { count: 10, wait: 1500 });
    const impressionEvent: ClientImpressionRequest = await waitForNumberClientImpressionEvents(4, filter, 65000);
    await verifyTitleIdsFromSameRow({
      containerIds: ['recommended_for_you'],
      impressionRequests: impressionEvent,
      row: 2,
      titleIds: titleIds,
    });
    expect(impressionEvent.requestBody.home_page.content_mode).equal(EventsValues.conentModeUnknown);
  });

  it('Navigate vertically 10x times and check titleIds C746886 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent.home_page?.content_mode === 'CONTENT_MODE_UNKNOWN';
    };

    const home = HomePage();
    await home.pageDidLoad();
    const ids = await home.getTitleIdHomeScreenVertical({ amount: 10 });
    for (let i = 0; i < 10; i++) {
      const impressionEvent = await waitForClientImpressionEvent(filter, 15000);
      const categorySlug = await home.getHomeCategoryName();
      await verifyTitleIdsFromSameColumn({
        containerIds: [categorySlug.categorySlug],
        impressionRequests: impressionEvent,
        row: i + 1,
        column: 1,
        titleIds: ids,
      });
      expect(impressionEvent.home_page.content_mode).equal(EventsValues.conentModeUnknown);
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1500 });
    }
  });

  it('Kids Mode - An impression event does NOT fire for all fully visible titles (3 titles) C681885 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent !== undefined;
    };

    const home = HomePage();
    await home.pageDidLoad();
    const kids = await home.selectSideNavTab(tabs.kids);
    await kids.pageDidLoad();
    const events = await waitForNumberClientImpressionEventsOrEmpty(0, filter, 15000);
    expect(events).to.be.empty;
  });

  it('LiveTV tab - An impression event does NOT fire while on linear page C688851 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent !== undefined;
    };

    const home = HomePage();
    await home.pageDidLoad();
    const liveNews = await home.selectSideNavTab(tabs.liveTV);
    await liveNews.pageDidLoad();
    const events = await waitForNumberClientImpressionEventsOrEmpty(0, filter, 15000);
    expect(events).to.be.empty;
  });

  it('Home - When a content tile is on display for <= 1 sec, an impression event does NOT fire C681886 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent !== undefined;
    };
    const home = HomePage();
    await home.navigateDown(1);
    const events = await waitForClientImpressionEventsForTime(filter, 55000);
    expect(events.length).equal(2);
  });

  it('Movies Tab - When a content tile is on display for <= 1 sec, an impression event does NOT fire C681887  @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent !== undefined;
    };

    await testUtils.startApplicationAtPage('movies', {
      shouldCreateNewUser: false,
    });
    const home = HomePage();
    await home.navigateDown(5);
    const events = await waitForClientImpressionEventsForTime(filter, 55000);
    expect(events).to.be.empty;
  });


  it('TV Shows Tab - When a content tile is on display for <= 1 sec, an impression event does NOT fire C681888 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent !== undefined;
    };

    await testUtils.startApplicationAtPage('tv', {
      shouldCreateNewUser: false,
    });
    const home = HomePage();
    await home.navigateDown(5);
    const events = await waitForClientImpressionEventsForTime(filter, 55000);
    expect(events).to.be.empty;
  });

  it('Español Tab - When a content tile is on display for <= 1 sec, an impression event does NOT fire C681889 @impressionEventsHomePage', async () => {
    const filter = (impressionEvent: ImpressionEvent) => {
      return impressionEvent !== undefined;
    };

    await testUtils.startApplicationAtPage('espanol', {
      shouldCreateNewUser: false,
    });
    const home = HomePage();
    await home.navigateDown(5);
    const events = await waitForClientImpressionEventsForTime(filter, 55000);
    expect(events).to.be.empty;
  });


  async function verifyNormalContainerContents(options: VerifyContainerOptions) {
    const { containerIds, impressionEvent, column = 1, row = 1, titleIds = [] } = options;
    titleIds.sort((a, b) => a - b);
    impressionEvent.containers.forEach((container) => {
      container.contents.sort((a, b) => b.video_id.toString().localeCompare(a.video_id.toString()));
    });
    impressionEvent.containers.forEach((container, index) => {
      expect(container.id).equal(
        containerIds[index],
        `container.id===featured, Event: \n ${JSON.stringify(impressionEvent)} \n`
      );
      titleIds.forEach((titleId, index) => {
        const content = container.contents[index];
        expect(content).to.have.any.keys('video_id', 'series_id');
        if (content.video_id) {
          expect(parseInt(content.video_id)).equal(titleId);
        }
        if (content.series_id) {
          expect(parseInt(content.series_id)).equal(titleId);
        }
        expect(content.row).equal(row, `content.row===1, Event: \n ${JSON.stringify(impressionEvent)} \n`);
        expect(content.col).equal(
          index + 1,
          `content.row===1, Event: \n ${JSON.stringify(impressionEvent)} \n`
        );
        expect(content.duration).to.be.within(1000, 17000);
      });
    });
  }

  async function verifyNormalContainerContentsUnknownTitleIds(options: VerifyContainerOptions, checkTheRow: boolean = true) {
    const { containerIds, impressionEvent, row = 1 } = options;
    let verified = false;
    impressionEvent.containers.forEach((container, index) => {
      if (containerIds[0] === container.id) {
        expect(container.id).equal(
          containerIds[0],
          `container.id===featured, Event: \n ${JSON.stringify(impressionEvent)} \n`
        );
        container.contents.forEach((content, index) => {
          const i = index + 1;
          expect(content).to.have.any.keys('video_id', 'series_id');
          if (content.video_id) {
            expect(parseInt(content.video_id)).to.be.a('number');
          }
          if (content.series_id) {
            expect(parseInt(content.series_id)).to.be.a('number');
          }
          if (checkTheRow) {
            expect(content.row).equal(row, `content.row===1, Event: \n ${JSON.stringify(impressionEvent)} \n`);
          }
          else {
            expect(content.row).to.be.a('number');
          }
          expect(content.col).equal(i, `content.row===1, Event: \n ${JSON.stringify(impressionEvent)} \n`);
          expect(content.duration).to.be.within(1000, 17000);
          verified = true;
        });
      }
    });
    expect(verified).equal(
      true,
      `didnt find expected container ${containerIds} , Event: \n ${JSON.stringify(impressionEvent)} \n`
    );
  }

  async function verifyTitleIdsFromSameRow(options: any) {
    let titlePosition = 0;
    const { containerIds, impressionRequests, column = 1, row = 1, titleIds = [] } = options;
    const matchingContainers: any[] = [];

    impressionRequests.forEach((impressionEvent) => {
      const containers = impressionEvent.containers.filter((container) => container.id === containerIds[0]);
      matchingContainers.push(...containers);
    });
    expect(matchingContainers.length).to.not.equal(0, `No matching containers found`);
    matchingContainers.forEach((container) => {
      container.contents.forEach((content) => {
        expect(content).to.have.any.keys('video_id', 'series_id');
        if (content.video_id) {
          expect(parseInt(content.video_id)).equal(
            parseInt(titleIds[titlePosition]),
            `should be ${content.video_id}===${titleIds[titlePosition]}, Event: \n ${JSON.stringify(container)} \n, found title ids ${JSON.stringify(titleIds)}`
          );
        }
        if (content.series_id) {
          expect(parseInt(content.series_id)).equal(
            titleIds[titlePosition],
            `should be ${content.series_id}===${titleIds[titlePosition]}, Event: \n ${JSON.stringify(container)} \n, found title ids ${JSON.stringify(titleIds)}`
          );
        }
        titlePosition += 1;
        expect(content.row).equal(row, `content.row===1, Event: \n ${JSON.stringify(container)} \n`);
        expect(content.col).equal(titlePosition, `content.row===1, Event: \n ${JSON.stringify(container)} \n`);
        expect(content.duration).to.be.within(1000, 20000);
      });
    });
  }

  async function verifyTitleIdsFromSameColumn(options: any) {
    const { containerIds, impressionRequests, column = 1, row = 1, titleIds = [] } = options;
    const category = containerIds.filter(
      (container) => container.toLowerCase() === impressionRequests.containers[0].id
    );
    const content = impressionRequests.containers[0].contents[0];
    expect(content).to.have.any.keys('video_id', 'series_id');
    if (content.video_id) {
      expect(parseInt(content.video_id)).equal(
        parseInt(titleIds[0]),
        `should be ${content.video_id}===${titleIds[0]}, Event: \n ${JSON.stringify(content)} \n, found title ids ${JSON.stringify(titleIds)}`
      );
    }
    if (content.series_id) {
      expect(content.series_id).equal(
        parseInt(titleIds[0]),
        `should be ${content.series_id}===${titleIds[0]}, Event: \n ${JSON.stringify(content)} \n, found title ids ${JSON.stringify(titleIds)}`
      );
    }
    expect(content.row).equal(row, `content.row===1, Event: \n ${JSON.stringify(content)} \n`);
    expect(content.col).equal(column, `content.row===1, Event: \n ${JSON.stringify(content)} \n`);
    expect(content.duration).to.be.within(500, 45000);
  }

  interface VerifyContainerOptions {
    containerIds: string[];
    impressionEvent: ImpressionEvent;
    column?: number;
    row?: number;
    titleIds?: number[];
  }
});

