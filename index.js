"use strict";

var CoffeeScript= require('coffee-script');
var fs          = require('fs');
var yaml        = require('js-yaml');
var path        = require('path');

// Register CoffeeScript if exits
if(CoffeeScript.register) CoffeeScript.register();

// Read config
var endpoint_path = path.join(__dirname, '../../zenproxy.yml');
global.config = yaml.safeLoad(fs.readFileSync(endpoint_path, 'utf8'));

module.exports = require('./lib/zenproxy');
