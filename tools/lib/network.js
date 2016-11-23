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

/**
 * upload roku pkg to target roku box
 * @param pkgfile roku package file
 * @param address roku device IP
 * @param password roku dev user password
 */
exports.uploadPkg = function(pkgfile, address, password) {
  return new Promise((res, rej) => {
    const url =`http://${address}/plugin_install`;
    const auth = {
      user: 'rokudev',
      pass: password,
      sendImmediately: false
    };

    const data = {
      mysubmit: 'Install',
      archive: fs.createReadStream(pkgfile)
    };
    request.post({url: url, auth: auth, formData: data}, (err, response, body) => {
      if (err) {
        rej(err);
      }
      res(body);
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
