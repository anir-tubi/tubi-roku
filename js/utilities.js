'use strict';
const log = require('fancy-log');
const { spawn } = require('child_process');
const shell = require('shelljs');
shell.config.silent = true;

// provide a custom error so as to not get a full stack trace which will be misleading
// in the case that the error is not with the code, but rather with git or aws or something else.
class NoStackError extends Error {
  constructor(...params) {
    super(...params);
    this.stack = this.message;
  }
}

// @done: function, the 'done' function from gulp.
// @command: string, a command to be executed, for example "git pull origin master"
// @defaultErrorMessage: string, an error message explaining which command was not able to be completed
function execShellCommand(done, command, defaultErrorMsg) {
  log(`Performing: ${command}`);
  const commandRes = shell.exec(command);

  if (commandRes.code) {
    const errorMsg = commandRes.stderr ? commandRes.stderr : defaultErrorMsg;
    done(new NoStackError(errorMsg));
  } else {
    return commandRes.stdout;
  }
}


// Provides means to run a shell command and provide realtime feedback. Does not return any
// @done: function, the 'done' function from gulp.
// @command: string, a command to be executed, for example "git pull origin master"
// @allowNonzeroExitCode: boolean, if true we won't consider the command to have failed if a nonzero exit code is returned on close
function spawnShellCommand(done, command, allowNonzeroExitCode = false) {
  log(`Performing: ${command}`);
  return new Promise((resolve) => {
    const process = spawn(command, {stdio: 'inherit', shell: true});
    process.on('close', (code) => {
      if (code === 0 || allowNonzeroExitCode) {
        resolve(code);
      } else {
        done(new NoStackError(`failed with code ${code}: ${command}`));
      }
    });
  });
}



module.exports = {
  NoStackError,
  execShellCommand,
  spawnShellCommand
};
