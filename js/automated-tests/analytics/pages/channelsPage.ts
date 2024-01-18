import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { CHANNELS_PAGE_NODES } from '../utils/constants';
import Container from './container';
const ChannelsPage = () => {
	const elements = {
		channelPoster: async () =>
			await testUtils.getNodeForElement(CHANNELS_PAGE_NODES.CHANNEL_POSTER),
		firstChannelName: async () =>
			await testUtils.getNodeForElement('firstChannelName'),
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const channelPoster = await elements.channelPoster();
			expect(channelPoster.visible).to.equal(true);
		});
	}

	async function selectChannelByName(channelName) {
		await testUtils.jumpToRowWithTitle('channelsListScreenGrid', channelName);
		await ecp.sendKeypress(ecp.Key.Ok);
		const container = Container();
		await container.pageDidLoad();
		return container;
	}

	async function getNameOfFirstChannel() {
		let text = '';
		await testUtils.retryWithTimeOut(async () => {
			const channelPoster = await elements.firstChannelName();
			expect(channelPoster.visible).to.equal(true);
			text = channelPoster.text;
		});
		return text;
	}

	return {
		pageDidLoad,
		selectChannelByName,
		getNameOfFirstChannel,
	};
};

export default ChannelsPage;
