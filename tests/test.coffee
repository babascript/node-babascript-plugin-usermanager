process.env.NODE_ENV = 'test'

path = require 'path'
assert = require 'assert'
Baba = require "../../node-babascript/lib/script"
Client = require "../../node-babascript-client/lib/client"
Manager = require path.resolve 'lib', "usermanager"

# server 立てて、そこをテスト対象にする
describe 'test', ->

  removeClients = []

  beforeEach (done) ->
    removeClients = []
    done()

  afterEach (done) ->
    console.log "--after each--"
    for c, i in removeClients
      if c?
        c.linda.io.disconnect()
        removeClients.splice i, 1
    console.log 'after done...'
    done()

  it 'manager group mediator', (done) ->
    baba = new Baba "sfc"
    baba.set "manager", new Manager()
    babac = new Client "baba"
    tanakac = new Client "tanaka"
    ishikawac = new Client "ishikawa"
    removeClients.push babac, tanakac, ishikawac
    babac.on "get_task", (task) ->
      console.log 'group mediator'
      console.log "get task baba"
      console.log task.cid
      @returnValue true
    tanakac.once "get_task", (task) ->
      console.log "get task tanaka"
      console.log task.cid
      @returnValue true
    ishikawac.once "get_task", (task) ->
      console.log "get task ishikawa"
      console.log task.cid
      @returnValue true

    baba.こんばんわてすと {broadcast: 3}, (result) ->
      done()

  it "manager not groups mediator", (done) ->
    space_name_baba = "baba"
    baba = new Baba space_name_baba
    baba.set "manager", new Manager()

    babac = new Client space_name_baba
    removeClients.push babac
    babac.once "get_task", (task) ->
      console.log 'not group mediator'
      console.log task
      @returnValue true

    baba.ユーザゲット {}, (result) ->
      assert.equal result.value, true
      done()

  it "manager not groups ['baba', '__yamada__']", (done) ->
    space_baba = "baba"
    space_yamada = "__yamada__"
    member = new Baba [space_baba, space_yamada]
    member.set "manager", new Manager()

    babac = new Client space_baba
    babac.once "get_task",(result) ->
      console.log "not group []"
      console.log "baba"
      @returnValue true
    yamadac = new Client space_yamada
    yamadac.once "get_task",(result) ->
      console.log "yamada"
      @returnValue true

    member.ふくすうにんでてすと {broadcast: 2, timeout: 3000}, (results) ->
      console.log results
      assert.equal results.length, 1
      done()
