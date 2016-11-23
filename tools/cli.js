#!/usr/bin/env node

const config = require('./lib/config');
const network = require('./lib/network');
const program = require('commander');

program.version('0.1.0');

/*
 * Right now configuration are read from config files. Later we
 * should read configuration from database.
 */
program
  .command('create-config <env> <filename>')
  .description('create roku configuration files')
  .action((env, filename) => {
    config.save(env, filename);
  });

program
  .command('create-manifest <env> <filename>')
  .description('create roku manifest file')
  .action((env, filename) => {
    config.genManifest(env, filename)
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
  .command('discover')
  .description('find roku device')
  .action(() => {
    network.autoDiscover().subscribe(
      data => console.log(`Found roku device: USN ${data.USN}, IP ${data.address}`),
      err => console.log(err)
    )
    console.log('Press Ctrl+C to stop auto discovery.');
  });
program.parse(process.argv);
