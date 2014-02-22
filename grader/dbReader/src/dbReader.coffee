
mongodb = require 'mongodb'

Db = mongodb.Db
Server = mongodb.Server

# create a new database
db = new Db 'wbDB',
      (new Server 'localhost', 27017),
      {native_parser: true, w: -1, safe:false, disableDriverBSONSizeCheck: true}

process_attempt = (attempt, call_back) ->
    call_back attempt.user

read_attempts = (call_back) ->
    db.open (err, db) ->
        if err
            call_back err
        else
            collection = db.collection 'attempts'
            collection.find {"mp_id": "1", "user": {$type: 2}}, {limit: 1, skip: 1}, (err, cursor) ->
                if err
                    call_back err
                else
                    cursor.toArray (err, attempts) ->
                        if err
                            call_back err
                        else
                            attempts.forEach (attempt) ->
                                process_attempt attempt, call_back

read_attempts (msg) -> console.log msg; db.close()
