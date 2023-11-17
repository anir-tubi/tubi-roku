export const NODES = {
	MOVIE_SCREEN_ROW_LIST: 'movieScreenRowList',
	TV_SHOW_SCREEN_ROW_LIST: 'tvScreenRowList',
};

export const PLAYER_NODES = {
	FAST_FORWARD_BUTTON: 'fastForwardButton',
	VIDEO_PLAYER_ACTUAL: 'videoPlayerActual',
	PLAY_PAUSE_BUTTON: 'playPauseButton',
	PLAYER_REMAINING: 'remainingLabel',
	CURRENT_TIME_PLAYED: 'currentTimePlayed',
};

export const AUTOPLAY_NODES = {
	COUNT_DOWN_MOVIE: 'countDownMovieAutoPlay',
};

export const TITLE_DETAILS_PAGE_NODES = {
	DETAILS_SCREEN: 'detailScreen',
	DETAILS_SCREEN_TITLE: 'detailScreenTitle',
	BACKGROUND_POSTER: 'titleSeriesBackgroundPoster',
};

export const ELEMENTS_FOCUSED = {
	HOME_SCREEN_ROW_LIST: 'homeScreenRowList',
};

export const PAGES = {
	HOME: 'home',
};

export const Events = {
	navigate_to_page: 'navigate_to_page',
	auto_play: 'auto_play',
	page_load: 'page_load',
	pageLoad: 'pageLoad',
	start_video: 'start_video',
	startVideo: 'startVideo',
	play_progress: 'play_progress',
	playProgress: 'playProgress',
	dialog: 'dialog',
	navigate_within_page: 'navigate_within_page',
	subtitles_toggle: 'subtitles_toggle',
	subtitlesToggle: 'subtitlesToggle',
	start_live_video: 'start_live_video',
	fullscreen_toggle: 'fullscreen_toggle',
	component_interaction: 'component_interaction',
	resume_after_break: 'resume_after_break',
	search: 'search',
	pause_toggle: 'pause_toggle',
	pauseToggle: 'pauseToggle',
	account: 'account',
	seek: 'seek',
	explicit_feedback: 'explicit_feedback',
	start_preview: 'start_preview',
	preview_play_progress: 'preview_play_progress',
	finish_preview: 'finish_preview',
	bookmark: 'bookmark',
};

export const PlaybackSource = {
	UNKNOWN_PLAYBACK_SOURCE: 'UNKNOWN_PLAYBACK_SOURCE',
	AUTOPLAY_AUTOMATIC: 'AUTOPLAY_AUTOMATIC',
	AUTOPLAY_DELIBERATE: 'AUTOPLAY_DELIBERATE',
	VIDEO_PREVIEWS: 'VIDEO_PREVIEWS',
};

export const milisecondsToMinutes = async (seconds) =>
	Math.floor(seconds / 60000);
