process.env.NODE_ENV = 'test'

path = require 'path'
Baba = require "../../node-babascript/lib/script"
Client = require "../../node-babascript-client/lib/client"
Manager = require path.resolve 'lib', "usermanager"
console.log Managers

baba = new Baba "baba"
baba.set "manager", new Manager()

client = new Client "baba"
client.set "manager", new Manager()

i = 1
setInterval ->
  baba.data.users.get("baba").set "__level", i, {sync: true}
  i += 1
  baba.data.users.get("baba").on "change_data", (data) ->
    console.log "change_data script"
    console.log data
  client.data.users.get("baba").on "change_data", (data) ->
    console.log "change_data client"
    console.log data
, 3000
