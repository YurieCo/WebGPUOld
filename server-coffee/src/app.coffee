# The **wbGPU app** is the main entry point to the **wbGPU** web server.


#### External Modules

# We use express along with other libraries provided by node
_ = require 'underscore'
express = require 'express'
fs = require 'fs'
path = require 'path'
flash = require 'connect-flash'
jade = require 'jade'

# We use a memory store for the session information
MemoryStore = require('connect').session.MemoryStore

# Markdown is used to convert the MPs to HTML files
markdown = (require 'node-markdown').Markdown

# config contains configurations such as the database address
# the running port, etc...
config = require './config'

# Attempts are the past attempts of the user
attempts = (require './db').AttemptsProvider

# OAuth interface
oauth = require './auth'

# The scheduler provides an address to the the next available 
# node. 
scheduler = require './scheduler'

# Login communicates with the database to handle authentication
# and sessions
login = require './login'

# Daemon is an interface to the daemon
daemon = require './daemon_interactor'

# Everything is logged via the logger
log = (require './log').log


#### Global variables

# Start the express server 
app = express()

# This server's address
address = null

# Because the login system is not setup, we are hard coding this
current_user = (req) ->
    if req.session.user_id == 'xx_test' or req.session.user_id == 'xx_guest'
        return req.session.user_id
    else if req.session.user_data?
        if _.isString req.session.user_data
            req.session.user_data = JSON.parse req.session.user_data
        return req.session.user_data.id
    else
        return "unknown_user"



#### Configuration

# Configure the server with the propper port and where the public
# directory maps to in the file system
app.configure () ->
  app.set 'port', config.port
  app.set 'view engine', 'jade'
  app.use '/public', express.static(__dirname + '/../public')
  app.set 'views', __dirname + '/../views'
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.errorHandler {
    dumpExceptions: true,
    showStack: true
  }
  app.use express.cookieParser()
  app.use express.session({
    secret: "coursera course",
    store: new MemoryStore({
      reapInterval:  60000 * 10
    })
  })
  app.use flash()
  app.locals (req, res) -> {
      session: req.session
      flash: req.flash
  }
  app.use app.router

#### Main Program

app.get '/index.html', (req, res) ->
  res.render 'index', {title: "Heterogeneous Parallel Programming"}

app.get '/', (req, res) ->
  res.redirect '/index.html'

# Checks if the cookie points to an authenticated user, otherwise
# redirect the user to the login page
is_authenticated = (req, res, next) ->
  if req.session.user_id == 'xx_test' or 
     req.session.user_id == 'xx_guest' or
     req.session.user_data?
    next()
  else
    res.redirect '/login'#,
                 #locals: {
                  #redirect: req.query.redirect or '/mp/1'
                 #}

app.get '/xx_test', (req, res) ->
  req.session.user_id = 'xx_test'
  res.redirect (req.body.redirect or '/mp/1')

app.get '/xx_guest', (req, res) ->
  req.session.user_id = 'xx_guest'
  res.redirect (req.body.redirect or '/mp/1')

# The login page contains fields for the user and password.
# These fields are validated against the login server, if valid
# then we forward the user to mp0, otherwise we show them the 
# login page again.

current_mp = 1

app.get '/login', (req, res) ->
  oauth.login req, res

app.get '/login/callback', (req, res) ->
  oauth.login_callback req, res, "/mp/0"


app.get '/plain_login', (req, res) ->
  html_path = path.join __dirname, '..', 'html', 'login.html'
  res.sendfile html_path

app.post '/plain_login', (req, res) ->
  post = req.body
  login.valid_password post.user, post.password, (err, valid) ->
    if err
      res.render '500'
    else if valid
      req.session.user_id = post.user
      res.redirect (req.body.redirect or '/mp/' + current_mp)
    else
      res.redirect '/plain_login'#,
                   #locals: {
                   # redirect: req.body.redirect
                   #}
  
