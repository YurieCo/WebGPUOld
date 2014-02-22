# This file provide a basic logger used for this app


#### Imports

Logger = require 'bunyan'

config = require './config'


#### Global

ring_buffer = new Logger.RingBuffer limit: 200

#### Methods

logger = new Logger {
  name: 'wbServer',
  streams: [
  	{
      stream: process.stdout,
      level: 'debug'
    },
    {
      # the application log path is defined in 
      # the system's configuration
      path: config.app_log_file_path,
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

#### Exports

exports.log = logger
