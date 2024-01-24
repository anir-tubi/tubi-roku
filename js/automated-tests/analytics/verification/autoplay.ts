import { Events, PlaybackSource, DialogAction } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC21398andC130133(idOfTitleFromAutoplay) {
	let eventStartVideo;
	let i = 1;
	while (eventStartVideo === undefined && i < 20) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.start_video,
			i + 3
		);
		eventStartVideo = pulletEvents.find(
			(event) =>
				event.start_video.playback_source === PlaybackSource.AUTOPLAY_DELIBERATE
		);
		i++;
	}
	expect(eventStartVideo.start_video.playback_source).equal(
		PlaybackSource.AUTOPLAY_DELIBERATE,
		`eventStartVideo.start_video.playback_source===PlaybackSource.AUTOPLAY_DELIBERATE, Event: \n
			${JSON.stringify(eventStartVideo)} \n`
	);
	await checkEventStartVideo(
		eventStartVideo.start_video,
		idOfTitleFromAutoplay
	);
}
export async function verifyC21392(videoId) {
	let autoplayEvent;
	let i = 1;
	while (autoplayEvent === undefined && i < 25) {
		let pulletEvents = await getMatchedEventsFromLastEvent(
			Events.auto_play,
			i + 20
		);
		autoplayEvent = pulletEvents.find(
			(event) =>
				event.auto_play.auto_play_action === DialogAction.show &&
				event.auto_play.video_id === parseInt(videoId)
		);
		i++;
	}
	expect(autoplayEvent.auto_play.video_id).equal(
		parseInt(videoId),
		`event.auto_play.video_id===${videoId}, Event: \n
			${JSON.stringify(autoplayEvent)} \n`
	);
	expect(autoplayEvent.auto_play.auto_play_action).equal(
		'SHOW',
		`event.auto_play.auto_play_action===SHOW, Event: \n
	${JSON.stringify(autoplayEvent)} \n`
	);
}

