request = require 'request'
{EventEmitter} = require("events")
_ = require 'lodash'
SocketIOClient = require "socket.io-client"
LindaSocketIOClient = require("linda-socket.io").Client

module.exports = class UserManager
  constructor: (api) ->
    @api = api || "http://manager-api.babascript.org"
    socket = SocketIOClient.connect @api
    @linda = new LindaSocketIOClient().connect socket

  start: (baba, next) ->
    @parent = baba
    name = baba.id
    baba.data.users = new Users()
    request "#{@api}/api/group/#{name}/member", (err, res, body) =>
      if !err and res.statusCode is 200
        data = JSON.parse body
        sts = []
        for st, i in baba.sts
          baba.sts.splice i, 1
        for d in data
          baba.sts.push baba.linda.tuplespace(d.username)
          user = new User @linda
          user.__syncStart
            username: d.username
            attribute: d.attribute
          baba.data.users.add user
        setTimeout ->
          next()
        , 100
      else
        name = name.split "::"
        options =
          url: "#{@api}/api/users"
          form:
            names: name
          json: true
        request.get options, (err, res, body) =>
          if res.statusCode is 200
            baba.sts = []
            for data in body
              baba.sts.push baba.linda.tuplespace(data.username)
              user = new User @linda
              user.__syncStart
                username: data.username
                attribute: data.attribute
              baba.data.users.add user
          setTimeout ->
            next()
          , 100

  class Users
    data: []
    add: (attribute) ->
      return if !attribute
      @data.push attribute

    get: (name) ->
      for d in @data
        return d if d.name is name
      return null

    remove: (name) ->
      for d, i in @data
        @data.splice i, 1 if d? and d.name is name
      return null

  class User extends EventEmitter
    data: {}
    isSyncable: false
    constructor: (@linda) ->
      super()

    get: (key) ->
      return if !key?
      return @data[key]

    __syncStart: (_data) ->
      return if !_data?
      @name = _data.username
      __data = null
      for key, value of _data.attribute
        if !@get(key)?
          @set key, value
        else
          __data = {} if !__data?
          __data[key] = value
      @isSyncable = true
      @emit "get_data", @data
      @ts = @linda.tuplespace(@name)
      @ts.watch {type: 'userdata'}, (err, result) =>
        return if err
        {key, value, username} = result.data
        if username is @name
          v = @get key
          if v isnt value
            @set key, value, {sync: false}
            @emit "change_data", @data
      if __data?
        for key, value of __data
          @sync key, value
        __data = null

    sync: (key, value) =>
      @ts.write {type: 'update', key: key, value: value}

    set: (key, value, options={sync: false}) ->
      return if !key? or !value?
      if options?.sync is true and @isSyncable is true
        if @get(key) isnt value
          @sync key, value
      else
        @data[key] = value