# The signup page contains fields for the user and password.
app.post '/plain_signup', (req, res) ->
  post = req.body
  login.add_user post.user, post.password, (err, obj) ->
    if err
      res.render '500'
    else
      req.session.user_id = post.user
      res.redirect '/mp/' + current_mp

# The signup page contains fields for the user and password.
app.get '/plain_signup', (req, res) ->
  html_path = path.join __dirname, '..', 'html', 'signup.html'
  res.sendfile html_path

# Register slave is the entry point for the daemons to register their
# services with the server. This information is passed back to the 
# scheduler which adds them to the list of available daemons.
app.post '/register_slave', (req, res) ->
  body = req.body
  scheduler.add_daemon body.address,
                       body.port,
                       (err, data) ->
                        if err
                          console.log 'failed to register slave ' + req.body.address


app.get '/is_registered', (req, res) ->
  scheduler.has_daemon req.body.address,
                       (has_daemon) ->
                          res.send {is_registered: has_daemon}


# When I am debugging the submit functionality this is set to true.
# This variable avoids calling the daemon to perform the computation,
# instead the json response is read from a file.
i_am_debugging_submit = false

decode = (encoded) =>
  buffer = new  Buffer(encoded || '', 'base64')
  buffer.toString 'utf8'

throttle = (user, mp_id, call_back) =>
    attempts.last_attempt_date user, mp_id, call_back

enableThrottle = true

# When a user is editing text of the page, it autosaves and uses
# this method.
app.post '/mp/:id/save_program', (req, res) ->
    mp_id = parseInt req.params.id
    if mp_id > current_mp
      return 
    if req.body == null
      return 
    user = current_user req
    if user == "unknown_user"
        return
    program = req.body.Data
    if !(_.isString program)
        return
    attempts.add_attempt user,
                         mp_id,
                         {"saved_program": program},
                         (err) -> 
                            res.send {"status": "success"}


# When a user hits the compute button on the web page, they are accessing
# this method.
app.post '/mp/:id/submit', (req, res) ->
  if i_am_debugging_submit && fs.existsSync 'test_response.json'
    data = JSON.parse (fs.readFileSync 'test_response.json', 'ascii')
    res.send data 
    return
  else
    # The MP number
    mp_id = parseInt req.params.id
    if mp_id > current_mp
      res.render '404', {msg: "Invalid mp"}
      return 
    # We pass the task to the scheduler.
    if req.body == null
      res.render '404', {msg: "Server is busy"}
      return 
    else
      try
        if req.session.user_id == 'test'
          req.body = (_.keys req.body)[0]
          req.body = decode req.body
          req.body = JSON.parse req.body
          req.body.Data = decode req.body.Data
      catch e
        res.render '404', {msg: "Invalid program"}
        return

      # The dataset id
      if req.body.dataset_id?
        dataset_id = parseInt req.body.dataset_id
      else
        dataset_id = 0
      # Program data
      program = req.body.Data
    user = current_user req

    throttle user, mp_id, (err, last_submission_date) ->
      if enableThrottle and last_attempt_date? and (new Date() - last_submission_date) < 5000
        res.send {
            "Throttled"
        }
        return
      else
        attempts.add_attempt user, mp_id, {"submitted_program": program}, (err) -> {}
        if !(_.isString program) or program == ''
          res.render '404', {msg: "Invalid program"}
          return 
        scheduler.run_on_free_daemon (err, host, port) ->
            if err
              res.render '404', {msg: "Server is busy"}
              return
            # daemon compute sends the 
            do_computation = (err) ->
              if err
                res.render '500'
                return
              daemon.compute host,
                             port,
                             mp_id,
                             {
                              data_id: dataset_id,
                              program: program
                             },
                             (err, _r, body) ->
                              # When debugging we call this
                              if i_am_debugging_submit 
                                fs.writeFileSync 'test_response.json', (JSON.stringify body), 'ascii'
                              # **TODO**: Better handeling for this
                              if err
                                res.render '500'
                                return
                              else if body.status == 'success'
                                # The program text need to be stored in the database
                                body.ProgramText = program
                                # Add the attempt to the database using both the current_user and mp_id as keys
                                attempts.add_attempt user, mp_id, body, (err) -> {}
                                # Send the results to the client
                                res.send body
                              else if body.status == 'missing config'
                                # the client does not have the config needed for this mp
                                daemon.send_config host, port, mp_id, (err) ->
                                    if err?
                                      res.render '500'
                                    else
                                      do_computation()
                              else if body.status == 'missing dataset'
                                # the client does not have the data needed for this mp
                                daemon.send_data host, port, mp_id, (err) ->
                                    if err?
                                      res.render '500'
                                      return
                                    else
                                      do_computation(err)
            do_computation()



