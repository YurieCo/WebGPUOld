# This file implements a basic scheduler so that 
# work is deligated to the propper node.


#### Imports

_ = require 'underscore'
daemon = require './daemon_interactor'

#### Globals

# the list of daemons that the scheduler knows about
daemons = {}

# the number of daemons that the schedule knows about
daemons_count = 0

#### Methods

# add a daemon, to the scheduler
add_daemon = (host, port, call_back) ->
  has_daemon host, (has_daemon) ->
    if has_daemon
      call_back true
    else
      daemon.status host,
                    port,
                    (err, status) ->
                      if err
                          call_back err
                      else
                          console.log 'Added slave node ' + host
                          daemons_count++
                          daemons[host] = status
                          call_back null, status

# Check if the daemon is alive, maybe we lost the connection.
# We want to remove it from the scheduler if it is dead.
daemon_is_alive = (host, call_back) ->
  daemon.is_alive host,
                  (err, alive, json) ->
                    if !alive
                        console.log 'deleted slave node ' + host
                        daemons_count--
                        daemons[host] = null

# Check if the daemon is free
daemon_is_free = (host, port, call_back) ->
  call_back true
  return
  daemon.is_free host,
                 port,
                 (is_free) ->
                  call_back is_free

# Are all the nodes struggling? This measure 
# is determined by the `daemon_is_struggling` method
# defined in the `daemon_interactor` file.
nodes_are_struggling = (call_back) ->
  async.map daemons,
            daemon_is_struggling,
            (results) ->
              busy_count = _.filter results, (daemon) -> daemon.busy?
              if busy_count > 0.8 * daemons_count
                call_back true
              else
                call_back false

# Remove the daemon from the daemon list.
remove_daemon = (host) ->
  if daemons[host]
    daemon.stop host, () -> {}
    daemons_count--
    daemons[host] = null

# Checks if the daemon is in the daemon list
has_daemon = (daemon_address, call_back) ->
  res = _.any daemons,
               (value, host) ->
                if host == daemon_address and daemons[host]
                  return true
                else
                  return false
  call_back res

# Run some function with `params` on a daemon
# that's free. We check if the scheduler is 
# struggling after this request and deal with
# it.
run_on_free_daemon = (call_back) ->
    called = false
    _.each daemons, (value, host) ->
        if daemons[host] && !called
            port = daemons[host].port
            daemon_is_free host,
                           port,
                           (freeQ) ->
                            if freeQ && !called
                                called = true
                                call_back null, host, port

    null

# This interacts with the AWS server and launches a new
# daemon instance. It is up to the daemon to register it
# self.
launch_daemon = (n) ->
  if !n?
    n = 1
  

# This interacts with the AWS server and kills a daemon
# by host. We make sure that the daemon is not doing any
# work before removing it.
kill_daemon = () ->

# This queries the scheduler, returning some load information
current_load = (call_back) ->


daemon_info = (host, call_back) ->
  daemon.status daemons[host].address, daemons[host].port, call_back

daemon_log = (host, call_back) ->
  daemon.log daemons[host].address, daemons[host].port, call_back

#### Exports

exports.daemons = daemons
exports.worker_info = daemon_info
exports.worker_log = daemon_log
exports.add_daemon = add_daemon
exports.has_daemon = has_daemon
exports.run_on_free_daemon = run_on_free_daemon 
