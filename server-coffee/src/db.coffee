# This file provide methods to interact with the
# mongodb datbase. In the future, we may switch
# databases, but the methods could still be the
# same.

#### Imports

mongodb = require 'mongodb'
config = require './config'
_ = require 'underscore'

#### Globals

Db = mongodb.Db
Server = mongodb.Server

# create a new database
db = new Db config.db_name,
      new Server config.db_address, config.db_port, {auto_reconnect: true}, {}

#### Methods

# Database constructor
DbProvider = (collection_name) ->
  this.collection_name = collection_name

# Gets a collection from the database. In mongodb
# terms, collections are tables in the database.
DbProvider.prototype.get_collection = (call_back) ->
  collection_name = this.collection_name
  _get_collection = () ->
    # try to create the collection
    db.createCollection collection_name, (err, col) ->
      db.collection collection_name,
              {safe: true},
              (err, collection) ->
                if err
                  call_back err
                else
                  call_back null, collection

  # if the database is not open, then we open it.
  if db.openCalled
    _get_collection()
  else
    db.open (err, res) ->
      if err
        call_back err
      else
        console.log 'Connected to database :: ' + config.db_name
        _get_collection()
  null

# Find all returns all entries in a database
DbProvider.prototype.find_all = (call_back) ->
  this.get_collection (err, collection) ->
    if err
      call_back err
    else
      collection.find().toArray (err, res) ->
        if err
          call_back err
        else
          call_back null, res
  null

# Find all user entries in the database, this
# works on both the login and attempts collections
DbProvider.prototype.find_user = (user, call_back) ->
  this.get_collection (err, collection) ->
    if err
      call_back err
    else
      collection.findOne {user: user}, (err, result) ->
        if err || !result?
          call_back err
        else
          if result && result.length > 0
            result = result[0]
          call_back null, result
  null

# Find all attempt entries tied to an mp in the database, this
# works only on the attempts collection
DbProvider.prototype.find_attempt = (user, mp_id, call_back) ->
  this.get_collection (err, collection) ->
    if err
      call_back err
    else
      collection.findOne {user: user, mp_id: mp_id}, (err, result) ->
        if err || !result?
          call_back true
        else
          if result.length > 0
            result = result[0]
          call_back null, result
  null

# Save some information into the database
DbProvider.prototype._save = (data, call_back) ->
  this.get_collection (err, collection) ->
    if err
      call_back err
    else
      # we keep track of the time of creation
      # and time of update
      data.created_at = new Date()
      data.updated_on = new Date()
      collection.insert data,
                {safe: true},
                (err, obj) ->
                  call_back err, obj
  null

# Create a new user with specified user and hash
DbProvider.prototype.new_user = (user, hash, call_back) ->
  this._save {
      user: user,
      pass: hash
    },
    call_back

# Change the password for a user
DbProvider.prototype.update = (user, hash, call_back) ->
  this.get_collection (err, collection) ->
    if err
      call_back err
    else
      collection.update {
                user: user
                },
                {
                  $set: {
                    pass: hash,
                    # we update the `updated_on` field
                    updated_on: new Date()
                  }
                },
                {
                  safe: true
                },
                (err) ->
                  call_back err
  null

# Create an empty attempts field for this user and mp
DbProvider.prototype.new_attempt = (user, mp_id, attempt, call_back) ->
  mp_id = '' + mp_id
  this._save {
      user: user,
      mp_id: mp_id,
      attempts: [attempt]
    },
    call_back

# Add an attempt to the database. If it does not exist, then we create 
# a new attempt
DbProvider.prototype.add_attempt = (user, mp_id, attempt, call_back) ->
  mp_id = '' + mp_id
  self = this
  if user == 'test' and !attempt.submitted_program?
    attempt.ProgramText = ''
  this.find_attempt user,
            mp_id,
            (err, res) ->
              # If the user does not exist in the database, then 
              # we add a new record.
              attempt.id = res.attempts.length + 1
              if err
                self.new_attempt user,
                         mp_id,
                         attempt,
                         (err, res) ->
                          if err
                            call_back err
                          else
                            call_back null
              else
                self.get_collection (err, collection) ->
                  if err
                    call_back err
                  else
                    if attempt.saved_program?
                      update = {
                        # append the list of attempts with this
                        # attempt
                        $push: {
                          attempts: attempt
                        }
                      }
                    else if attempt.submitted_program?
                      update = {
                        # append the list of attempts with this
                        # attempt
                        $push: {
                          attempts: attempt
                        },
                        $set: {
                          # update the `updated_on` time
                          updated_on: new Date(),
                          submitted_on: new Date()
                        }
                      }
                    else
                      update = {
                        # append the list of attempts with this
                        # attempt
                        $push: {
                          attempts: attempt
                        },
                        $set: {
                          # update the `updated_on` time
                          updated_on: new Date()
                        }
                      }
                       
                    # add the attempt
                    collection.update {
                                user: user,
                                mp_id: mp_id
                              },
                              update,
                              {
                                safe: true
                              },
                              (err) ->
                                call_back err
  null

# For each attempt, perform some action
DbProvider.prototype.for_each_attempt = (user, mp_id, call_back) ->
  mp_id = '' + mp_id
  this.find_attempt user,
            mp_id,
            (err, res) ->
              if err
                call_back err
              else
                call_back null, res.attempts
  null

# For each attempt, perform some action
DbProvider.prototype.last_attempt_date = (user, mp_id, call_back) ->
  mp_id = '' + mp_id
  this.find_attempt user,
            mp_id,
            (err, res) ->
              if err
                call_back err
              else
                call_back null, res.submitted_on
  null

#### Exports

AuthProvider = new DbProvider config.db_collection_auth_name
AttemptsProvider =  new DbProvider config.db_collection_attempt_name

exports.AuthProvider = AuthProvider
exports.AttemptsProvider = AttemptsProvider