app.get '/404', (req, res) ->
  res.render '404'

app.get '/500', (req, res) ->
  res.render '500'

# The help page
app.get '/help', (req, res) ->
  res.render 'help', {title: "Help"}

app.get '/description', (req, res) ->
  # the path to the description
  file_path = path.join '..', 'mp', 'description', 'description.txt'
  if !fs.existsSync file_path
    # we need to show a nicer page eventually
    res.render '404', {msg: file_path + ' was not found'}
  else
    # read the file
    fs.readFile file_path, 'ascii', (err, data) ->
      if err
        res.render '404', {msg: 'Unable to read ' + file_path}
      else
        # use markdown to transform the file into html
        html = markdown data
        # send the html result to the client
        res.send html

app.get '/description_images/org/:file', (req, res) ->
  file = req.params.file
  # the path to the description
  file_path = path.join '..', 'mp', 'description', 'images', 'org', file
  fs.readFile file_path, 'binary', (err, data) ->
      if err
        res.render '404', {msg: 'Unable to read ' + file_path}
      else
        res.writeHead 200, {'Content-Type': 'image/png'}
        res.end data, 'binary'

app.get '/description_images/:file', (req, res) ->
  file = req.params.file
  # the path to the description
  file_path = path.join '..', 'mp', 'description', 'images', file
  fs.readFile file_path, 'binary', (err, data) ->
      if err
        res.render '404', {msg: 'Unable to read ' + file_path}
      else
        res.writeHead 200, {'Content-Type': 'image/png'}
        res.end data, 'binary'

# The MP description is the text with the instructions on what the MP does
app.get '/mp/:id/description', (req, res) ->
  # the mp number
  id = req.params.id
  # the path to the mp
  if _.isString id
    id = parseInt id
    id = "" + id
  mp_path = path.join '..', 'mp', id, 'description.txt'
  if !fs.existsSync mp_path
    # we need to show a nicer page eventually
    res.render '404', {msg: mp_path + ' was not found'}
  else
    # read the file
    fs.readFile mp_path, 'ascii', (err, data) ->
      if err
        res.render '404', {msg: 'Unable to read ' + mp_path}
      else
        # use markdown to transform the file into html
        html = markdown data
        # send the html result to the client
        res.send html

# The MP config 
app.get '/mp/:id/config', (req, res) ->
  # the mp number
  id = req.params.id
  # the path to the mp config
  if _.isString id
    id = parseInt id
    id = "" + id
  config_path = path.join '..', 'mp', id, 'config.txt'
  if !fs.existsSync config_path
    # we need to show a nicer page eventually
    res.render '404', {msg: config_path + ' was not found'}
  else
    # read the file
    fs.readFile config_path, 'ascii', (err, data) ->
      if err
        res.render '404', {msg: 'Unable to read ' + mp_path}
      else
        # send the file content to the client
        res.send (JSON.parse data)

