const path = require('path');

/**
 * @type {import("puppeteer").Configuration}
 */
module.exports = {
  // Changes the cache location for Puppeteer to a visible directory
  cacheDirectory: path.join(__dirname, 'puppeteer-cache'),
};
