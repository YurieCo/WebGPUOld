

url = require 'url'
request = require 'request'
config = require './config'

register = (address) ->
	uri = url.format
		protocol: 'http:',
		hostname: config.master_address,
		port: config.master_port,
		pathname: '/is_registered'

	request
			uri: uri,
			method: 'GET',
			json: true,
			body: {
				address: address.address
			}
		,
		(err, res, json) ->
			if err || (json? and json.is_registered == false)
				broadcast address


broadcast = (address) -> 
	uri = url.format
		protocol: 'http:',
		hostname: config.master_address,
		port: config.master_port,
		pathname: config.master_path

	body = JSON.stringify {
		"address": address.address,
		"port": address.port,
		"max_processes": config.max_processes
	}

	request
			uri: uri,
			method: 'POST',
			json: true,
			body: body
		,
		() -> {}

module.exports = {
	broadcast: broadcast,
	register: register
}
