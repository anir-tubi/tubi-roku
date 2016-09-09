jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000;

const RokuTest = require('roku-test');
const ip = require('ip');
const fs = require('fs');
const localWebServer = require('local-web-server');

describe('hotpatch', function() {

  const webServerLocation = ip.address();
  const testAppName = 'dev';  // this will be 'dev' for sideloaded channels
  const channelZipFile = __dirname + '/../build/tubitv_roku.zip'

  beforeAll(function(done) {
    this.device = new RokuTest(process.env.ROKU_DEV_TARGET, process.env.DEV_PASSWORD, RokuTest.MAIN);

    this.launchChannel = function(args) {
      // helper to start the channel
      console.log('Returning home');
      this.device.press(RokuTest.HOME);
      this.device.delay(1000);
      console.log('Launching channel');
      this.device.launchWithArgs(testAppName, args);
      this.device.delay(1000);
    }


    this.launchWebService = function(mocks) {
      var port = 8000;
      var defaultMocks = [
        // a test route that simply returns a unique string
        {   
          'route': '/hotpatch.brs',
          'response': {
            'body': 'print "HOTPATCH SUCCESSFUL"'
          }
        }
      ];
      var server_config = { 
        'verbose': true,
        'log': {
          'format': 'dev'
        }
      };
      mocks = mocks || []
      server_config['mocks'] = mocks.concat(defaultMocks);
      console.log('Launching web server');
      return localWebServer(server_config).listen(port);
    }

    console.log(">> Installing test channel");
    this.device.install(fs.createReadStream(channelZipFile));
    this.device.press(RokuTest.HOME);
    this.device.delay(1000);
    done();
  });


  afterAll(function() {
    this.device.destroyDebug();
  });

  beforeEach(function() {
    this.listener = null;
    this.webServerLocation = ip.address();
    this.testAppName = 'dev';  // this will be 'dev' for sideloaded channels
    this.channelZipFile = __dirname + '/../build/tubitv_roku.zip'
  });

  afterEach(function() {
    // whether tests pass or fail, we don't want callbacks hanging around
    this.device.removeAllListeners('debugData');
    // shut down web server
    if (this.listener !== null) {
      this.listener.close();
      this.listener = null;
    }
  });

  ///////////////////////
  // Tests
  ///////////////////////

  it("should request on launch", function(done) {
    this.listener = this.launchWebService();
    this.device.on('debugData', function(data) {
      console.log(">>> DEBUG: " + data);
      if (data.toString().match('HOTPATCH SUCCESSFUL') !== null) {
        done();
      }
    }); 
    this.launchChannel();
  });

  it("should not crash on missing hotpatch", function(done) {
    this.device.destroyDebug()
    this.device = new RokuTest(process.env.ROKU_DEV_TARGET, process.env.DEV_PASSWORD, RokuTest.SG);
    this.device.on('debugData', function(data) {
      console.log(">>> DEBUG: " + data);
      if (data.toString().match('CategoryScreen.onCategoriesReceived') !== null) {
        done();
      }
    }); 
    this.launchChannel();
  });

}); // screens
