###
YOI
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <javi@tapquo.org> || @soyjavi

@namespace    lib/zenproxy
###
"use strict"

# Libraries
http      = require "http"
httpProxy = require "http-proxy"

# Configuration

ZenProxy =

  run: (callback) ->
    console.log "It's ok from zenproxy"


    # -- TEST.1 -> Basic proxy -------------------------------------------------
    proxy = httpProxy.createProxyServer({target:'http://localhost:8000'}).listen(9000)
    proxy.on "error", (err, req, res) ->
      res.writeHead 500, "Content-Type": "text/plain"
      res.end "Something went wrong. And we are reporting a custom error message."
      return


    # -- TEST.2 -> Delay proxies -----------------------------------------------
    proxyRandom = httpProxy.createProxyServer({target:'http://localhost:8001'}).listen(9001)
    # Random NODEJS servers (from :8001 to :8010)
    port = 8000
    for i in [1..10]
      port++
      do =>
        http.createServer((req, res) ->
          setTimeout ->
            console.log req.connection.server.domain, req.connection.server._connectionKey
            res.writeHead 200, "Content-Type": "text/plain"
            res.write "request successfully proxied!" + "\n" + JSON.stringify(req.headers, true, 2)
            res.end()
          , 500
          return
        ).listen port


    # -- TEST.3 -> Machine Balancer --------------------------------------------
    proxyBalancer = httpProxy.createProxyServer (req, res, proxy) ->
      target =
        host: 'localhost'
        port: 8002
      proxy.proxyBalancer req, res, target
    proxyBalancer.on "proxyRes", (res) ->
      console.log('RAW Response from the target', JSON.stringify(res.headers, true, 2))
    proxyBalancer.listen 9002


module.exports = ZenProxy
