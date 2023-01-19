'use strict';
const { device, odc, utils } = require('roku-test-automation');

before(async () => {
	utils.setupEnvironmentFromConfigFile('rta-config.json');

	console.log('deploying app');
	await device.deploy({
		rootDir: 'build/local',
		files: [
			'**/*'
		]
	});
});


after(async function () {
	await odc.shutdown();
});