export async function verifyC285598(videoId) {
	let playProgressEvent;
	let i = 1;
	while (playProgressEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			10 + i
		);
		playProgressEvent = pulletEvents.find(
			(event) =>
				event.play_progress.playback_source ===
				PlaybackSource.UNKNOWN_PLAYBACK_SOURCE
		);
		i++;
	}
	expect(playProgressEvent.play_progress.playback_source).equal(
		PlaybackSource.UNKNOWN_PLAYBACK_SOURCE,
		`playProgressEvent.play_progress.playback_source===VIDEO_PREVIEWS, Event: \n
			${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.position).to.match(
		/./,
		`playProgressEvent.play_progress.position===someString: \n ${playProgressEvent}`
	);
	expect(playProgressEvent.play_progress.video_id).equal(
		parseInt(videoId),
		`playProgressEvent.play_progress.video_id===${videoId}, Event: \n
			${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.video_player).equal(
		'DEFAULT',
		`playProgressEvent.play_progress.video_player===DEFAULT, Event: \n
			${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.view_time).to.match(
		/./,
		`playProgressEvent.play_progress.view_time===someString: \n ${playProgressEvent}`
	);
}
export async function verifyC285597(id) {
	let eventStartVideo;
	let i = 1;
	while (eventStartVideo === undefined && i < 10) {
		let pulletEvents = await getMatchedEventsFromLastEvent(
			Events.start_video,
			10 + i
		);
		eventStartVideo = pulletEvents.find(
			(event) =>
				event.start_video.playback_source ===
				PlaybackSource.UNKNOWN_PLAYBACK_SOURCE
		);
		i++;
	}
	expect(eventStartVideo.start_video.playback_source).equal(
		PlaybackSource.UNKNOWN_PLAYBACK_SOURCE,
		`eventStartVideo.start_video.playback_source===PlaybackSource.UNKNOWN_PLAYBACK_SOURCE, Event: \n
			${JSON.stringify(eventStartVideo)} \n`
	);
	await checkEventStartVideo(eventStartVideo.start_video, { id: id });
}

export async function verifyC285596(videoId) {
	let playProgressEvent;
	let i = 1;
	while (playProgressEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			10 + i
		);
		playProgressEvent = pulletEvents.find(
			(event) =>
				event.play_progress &&
				event.play_progress.playback_source &&
				event.play_progress.playback_source === PlaybackSource.VIDEO_PREVIEWS
		);
		i++;
	}
	expect(playProgressEvent.play_progress.playback_source).equal(
		PlaybackSource.VIDEO_PREVIEWS,
		`playProgressEvent.play_progress.playback_source===VIDEO_PREVIEWS, Event: \n
			${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.position).to.match(
		/./,
		`playProgressEvent.play_progress.position===someString: \n ${playProgressEvent}`
	);
	expect(playProgressEvent.play_progress.video_id).equal(
		parseInt(videoId),
		`playProgressEvent.play_progress.video_id===${videoId}, Event: \n
			${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.view_time).to.match(
		/./,
		`playProgressEvent.play_progress.view_time===someString: \n ${playProgressEvent}`
	);
}

export async function verifyC285595(id) {
	let eventStartVideo;
	let i = 1;
	while (eventStartVideo === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.start_video,
			10 + i
		);
		eventStartVideo = pulletEvents.find(
			(event) =>
				event.start_video.playback_source === PlaybackSource.VIDEO_PREVIEWS
		);
		i++;
	}
	expect(eventStartVideo.start_video.playback_source).equal(
		PlaybackSource.VIDEO_PREVIEWS,
		`eventStartVideo.start_video.playback_source===PlaybackSource.VIDEO_PREVIEWS, Event: \n
			${JSON.stringify(eventStartVideo)} \n`
	);
	await checkEventStartVideo(eventStartVideo.start_video, { id: id });
}

export async function verifyC130134(autoplayId) {
	let eventStartVideo;
	let i = 1;
	while (eventStartVideo === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.start_video,
			5 + i
		);
		eventStartVideo = pulletEvents.find(
			(event) =>
				event.start_video.playback_source &&
				event.start_video.playback_source === PlaybackSource.AUTOPLAY_AUTOMATIC
		);
		i++;
	}
	await checkEventStartVideo(eventStartVideo.start_video, autoplayId.id);
	await verifyStartVideoFromAutoplay(eventStartVideo);
}

export async function verifyC130136(autoplayId) {
	let eventPlayProgress;
	let i = 1;
	while (eventPlayProgress === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			i + 4
		);
		eventPlayProgress = pulletEvents.find(
			(event) =>
				event.play_progress &&
				event.play_progress.playback_source ===
					PlaybackSource.AUTOPLAY_AUTOMATIC //present for FireTV
		);
		i++;
	}
	expect(eventPlayProgress.play_progress.playback_source).equal(
		PlaybackSource.AUTOPLAY_AUTOMATIC,
		`event should contain eventPlayProgress.play_progress.playback_source==PlaybackSource.AUTOPLAY_DELIBERATE, Event: \n ${JSON.stringify(
			eventPlayProgress
		)}`
	);
	expect(
		parseInt(eventPlayProgress.play_progress.view_time)
	).greaterThanOrEqual(
		500,
		`event should contain firstPlayProgress.play_progress.view_time, Event: \n ${JSON.stringify(
			eventPlayProgress
		)}`
	);
	expect(parseInt(eventPlayProgress.play_progress.position)).greaterThanOrEqual(
		500,
		`event should contain eventPlayProgress.play_progress.position, Event: \n ${JSON.stringify(
			eventPlayProgress
		)}`
	);
	expect(eventPlayProgress.play_progress.video_id).equal(
		parseInt(autoplayId.id),
		`event should contain feventPlayProgress.play_progress.video_id==${
			autoplayId.id
		} but in event ${
			eventPlayProgress.play_progress.video_id
		}, Event: \n ${JSON.stringify(eventPlayProgress)}`
	);
}

export async function verifyC130132NavigateToPage(idOfNextEpisode, episodeId) {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			6
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.auto_play_component &&
				event.navigate_to_page.auto_play_component.content_tile &&
				event.navigate_to_page.auto_play_component.content_tile.row === 1
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_to_page.video_player_page.video_id).equal(
		parseInt(episodeId),
		`eventNavigateToPage.navigate_to_page.video_player_page.video_id===${episodeId}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id
	).equal(
		parseInt(idOfNextEpisode.id),
		`eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id===${idOfNextEpisode}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.auto_play_component.content_tile
			.video_id
	).equal(
		parseInt(idOfNextEpisode.id),
		` eventNavigateToPage.navigate_to_page.auto_play_component
      .content_tile.video_id===${idOfNextEpisode}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.auto_play_component.content_tile.row
	).equal(
		1,
		` eventNavigateToPage.navigate_to_page.auto_play_component
      .content_tile.row===1, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.auto_play_component.content_tile.col
	).equal(
		1,
		` eventNavigateToPage.navigate_to_page.auto_play_component
      .content_tile.col===1, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
}

export async function verifyC25123(id) {
	let playProgress;
	let i = 1;
	while (playProgress === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			15 + i
		);
		playProgress = pulletEvents.find(
			(event) => event.play_progress.video_id !== parseInt(id)
		);
		i++;
	}
	expect(playProgress.play_progress.video_id).not.equal(
		parseInt(id),
		`event.auto_play.video_id===${id}, Event: \n
      ${JSON.stringify(playProgress)} \n`
	);
}

export async function verifyC21396(id) {
	let eventAutoplayShow;
	let i = 1;
	while (eventAutoplayShow === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.auto_play,
			6 + i
		);
		eventAutoplayShow = pulletEvents.find(
			(event) =>
				event.auto_play.video_id &&
				event.auto_play.auto_play_action &&
				event.auto_play.auto_play_action === DialogAction.show
		);
		i++;
	}
	expect(eventAutoplayShow.auto_play.video_id).equal(
		parseInt(id),
		`event.auto_play.video_id===${id}, Event: \n
      ${JSON.stringify(eventAutoplayShow)} \n`
	);
	expect(eventAutoplayShow.auto_play.auto_play_action).equal(
		DialogAction.show,
		`event.auto_play.auto_play_action===SHOW, Event: \n
  ${JSON.stringify(eventAutoplayShow)} \n`
	);
}

