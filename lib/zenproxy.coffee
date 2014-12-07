"use strict"

# Libraries
childProcess  = require "child_process"
colors        = require "colors"
fs            = require "fs"
path          = require "path"
http          = require "http"
https         = require "https"
url           = require "url"

ZENproxy      = require "./zenproxy.config"
fileServe     = require "./zenproxy.fileserve"

module.exports =

  start: ->
    do @blockPorts
    queries = {}

    proxy = __proxy()
    proxy.on "request", (request, response) ->
      url   = "#{request.headers.host}#{request.url}"
      index = queries[url]
      rule  = if index >= 0 then ZENproxy.rules[index] else __getRule url

      if rule
        statics = false
        (statics = __serveStatic request, response, rule)  if rule.statics?

        unless statics
          rule.strategy = "random" unless rule.strategy?
          if rule.strategy is "random"
            host = rule.hosts[Math.floor Math.random() * (rule.hosts.length)]
          else if rule.strategy is "roundrobin"
            host = rule.hosts.shift()
            rule.hosts.push host
          if rule.redirect
            __redirect request, response, rule, host.address, host.port
          else
            __request request, response, rule, host.address, host.port
      else
        console.log " ⇤ ".magenta, "#{request.method} #{request.headers.host}#{request.url}".grey
        response.writeHead 200, "Content-Type": "text/html"
        response.end "<h1>ZENproxy</h1>"

    proxy.timeout = ZENproxy.timeout if ZENproxy.timeout
    proxy.listen ZENproxy.port


    __serveStatic = (request, response, rule) ->
      served = false
      for policy in rule.statics #when request.url is rule.query + policy.url
        folder_query = path.join rule.query.toString(), policy.url.toString()
        if request.url.lastIndexOf(folder_query) is 0
          served = true
          resource = request.url.replace(folder_query, "")
          fileServe response, "#{policy.folder}#{resource}", policy.maxage
          break
      served


    __getRule = (url) ->
      for rule, index in ZENproxy.rules when rule.domain? and rule.query?
        port = if ZENproxy.port is 80 then "" else ":#{ZENproxy.port}"
        if rule.https
          port = if ZENproxy.port is 443 then "" else ":#{ZENproxy.port}"
        regexQuery = new RegExp "#{rule.domain}#{port}#{rule.query}"
        if url.match regexQuery
          queries[url] = index
          return rule


    __request = (request, response, rule, address, port = 80) ->
      part = request.headers.host.split(".")[0]
      if rule.subdomain and (rule.subdomain is "*" or rule.subdomain is part)
        request.url = "/" + part

      options =
        hostname: address
        port    : port
        headers : request.headers
        path    : request.url
        method  : request.method
        agent   : false # Turn off socket pooling

      now = new Date()
      proxy = http.request options, (res) =>
        latence = (new Date() - now)
        console.log " ⇤ ".cyan, request.method.grey, "#{rule.name}#{request.url}",
          "↹ #{res.statusCode}".cyan, "#{latence}ms",
          "⇥ ".cyan, "#{address}:#{port}".grey
        response.statusCode = res.statusCode
        response.setHeader key, value for key, value of res.headers
        res.pipe response, end: true
      proxy.on "error", (error) -> console.log "ZENproxy (error): #{error}"
      request.pipe proxy, end: true


    __redirect = (request, response, rule, address, port = 80) ->
      console.log " ⇤ ".cyan, request.method.grey, "#{rule.name}#{request.url}",
          "↹ redirect".cyan,
          "⇥ ".cyan, "#{address}:#{port}".grey
      response.writeHead 301, Location: address
      response.end()


  addHost: (rule_name, address, port) ->
    for rule in ZENproxy.rules when rule.name is rule_name
      rule.hosts.push
        address: address
        port   : port
      break


  removeHost: (rule_name, address, port) ->
    for rule, index in ZENproxy.rules when rule.name is rule_name
      for host, index in rule.hosts when host.address is address and host.port is port
        rule.hosts.splice(index, 1)
        break
      break


  blockPorts: ->
    for rule in ZENproxy.rules
      for host in rule.hosts when host.block is true
        childProcess.exec "iptables -A INPUT -p tcp --dport #{host.port} -j DROP"

# -- Private methods -----------------------------------------------------------
__proxy = ->
  if ZENproxy.protocol is "https"
    certificates = __dirname + "/../../../certificates/"
    https.createServer
      cert  : fs.readFileSync("#{certificates}#{ZENproxy.cert}")
      key   : fs.readFileSync("#{certificates}#{ZENproxy.key}")
  else
    http.createServer()
