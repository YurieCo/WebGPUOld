# This file allows you to use the `ssh` command from within node


exec = (require 'child_process').exec;

ssh = module.exports = {};

ssh_command = if process.platform == 'win32' then 'ssh.exe' else 'ssh'


ssh.exec = (cmd, options, cb) ->
  command = [
    ssh_command,
    '-o StrictHostKeyChecking=no',
    if options.key?  then '-i ' + options.key else '',
    '-p',
    if options.port? then options.port else '22',
    options.file,
    if options.user? options.user+'@' + options.host + ':' + options.path else options.path,
    "'" + cmd + "'"
  ]
  exec (command.join ' '), (err, stdout, stderr) ->
    if cb?
      cb err, stdout, stderr
    else if err
        throw new Error err

