"use strict"

# Libraries
childProcess  = require "child_process"
colors        = require "colors"
fs            = require "fs"
http          = require "http"
https         = require "https"
Table         = require "cli-table"

fileServe     = require "./zenproxy.fileserve"
PATH          = __dirname + "/../../../.."

ZenProxy =

  addHost: (rule_name, address, port) ->
    for rule in global.config.rules when rule.name is rule_name
      rule.hosts.push
        address: address
        port   : port
      @summary "Added " + "#{address}:#{port}".green + " to rule " + "#{rule.name}".green
      break

  removeHost: (rule_name, address, port) ->
    for rule, index in global.config.rules when rule.name is rule_name
      for host, index in rule.hosts when host.address is address and host.port is port
        rule.hosts.splice(index, 1)
        @summary "Remove " + "#{address}:#{port}".red + " to rule " + "#{rule.name}".red
        break
      break

  run: ->
    @summary "Starting..."
    do @blockPorts
    queries = {}

    if global.config.http
      global.config.http = global.config.http or 80
      http.createServer((request, response) ->
        __zen request, response
      ).listen global.config.http

    if global.config.https
      global.config.https = global.config.https or 443
      certificates = __dirname + "/../../../certificates/"
      options =
        key   : fs.readFileSync("#{certificates}key.pem")
        cert  : fs.readFileSync("#{certificates}cert.pem")
      https.createServer(options, (request, response) ->
        __zen request, response
      ).listen global.config.https

    __zen = (request, response) ->
      url   = "#{request.headers.host}#{request.url}"
      index = queries[url]
      rule  = if index >= 0 then global.config.rules[index] else __getRule url

      if rule
        statics = false
        if rule.statics?
          statics = __serveStatic request, response, rule

        unless statics
          if rule.strategy is "random"
            host = rule.hosts[Math.floor Math.random() * (rule.hosts.length)]
          else if rule.strategy is "roundrobin"
            host = rule.hosts.shift()
            rule.hosts.push host
          __proxyRequest request, response, rule, host.address, host.port
      else
        console.log "[", "#{request.method}".red, "]", "#{request.headers.host + request.url}".grey
        response.writeHead 200, "Content-Type": "text/html"
        response.write "<h1>ZENproxy</h1>"
        response.end()

    __serveStatic = (request, response, rule) ->
      served = false
      for policy in rule.statics #when request.url is rule.query + policy.url
        folder_query = "#{rule.query}#{policy.url}"
        if request.url.lastIndexOf(folder_query) is 0
          statics = true
          resource = request.url.replace(folder_query, "")
          fileServe response, "#{PATH}#{policy.folder}/#{resource}", policy.maxage
          break
      served

    __getRule = (url) ->
      for rule, index in global.config.rules when rule.domain? and rule.query?
        port = if global.config.http is 80 then "" else ":#{global.config.http}"
        if rule.https
          port = if global.config.https is 443 then "" else ":#{global.config.https}"
        regexQuery = new RegExp "#{rule.domain}#{port}#{rule.query}"
        if url.match regexQuery
          queries[url] = index
          return rule

    __proxyRequest = (request, response, rule, address, port = 80) ->
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
        ms = (new Date() - now)
        console.log "[", request.method.grey, "#{res.statusCode} ]"
                  , "[", "#{ms}ms".green, "]"
                  , "#{rule.name + request.url} ->".grey, "#{address}:#{port}"
        response.statusCode = res.statusCode
        response.setHeader key, value for key, value of res.headers
        res.pipe response, end: true

      proxy.on "error", (error) ->
        console.log "ZENproxy (error): #{error}"

      request.pipe proxy, end: true

  blockPorts: ->
    for rule in global.config.rules
      for host in rule.hosts when host.block is true
        childProcess.exec "iptables -A INPUT -p tcp --dport #{host.port} -j DROP"

  summary: (message) ->
    table = new Table head: ["ZENproxy".green + " v0.09.09".grey + " - #{message}"], colWidths: [80]
    console.log table.toString()
    table = new Table
      head      : ["Rule".grey, "Strategy".grey, "domain".grey, "query".grey, "servers".grey]
      colWidths : [12, 12, 12, 20, 20]

    for rule in global.config.rules
      hosts = ""
      hosts += "#{host.address}:#{host.port}\n" for host in rule.hosts
      table.push [rule.name, rule.strategy, rule.domain, rule.query, hosts]
    console.log(table.toString())

module.exports = ZenProxy
