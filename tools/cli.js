#!/usr/bin/env node

'use strict';
const build = require('./lib/build');
const config = require('./lib/config');
const network = require('./lib/network');
const program = require('commander');

program.version('0.1.0');

/*
 * Right now configuration are read from config files. Later we
 * should read configuration from database.
 */
program
  .command('create-settings <env> <filename>')
  .description('create roku configuration files')
  .action((env, filename) => {
    build.createSettings(env, filename);
  });

program
  .command('create-manifest <env> <filename> <manifestname>')
  .description('create roku manifest file')
  .action((env, filename, manifestname) => {
    build.createManifest(env, filename, manifestname)
  });

program
  .command('create-hotpatch <env>')
  .description('create hotpatch files')
  .action((env) => {
    build.createHotpatch(env)
  });

program
  .command('upload <pkgfile> <address> <password>')
  .description('upload image file to address')
  .action((pkgfile, address, password) => {
    network.keypress('home', address, password).then(() => {
      console.log('Uploading %s to %s...', pkgfile, address);
      network.uploadPkg(pkgfile, address, password).then(data => {
        console.log('Upload %s to %s successfully.', pkgfile, address);
      }).catch(err => {
        console.log(err);
      });
    });
  });

program
  .command('sign-package <address> <dev_password> <sign_password> <appname> <outputpath>')
  .description('sign and download pkg file')
  .action((address, devPassword, signPassword, appName, pkgPath) => {
    network.signPkg(address, devPassword, signPassword, appName, pkgPath).then(path => {
      console.log("Signed package at %s.", path);
    }).catch(err => {
      console.log(err);
    });
  });

program
  .command('discover')
  .description('find roku device')
  .action(() => {
    network.autoDiscover().subscribe(
      data => console.log(`Found roku device: USN ${data.USN}, IP ${data.address}`),
      err => console.log(err)
    )
    console.log('Press Ctrl+C to stop auto discovery.');
  });

program
  .command('increment-build-number')
  .description('bump the build number for a release')
  .action(() => {
    config.incrementBuildNumber()
  });

program
  .command('get-build-tag <is_minor> <is_dot>')
  .description('dump a git-friendly version number to use as a tag')
  .action((isMinor, isDot) => {
    console.log(config.getBuildTag(isMinor, isDot));
  });

program
  .command('host-components <zippath> <port>')
  .description('set up a temporary service that will return the externally loaded components')
  .action((zippath, port) => {
    network.hostComponents(zippath, port)
  });

program
  .command('zip-files <dir_path>')
  .description('zip the contents of a directory')
  .action((dir_path) => {
    build.zipDir(dir_path);
  });

program.parse(process.argv);
