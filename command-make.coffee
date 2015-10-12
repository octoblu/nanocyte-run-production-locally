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

    templatePath = path.join(__dirname, 'templates')

    deployTemplate = fs.readFileSync(path.join(templatePath, 'deploy-flow.template'))
    @deployScript = _.template(deployTemplate) options

    clickTriggerTemplate = fs.readFileSync(path.join(templatePath, 'click-trigger.template'))
    @clickTriggerScript = _.template(clickTriggerTemplate) options

    onStartTemplate = fs.readFileSync(path.join(templatePath, 'on-start.template'))
    @onStartScript = _.template(onStartTemplate) options

    pulseSubscribeTemplate = fs.readFileSync(path.join(templatePath, 'pulse-subscribe.template'))
    @pulseSubscribeScript = _.template(pulseSubscribeTemplate) options

    callback()

  writeTemplates: =>
    dirname = @outputDirectory
    console.log "Saving files to #{dirname}"
    fs.mkdirpSync dirname

    deployPath = path.join(dirname, 'deploy-flow.sh')
    fs.writeFileSync deployPath, @deployScript
    fs.chmodSync deployPath, '777'

    clickTriggerPath = path.join(dirname, 'click-trigger.sh')
    fs.writeFileSync clickTriggerPath, @clickTriggerScript
    fs.chmodSync clickTriggerPath, '777'

    onStartPath = path.join(dirname, 'on-start.sh')
    fs.writeFileSync onStartPath, @onStartScript
    fs.chmodSync onStartPath, '777'

    pulseSubscribePath = path.join(dirname, 'pulse-subscribe.sh')
    fs.writeFileSync pulseSubscribePath, @pulseSubscribeScript
    fs.chmodSync pulseSubscribePath, '777'

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new CommandMake().run()