# The MP program is the starting program that users need to modify
app.get '/mp/:id/program', is_authenticated, (req, res) ->
  # the mp number
  id = req.params.id
  user = current_user req
  if _.isString id
    id = parseInt id
    id = "" + id
  send_program_from_file = () ->
        # the path to the template program
        mp_path = path.join '..', 'mp', id, 'template_program.cu'
        if !fs.existsSync mp_path
          res.render '404', {msg: 'mp' + id + '.markdown not found'}
        else
          # read the file
          fs.readFile mp_path, 'ascii', (err, data) ->
            if err
              res.render '404', {msg: 'Unable to read mp' + id + '.markdown'}
            else
              # send the file to the client
              res.send data
  attempts.find_attempt user,
                        id,
                        (err, data) ->
                          if err or !data?
                            return send_program_from_file()
                          else
                            attempts_submitted = _.filter data.attempts, (attempt) ->
                                attempt.submitted_program? or attempt.saved_program?
                            if attempts_submitted.length == 0
                              return send_program_from_file()
                            else
                              attempt = _.last attempts_submitted
                              if attempt.saved_program?
                                program = attempt.saved_program
                              else if attempt.submitted_program? or program == ''
                                program = attempt.submitted_program
                              else
                                program = ''
                              if !program? or program == 'reset' or program == ''
                                return send_program_from_file()
                              else
                                res.send program


# The MP returns one HTML file, the HTML file has javascript
# code that determines which program and text description to
# fetch. This reduces the amount of code and avoids having to
# write templates (it also delegates some of the work to 
# the client's browser --- i.e. less load on the server).
app.get '/mp/0', is_authenticated, (req, res) ->
  user = current_user req
  if user == "unknown_user"
    res.render '404', {msg: "Invalid login. Try logging out and back in again."}
    return
  res.render 'mp0', {title: "MP 0"}

app.get '/mp/:id', is_authenticated, (req, res) ->
  mp_id = req.params.id
  if _.isString mp_id
    mp_id = parseInt mp_id
  user = current_user req
  if user == "unknown_user"
    res.render '404', {msg: "Invalid login. Try logging out and back in again."}
    return
  if mp_id < 0 or mp_id > current_mp
    res.render '404', {msg: "Invalid MP"}
  else
    res.render 'mp', {title: "MP " + req.params.id}

# The attempt count is just the number of times the user
# tried the mp. the result is a number.
app.get '/mp/:id/attempt_count', is_authenticated, (req, res) ->
  # the id of the mp
  mp_id = req.params.id
  # the current user
  user = current_user req
  # query the database
  attempts.find_attempt user,
                        mp_id,
                        (err, data) ->
                          if err
                            res.render '500'
                          else if data?
                            attempts = _.filter data.attempts, (attempt) -> attempt.ProgramText?
                            res.send attempts.length
                          else
                            res.send 0
  null

# The attempt summary is a snippet of the attempts
# the user has made for the mp. The idea is to make
# it have some information, but make it small.
app.get '/mp/:id/attempt_summary', is_authenticated, (req, res) ->
  user = current_user req
  # the id of the mp
  mp_id = req.params.id
  attempts.find_attempt user,
                        mp_id,
                        (err, data) ->
                          if err
                            res.render '500'
                          else if !data?
                            res.send []
                          else
                            # for each attempt, we reduce the data to generate a summary
                            attempts_summary = _.filter data.attempts, (attempt) ->
                                !attempt.submitted_program? and !attempt.saved_program
                            attempts_summary = _.map attempts_summary, (attempt) ->
                                # if a program failed to compile, then it does not contain the timer
                                run_time = if attempt.ProgramElapsedTime? then attempt.ProgramElapsedTime else 0
                                correct = if attempt.SolutionData? then attempt.SolutionData.CorrectQ else false
                                solution_message = if attempt.SolutionData? then attempt.SolutionData.Message else 'Failed to determine solution'
                                dataset_id = if attempt.SolutionData? then attempt.SolutionData.DatasetId else -1

                                # the summary of the attempts
                                {
                                  id: attempt.id,
                                  created_on: attempt.created_on,
                                  elapsed_time: attempt.elapsed_time,
                                  compile_failed: (_.isString attempt.CompileFailed),
                                  program_failed: (_.isString attempt.ProgramFailed),
                                  correct: correct,
                                  solution_message: solution_message,
                                  run_time: run_time
                                  dataset_id: dataset_id
                                }
                            if attempts_summary.length > 5
                              attempts_summary = attempts_summary.slice -5
                            res.send attempts_summary
  null

