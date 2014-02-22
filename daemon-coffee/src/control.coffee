
fs = require 'fs.extra'
temp = require 'temp'
async = require 'async'

stop = (params) ->
	process.exit 1

clear_tmp = (params, call_back) ->
	temp.cleanup()
	dir = temp.dir
	fs.readdir dir, (err, files) ->
		if err
			call_back err, params
		else
			async files,
				  (file) -> fs.rmRecursive file if (file.indexOf config.tmpdir_prefix) != -1,
				  () ->
				  	call_back null, params


module.exports = {
	stop: stop,
	clear_tmp: clear_tmp
}


