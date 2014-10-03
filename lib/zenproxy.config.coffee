"use strict"

fs            = require "fs"
yaml          = require "js-yaml"
node_package  = require "../package.json"
path          = require "path"

module.exports = do ->
  file = path.join __dirname, "../../../#{process.argv[2] or 'zen.proxy'}.yml"
  ZENproxy = yaml.safeLoad fs.readFileSync(file, "utf8")

  # -- ZEN output ------------------------------------------------------------
  process.stdout.write "\u001B[2J\u001B[0;0f"
  console.log "========================================================================"
  console.log " ZENserver v#{node_package.version}", "- #{node_package.description}".grey
  console.log " #{node_package.homepage}".grey
  console.log "========================================================================"
  for rule in ZENproxy.rules
    console.log " ✓".green, rule.name.toUpperCase(), "(#{rule.strategy})".grey, "↹".cyan, "#{rule.domain}#{rule.query}"
    for host in rule.hosts
      console.log "   ⇥".cyan, "#{host.address}:#{host.port}".grey, "#{if host.block then '(locked)' else ''}".grey

  ZENproxy.br = (heading) ->
    console.log "------------------------------------------------------------------------".grey
    console.log " ▣ #{heading}" if heading

  global.ZENproxy = ZENproxy
