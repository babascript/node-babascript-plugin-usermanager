(function() {
  var EventEmitter, LindaSocketIOClient, SocketIOClient, UserManager, request, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  request = require('request');

  EventEmitter = require("events").EventEmitter;

  _ = require('lodash');

  SocketIOClient = require("socket.io-client");

  LindaSocketIOClient = require("linda-socket.io").Client;

  module.exports = UserManager = (function() {
    var User, Users;

    function UserManager(api) {
      var socket;
      this.api = api || "http://manager-api.babascript.org";
      socket = SocketIOClient.connect(this.api);
      this.linda = new LindaSocketIOClient().connect(socket);
    }

    UserManager.prototype.start = function(baba, next) {
      var name;
      this.parent = baba;
      name = baba.id;
      baba.data.users = new Users();
      return request("" + this.api + "/api/group/" + name + "/member", (function(_this) {
        return function(err, res, body) {
          var d, data, i, options, st, sts, user, _i, _j, _len, _len1, _ref;
          if (!err && res.statusCode === 200) {
            data = JSON.parse(body);
            sts = [];
            _ref = baba.sts;
            for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
              st = _ref[i];
              baba.sts.splice(i, 1);
            }
            for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
              d = data[_j];
              baba.sts.push(baba.linda.tuplespace(d.username));
              user = new User(_this.linda);
              user.__syncStart({
                username: d.username,
                attribute: d.attribute
              });
              baba.data.users.add(user);
            }
            return setTimeout(function() {
              return next();
            }, 100);
          } else {
            name = name.split("::");
            options = {
              url: "" + _this.api + "/api/users",
              form: {
                names: name
              },
              json: true
            };
            return request.get(options, function(err, res, body) {
              var _k, _len2;
              if (res.statusCode === 200) {
                baba.sts = [];
                for (_k = 0, _len2 = body.length; _k < _len2; _k++) {
                  data = body[_k];
                  baba.sts.push(baba.linda.tuplespace(data.username));
                  user = new User(_this.linda);
                  user.__syncStart({
                    username: data.username,
                    attribute: data.attribute
                  });
                  baba.data.users.add(user);
                }
              }
              return setTimeout(function() {
                return next();
              }, 100);
            });
          }
        };
      })(this));
    };

    Users = (function() {
      function Users() {}

      Users.prototype.data = [];

      Users.prototype.add = function(attribute) {
        if (!attribute) {
          return;
        }
        return this.data.push(attribute);
      };

      Users.prototype.get = function(name) {
        var d, _i, _len, _ref;
        _ref = this.data;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          if (d.name === name) {
            return d;
          }
        }
        return null;
      };

      Users.prototype.remove = function(name) {
        var d, i, _i, _len, _ref;
        _ref = this.data;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          d = _ref[i];
          if ((d != null) && d.name === name) {
            this.data.splice(i, 1);
          }
        }
        return null;
      };

      return Users;

    })();

    User = (function(_super) {
      __extends(User, _super);

      User.prototype.data = {};

      User.prototype.isSyncable = false;

      function User(linda) {
        this.linda = linda;
        this.sync = __bind(this.sync, this);
        User.__super__.constructor.call(this);
      }

      User.prototype.get = function(key) {
        if (key == null) {
          return;
        }
        return this.data[key];
      };

      User.prototype.__syncStart = function(_data) {
        var key, value, __data, _ref;
        if (_data == null) {
          return;
        }
        this.name = _data.username;
        __data = null;
        _ref = _data.attribute;
        for (key in _ref) {
          value = _ref[key];
          if (this.get(key) == null) {
            this.set(key, value);
          } else {
            if (__data == null) {
              __data = {};
            }
            __data[key] = value;
          }
        }
        this.isSyncable = true;
        this.emit("get_data", this.data);
        this.ts = this.linda.tuplespace(this.name);
        this.ts.watch({
          type: 'userdata'
        }, (function(_this) {
          return function(err, result) {
            var username, v, _ref1;
            if (err) {
              return;
            }
            _ref1 = result.data, key = _ref1.key, value = _ref1.value, username = _ref1.username;
            if (username === _this.name) {
              v = _this.get(key);
              if (v !== value) {
                _this.set(key, value, {
                  sync: false
                });
                return _this.emit("change_data", _this.data);
              }
            }
          };
        })(this));
        if (__data != null) {
          for (key in __data) {
            value = __data[key];
            this.sync(key, value);
          }
          return __data = null;
        }
      };

      User.prototype.sync = function(key, value) {
        return this.ts.write({
          type: 'update',
          key: key,
          value: value
        });
      };

      User.prototype.set = function(key, value, options) {
        if (options == null) {
          options = {
            sync: false
          };
        }
        if ((key == null) || (value == null)) {
          return;
        }
        if ((options != null ? options.sync : void 0) === true && this.isSyncable === true) {
          if (this.get(key) !== value) {
            return this.sync(key, value);
          }
        } else {
          return this.data[key] = value;
        }
      };

      return User;

    })(EventEmitter);

    return UserManager;

  })();

}).call(this);
