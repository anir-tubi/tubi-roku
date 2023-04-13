'use strict';
const log = require('fancy-log');
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

// @command: string, a command to be executed, for example "git pull origin master"
// @defaultErrorMessage: string, an error message explaining which command was not able to be completed
// @done: function, the 'done' function from gulp.
function execShellCommand(done, command, defaultErrorMsg) {
  log(`Performing: ${command}`);
  const commandRes = shell.exec(command);

  if (commandRes.code) {
    log(defaultErrorMsg);
    const errorMsg = commandRes.stderr ? commandRes.stderr : defaultErrorMsg;
    done(new NoStackError(errorMsg));
  } else {
    return commandRes.stdout;
  }
}

module.exports = {
  NoStackError,
  execShellCommand
};
