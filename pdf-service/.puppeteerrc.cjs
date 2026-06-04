const path = require('path');

/**
 * @type {import("puppeteer").Configuration}
 */
module.exports = {
<<<<<<< HEAD
  // Changes the cache location for Puppeteer to a visible directory
  cacheDirectory: path.join(__dirname, 'puppeteer-cache'),
=======
  // Changes the cache location for Puppeteer.
  cacheDirectory: path.join(__dirname, '.cache', 'puppeteer'),
>>>>>>> 891ec1fc40e62f35f5eef65fd389acaaae846ecd
};
