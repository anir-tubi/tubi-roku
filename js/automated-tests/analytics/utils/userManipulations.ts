export async function addMoviesToQueue(user, count) {
	const ContentG = await user.getContentById(100011545);
	await user.addContentToWatchList(ContentG);
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

export async function addMrPostmanTitleToHistory(user) {
	const contentId = await user.getContentById(463669);
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