export async function verifyC21397(id) {
	let eventAutoplayShow;
	let i = 1;
	while (eventAutoplayShow === undefined && i < 15) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.auto_play,
			8 + i
		);
		eventAutoplayShow = pulletEvents.find(
			(event) =>
				event.auto_play.video_id &&
				event.auto_play.auto_play_action &&
				event.auto_play.auto_play_action === DialogAction.dissmiss
		);
		i++;
	}
	expect(eventAutoplayShow.auto_play.video_id).equal(
		parseInt(id),
		`event.auto_play.video_id===${id}, Event: \n
      ${JSON.stringify(eventAutoplayShow)} \n`
	);
	expect(eventAutoplayShow.auto_play.auto_play_action).equal(
		DialogAction.dissmiss,
		`event.auto_play.auto_play_action===SHOW, Event: \n
  ${JSON.stringify(eventAutoplayShow)} \n`
	);
}

export async function verifyC130132(idOfNextEpisode) {
	let eventPageLoad;
	let i = 1;
	while (eventPageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			6 + i
		);
		eventPageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.video_player_page &&
				event.page_load.video_player_page.video_id ===
					parseInt(idOfNextEpisode.id)
		);
		i++;
	}
	expect(eventPageLoad.page_load.video_player_page.video_id).equal(
		parseInt(idOfNextEpisode.id),
		`eventPageLoad.page_load.video_player_page.video_id===${idOfNextEpisode}, Event: \n
      ${JSON.stringify(eventPageLoad)} \n`
	);
}

export async function verifyC21393(episodeId) {
	let eventAutoplay;
	let i = 1;
	while (eventAutoplay === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.auto_play,
			8 + i
		);
		eventAutoplay = pulletEvents.find(
			(event) =>
				event.auto_play &&
				event.auto_play.auto_play_action === DialogAction.show
		);
		i++;
	}
	expect(eventAutoplay.auto_play.video_id).equal(
		parseInt(episodeId),
		`event.auto_play.video_id===${episodeId}, Event: \n
      ${JSON.stringify(eventAutoplay)} \n`
	);
	expect(eventAutoplay.auto_play.auto_play_action).equal(
		'SHOW',
		`event.auto_play.auto_play_action===SHOW, Event: \n
  ${JSON.stringify(eventAutoplay)} \n`
	);
}

export async function verifyC285592(id) {
	let eventPlayProgress;
	let i = 1;
	while (eventPlayProgress === undefined && i < 20) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			30 + i
		);
		eventPlayProgress = pulletEvents.find(
			(event) =>
				event.play_progress.video_id &&
				event.play_progress.video_id === parseInt(id.id)
		);
		i++;
	}
	expect(eventPlayProgress.play_progress.video_id).equal(
		parseInt(id.id),
		`eventPlayProgress.play_progress.video_id===${id}, Event: \n
      ${JSON.stringify(eventPlayProgress)} \n`
	);
	expect(eventPlayProgress.play_progress.playback_source).equal(
		PlaybackSource.AUTOPLAY_DELIBERATE,
		`eventPlayProgress.play_progress.playback_source===AUTOPLAY_DELIBERATE, Event: \n
      ${JSON.stringify(eventPlayProgress)} \n`
	);
	expect(eventPlayProgress.play_progress.position).to.match(
		/\d/,
		`eventPlayProgress.play_progress.position event: \n ${eventPlayProgress}`
	);
	expect(eventPlayProgress.play_progress.video_player).equal(
		'DEFAULT',
		`eventPlayProgress.play_progress.video_player===DEFAULT or false: \n ${JSON.stringify(
			eventPlayProgress
		)}`
	);
	expect(eventPlayProgress.play_progress.view_time).to.match(
		/\d/,
		`eventPlayProgress.play_progress.view_time event: \n ${eventPlayProgress}`
	);
}

