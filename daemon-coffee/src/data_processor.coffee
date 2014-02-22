
fs = require 'fs.extra'
path = require 'path'
async = require 'async'
request = require 'request'
_ = require 'underscore'
config = require './config'

has_data = (mp_id, conf, dataset_id) ->
	dir = path.join config.mp_dir, mp_id.toString(), 'data'
	files = []
	_.each conf.input, (file) -> files.push file
	files.push conf.output
	files = _.flatten files
	files = _.map files, (file) -> return (path.join dir, file)
	_.all files, (file) -> fs.existsSync file

module.exports = {
	has_data: has_data
}

