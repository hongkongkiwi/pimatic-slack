# #TTS Plugin

# This is an plugin to read text to speech from the audio speaker

# ##The plugin code
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  #util = env.require 'util'
  os = require 'os'
  M = env.matcher

  slack = require 'slack'
  # ###Play class
  class SlackPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, @config) =>

      @bot = slack.rtm.client()
      token = @config.apiKey

      @bot.message(message =>
        console.log(`Got a message: ${message}`)
        #bot.close()
      )

      @bot.listen({token})

      @framework.ruleManager.addActionProvider(new SlackActionProvider @framework, @config)

  # Create a instance of my plugin
  plugin = new SlackPlugin

  class SlackActionProvider extends env.actions.ActionProvider

    constructor: (@framework, @config) ->
      return

    parseAction: (input, context) =>
      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      textTokens = strToTokens ""

      setText = (m, tokens) => textTokens = tokens

      m = M(input, context)
        .match(['slack '])
        .match(['post ','write ','output ','say '], optional: yes)
        .matchStringWithVars(setText)

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(textTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SlackActionHandler(
            @framework, textTokens
          )
        }

  plugin.SlackActionProvider = SlackActionProvider

  class SlackActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @textTokens) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
      ]).then( ([text]) =>
        return new Promise((resolve, reject) ->
          if simulate
            return resolve(__("Would Post to Slack '#{text}'"))
          else
            __("Posted to Slack '#{text}'")
        )
      )

  plugin.SlackActionHandler = SlackActionHandler

  # and return it to the framework.
  return plugin