export async function verifyC285594(playProgressEvent, videoId) {
	expect(playProgressEvent.play_progress.playback_source).equal(
		PlaybackSource.AUTOPLAY_AUTOMATIC,
		`playProgressEvent.play_progress.playback_source===AUTOPLAY_AUTOMATIC, Event: \n
      ${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.position).to.match(
		/./,
		`playProgressEvent.play_progress.position===someString: \n ${playProgressEvent}`
	);
	expect(playProgressEvent.play_progress.video_id).equal(
		parseInt(videoId.id),
		`playProgressEvent.play_progress.video_id===${videoId}, Event: \n
      ${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.video_player).equal(
		'DEFAULT',
		`playProgressEvent.play_progress.video_player===DEFAULT, Event: \n
      ${JSON.stringify(playProgressEvent)} \n`
	);
	expect(playProgressEvent.play_progress.view_time).to.match(
		/./,
		`playProgressEvent.play_progress.view_time===someString: \n ${playProgressEvent}`
	);
}

export async function verifyC21265(idOfTitleFromAutoplay, id) {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			10
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.auto_play_component &&
				event.navigate_to_page.auto_play_component.content_tile &&
				event.navigate_to_page.auto_play_component.content_tile.col === 1
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_to_page.video_player_page.video_id).equal(
		parseInt(id),
		`eventNavigateToPage.navigate_to_page.video_player_page.video_id===${id}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id
	).equal(
		parseInt(idOfTitleFromAutoplay.id),
		`eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id===${idOfTitleFromAutoplay}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.auto_play_component.content_tile
			.video_id
	).equal(
		parseInt(idOfTitleFromAutoplay.id),
		`eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id===${idOfTitleFromAutoplay}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.auto_play_component.content_tile.row
	).equal(
		1,
		`eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id===${idOfTitleFromAutoplay}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.auto_play_component.content_tile.col
	).equal(
		1,
		`eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id===${idOfTitleFromAutoplay}, Event: \n
      ${JSON.stringify(eventNavigateToPage)} \n`
	);
}

export async function verifyStartVideoFromAutoplay(eventStartVideo) {
	expect(eventStartVideo.start_video.playback_source).equal(
		PlaybackSource.AUTOPLAY_AUTOMATIC,
		`startVideoEvent.start_video.playback_source===PlaybackSource.AUTOPLAY_AUTOMATIC, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
}

async function checkEventStartVideo(eventStartVideo, idOfTitleFromAutoplay) {
	if (idOfTitleFromAutoplay.id !== undefined) {
		expect(eventStartVideo.video_id).equal(
			parseInt(idOfTitleFromAutoplay.id),
			`eventStartVideo.start_video.video_id===${
				idOfTitleFromAutoplay.id
			}, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
		);
	}
	expect(eventStartVideo.has_subtitles).to.match(
		/true|false/,
		`startVideoEvent.start_video.has_subtitles===true or false, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.is_embedded).to.match(
		/true|false/,
		`startVideoEvent.start_video.is_embedded===true or false, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.is_fullscreen).equal(
		true,
		`startVideoEvent.start_video.is_fullscreen===true, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.is_livetv).equal(
		false,
		`startVideoEvent.start_video.is_livetv===true or false, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.has_subtitles).to.match(
		/true|false/,
		`startVideoEvent.start_video.has_subtitles===true or false, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(parseInt(eventStartVideo.start_position)).equal(
		0,
		`startVideoEvent.start_video.start_position===0, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.video_codec_type).to.match(
		/VIDEO_CODEC_H264|VIDEO_CODEC_H265/,
		`startVideoEvent.start_video.video_codec_type===VIDEO_CODEC_H264, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.video_resolution).to.match(
		/VIDEO_RESOLUTION_720P|VIDEO_RESOLUTION_480P/,
		`startVideoEvent.play_progress.video_resolution===VIDEO_RESOLUTION_720P, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.video_resource_type).to.match(
		/VIDEO_RESOURCE_TYPE_HLSV6|VIDEO_RESOURCE_TYPE_DASH_WIDEVINE|VIDEO_RESOURCE_TYPE_DASH/,
		`startVideoEvent.play_progress.video_resource_type===VIDEO_RESOURCE_TYPE_HLSV6, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
	expect(eventStartVideo.video_resource_url).to.match(
		/./,
		`startVideoEvent.play_progress.video_resource_url===URL, Event: \n
      ${JSON.stringify(eventStartVideo)} \n`
	);
}
