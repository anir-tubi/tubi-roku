jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000;

const RokuTest = require('roku-test');
const ip = require('ip');
const fs = require('fs');
const localWebServer = require('local-web-server');

describe('screens', function() {

  const webServerLocation = ip.address();
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


    this.launchWebService = function(mocks) {
      var port = 8000;
      var defaultMocks = [
        // a test route that simply returns a unique string
        {   
          'route': '/cms/categories',
          'response': function(ctx) {
            ctx.status = 200;
            if (ctx.query.cat_id === undefined) {
              ctx.body = require('./categories.json');
            }
            else {
              ctx.body = require('./category_1611.json');
            }
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

describe("category_screen", function() {

  describe("fetch categories", function() {

    it("should request on launch", function(done) {
      this.listener = this.launchWebService();
      this.device.on('debugData', function(data) {
        console.log(">>> DEBUG: " + data);
        if (data.toString().match('CategoryScreen.onContentChange') !== null) {
          done();
        }
      }); 
      this.launchChannel();
    });

    it("should show error message on 404 failure", function(done) {
      var mocks = [{   
        'route': '/cms/categories',
        'response': { 'status': 404 }
      }]
      this.listener = this.launchWebService(mocks);
      this.device.on('debugData', function(data) {
        console.log(">>> DEBUG: " + data);
        if (data.toString().match('showErrorModal: code =  404') !== null) {
          done();
        }
      }); 
      this.launchChannel();
    });

    it("should show error message on 500 errors", function(done) {
      var mocks = [{   
        'route': '/cms/categories',
        'response': { 'status': 500 }
      }]
      this.listener = this.launchWebService(mocks);
      this.device.on('debugData', function(data) {
        console.log(">>> DEBUG: " + data);
        if (data.toString().match('showErrorModal: code =  500') !== null) {
          done();
        }
      }); 
      this.launchChannel();
    });
  });

  describe("fetch category content", function() {
    // This will succeed once the 'auto-focus on Featured category' branch is merged
    it("should request on launch", function(done) {
      mocks = [
        {   
          'route': '/cms/categories',
          'response': function(ctx) {
            console.log("/cms/categories called");
            ctx.status = 200;
            if (ctx.query.cat_id === undefined) {
              ctx.body = require('./categories.json');
            }
            else {
              ctx.body = require('./category_1611.json');
            }
          }
        }
      ];
      this.listener = this.launchWebService(mocks);
      this.device.on('debugData', function(data) {
        console.log(">>> DEBUG: " + data);
        if (data.toString().match('CategoryScreen.onCategoryContentReceived') !== null) {
          done();
        }
      }); 
      this.launchChannel();
   });

    it("should show error modal on 500 errors", function(done) {
      mocks = [
        {   
          'route': '/cms/categories',
          'response': function(ctx) {
            console.log("/cms/categories called");
            ctx.status = 200;
            if (ctx.query.cat_id === undefined) {
              ctx.body = require('./categories.json');
            }
            else {
              ctx.status = 500;
            }
          }
        }
      ];
      this.listener = this.launchWebService(mocks);
      this.device.on('debugData', function(data) {
        console.log(">>> DEBUG: " + data);
        if (data.toString().match('showErrorModal: code =  500') !== null) {
          done();
        }
      }); 
      this.launchChannel();
   });
  });

});


describe("detail_screen", function() {
  // disabled until the 'Feature' category focus is merged
  it("should request item details", function(done) {
    var ctx = this;
    var mocks = [
      {   
        'route': '/cms/categories',
        'response': function(ctx) {
          ctx.status = 200;
          if (ctx.query.cat_id === undefined) {
            ctx.body = require('./categories.json');
          }
          else {
            ctx.body = require('./category_1611.json');
          }
        }
      },
      {
        'route': '/cms/content',
        'response': {
          'body': require('./content_289827.json')
        }
      }
    ];
    this.listener = this.launchWebService(mocks);
    this.device.on('debugData', function(data) {
      console.log(">>> DEBUG: " + data);
      if (data.toString().match('CategoryScreen.onCategoryContentReceived') !== null) {
        // navigate to the detail screen for the first item
        ctx.device.press(RokuTest.RIGHT);
        ctx.device.delay(500);
        ctx.device.press(RokuTest.SELECT);
      }
      if (data.toString().match('DetailScreen.onContentChange') !== null) {
        done();
      }
    }); 
    this.launchChannel();
  });

  it("should show error modal on 500 errors", function(done) {
    var ctx = this;
    var mocks = [{
      'route': '/cms/content',
      'response': {
        'status': 500
      }
    }];
    this.listener = this.launchWebService(mocks);
    this.device.on('debugData', function(data) {
      console.log(">>> DEBUG: " + data);
      if (data.toString().match('CategoryScreen.onCategoryContentReceived') !== null) {
        // navigate to the detail screen for the first item
        ctx.device.press(RokuTest.RIGHT);
        ctx.device.delay(500);
        ctx.device.press(RokuTest.SELECT);
      }
      if (data.toString().match('showErrorModal: code =  500') !== null) {
        done();
      }
    }); 
    this.launchChannel();
  });

});

describe('search_screen', function() {

  const searchScreenMocks = [
      {   
        'route': '/cms/categories',
        'response': function(ctx) {
          ctx.status = 200;
          if (ctx.query.cat_id === undefined) {
            ctx.body = require('./categories.json');
          }
          else {
            ctx.body = require('./category_1611.json');
          }
        }
      },
      {
        'route': '/cms/content',
        'response': {
          'body': require('./content_289827.json')
        }
      },
      {
        // History and Queue grid content
        'route': '/cms/contents',
        'response': {
          'body': "{}"  // just make it empty for now
        }
      }
  ];

  beforeAll(function() {
    this.navigateToSearch  = function() {
      // navigate to the search screen.  if logged in, we may be up to 3 categories
      // from the top 'Search&SignIn' category
      this.device.delay(500);
      this.device.press(RokuTest.UP);
      this.device.delay(500);
      this.device.press(RokuTest.UP);
      this.device.delay(500);
      this.device.press(RokuTest.UP);
      this.device.delay(500);
      this.device.press(RokuTest.RIGHT);
      this.device.delay(500);
      this.device.press(RokuTest.SELECT);
    }

    this.enterSearchTerm = function() {
      // enter a search 'b'
      this.device.delay(500);
      this.device.press(RokuTest.DOWN);
      this.device.delay(500);
      this.device.press(RokuTest.RIGHT);
      this.device.delay(500);
      this.device.press(RokuTest.SELECT);
    }
  });

  it("should send search term", function(done) {
    var ctx = this;
    var mocks = searchScreenMocks.concat([{
      'route': '/cms/search',
      'response': {
        'body': require('./search_b.json')
      }
    }]);
    this.listener = this.launchWebService(mocks);
    this.device.on('debugData', function(data) {
      console.log(">>> DEBUG: " + data);
      if (data.toString().match('CategoryScreen.onContentChange') !== null) {
        ctx.navigateToSearch();
      }
      if (data.toString().match('SearchScreen.init') !== null) {
        ctx.enterSearchTerm();
      }
      if (data.toString().match('SearchScreen.onSearchResultsReceived') !== null) {
        done();
      }
    }); 
    this.launchChannel();
  });

  it("should show error modal on 404 errors", function(done) {
    var ctx = this;
    var mocks = searchScreenMocks.concat([{
      'route': '/cms/search',
      'response': {
        'status': 404
      }
    }]);
    this.listener = this.launchWebService(mocks);
    this.device.on('debugData', function(data) {
      console.log(">>> DEBUG: " + data);
      if (data.toString().match('CategoryScreen.onContentChange') !== null) {
        ctx.navigateToSearch();
      }
      if (data.toString().match('SearchScreen.init') !== null) {
        ctx.enterSearchTerm();
      }
      if (data.toString().match('SearchScreen.onSearchResultsReceived') !== null) {
        done();
      }
    }); 
    this.launchChannel();
  });
});  // search screen

}); // screens
