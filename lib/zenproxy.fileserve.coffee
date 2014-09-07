"use strict"

fs            = require "fs"
path          = require 'path'
mime          = require './zenproxy.mime'

module.exports = (response, file, maxage = 60) ->
  extension = path.extname(file)?.slice(1) or "html"
  fs.readFile file, (error, data) ->
    if error
      response.writeHead 404
      response.end JSON.stringify error
    else
      response.writeHead 200,
        "Content-Type" : mime[extension]
        "Cache-Control": "max-age=#{maxage.toString()}"
      response.end data
