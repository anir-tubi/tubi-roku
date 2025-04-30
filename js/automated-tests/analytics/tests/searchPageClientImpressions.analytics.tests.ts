import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import { ecp, utils, proxy } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import { EventsValues } from '../utils/constants';
import { ImpressionEvent, ClientImpressionRequest, waitForClientImpressionEventsForTime, waitForClientImpressionEvent, waitForNumberClientImpressionEvents, waitForNumberClientImpressionEventsOrEmpty } from '../utils/network/clientImpression';
import SearchPage from '../pages/searchPage';

describe('Client Impressions events', function () {
    beforeEach(async () => {
        this.timeout(300000);
        await testUtils.startApplicationAtPage('search', {
            shouldCreateNewUser: false,
        });
        await proxy.start();
    });

    afterEach(async () => {
        await proxy.stop();
    });

    it('C754600 Impression event fires when switching to a different screen @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        await utils.sleep(3000);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        await searchPage.navigateToSideNav();
        await SideNav().selectTabNoPageReturn(tabs.categories);
        const impressionEvent = await waitForClientImpressionEvent(filter, 35000);
        await verifyNormalContainerContents({
            containerIds: ['top_searched'],
            impressionEvent,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEvent.search_page).to.be.an('object');
    });

    it('C754615 Impression event fires when left nav is in focus @impressionEvents,', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        await utils.sleep(5000);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        await searchPage.navigateToSideNav();
        const impressionEvent = await waitForClientImpressionEvent(filter, 35000);
        await verifyNormalContainerContents({
            containerIds: ['top_searched'],
            impressionEvent,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEvent.search_page).to.be.an('object');
    });

    it('C754616 Impression event fires after user inputs a letter in search @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'search';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.enterSearch('a');
        await utils.sleep(5000);
        await ecp.sendKeypress(ecp.Key.Left);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        const impressionEvent = await waitForClientImpressionEventsForTime(filter, 65000);
        await verifyNormalContainerContents({
            containerIds: ['search'],
            impressionEvent,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEvent.search_page).to.be.an('object');
    });

    it('C754601 Impression event fires for all fully visible titles that are displayed for more than 1 sec (Trending Searches) @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        await ecp.sendKeypress(ecp.Key.Down);
        const impressionEvent = await waitForClientImpressionEvent(filter, 35000);
        await verifyNormalContainerContents({
            containerIds: ['top_searched'],
            impressionEvent,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEvent.search_page).to.be.an('object');
    });

    it('C754620 Impression event fires when user enter details page @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        await searchPage.selectFocusedTitle();
        const impressionEvent = await waitForClientImpressionEvent(filter, 35000);
        await verifyNormalContainerContents({
            containerIds: ['top_searched'],
            impressionEvent,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEvent.search_page).to.be.an('object');
    });

    it('C754602 Impression event does NOT fire when fully visible titles are displayed for less than 1 sec @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        const titleIds = await searchPage.getRangeTitleIdSarchScreenVertical({ from: 5, to: 10 });
        await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
        const impressionEvents: ClientImpressionRequest = await waitForClientImpressionEventsForTime(filter, 65000);
        await verifyImpressionEventDoesNotContainTitleIds({
            impressionEvents,
            titleIds: titleIds,
        });
        const hasSearchPage = impressionEvents.some((impressionEvent) => {
            return impressionEvent.search_page && typeof impressionEvent.search_page === 'object';
        });
        expect(hasSearchPage).to.be.true;
    });

    it('C754603 Impression event does NOT fire for titles that are NOT fully visible @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        const titleIds = await searchPage.getRangeTitleIdSarchScreenVertical({ from: 5, to: 10 });
        await ecp.sendKeypress(ecp.Key.Down);
        const impressionEvents: ClientImpressionRequest = await waitForClientImpressionEventsForTime(filter, 65000);
        await verifyImpressionEventDoesNotContainTitleIds({
            impressionEvents,
            titleIds: titleIds,
        });
        const hasSearchPage = impressionEvents.some((impressionEvent) => {
            return impressionEvent.search_page && typeof impressionEvent.search_page === 'object';
        });
        expect(hasSearchPage).to.be.true;
    });

    it('C754604 Multiple impression events for the same title @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'top_searched';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.goToTitleInPosition(1);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        await ecp.sendKeypress(ecp.Key.Down);
        const impressionEventFirst = await waitForClientImpressionEvent(filter, 35000);
        await ecp.sendKeypress(ecp.Key.Up, { wait: 2000 });
        await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
        const impressionEventSecond = await waitForClientImpressionEvent(filter, 35000);
        impressionEventSecond.containers[0].contents = impressionEventSecond.containers[0].contents.filter((content) => {
            return content.row === 1;
        });
        await verifyNormalContainerContents({
            containerIds: ['top_searched'],
            impressionEvent: impressionEventFirst,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEventFirst.search_page).to.be.an('object');
        await verifyNormalContainerContents({
            containerIds: ['top_searched'],
            impressionEvent: impressionEventSecond,
            column: 1,
            titleIds: titleIds,
        });
        expect(impressionEventSecond.search_page).to.be.an('object');
    });

    it('C754622 Search query is added to payload @impressionEvents', async () => {
        const filter = (impressionEvent: ImpressionEvent) => {
            return impressionEvent.containers?.some((container) => {
                return container.id === 'search';
            });
        };

        const searchPage = SearchPage();
        await searchPage.pageDidLoad();
        await searchPage.enterSearch('ninja');
        await utils.sleep(5000);
        await ecp.sendKeypress(ecp.Key.Left);
        const titleIds = await searchPage.getTitleIdSarchScreenVertical({ amount: 5 });
        const impressionEvent = await waitForClientImpressionEvent(filter, 65000);
        await verifyNormalContainerContentsSearch({
            containerIds: ['search'],
            impressionEvent,
            column: 1,
            titleIds: titleIds,
        }, 'ninja');
        expect(impressionEvent.search_page).to.be.an('object');
    });


    async function verifyNormalContainerContents(options: VerifyContainerOptions) {
        const { containerIds, impressionEvent, column = 1, row = 1, titleIds = [] } = options;
        impressionEvent.containers.forEach((container, index) => {
            expect(container.id).equal(
                containerIds[index],
                `container.id===featured, Event: \n ${JSON.stringify(impressionEvent)} \n`
            );
            container.contents.sort((a, b) => a.col - b.col);
            titleIds.forEach((titleId, index) => {
                const content = container.contents[index];
                expect(content).to.have.any.keys('video_id', 'series_id');
                if (content.video_id) {
                    expect(content.video_id).equal(titleId);
                }
                if (content.series_id) {
                    expect(content.series_id).equal(titleId);
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

    async function verifyNormalContainerContentsSearch(options: VerifyContainerOptions, searchText: string) {
        const { containerIds, impressionEvent, column = 1, row = 1, titleIds = [] } = options;
        expect(impressionEvent.search_page.query).equal(
            searchText,
            `searchText===${searchText}, Event: \n ${JSON.stringify(impressionEvent)} \n`
        );
        impressionEvent.containers.forEach((container, index) => {
            expect(container.id).equal(
                containerIds[index],
                `container.id===featured, Event: \n ${JSON.stringify(impressionEvent)} \n`
            );
            container.contents.sort((a, b) => a.col - b.col);
            titleIds.forEach((titleId, index) => {
                const content = container.contents[index];
                expect(content).to.have.any.keys('video_id', 'series_id');
                if (content.video_id) {
                    expect(content.video_id).equal(titleId);
                }
                if (content.series_id) {
                    expect(content.series_id).equal(titleId);
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
    async function verifyImpressionEventDoesNotContainTitleIds(options: VerifyContainerOptions) {
        const { impressionEvents, titleIds = [] } = options;

        // Ensure impressionEvents is an array and iterate through each event
        impressionEvents.forEach((impressionEvent) => {
            if (!impressionEvent.containers || impressionEvent.containers.length === 0) {
                console.warn(`No containers found in impressionEvent: \n ${JSON.stringify(impressionEvent)} \n`);
                return;
            }
            impressionEvent.containers.forEach((container) => {
                if (!container.contents || container.contents.length === 0) {
                    console.warn(`No contents found in container ${container.id}, Event: \n ${JSON.stringify(impressionEvent)} \n`);
                    return;
                }
                container.contents.forEach((content) => {
                    if (content.video_id) {
                        expect(titleIds).to.not.include(
                            content.video_id,
                            `Found unexpected video_id ${content.video_id} in container ${container.id}, Event: \n ${JSON.stringify(impressionEvent)} \n`
                        );
                    }
                    if (content.series_id) {
                        expect(titleIds).to.not.include(
                            content.series_id,
                            `Found unexpected series_id ${content.series_id} in container ${container.id}, Event: \n ${JSON.stringify(impressionEvent)} \n`
                        );
                    }
                });
            });
        });
    }

    interface VerifyContainerOptions {
        containerIds: string[];
        impressionEvent: ImpressionEvent;
        column?: number;
        row?: number;
        titleIds?: number[];
    }
});

