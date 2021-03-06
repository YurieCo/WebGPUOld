// Generated by CoffeeScript 1.3.3
(function() {
  var async, config, fs, has_data, path, request, _;

  fs = require('fs.extra');

  path = require('path');

  async = require('async');

  request = require('request');

  _ = require('underscore');

  config = require('./config');

  has_data = function(mp_id, conf, dataset_id) {
    var dir, files;
    dir = path.join(config.mp_dir, mp_id.toString(), 'data');
    files = [];
    _.each(conf.input, function(file) {
      return files.push(file);
    });
    files.push(conf.output);
    files = _.flatten(files);
    files = _.map(files, function(file) {
      return path.join(dir, file);
    });
    return _.all(files, function(file) {
      return fs.existsSync(file);
    });
  };

  module.exports = {
    has_data: has_data
  };

}).call(this);
