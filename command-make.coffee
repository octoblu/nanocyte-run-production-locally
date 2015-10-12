_         = require 'lodash'
fs        = require 'fs-extra'
path      = require 'path'
colors    = require 'colors'
commander = require 'commander'
MeshbluHttp = require 'meshblu-http'
debug     = require('debug')('command-trace:check')

class CommandMake
  parseOptions: =>
    commander
      .version('1.0.0')
      .usage '<options> outputDirectory'
      .option '-f,--flow [flowUuid]', 'Flow ID'
      .option '-u,--user [userUuid]', 'User UUID'
      .option '-t,--token [userToken]', 'User Token'
      .option '-c,--trigger [triggerUuid]', 'Trigger Uuid (optional)'
      .parse process.argv

    @flowUuid = commander.flow
    @userUuid = commander.user
    @userToken = commander.token
    @triggerUuid = commander.trigger
    @outputDirectory = _.first commander.args

  run: =>
    @parseOptions()
    return @die new Error('Missing flowUuid') unless @flowUuid?
    return @die new Error('Missing userUuid') unless @userUuid?
    return @die new Error('Missing userToken') unless @userToken?
    return @die new Error('Missing outputDirectory') unless @outputDirectory?

    @getFlowToken =>
      @buildTemplates =>
        @writeTemplates()

  getFlowToken: (callback) =>
    meshbluHttp = new MeshbluHttp
      uuid: @userUuid
      token: @userToken

    meshbluHttp.generateAndStoreToken @flowUuid, (error, result) =>
      return @die error if error?
      @flowToken = result.token
      callback()

  buildTemplates: (callback) =>
    options =
      userUuid: @userUuid
      userToken: @userToken
      flowUuid: @flowUuid
      flowToken: @flowToken
      triggerUuid: @triggerUuid

    deployTemplate = fs.readFileSync('./templates/deploy-flow.template')
    clickTriggerTemplate = fs.readFileSync('./templates/click-trigger.template')
    @deployScript = _.template(deployTemplate) options
    @clickTriggerScript = _.template(clickTriggerTemplate) options

    callback()

  writeTemplates: =>
    dirname = path.join(__dirname, @outputDirectory)
    console.log "Saving files to #{dirname}"
    fs.mkdirpSync dirname
    deployPath = path.join(dirname, 'deploy-flow.sh')
    clickTriggerPath = path.join(dirname, 'click-trigger.sh')
    fs.writeFileSync deployPath, @deployScript
    fs.chmodSync deployPath, '777'
    fs.writeFileSync clickTriggerPath, @clickTriggerScript
    fs.chmodSync clickTriggerPath, '777'

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new CommandMake().run()
