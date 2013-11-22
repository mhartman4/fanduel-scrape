var request = require('request')
  , cheerio = require('cheerio');

var searchTerm = 'screen+scraping';
var url = 'https://www.fanduel.com/e/Game/9093?tableId=3128082';
request(url, function(err, resp, body){
  $ = cheerio.load(body);

  });
});
