jasmine.DEFAULT_TIMEOUT_INTERVAL = 20000;

describe("deep-linking", function() {

  const RokuTest = require('roku-test');
  const ip = require('ip');
  const fs = require('fs');
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

    console.log(">> Installing test channel");
    this.device.install(fs.createReadStream(channelZipFile));
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

    /*
     * CONTENT ID: 011
     * Title: Transformers Generation 1
     * Type: Series/Season
     *
     * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=11&MediaType=series"
     *
     * NOTE:  This is not an expected combination of contentId and MediaType but we
     *        are making sure the deep link accepts it
     */
  it("should show detail screen for series content id and mediatype series", function(done) {
    var contentId = "11";
    var contentIdReceived = false;
    var mediaTypeReceived = false;
    var detailScreenReceived = false;
    this.device.on('debugData', function(data) {
      if (data.match('TEST: Deep link contentId = ' + contentId) !== null) {
        contentIdReceived = true;
      }
      // Note that 'season' gets translated to 'series' before reporting on the console
      if (data.match('TEST: Deep link type = series') !== null) {
        mediaTypeReceived = true;
      }
      if (data.match('') !== null) {
        detailScreenReceived = true;        
      }
      if (mediaTypeReceived && contentIdReceived && detailScreenReceived) {
        done();
      }
    }); 
    this.launchChannel({
      contentId: contentId,
      mediaType: "series",
      source: "meta-search"
    });
  }); 
  

  describe("should show video player", function() {
    
    beforeEach(function() {
      this.showVideoPlayerHelper = function(contentId, mediaType, done) {
        var contentIdReceived = false;
        var mediaTypeReceived = false;
        var onPlayReceived = false;
        this.device.on('debugData', function(data) {
          if (data.match('TEST: Deep link contentId = ' + contentId) !== null) {
            contentIdReceived = true;
          }
          if (data.match('TEST: Deep link type = video') !== null) {
            mediaTypeReceived = true;
          }
          if (data.match('ContentController.onPlay') !== null) {
            onPlayReceived = true;        
          }
          if (mediaTypeReceived && contentIdReceived && onPlayReceived) {
            done();
          }
        }); 
        this.launchChannel({
          contentId: contentId,
          mediaType: mediaType,
          source: "meta-search"
        });
      }
    });
    
    /*
     * CONTENT ID: 348932
     * Title: Escape Plan
     * Type: Movie
     *
     * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=348932&MediaType=movie"
     *
     */
    it("for movie", function(done) {
      this.showVideoPlayerHelper("348932", "movie", done);
    });

  
    /*
     * CONTENT ID: 111770
     * Title: Transformers Generation 1 -- S01:E01 - More Than Meets The Eye, Part 1
     * Type: Episode
     *
     * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=111770&MediaType=episode"
     */
    it("for episode", function(done) {
      this.showVideoPlayerHelper("111770", "episode", done);
    });
  
  });

    
    /*
    * CONTENT ID: 111770
    * Title: Tranformers Generation 1
    * Type: Series/Season
    *
    * curl -d '' "http://${ROKU_DEV_TARGET}:8060/launch/dev?contentID=111770&MediaType=season"
    * 
    * SEE CLIEN-1352 bug.  This combination of episode id and 'series' mediatype can come from
    *                      the Roku mobile app.
    * 
    */
  it("should show episode screeen when mediatype is season", function(done) {
    var contentId = "111770";
    var contentIdReceived = false;
    var mediaTypeReceived = false;
    var episodeScreenReceived = false;
    this.device.on('debugData', function(data) {
      if (data.match('TEST: Deep link contentId = ' + contentId) !== null) {
        contentIdReceived = true;
      }
      // Note that 'season' gets translated to 'series' before reporting on the console
      if (data.match('TEST: Deep link type = series') !== null) {
        mediaTypeReceived = true;
      }
      if (data.match('EpisodesScreen.onEpisodeSelected') !== null) {
        episodeScreenReceived = true;
      }
      if (mediaTypeReceived && contentIdReceived && episodeScreenReceived) {
        done();
      }
    });
    this.launchChannel({
      contentId: contentId,
      mediaType: "season",
      source: "meta-search"
    });
  });

});
