commander   = require 'commander'
packageJSON = require './package.json'

class Command
  run: =>
    commander
      .version packageJSON.version
      .command 'make', 'make the scripts to run a flow'
      .parse process.argv

    unless commander.runningCommand
      commander.outputHelp()
      process.exit 1

(new Command()).run()
