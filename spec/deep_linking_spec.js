jasmine.DEFAULT_TIMEOUT_INTERVAL = 20000;

describe("deep-linking", function() {

  const RokuTest = require('roku-test');
  const ip = require('ip');
  const fs = require('fs');
  const testAppName = 'dev';  // this will be 'dev' for sideloaded channels
  const channelZipFile = __dirname + '/../build/tubitv_roku.zip'

  beforeAll(function(done) {
    this.device = new RokuTest(process.env.ROKU_DEV_TARGET, process.env.DEV_PASSWORD, RokuTest.SG);

    this.launchChannel = function(args) {
      // helper to start the channel
      console.log('Returning home');
      this.device.press(RokuTest.HOME);
      this.device.delay(1000);
      console.log('Launching channel');
      this.device.launchWithArgs(testAppName, args);
      this.device.delay(1000);
    }

    console.log(">> Installing test channel");
    device.install(fs.createReadStream(channelZipFile));
    this.device.press(RokuTest.HOME);
    this.device.delay(1000);
    done();
  });

  afterAll(function() {
    this.device.destroyDebug();
  });

  afterEach(function() {
    // whether tests pass or fail, we don't want callbacks hanging around
    this.device.removeAllListeners('debugData');
    // exit the channel
    this.device.press(RokuTest.HOME);
  });

  ///////////////////////
  // Tests
  ///////////////////////

  it("should accept deep link parameters", function(done) {
    var mainConsole = new RokuTest(process.env.ROKU_DEV_TARGET, process.env.DEV_PASSWORD, RokuTest.MAIN);
    var contentIdReceived = false;
    var mediaTypeReceived = false;
    var sourceReceived = false;
    
    mainConsole.on('debugData', function(data) {
      log = data.toString();
      if (log.match('mediaType =') !== null) {
        mediaTypeReceived = true;
      } else if (log.match('contentId =') !== null) {
        contentIdReceived = true;
      } else if (log.match('source =') !== null) {
        sourceReceived = true;
      }
      if (mediaTypeReceived && contentIdReceived && sourceReceived) {
        done();
      }
    }); 
    this.launchChannel({
      contentId: "123456",
      mediaType: "movie",
      source: "meta-search"
    });
  });
  
  
  /*
   * CONTENT ID: 01079
   * Title: Crash
   * Type: Series
   *
   * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=1079&MediaType=series"
   *
   */
  it("should show detail screen for series", function(done) {
    var contentId = "1079";
    this.device.on('debugData', function(data) {
      if (data.toString().match('TEST: Deep link contentId = ' + contentId) !== null) {
        done();
      }
    }); 
    this.launchChannel({
      contentId: contentId,
      mediaType: "series",
      source: "meta-search"
    });
  });

  
  /*
   * CONTENT ID: 321221
   * Title: We Are Young
   * Type: Movie
   *
   * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=321221&MediaType=movie"
   *
   */
  
   
  it("should show detail screen for movie", function(done) {
    var contentId = "321221";
    this.device.on('debugData', function(data) {
      if (data.toString().match('TEST: Deep link contentId = ' + contentId) !== null) {
        done();
      }
    }); 
    this.launchChannel({
      contentId: contentId,
      mediaType: "movie",
      source: "meta-search"
    });
  });
  
  
  /*
   * CONTENT ID: 302800
   * Title: S02:E05 - You, I'll Be Following
   * Type: Episode
   *
   * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=302800&MediaType=episode"
   */
  it("should show detail screen with correct episode", function(done) {
    var contentId = "302800";
    this.device.on('debugData', function(data) {
      if (data.toString().match('TEST: Deep link contentId = ' + contentId) !== null) {
        done();
      }
    }); 
    this.launchChannel({
      contentId: contentId,
      mediaType: "episode",
      source: "meta-search"
    });
  });
  
});
