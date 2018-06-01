(function() {
  this.LiveRecord || (this.LiveRecord = {});

}).call(this);
(function() {
  var base;

  (base = this.LiveRecord).helpers || (base.helpers = {});

}).call(this);
(function() {
  this.LiveRecord.helpers.caseConverter = {
    toCamel: function(string) {
      return string.replace(/(\-[a-z])/g, function($1) {
        return $1.toUpperCase().replace('-', '');
      });
    },
    toUnderscore: function(string) {
      return string.replace(/([A-Z])/g, function($1) {
        return "_" + $1.toLowerCase();
      });
    }
  };

}).call(this);
(function() {
  this.LiveRecord.helpers.loadRecords = function(args) {
    args['modelName'] || (function() {
      throw new Error(':modelName argument required');
    })();
    if (LiveRecord.Model.all[args['modelName']] === void 0) {
      throw new Error(':modelName is not defined in LiveRecord.Model.all');
    }
    args['url'] || (args['url'] = window.location.href);
    return $.getJSON(args['url']).done(function(data) {
      var i, len, record, record_attributes, record_or_records, records, records_attributes;
      record_or_records = void 0;
      if ($.isArray(data)) {
        records_attributes = data;
        records = [];
        for (i = 0, len = records_attributes.length; i < len; i++) {
          record_attributes = records_attributes[i];
          record = new LiveRecord.Model.all[args['modelName']](record_attributes);
          record.create();
          records.push(record);
        }
        record_or_records = records;
      } else if (data) {
        record_attributes = data;
        record = new LiveRecord.Model.all[args['modelName']](record_attributes);
        record.create();
        record_or_records = record;
      }
      if (args['onLoad']) {
        return args['onLoad'].call(this, record_or_records);
      }
    }).fail(function(jqxhr, textStatus, error) {
      if (args['onError']) {
        return args['onError'].call(this, jqxhr, textStatus, error);
      }
    });
  };

}).call(this);
(function() {
  this.LiveRecord.helpers.spaceship = function(val1, val2) {
    if (val1 === null || val2 === null || typeof val1 !== typeof val2) {
      return null;
    }
    if (typeof val1 === 'string') {
      return val1.localeCompare(val2);
    } else {
      if (val1 > val2) {
        return 1;
      } else if (val1 < val2) {
        return -1;
      }
      return 0;
    }
  };

}).call(this);
(function() {
  var base;

  (base = this.LiveRecord).Model || (base.Model = {});

}).call(this);
(function() {
  this.LiveRecord.Model.all = {};

}).call(this);
(function() {
  this.LiveRecord.Model.create = function(config) {
    var Model, callbackFunction, callbackFunctions, callbackKey, i, index, len, methodKey, methodValue, pluginKey, pluginValue, ref, ref1, ref2, ref3;
    config.modelName !== void 0 || (function() {
      throw new Error('missing :modelName argument');
    })();
    config.callbacks !== void 0 || (config.callbacks = {});
    config.plugins !== void 0 || (config.callbacks = {});
    Model = function(attributes) {
      if (attributes == null) {
        attributes = {};
      }
      this.attributes = attributes;
      Object.keys(this.attributes).forEach(function(attribute_key) {
        if (Model.prototype[attribute_key] === void 0) {
          return Model.prototype[attribute_key] = function() {
            return this.attributes[attribute_key];
          };
        }
      });
      this._callbacks = {
        'on:connect': [],
        'on:disconnect': [],
        'on:responseError': [],
        'before:create': [],
        'after:create': [],
        'before:update': [],
        'after:update': [],
        'before:destroy': [],
        'after:destroy': []
      };
      return this;
    };
    Model.modelName = config.modelName;
    Model.associations = {
      hasMany: config.hasMany,
      belongsTo: config.belongsTo
    };
    if (Model.associations.hasMany) {
      Object.keys(Model.associations.hasMany).forEach(function(key, index) {
        var associationConfig, associationName;
        associationName = key;
        associationConfig = Model.associations.hasMany[associationName];
        return Model.prototype[associationName] = function() {
          var associatedModel, associatedRecords, id, isAssociated, record, ref, self;
          self = this;
          associatedModel = LiveRecord.Model.all[associationConfig.modelName];
          if (!associatedModel) {
            throw new Error('No defined model for "' + associationConfig.modelName + '"');
          }
          associatedRecords = [];
          ref = associatedModel.all;
          for (id in ref) {
            record = ref[id];
            isAssociated = record[associationConfig.foreignKey]() === self.id();
            if (isAssociated) {
              associatedRecords.push(record);
            }
          }
          return associatedRecords;
        };
      });
    }
    if (Model.associations.belongsTo) {
      Object.keys(Model.associations.belongsTo).forEach(function(key, index) {
        var associationConfig, associationName;
        associationName = key;
        associationConfig = Model.associations.belongsTo[associationName];
        return Model.prototype[associationName] = function() {
          var associatedModel, belongsToID, self;
          self = this;
          associatedModel = LiveRecord.Model.all[associationConfig.modelName];
          if (!associatedModel) {
            throw new Error('No defined model for "' + associationConfig.modelName + '"');
          }
          belongsToID = self[associationConfig.foreignKey]();
          return associatedModel.all[belongsToID];
        };
      });
    }
    Model.all = {};
    Model.subscriptions = [];
    Model.autoload = function(config) {
      var subscription;
      if (config == null) {
        config = {};
      }
      config.callbacks || (config.callbacks = {});
      config.reload || (config.reload = false);
      if (config.callbacks.afterReload && !config.reload) {
        throw new Error('`afterReload` callback only works with `reload: true`');
      }
      subscription = App.cable.subscriptions.create({
        channel: 'LiveRecord::AutoloadsChannel',
        model_name: Model.modelName,
        where: config.where
      }, {
        connected: function() {
          if (config.reload) {
            config.reload = false;
            this.syncRecords();
          }
          if (this.liveRecord._staleSince !== void 0) {
            this.syncRecords();
          }
          if (config.callbacks['on:connect']) {
            return config.callbacks['on:connect'].call(this);
          }
        },
        disconnected: function() {
          if (!this.liveRecord._staleSince) {
            this.liveRecord._staleSince = (new Date()).toISOString();
          }
          if (config.callbacks['on:disconnect']) {
            return config.callbacks['on:disconnect'].call(this);
          }
        },
        received: function(data) {
          if (data.error) {
            if (!this.liveRecord._staleSince) {
              this.liveRecord._staleSince = (new Date()).toISOString();
            }
            return this.onError[data.error.code].call(this, data);
          } else {
            return this.onAction[data.action].call(this, data);
          }
        },
        onAction: {
          createOrUpdate: function(data) {
            var doesRecordAlreadyExist, record;
            record = Model.all[data.attributes.id];
            if (record) {
              doesRecordAlreadyExist = true;
            } else {
              record = new Model(data.attributes);
              doesRecordAlreadyExist = false;
            }
            if (config.callbacks['before:createOrUpdate']) {
              config.callbacks['before:createOrUpdate'].call(this, record);
            }
            if (doesRecordAlreadyExist) {
              record.update(data.attributes);
            } else {
              record.create();
            }
            if (config.callbacks['after:createOrUpdate']) {
              return config.callbacks['after:createOrUpdate'].call(this, record);
            }
          },
          afterReload: function(data) {
            if (config.callbacks['after:reload']) {
              return config.callbacks['after:reload'].call(this, data.recordIds);
            }
          }
        },
        onError: {
          forbidden: function(data) {
            return console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this);
          },
          bad_request: function(data) {
            return console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this);
          }
        },
        syncRecords: function() {
          this.perform('sync_records', {
            model_name: Model.modelName,
            where: config.where,
            stale_since: this.liveRecord._staleSince
          });
          return this.liveRecord._staleSince = void 0;
        }
      });
      subscription.liveRecord = {};
      subscription.liveRecord.modelName = Model.modelName;
      subscription.liveRecord.where = config.where;
      subscription.liveRecord.callbacks = config.callbacks;
      this.subscriptions.push(subscription);
      return subscription;
    };
    Model.subscribe = function(config) {
      var subscription;
      if (config == null) {
        config = {};
      }
      config.callbacks || (config.callbacks = {});
      config.reload || (config.reload = false);
      if (config.callbacks.afterReload && !config.reload) {
        throw new Error('`afterReload` callback only works with `reload: true`');
      }
      subscription = App.cable.subscriptions.create({
        channel: 'LiveRecord::PublicationsChannel',
        model_name: Model.modelName,
        where: config.where
      }, {
        connected: function() {
          if (config.reload) {
            config.reload = false;
            this.syncRecords();
          }
          if (this.liveRecord._staleSince !== void 0) {
            this.syncRecords();
          }
          if (config.callbacks['on:connect']) {
            return config.callbacks['on:connect'].call(this);
          }
        },
        disconnected: function() {
          if (!this.liveRecord._staleSince) {
            this.liveRecord._staleSince = (new Date()).toISOString();
          }
          if (config.callbacks['on:disconnect']) {
            return config.callbacks['on:disconnect'].call(this);
          }
        },
        received: function(data) {
          if (data.error) {
            if (!this.liveRecord._staleSince) {
              this.liveRecord._staleSince = (new Date()).toISOString();
            }
            return this.onError[data.error.code].call(this, data);
          } else {
            return this.onAction[data.action].call(this, data);
          }
        },
        onAction: {
          create: function(data) {
            var record;
            record = new Model(data.attributes);
            if (config.callbacks['before:create']) {
              config.callbacks['before:create'].call(this, record);
            }
            record.create();
            if (config.callbacks['after:create']) {
              return config.callbacks['after:create'].call(this, record);
            }
          },
          afterReload: function(data) {
            if (config.callbacks['after:reload']) {
              return config.callbacks['after:reload'].call(this, data.recordIds);
            }
          }
        },
        onError: {
          forbidden: function(data) {
            return console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this);
          },
          bad_request: function(data) {
            return console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this);
          }
        },
        syncRecords: function() {
          this.perform('sync_records', {
            model_name: Model.modelName,
            where: config.where,
            stale_since: this.liveRecord._staleSince
          });
          return this.liveRecord._staleSince = void 0;
        }
      });
      subscription.liveRecord = {};
      subscription.liveRecord.modelName = Model.modelName;
      subscription.liveRecord.where = config.where;
      subscription.liveRecord.callbacks = config.callbacks;
      this.subscriptions.push(subscription);
      return subscription;
    };
    Model.unsubscribe = function(subscription) {
      var index;
      index = this.subscriptions.indexOf(subscription);
      if (index === -1) {
        throw new Error('`subscription` argument does not exist in ' + this.modelName + ' subscriptions list');
      }
      App.cable.subscriptions.remove(subscription);
      this.subscriptions.splice(index, 1);
      return subscription;
    };
    ref = config.classMethods;
    for (methodKey in ref) {
      methodValue = ref[methodKey];
      if (Model[methodKey] !== void 0) {
        throw new Error('Cannot use reserved name as class method: ', methodKey);
      }
      Model[methodKey] = methodValue;
    }
    Model.prototype.subscribe = function(config) {
      var subscription;
      if (config == null) {
        config = {};
      }
      if (this.subscription !== void 0) {
        return this.subscription;
      }
      config.reload || (config.reload = false);
      subscription = App['live_record_' + this.modelName() + '_' + this.id()] = App.cable.subscriptions.create({
        channel: 'LiveRecord::ChangesChannel',
        model_name: this.modelName(),
        record_id: this.id()
      }, {
        record: function() {
          var identifier;
          if (this._record) {
            return this._record;
          }
          identifier = JSON.parse(this.identifier);
          return this._record = Model.all[identifier.record_id];
        },
        connected: function() {
          if (config.reload) {
            config.reload = false;
            this.syncRecord(this.record());
          }
          if (this.record()._staleSince !== void 0) {
            this.syncRecord(this.record());
          }
          return this.record()._callCallbacks('on:connect', void 0);
        },
        disconnected: function() {
          if (!this.record()._staleSince) {
            this.record()._staleSince = (new Date()).toISOString();
          }
          return this.record()._callCallbacks('on:disconnect', void 0);
        },
        received: function(data) {
          if (data.error) {
            if (!this.record()._staleSince) {
              this.record()._staleSince = (new Date()).toISOString();
            }
            this.onError[data.error.code].call(this, data);
            this.record()._callCallbacks('on:responseError', [data.error.code]);
            return delete this.record()['subscription'];
          } else {
            return this.onAction[data.action].call(this, data);
          }
        },
        onAction: {
          update: function(data) {
            this.record()._setChangesFrom(data.attributes);
            this.record().update(data.attributes);
            return this.record()._unsetChanges();
          },
          destroy: function(data) {
            return this.record().destroy();
          }
        },
        onError: {
          forbidden: function(data) {
            return console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this.record());
          },
          bad_request: function(data) {
            return console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this.record());
          }
        },
        syncRecord: function() {
          this.perform('sync_record', {
            model_name: this.record().modelName(),
            record_id: this.record().id(),
            stale_since: this.record()._staleSince
          });
          return this.record()._staleSince = void 0;
        }
      });
      return this.subscription = subscription;
    };
    Model.prototype.model = function() {
      return Model;
    };
    Model.prototype.modelName = function() {
      return Model.modelName;
    };
    Model.prototype.unsubscribe = function() {
      if (this.subscription === void 0) {
        return;
      }
      App.cable.subscriptions.remove(this.subscription);
      return delete this['subscription'];
    };
    Model.prototype.isSubscribed = function() {
      return this.subscription !== void 0;
    };
    Model.prototype.create = function(options) {
      if (Model.all[this.attributes.id]) {
        throw new Error(Model.modelName + '(' + this.id() + ') is already in the store');
      }
      this._callCallbacks('before:create', void 0);
      Model.all[this.attributes.id] = this;
      this.subscribe({
        reload: true
      });
      this._callCallbacks('after:create', void 0);
      return this;
    };
    Model.prototype.update = function(attributes) {
      var self;
      self = this;
      Object.keys(attributes).forEach(function(attribute_key) {
        if (Model.prototype[attribute_key] === void 0) {
          return Model.prototype[attribute_key] = function() {
            return this.attributes[attribute_key];
          };
        }
      });
      this._callCallbacks('before:update', void 0);
      Object.keys(attributes).forEach(function(attribute_key) {
        return self.attributes[attribute_key] = attributes[attribute_key];
      });
      this._callCallbacks('after:update', void 0);
      return true;
    };
    Model.prototype.destroy = function() {
      this._callCallbacks('before:destroy', void 0);
      this.unsubscribe();
      delete Model.all[this.attributes.id];
      this._callCallbacks('after:destroy', void 0);
      return this;
    };
    Model._callbacks = {
      'on:connect': [],
      'on:disconnect': [],
      'on:responseError': [],
      'before:create': [],
      'after:create': [],
      'before:update': [],
      'after:update': [],
      'before:destroy': [],
      'after:destroy': []
    };
    Model.prototype.addCallback = Model.addCallback = function(callbackKey, callbackFunction) {
      var index;
      index = this._callbacks[callbackKey].indexOf(callbackFunction);
      if (index === -1) {
        this._callbacks[callbackKey].push(callbackFunction);
        return callbackFunction;
      }
    };
    Model.prototype.removeCallback = Model.removeCallback = function(callbackKey, callbackFunction) {
      var index;
      index = this._callbacks[callbackKey].indexOf(callbackFunction);
      if (index !== -1) {
        this._callbacks[callbackKey].splice(index, 1);
        return callbackFunction;
      }
    };
    Model.prototype._callCallbacks = function(callbackKey, args) {
      var callback, i, j, len, len1, ref1, ref2, results;
      ref1 = Model._callbacks[callbackKey];
      for (i = 0, len = ref1.length; i < len; i++) {
        callback = ref1[i];
        callback.apply(this, args);
      }
      ref2 = this._callbacks[callbackKey];
      results = [];
      for (j = 0, len1 = ref2.length; j < len1; j++) {
        callback = ref2[j];
        results.push(callback.apply(this, args));
      }
      return results;
    };
    Model.prototype._setChangesFrom = function(attributes) {
      var attributeName, attributeValue, results;
      this.changes = {};
      results = [];
      for (attributeName in attributes) {
        attributeValue = attributes[attributeName];
        if (this.attributes[attributeName] !== attributeValue) {
          results.push(this.changes[attributeName] = [this.attributes[attributeName], attributeValue]);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };
    Model.prototype._unsetChanges = function() {
      return delete this['changes'];
    };
    ref1 = config.instanceMethods;
    for (methodKey in ref1) {
      methodValue = ref1[methodKey];
      if (Model.prototype[methodKey] !== void 0) {
        throw new Error('Cannot use reserved name as instance method: ', methodKey);
      }
      Model.prototype[methodKey] = methodValue;
    }
    ref2 = config.callbacks;
    for (callbackKey in ref2) {
      callbackFunctions = ref2[callbackKey];
      for (i = 0, len = callbackFunctions.length; i < len; i++) {
        callbackFunction = callbackFunctions[i];
        Model.addCallback(callbackKey, callbackFunction);
      }
    }
    ref3 = config.plugins;
    for (pluginKey in ref3) {
      pluginValue = ref3[pluginKey];
      if (LiveRecord.plugins) {
        index = Object.keys(LiveRecord.plugins).indexOf(pluginKey);
        if (index !== -1) {
          LiveRecord.plugins[pluginKey].applyToModel(Model, pluginValue);
        }
      }
    }
    LiveRecord.Model.all[config.modelName] = Model;
    return Model;
  };

}).call(this);
(function() {
  var base;

  (base = this.LiveRecord).plugins || (base.plugins = {});

}).call(this);
