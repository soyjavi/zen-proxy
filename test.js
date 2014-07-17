var http = require('http');
var hyperquest = require('hyperquest');


for (var i = 0; i < 500; i++) {
    hyperquest('http://localhost:8888/random');
    // hyperquest('http://localhost:8888/roundrobin');
};
process.stdout.setMaxListeners(0);