app.get '/mp/:id/attempt/:attempt_id', is_authenticated, (req, res) ->
  mp_id = req.params.id
  if _.isString mp_id
    mp_id = parseInt mp_id
  user = current_user req
  if user == "unknown_user"
    res.render '404', {msg: "Invalid login. Try logging out and back in again."}
    return
  if mp_id < 0 or mp_id > current_mp
    res.render '404', {msg: "Invalid MP"}
  else
    res.render 'attempt', {title: "Attempt for MP " + req.params.id}

app.get '/mp/:id/attempt_description/:attempt_id', is_authenticated, (req, res) ->
  user = current_user req
  # the id of the mp
  mp_id = req.params.id
  attempts.find_attempt user,
                        mp_id,
                        (err, data) ->
                          if err
                            res.send 500, 'Something broke!'
                          else if !data?
                            res.send undefined
                          else
                            attempt_id = parseInt req.params.attempt_id
                            # find the attempt that matches the requested id
                            attempt = _.find data.attempts, (attempt) -> attempt.id == attempt_id
                            # if it exists then we return it, otherwise we return an error
                            if attempt?
                              data = attempt.ProgramText
                              if data?
                                res.send data
                              else
                                res.send "Program not found"
                            else
                              res.send undefined
  null

# The program contains all the data stored about an attempt
# on the server.
app.get '/mp/:id/program/:attempt_id', is_authenticated, (req, res) ->
  user = current_user req
  # the id of the mp
  mp_id = req.params.id
  attempts.find_attempt user,
                        mp_id,
                        (err, data) ->
                          if err
                            res.send 500, 'Something broke!'
                          else if !data?
                            res.send undefined
                          else
                            attempt_id = parseInt req.params.attempt_id
                            # find the attempt that matches the requested id
                            attempt = _.find data.attempts, (attempt) -> attempt.id == attempt_id
                            # if it exists then we return it, otherwise we return an error
                            if attempt?
                              data = attempt.ProgramText
                              if data?
                                data = data.split("\n")
                                data = _.map data, (line) -> "\t" + line
                                data = data.join "\n"
                                # use markdown to transform the file into html
                                html = markdown data
                                # send the html result to the client
                                res.send html
                              else
                                res.send "Program not found"
                            else
                              res.send undefined
  null

# The attempt contains all the data stored about an attempt
# on the server.
app.get '/mp/:id/attempt/:attempt_id', is_authenticated, (req, res) ->
  user = current_user req
  # the id of the mp
  mp_id = req.params.id
  attempts.find_attempt user,
                        mp_id,
                        (err, data) ->
                          if err
                            res.send 500, 'Something broke!'
                          else if !data?
                            res.send undefined
                          else
                            attempt_id = parseInt req.params.attempt_id
                            # find the attempt that matches the requested id
                            attempt = _.find data.attempts, (attempt) -> attempt.id == attempt_id
                            # if it exists then we return it, otherwise we return an error
                            if attempt?
                              res.send attempt
                            else
                              res.send undefined
  null

app.get '/workers', (req, res) ->
  res.send scheduler.daemons

app.get '/worker/:host', (req, res) ->
  scheduler.worker_info req.params.host,
                 (err, info) ->
                    if err
                      res.send {}
                    else
                      res.send info

app.get '/worker/log/:host', (req, res) ->
  scheduler.worker_log req.params.host,
                       (err, info) ->
                          if err
                            res.send {}
                          else
                            res.send info

# on not-found page, show a stub page
app.use (req, res, next) ->
  res.render '404', {msg: 'Page not found'}

# on error, show a stub page
app.use (err, req, res, next) ->
  console.error err.stack
  res.render '500'

#### Start the server

address = {
    'port': (app.get 'port'),
    'address': 'localhost'
}

if !module.parent
  port = app.get 'port'
  console.log "Express server listening on port " + port
  # listen on the port set
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
  # get the address of the server and store it in the 
  # global variable
  ((require 'look').start config.look_port, address.address)
  oauth.setup address

exports.address = address

