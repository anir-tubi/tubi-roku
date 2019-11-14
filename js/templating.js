'use strict';
const fs = require('fs');
const handlebars = require('handlebars');

// @templateSource: string, a string containing handlebar placeholders
// @values: obj, keys represent the name of the placeholders, values are what will replace the placeholders
// returns a string with the placeholders replaced
function renderTemplate(templateSource, values) {
  const template = handlebars.compile(templateSource, { noEscape: true });
  return template(values);
}

module.exports = { renderTemplate };
