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
  slack.chat.postMessage = Promise.promisify slack.chat.postMessage

  # ###Play class
  class SlackPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, @config) =>

      @bot = slack.rtm.client()
      @apiKey = @config.apiKey || ""
      if @apiKey is ""
        env.logging.error "No API Key Found"

      @bot.message (message) =>
        if message? and message.type is 'message' and message.subtype is not 'subtype'
          console.log JSON.stringify(message,null,2)
          console.log("Got a message: #{message.text}")
          #bot.close()

      @bot.listen({token: @apiKey})

      @framework.ruleManager.addActionProvider(new SlackActionProvider @framework, @apiKey, @config.channelId || "")

  # Create a instance of my plugin
  plugin = new SlackPlugin

  class SlackActionProvider extends env.actions.ActionProvider

    constructor: (@framework, @apiKey, @defaultChannel) ->
      return

    parseAction: (input, context) =>
      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      textTokens = strToTokens ""
      channelTokens = strToTokens @defaultChannel

      setText = (m, tokens) => textTokens = tokens
      setChannel = (m, tokens) => channelTokens = tokens

      unfurlLinks = true
      unfurlMedia = true

      m = M(input, context)
        .match(['slack '])
        .match(['post ','write ','output ','say '], optional: yes)
        .matchStringWithVars(setText)

      next = m.match(['in ',' with',' using',' on'], optional: yes)
              .match([' channel '])
              .matchStringWithVars(setChannel)
      if next.hadMatch() then m = next

      next = m.match([' ignore',' no unfurl',' do not unfurl']).match([' links'])
      if next.hadMatch()
        unfurlLinks = false
        m = next

      next = m.match([' ignore',' no unfurl',' do not unfurl']).match([' media'])
      if next.hadMatch()
        unfurlLinks = false
        m = next

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(textTokens)
        assert Array.isArray(channelTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SlackActionHandler(
            @framework, @apiKey, textTokens, channelTokens, { unfurlLinks: unfurlLinks, unfurlMedia: unfurlMedia}
          )
        }

  plugin.SlackActionProvider = SlackActionProvider

  class SlackActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @apiKey, @textTokens, @channelTokens, @options) ->
      return

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
        @framework.variableManager.evaluateStringExpression(@channelTokens)
      ]).then( ([text, channel]) =>
        return new Promise((resolve, reject) =>
          meta = {
            token: @apiKey,
            channel: channel,
            text: text
            unfurl_links: @options.unfurlLinks
            unfurl_media: @options.unfurlMedia,
          }
          if channel is ""
            return reject(__("No Channel Specified in either config or action! Ignoring"))
          if text is ""
            return reject(__("No Text Specified to post! Ignoring"))

          if simulate
            return resolve(__("Would Post to Slack '#{text}' to channel '#{channel}'"))

          return slack.chat.postMessage(meta).then((data)=>
            resolve(__("Posted to Slack '#{text}' channel '#{channel}'"))
          )
        )
      )

  plugin.SlackActionHandler = SlackActionHandler

  # and return it to the framework.
  return plugin
