export async function addMoviesToQueue(user, count) {
	const ContentG = await user.getContentById(100011545);
	await user.addContentToWatchList(ContentG);
	// const movieContentTVY7 = await user.getContent().ofContentType(['series']).withRating('TV-Y7').retrieve({ limit: 3});
	// await user.addContentToWatchList(movieContentTVY7);
	// const movieContentTVMA = await user.getContent().ofContentType(['series']).withRating('TV-MA').retrieve({ limit: 3});
	// await user.addContentToWatchList(movieContentTVMA);
	// const movieContentR = await user.getContent().ofContentType(['series', 'movie']).withRating('R').retrieve({ limit: 2});
	// await user.addContentToWatchList(movieContentR);
	// const movieContentPG = await user.getContent().ofContentType(['series', 'movie']).withRating('PG').retrieve({ limit: 2});
	// await user.addContentToWatchList(movieContentPG);
	// const movieContentPG13 = await user.getContent().ofContentType(['series', 'movie']).withRating('PG-13').retrieve({ limit: 2});
	// await user.addContentToWatchList(movieContentPG13);
	// const movieContentTV14 = await user.getContent().ofContentType(['series']).withRating('TV-14').retrieve({ limit: 2});
	// await user.addContentToWatchList(movieContentTV14);
	// const movieContentNR = await user.getContent().ofContentType(['movie']).withRating('NR').retrieve({ limit: 2});
	// await user.addContentToWatchList(movieContentNR);
}

export async function addTheFreakBrothersTVShowToQueue(user) {
	const contentId = await user.getContentById(300007896);
	await user.addContentToWatchList(contentId);
}

export async function addTheFreakBrothersTVShowToHistory(user) {
	const contentId = await user.getContentById(300007896);
	await user.addContentToViewHistory(contentId, 500);
}

export async function addZappedTitleToHistory(user) {
	const contentId = await user.getContentById(342067);
	await user.addContentToViewHistory(contentId, 500);
}

export async function addTheFreakBrothersTVShowToMyList(user) {
	const contentId = await user.getContentById(300007896);
	await user.addContentToWatchList(contentId, 500);
}

export async function addZappedTitleToMyList(user) {
	const contentId = await user.getContentById(342067);
	await user.addContentToWatchList(contentId, 500);
}
