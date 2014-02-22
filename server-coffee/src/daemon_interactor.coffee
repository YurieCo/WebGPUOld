
_ = require 'underscore'
http = require 'http'
request = require 'request'
url = require 'url'
path = require 'path'
fs = require 'fs'
async = require 'async'


log = (require './log').log
config = require './config'
aws = require './aws_helper'


daemon_query = (hostname, path, options, call_back) ->
  port = if options.port? then options.port else config.aws_daemon_running_port
  method = if options.method? then options.method else 'GET'
  body = if options.body? then options.body else {}
  json = if options.json? then options.json else false
  timeout = if options.timeout? then options.timeout else 500000
 
  uri = url.format {
    protocol: 'http:',
    hostname: hostname,
    port: port,
    pathname: path,
    timeout: timeout
  }

  request {
      uri: uri,
      method: method,
      json: json,
      body: body
    },
    call_back


daemon_stop = (host, port, call_back) ->
  daemon_query host,
         '/stop',
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, res, json) ->
          call_back err, res, json


daemon_status = (host, port, call_back) ->
  daemon_query host,
         '/status',
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, _, json) ->
          call_back err, json
  

daemon_is_alive = (host, port, call_back) ->
  daemon_query host,
         '/status',
         {
          method: 'GET',
          json: true,
          port: port,
          timeout: 2000
         },
         (err, res, json) ->
          if err || !json?
            call_back false
          else
            call_back true

daemon_is_struggling = (host, port, call_back) ->
  daemon_query host,
         '/busy',
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, res, json) ->
          if err
            call_back err
          else
            call_back null, json

daemon_log = (host, port, call_back) ->
  daemon_query host,
         '/log',
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, res, json) ->
          call_back err, json

daemon_clear_tmp = (host, port, call_back) ->
  daemon_query host,
         '/clear_tmp',
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, res, json) ->
          call_back err, res, json

daemon_is_free = (host, port, call_back) ->
  daemon_query host,
         '/busy',
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, res, busyQ) ->
          if err
            call_back false
          else
            call_back !busyQ

daemon_has_config = (host, port, mp, call_back) ->
  daemon_query host,
         '/mp/has_config/' + mp,
         {
          method: 'GET',
          json: true,
          port: port
         },
         (err, res, json) ->
          call_back err, res, json

mp_config_cache = {}

read_config_into_cache = (mp, call_back) ->
  # the path to the mp config
  config_path = path.join '..', 'mp', mp.toString(), 'config.txt'
  if !fs.existsSync config_path
    call_back true
  else
    # read the file
    fs.readFile config_path, 'ascii', (err, data) ->
      if err
        call_back err
      else
        # send the file content to the client
        mp_config_data = JSON.parse data
        mp_config_cache[mp] = mp_config_data
        call_back mp_config_data

daemon_send_config = (host, port, mp, call_back) ->
  console.log 'sending mp config file for mp ' + mp + ' to ' + host + ':' + port
  send_mp_config = (data) ->
                    daemon_query host,
                                 '/mp/config/' + mp,
                                 {
                                  method: 'POST',
                                  json: true,
                                  body: data,
                                  port: port
                                 },
                                 (err, res, json) ->
                                  call_back err
  if mp_config_cache[mp]
    send_mp_config mp_config_cache[mp]
  else
    read_config_into_cache mp, (data) -> send_mp_config data
          
daemon_has_data = (host, port, mp, file, call_back) ->
  daemon_query host,
               '/mp/has_data',
               {
                method: 'GET',
                json: true,
                port: port,
                body: {
                  mp: mp,
                  file: file
                }
               },
               (err, res, json) ->
                call_back err, res, json

data_file_cache = {}

daemon_send_data = (host, port, mp, call_back) ->
  send_file = (file, body, mp) ->
    daemon_has_data host,
                    port,
                    mp,
                    file,
                    (err, res, data) ->
                      if err || data == false
                        console.log 'sending data ', file
                        daemon_query host,
                                     '/mp/data',
                                     {
                                      method: 'POST',
                                      json: true,
                                      port: port,
                                      body: {
                                        mp: mp,
                                        file: file,
                                        data: body
                                      }
                                     },
                                     (err, res, data) -> {}
  send_data = (data, mp) ->
    data_files = _.flatten [data.input, data.output]
    async.map data_files,
              (file) ->
                if data_file_cache[mp]? and data_file_cache[mp][file]?
                   return send_file file, data_file_cache[mp][file], mp
                else
                  file_path = path.join '..', 'mp', mp.toString(), 'data', file
                  if !fs.existsSync file_path
                    console.log 'file does not exist ', file_path
                  else
                    fs.readFile file_path, 'ascii', (err, data) ->
                      if err
                        console.log 'unable to read file ', file_path
                      else
                        if data_file_cache[mp]
                          data_file_cache[mp][file] = data
                        else
                          data_file_cache[mp] = {}
                          data_file_cache[mp][file] = data
                        return send_file file, data, mp
              (err, res) ->
                call_back err
  if mp_config_cache[mp]
    mp_config = mp_config_cache[mp]
    _.map mp_config.data, (data) -> send_data data, mp
  else
    console.log "MP Config ", mp, " is not in the cache."
    read_config_into_cache mp, (_) -> daemon_send_data host, port, mp, call_back

daemon_current_process_count = (host, port, call_back) ->
  daemon_query host,
         '/current_process_count',
         {
          method: 'GET',
          json: true,
          port: port,
         },
         (err, res, json) ->
          call_back err, res, json.current_process_count

# trim strips the initial and end spaces from a string
trim = (string) ->
    string.replace /^\s*|\s*$/g, ''

daemon_compute_program = (host, port, mp_id, body, call_back) ->
  console.log 'requesting computation from ' + host + ':' + port
  daemon_query host,
         '/mp/submit/' + mp_id,
         {
          method: 'POST',
          json: true,
          port: port,
          body: body
         },
         (err, res, json) ->
          if err
            call_back err, res
          else if json?
            data = {}
            log = json.log
            data.status = json.status
            if json.type == 'compute' || json.type == 'error' || json.type == 'sandboxed'
              data.id = json.id
              data.created_on = json.created_on
              data.elapsed_time = json.elapsed_time
              data.process_count = json.process_count
              process_log_element = (entry) ->
                if entry.err?
                  try
                    data[entry.err] = JSON.parse entry.msg
                  catch e
                    data[entry.err] = trim entry.msg
              process_log_element(entry) for entry in log
            call_back err, res, data
           else
            call_back err

exports.send_config = daemon_send_config
exports.send_data = daemon_send_data
exports.is_struggling = daemon_is_struggling
exports.is_alive = daemon_is_alive
exports.is_free = daemon_is_free
exports.stop = daemon_stop
exports.log = daemon_log
exports.status = daemon_status
exports.compute = daemon_compute_program

