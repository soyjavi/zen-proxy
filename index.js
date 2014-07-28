/*jslint node: true, indent: 4, maxlen: 80 */
/*
    YOI
    @description  Easy (but powerful) NodeJS Server
    @version      1.04.22
    @author       Javi Jimenez Villar <javi@tapquo.org> || @soyjavi
    @author       Catalina Oyaneder <catalina@tapquo.org> || @cataflu
*/
"use strict";

var CoffeeScript= require('coffee-script');
var fs          = require('fs');
var yaml        = require('js-yaml');
var path        = require('path');

// Register CoffeeScript if exits
if(CoffeeScript.register) CoffeeScript.register();

// Read config
var endpoint_path = path.join(__dirname, 'zenproxy.yml');
global.config = yaml.safeLoad(fs.readFileSync(endpoint_path, 'utf8'));

var zenproxy = require('./lib/zenproxy');
zenproxy.run()
setTimeout(function() {
  zenproxy.addHost("One", "localhost", 1986);
  zenproxy.addHost("One", "localhost", 1987);
}, 1000);
setTimeout(function() {
  zenproxy.removeHost("Two", "127.0.0.1", 1987);
  zenproxy.removeHost("Two", "localhost", 1986);
}, 2000);
