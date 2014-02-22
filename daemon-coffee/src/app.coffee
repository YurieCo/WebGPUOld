
_ = require 'underscore'
express = require 'express'
fs = require 'fs.extra'
path = require 'path'
config = require './config'
control = require './control'
compile_run = require './compile_run'
data_processor = require './data_processor'
broadcast = (require './broadcast').broadcast
register = (require './broadcast').register
Logger = require('bunyan')


app = express()
address = null

ring_buffer = new Logger.RingBuffer limit: 200
logger = new Logger {
  name: 'wbDaemon',
  streams: [
    {
      stream: process.stdout,
      level: 'debug'
    },
    {
      path: config.log_file_path,
      level: 'trace'
    },
    {
        type: 'raw',
        stream: ring_buffer,
        level: 'trace'
    }
  ],
  serializers:
    req: Logger.stdSerializers.req,
    res: Logger.stdSerializers.res
}

app.configure () ->
    app.set 'port', config.port
    app.use express.methodOverride()
    app.use express.bodyParser()
    app.use express.errorHandler {
        dumpExceptions: true,
        showStack: true
    }
    app.use app.router

app.configure 'development', () ->
  app.use express.errorHandler({dumpExceptions: true, showStack: true })

app.configure 'production', () ->
  app.use express.errorHandler()

app.get '/stop', (req, res) ->
    control.stop {
        request: req,
        result: res,
        logger: logger
    }

app.get '/clear_tmp', (req, res) ->
    clear_tmp {
            request: req,
            result: res,
            logger: logger
        },
        (err, params) ->
            if err
                res.send 500, 'unable to clear temporary files'
            else
                res.send {
                    status: 'success'
                }

app.get '/status', (req, res) ->
    res.send {
        current_process_count: compile_run.current_process_count(),
        number_processes: compile_run.served_processes(),
        address: address.address,
        port: address.port,
        log: ring_buffer.records
    }

app.get '/log', (req, res) ->
    res.send ring_buffer.records

app.get '/busy', (req, res) ->
    res.send (compile_run.current_process_count() >= config.max_processes)

mp_config_cache = {}

has_mp_config = (mp_id) ->
    if mp_config_cache[mp_id]?
        return true
    else
        mp_config_file = path.join config.mp_dir, mp_id, 'config.txt'
        if fs.existsSync mp_config_file
            data = fs.readFileSync mp_config_file, 'ascii'
            mp_config_cache[mp_id] = JSON.parse data
            return true
        else
            return false

get_mp_config = (mp_id) ->
    if mp_config_cache[mp_id]?
        return mp_config_cache[mp_id]
    else
        mp_config_file = path.join config.mp_dir, mp_id, 'config.txt'
        if fs.existsSync mp_config_file
            data = fs.readFileSync config_file, 'ascii'
            mp_config_cache[mp_id] = JSON.parse data
            return mp_config_cache[mp_id]
        else
            return {}

dataset_exists_cache = {}

has_mp_data = (mp_id, dataset_id) ->
    if dataset_exists_cache[mp_id]? and dataset_exists_cache[mp_id][dataset_id]
        true
    else
        if !dataset_exists_cache[mp_id]?
            dataset_exists_cache[mp_id] = {}
        mp_config = get_mp_config mp_id
        if _.isEmpty mp_config.data
            res = true
        else
            res = data_processor.has_data mp_id, mp_config.data[dataset_id], dataset_id
        dataset_exists_cache[mp_id][dataset_id] = res
        res

has_all_mp_data = (mp_id) ->
    if dataset_exists_cache[mp_id]?
        return true
    else
        required_datasets = mp_config_cache[mp_id].data
        required_datasets_length = required_datasets.length
        existsQ = _.all (_.range required_datasets.length), (dataset_id) -> return has_mp_data mp_id, dataset_id
        if existsQ
            return true
        else
            return false

app.post '/mp/submit/:id', (req, res) ->
    # console.log 'Submitting program'
    mp_id = req.params.id
    data_id = parseInt req.body.data_id
    program = req.body.program
    if (has_mp_config mp_id) and (has_mp_data mp_id, data_id)
        compile_run.compile_run.start {
            status: 'success',
            request: req,
            response: res,
            mp_id: mp_id,
            data_id: data_id,
            program: program,
            mp_config: (get_mp_config mp_id),
            mode: req.body.mode
        }
    else if !(has_mp_config mp_id)
        console.log 'missing config for mp' + mp_id
        res.send {
            status: 'missing config'
        }
    else
        console.log 'missing dataset for mp' + mp_id
        res.send {
            status: 'missing dataset'
        }

app.post '/mp/config/:id', (req, res) ->
    mp_id = req.params.id
    body = req.body

    dir = path.join config.mp_dir, mp_id
    config_file = path.join dir, 'config.txt'

    if !fs.existsSync dir
        fs.mkdirRecursiveSync dir

    try
        json = JSON.parse body
    catch e
        json = body
    

    mp_config_cache[mp_id] = json

    fs.writeFile config_file, (JSON.stringify json), 'ascii', (err) ->
        if err
            console.log 'unable to write config file for mp' + mp_id
            res.send 500, 'unable to open config file'
        else
            console.log 'wrote config file for mp' + mp_id
            res.send true


app.post '/mp/data', (req, res) ->
    body = req.body
    mp_id = body.mp
    file = body.file.split('/')

    dir = path.join config.mp_dir, '' + mp_id, 'data', file[0]
    file_path = path.join dir, file[1]
    
    if !fs.existsSync dir
        fs.mkdirRecursiveSync dir

    fs.writeFile file_path, body.data, 'ascii', (err) ->
        if err
            console.log 'unable to write data file ' + file_path + ' for mp' + mp_id
            res.send 500, 'unable to write data file'
        else
            console.log 'wrote config data file ' + file.join("/") + ' for mp' + mp_id
            res.send true

has_data_cache = {}

app.get '/mp/has_data', (req, res) ->
    body = req.body
    mp_id = body.mp
    file = body.file

    if has_data_cache[mp_id] and has_data_cache[mp_id][file] == true
        res.send true
    else
        dir = path.join config.mp_dir, '' + mp_id, 'data'
        file_path = path.join dir, file

        fs.exists file_path, (existsQ) ->
            if !has_data_cache[mp_id]?
                has_data_cache[mp_id] = {}
            has_data_cache[mp_id][file] = existsQ
            res.send existsQ

if !module.parent
    port = app.get 'port'
    console.log "Express server listening on port " + port
    server = app.listen port
    address = server.address()
    if address.address == '0.0.0.0'
      os = require 'os'
      ifaces = os.networkInterfaces()
      _.each ifaces, (dev, key) =>
          _.each dev, (detail) =>
              if detail.family == 'IPv4' and detail.internal == false
                  address.address = detail.address
    console.log "address = " + address.address
    broadcast address
    setInterval (() -> register address), 5000
    ((require 'look').start config.look_port, address.address)
