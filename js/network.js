'use strict';
const fs = require('fs');
let _request;
function request() {
  // Only want to load request when it is needed to speed up other gulp tasks
  if (!_request) {
    _request = require('request');
  }
  return _request;
}
const log = require('fancy-log');

exports.keypress = function(key, address, password) {
  log(`Sending keypress '${key}'`);
  return new Promise((res, rej) => {
    const url =`http://${address}:8060/keypress/${key}`;
    const data = {};
    request().post({url: url, formData: data}, (err, response, body) => {
      if (err) {
        rej(err);
      }
      res(body);
    });
  });
};

exports.deeplink = function(rokuAppId, address) {
  return new Promise((res, rej) => {
    const url = `http://${address}:8060/launch/${rokuAppId}`;
    const options = {
      url,
      data: {}
    };
    request().post(options, (err, response, body) => {
      if (err) {
        rej(err);
      }
      res(body);
    });
  });
}

/**
 * upload roku zip to target roku box
 * @param zipPath the file location of the zip to be uploded
 * @param address roku device IP
 * @param password roku dev user password
 */
exports.uploadPkg = function(zipPath, deviceIp, password) {
  return new Promise((res, rej) => {
    const url = `http://${deviceIp}/plugin_install`;
    const auth = {
      user: 'rokudev',
      pass: password,
      sendImmediately: false
    };
    const formData = {
      mysubmit: 'Install',
      archive: fs.createReadStream(zipPath)
    };
    const options = {
      url,
      auth,
      formData
    };

    request().post(options, (err, response, body) => {
      const success = !!body ? body.match(/<font color="red">.*Install Success.<\/font>/) : null

      if (err) {
        rej(err);
      }
      else if (response.statusCode !== 200) {
        rej(`HTTP Status code ${response.statusCode}`);
      }
      else if (success === null) {
        let errorMessages = body.match(/<font color="red">([^<]*)/);
        if (errorMessages !== null) {
          var rejMessage = '';
          errorMessages.shift()
          errorMessages.forEach((message) => {
            log(`Device install error: ${message}`);
            rejMessage = message
          });
        }
        else {
          log('Unknown install error');
        }
        rej(rejMessage);
      }
      else {
        res(body);
      }
    });
  });
};


// @zipPath: string, local path to the zip file that will be converted
// @deviceIp: string, the ip of the roku device
// @password: string, the dev password for the roku device
exports.installWithSquashfs = function(zipPath, deviceIp, password) {
  return new Promise((res, rej) => {
    const url = `http://${deviceIp}/plugin_install`;

    const auth = {
      user: 'rokudev',
      pass: password,
      sendImmediately: false
    };

    const formData = {
      mysubmit: 'Install with squashfs',
      archive: fs.createReadStream(zipPath)
    };
    const options = {
      url,
      auth,
      formData
    };

    request().post(options, (err, response, body) => {
      let success = null;
      if (!!body) {
        success = body.match(/<font color="red">.*Install Success.<\/font>/);
        if (success === null) {
          success = body.match(/<font color="red">Uninstall Success.<\/font>/);
        }
      }

      if (err) {
        rej(err);
      }
      else if (response.statusCode !== 200) {
        rej(`HTTP Status code ${response.statusCode}`);
      }
      else if (!success) {
        let errorMessages = body.match(/<font color="red">([^<]*)/);
        if (errorMessages !== null) {
          var rejMessage = '';
          errorMessages.shift()
          errorMessages.forEach((message) => {
            log(`Squashfs conversion error: ${message}`);
            rejMessage = message
          });
        }
        else {
          log('Unknown squashfs conversion error');
        }
        rej(rejMessage);
      }
      else {
        res(body);
      }
    });
  });
}


/**
 * sign and download pkg from target roku box
 *
 * @param address roku device IP
 * @param devPassword roku dev user password
 * @param signPassword genkey password for the developer id
 * @param pkgpath download path for signed pkg file
 */
exports.signPkg = function(address, devPassword, signPassword, appName, pkgPath) {
  return new Promise((res, rej) => {
    const url = `http://${address}/plugin_package`;
    const auth = {
      user: 'rokudev',
      pass: devPassword,
      sendImmediately: false
    };
    const data = {
      mysubmit: 'Package',
      app_name: `${appName}/1.0.0`,
      passwd: signPassword,
      pkg_time: '',
    };
    request.post({url: url, auth: auth, formData: data}, (err, response, body) => {
      var packages = body ? body.match(/pkgs\/\/([^\"]*)/) : '';
      if (err)
        rej(err);
      else if (response.statusCode !== 200)
        rej(`HTTP Status code ${response.statusCode}`);
      else if (packages === null) {
        rej('No downloadable packages found!');
      }
      else {
        log("Got " + body.length + " bytes response");
        const url = `http://${address}/pkgs/${packages[1]}`;
        const auth = {
          user: 'rokudev',
          pass: devPassword,
          sendImmediately: false
        };
        var writePath = `${pkgPath}/${appName}.pkg`;
        request().get({url: url, auth: auth}, (err, response, body) => {
          if (err) {
            rej(err);
          }
          res(writePath);
        }).pipe(fs.createWriteStream(writePath));
      }
    });
  });
};

/**
 * Find roku devices
 */
exports.autoDiscover = function() {
  const Rx = require('rx');
  const SSDPClient = require('node-ssdp').Client;
  return new Rx.Observable.create(observer => {
    const ssdp = new SSDPClient();
    ssdp.on('response', (headers, statusCode, rinfo) => {
      observer.onNext({
        USN: headers.USN,
        address: rinfo.address
      });
    });
    ssdp.search('roku:ecp');
  });
};
