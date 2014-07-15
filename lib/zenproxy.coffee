###
YOI
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <javi@tapquo.org> || @soyjavi

@namespace    lib/zenproxy
###
"use strict"

# Libraries
http      = require "http"

ZenProxy =

  run: (callback) ->
    console.log "It's ok from zenproxy"

    # -- Random NODEJS servers (from :1981 to :1990) ---------------------------
    machines = []
    port = 1980
    for i in [1..10]
      port++
      machines.push "localhost:#{port}"
      http.createServer((req, res) ->
        res.writeHead 200, "Content-Type": "text/plain"
        res.write "PI: #{__estimatePi()} \n"
        res.write JSON.stringify(req.headers, true, 2)
        res.end()
        return
      ).listen port

    # -- TEST.1 -> Machine Balancer (RANDOM) -----------------------------------
    http.createServer((request, response) ->
      machine = machines[Math.floor Math.random() * (machines.length)]
      __proxyRequest request, response, machine
    ).listen 3000

    # -- TEST.2 -> Machine Balancer (ROUND-ROBIN) ------------------------------
    http.createServer((request, response) ->
      machine = machines.shift()
      __proxyRequest request, response, machine
      machines.push machine
    ).listen 3001

    # -- TEST.3 -> Machine Balancer (CPU) --------------------------------------


    __proxyRequest = (request, response, machine) ->
      machine = machine.split ":"
      options =
        hostname: machine[0]
        port    : machine[1]
        host    : "#{machine[0]}:#{machine[1]}"
        headers : request.headers
        path    : request.url
        method  : request.method

      proxy = http.request options, (res) -> res.pipe response, end: true

      request.pipe proxy, end: true


module.exports = ZenProxy


###
This function estimates pi using Monte-Carlo integration
https://en.wikipedia.org/wiki/Monte_Carlo_integration
@returns {number}
###
__estimatePi = ->
  n = 10000000
  inside = 0
  i = undefined
  x = undefined
  y = undefined
  i = 0
  while i < n
    x = Math.random()
    y = Math.random()
    inside++  if Math.sqrt(x * x + y * y) <= 1
    i++
  4 * inside / n
