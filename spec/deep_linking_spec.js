jasmine.DEFAULT_TIMEOUT_INTERVAL = 20000;

var RokuTest = require('roku-test');
var ip = require('ip');
var fs = require('fs');

var device = new RokuTest(process.env.ROKU_DEV_TARGET, process.env.DEV_PASSWORD, RokuTest.SG);
var testAppName = 'dev';  // this will be 'dev' for sideloaded channels
var channelZipFile = __dirname + '/../build/tubitv_roku.zip'

function launchChannel(args) {
  console.log('Returning home');
  device.press(RokuTest.HOME);
  device.delay(1000);
  console.log('Launching channel');
  device.launchWithArgs(testAppName, args);
  device.delay(1000);
}

describe("deep-linking", function() {

  beforeAll(function(done) {
    console.log(">> Installing test channel");
    device.install(fs.createReadStream(channelZipFile));
    done();
  });

  afterAll(function() {
    device.destroyDebug();
  });

  afterEach(function() {
    // whether tests pass or fail, we don't want callbacks hanging around
    device.removeAllListeners('debugData');
    // exit the channel
    device.press(RokuTest.HOME);
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
    launchChannel({
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
    device.on('debugData', function(data) {
      if (data.toString().match('Deep link contentId = ' + contentId) !== null) {
        done();
      }
    }); 
    launchChannel({
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
    device.on('debugData', function(data) {
      if (data.toString().match('Deep link contentId = ' + contentId) !== null) {
        done();
      }
    }); 
    launchChannel({
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
    var contentId = "321221";
    device.on('debugData', function(data) {
      if (data.toString().match('Deep link contentId = ' + contentId) !== null) {
        done();
      }
    }); 
    launchChannel({
      contentId: contentId,
      mediaType: "episode",
      source: "meta-search"
    });
  });
  
});
