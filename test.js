var http = require('http');
var hyperquest = require('hyperquest');

/* -- Random NODEJS servers (from :1981 to :1990) --------------------------- */
var delay, i, machines, port, _i;
machines = [];
port = 1980;
delay = 10;
for (i = _i = 1; _i <= 10; i = ++_i) {
  port++;
  machines.push("localhost:" + port);
  http.createServer(function(req, res) {
    setTimeout(function() {
      res.writeHead(200, {"Content-Type": "text/plain"});
      res.write(JSON.stringify(req.headers, true, 2));
      return res.end();
    }, delay);
  }).listen(port);
}

for (var i = 0; i < 5; i++) {
    hyperquest('http://localhost:8888/random');
    hyperquest('http://127.0.0.1:8888/roundrobin');
};
process.stdout.setMaxListeners(0);
