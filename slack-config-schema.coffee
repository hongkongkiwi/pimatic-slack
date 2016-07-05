module.exports = {
  title: "Slack Plugin Config Options"
  type: "object"
  required: ["apiKey"]
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
    apiKey:
      description: "Slack API Key"
      type: "string"
      default: ""
    channelId:
      description: "Action messages are posted here unless a channel is specified in the action. If this is empty, the bot will not post in any channel"
      type: "string"
      default: ""
    username:
      description: "What username we should post as"
      type: "string"
      default: ""
    userIconUrl:
      description: "URL to an image to use as the icon for this message. "
      type: "string"
      default: ""
    userIconEmoji:
      description: "emoji to use as the icon for this message. Overrides userIconUrl"
      type: "string"
      default: ""
}
