'use strict';
const path = require('path');
const http = require('http');
const fs = require('fs');
const request = require('request');
const Rx = require('rx');
const SSDPClient = require('node-ssdp').Client;

exports.keypress = function(key, address, password) {
  console.log("Sending keypress '" + key + "'");
  return new Promise((res, rej) => {
    const url =`http://${address}:8060/keypress/${key}`;
    const data = { };
    request.post({url: url, formData: data}, (err, response, body) => {
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
    request.post(options, (err, response, body) => {
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

    request.post(options, (err, response, body) => {
      const success = !!body ? body.match(/<font color="red">Install Success.<\/font>/) : null
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
            console.log(`Device install error: ${message}`);
            rejMessage = message
          });
        }
        else {
          console.log('Unknown install error');
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
exports.convertToSquashfs = function(zipPath, deviceIp, password) {
  return new Promise((res, rej) => {
    const url = `http://${deviceIp}/plugin_install`;

    const auth = {
      user: 'rokudev',
      pass: password,
      sendImmediately: false
    };

    const formData = {
      mysubmit: 'Convert to squashfs',
      archive: fs.createReadStream(zipPath)
    };
    const options = {
      url,
      auth,
      formData
    };

    request.post(options, (err, response, body) => {
      const success = !!body ? (body.match(/<font color="red">Install Success.<\/font>/) && body.match(/<font color="red">Conversion succeeded/)) : null
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
            console.log(`Squashfs conversion error: ${message}`);
            rejMessage = message
          });
        }
        else {
          console.log('Unknown squashfs conversion error');
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
        console.log("Got " + body.length + " bytes response");
        const url = `http://${address}/pkgs/${packages[1]}`;
        const auth = {
          user: 'rokudev',
          pass: devPassword,
          sendImmediately: false
        };
        var writePath = `${pkgPath}/${appName}.pkg`;
        request.get({url: url, auth: auth}, (err, response, body) => {
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
