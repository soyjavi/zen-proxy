var http = require('http');
var hyperquest = require('hyperquest');

for (var i = 0; i < 100; i++) {
    // hyperquest('http://localhost:8888/random');

    options = {
        hostname: "localhost",
        port    : 8888,
        path    : "/roundrobin",
        method  : "GET"
    };
    // http.request(options);
    hyperquest('http://localhost:8888/roundrobin');
};
process.stdout.setMaxListeners(0);
