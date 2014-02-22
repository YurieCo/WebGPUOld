# This file allows you to use the `scp` command from within node

exec = (require 'child_process').exec;

scp = module.exports = {}

scp_command = if process.platform== 'win32' then 'scp.exe' else 'scp'

scp.send = (options, cb) ->
  command = [
    scp_command,
    '-o StrictHostKeyChecking=no',
    if options.key?  then '-i ' + options.key else '',
    '-r',
    '-P',
    if options.port? then options.port else '22',
    options.file,
    if options.user? options.user+'@' + options.host + ':' + options.path else options.path,
  ]
  exec (command.join ' '), (err, stdout, stderr) ->
    if cb?
      cb err, stdout, stderr
    else if err
        throw new Error err

scp.get = (options, cb) ->
  command = [
    scp_command,
    '-o StrictHostKeyChecking=no',
    if options.key?  then '-i ' + options.key else '',
    if options.port? then options.port else '22',
    '-r',
    if options.user? options.user+'@' + options.host + ':' + options.path else options.path,
    options.path
  ]
  exec (command.join ' '), (err, stdout, stderr) ->
    if cb?
      cb err, stdout, stderr
    else if err
        throw new Error err


