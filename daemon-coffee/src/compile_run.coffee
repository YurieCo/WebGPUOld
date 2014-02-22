

os = require 'os'
async = require 'async'
fs = require 'fs.extra'
temp = require 'temp'
path = require 'path'
bunyan = require 'bunyan'
execFile = (require 'child_process').execFile
_ = require 'underscore'
events = require 'events'
sys = require 'sys'
config = require './config'
sandbox = require './sandbox'

current_process_count = 0
served_processes = 0

compile_run = () ->
    events.EventEmitter.call this

compile_run.super_ = events.EventEmitter
compile_run.prototype = Object.create events.EventEmitter.prototype,
  constructor:
    value: compile_run,
    enumerable: false

compile_run = new compile_run()

Logger = (dir) ->
  ring_buffer = new bunyan.RingBuffer limit: 200
  log = new bunyan
    name: 'wbCUDA',
    streams: [
        path: (path.join dir, 'process.log'),
        level: 'trace'
      ,
        stream: ring_buffer,
        level: 'info',
        type: 'raw'
      
    ],
    src: true

  {
    log: log,
    ring_buffer: ring_buffer,
    id: served_processes
  }

nvvc_paths = () ->
  paths = process.env['PATH'].split ';'

  if process.platform == 'win32'
    default_envs = [
      "CUDA_PATH_V5_0",
      "CUDA_PATH_V4_2",
      "CUDA_PATH_V4_2",
      "CUDA_PATH_V4_1",
      "CUDA_PATH_V4_0",
      "CUDA_BIN_PATH",
    ]
  else
    paths.push '/usr/local/cuda/bin'
    paths.push '/opt/nvidia/cuda/bin'
    default_envs = [
      "PATH",
      "CUDA_BIN_PATH"
    ]

  default_envs.forEach (env) ->
    if process.env[env]
      paths.push process.env[env]

  paths


find_nvcc_exe = () ->
  exe = if process.platform == 'win32' then 'nvcc.exe' else 'nvcc'

  for dir in nvvc_paths()
    file = path.join dir, exe
    if fs.existsSync file
      return {exe: file, path: dir}

    file = path.join dir, 'bin', exe
    if fs.existsSync file
      return {exe: file, path: dir}

  null

if find_nvcc_exe()?
    nvcc_exe = find_nvcc_exe().exe
    nvcc_path = find_nvcc_exe().path
    if nvcc_path.indexOf('bin', nvcc_path.length - 3) != -1
        nvcc_path += '/..'
else
    nvcc_exe = null

quote = (str) -> '"' + str + '"'

compile_run.on 'respond', (self) ->
  logger = self.logger
  ring_buffer = logger.ring_buffer
  toc = process.hrtime self.tic
  # console.log 'sending compute response'
  self.response.send {
    status: 'success',
    type: 'compute',
    log: ring_buffer.records,
    elapsed_time: toc,
    process_count: current_process_count,
    created_on: new Date(),
    logger_id: logger.id
  }
  current_process_count--
  fs.rmrf self.dir, (err) => {}

compile_run.on 'respond_grades', (self) ->
  logger = self.logger
  ring_buffer = logger.ring_buffer
  toc = process.hrtime self.tic
  self.response.send {
    status: 'success',
    type: 'grades',
    log: ring_buffer.records,
    elapsed_time: toc,
    process_count: current_process_count,
    created_on: new Date(),
    logger_id: logger.id,
    grades: self.grades
  }
  current_process_count--
  fs.rmrf self.dir, (err) => {}

compile_run.on 'error', (self) ->
  logger = self.logger
  ring_buffer = logger.ring_buffer
  toc = process.hrtime self.tic
  self.response.send {
    status: 'success',
    type: 'error',
    elapsed_time: toc,
    process_count: current_process_count,
    log: ring_buffer.records,
    created_on: new Date(),
    logger_id: logger.id
  }
  current_process_count--
  fs.rmrf self.dir, (err) => {}

compile_run.on 'sandbox-error', (self) ->
  logger = self.logger
  ring_buffer = logger.ring_buffer
  toc = process.hrtime self.tic
  self.response.send {
    status: 'success',
    type: 'sandboxed',
    elapsed_time: toc,
    process_count: current_process_count,
    log: ring_buffer.records,
    created_on: new Date(),
    logger_id: logger.id
  }
  current_process_count--
  fs.rmrf self.dir, (err) => {}

run_program = (self, call_back) ->
  logger = self.logger
  dir = self.dir
  program = path.join dir, 'program'

  if self.mp_config.output_type == 'image'
    output_file_base_name = 'output.ppm'
  else
    output_file_base_name = 'output.raw'
  output_file = path.join dir, output_file_base_name
  tic = process.hrtime()
  dataset = get_dataset self, self.data_id

  # console.log [
  #     program,
  #     '-i',
  #     (dataset.input.join ','),
  #     '-o',
  #     output_file,
  #     '-e',
  #     dataset.expected_output,
  #     '-t',
  #     self.mp_config.output_type
  #   ].join ' '
  run_props = {
      'cwd': dir,
      'timeout': config.process_timeout,
  }
  if system_id == 'Linux-x86-64'
    run_props['env'] = {
        'LD_LIBRARY_PATH': dir + ":" + nvcc_path + '/lib64'
    }

  execFile program,
    [
      '-i',
      (dataset.input.join ','),
      '-o',
      output_file,
      '-e',
      dataset.expected_output,
      '-t',
      self.mp_config.output_type
    ],
    run_props,
    (err, stdout, stderr) ->
      res = {}
      toc = process.hrtime tic
      res.program_run_time = toc
      res.ProgramElapsedTime = toc
      res.ProgramStdoutOutput = stdout
      if err
        res.ProgramStderrOutput = stderr
        if err.killed
          res.ProgramKilled = true
          res.ProgramFailed ='Program was terminated based on timeout policy.'
        else if err.signal == 'SIGSYS'
          res.ProgramKilled = true
          res.ProgramFailed = 'Program was terminated based on security policy.'
        else
          res.ProgramFailed = 'Failed to run input program.'
      # program did not fail
      else
        # we use `==$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$` as seperator between the stdout
        # and the output from the timer and logger (in the future we may just write
        # the output of the logger and timer to a file.)
        tmp = stderr.split '==$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
        stderr = tmp[0]
        if (stderr.indexOf 'MEMORYERROR') != -1
          stderr = stderr.split '\n'
          stderr = _.filter stderr, (line) => (line.indexOf 'MEMORYERROR') == -1
          stderr = stderr.join '\n'
          res.ProgramKilled = true
          res.ProgramFailed = 'Program was terminated based on memory allocation policy.'
          res.ProgramStderrOutput = stderr
        else
          res.ProgramStderrOutput = stderr
          if tmp.length > 0
            try
              json = JSON.parse tmp[1]
              if _.isEmpty dataset.input
                res.Correctness = true
                res.SolutionData = {}
                res.SolutionData.InputData = []
                res.SolutionData.Stderr = stderr
                res.SolutionData.DatasetId = 'None'
                res.SolutionData.CorrectQ = true
                res.SolutionData.Message = "Solution is correct."
              else
                res.SolutionData = json.Solution
                res.SolutionData.InputData = []
                # _.each res.SolutionData.InputFiles, (file) -> 
                #  res.SolutionData.InputData.push (fs.readFileSync file, 'ascii').toString()
                # res.SolutionData.UserOutputData = (fs.readFileSync res.SolutionData.OutputFile, 'ascii').toString()
                # res.SolutionData.ExpectedOutputData = (fs.readFileSync dataset.expected_output, 'ascii').toString()
                # res.SolutionData.DatasetId = self.data_id
                res.Correctness = res.UserOutput == res.ExpectedOutput
              res.ProgramTimer = JSON.stringify json.Timer
              res.ProgramLogger = JSON.stringify json.Logger
            catch e
              {}
      call_back err, self, res


dataset_location_cache = {}

get_dataset = (self, dataset_id) ->
  mp_id = self.mp_id
  dataset_id = dataset_id.toString()
  if dataset_location_cache[mp_id]? and dataset_location_cache[mp_id][dataset_id]?
    return dataset_location_cache[mp_id][dataset_id]
  else
    dir = path.join config.mp_dir, mp_id, 'data'
    id = parseInt dataset_id
    dataset_config = self.mp_config.data[id]
    if !dataset_config
        res = {
            input: [],
            output: ""
        }
    else
        res = {
          input: (_.map dataset_config.input, (input) -> path.join dir, input),
          expected_output: (path.join dir, dataset_config.output)
        }
    if !dataset_location_cache[mp_id]?
      dataset_location_cache[mp_id] = {}
    dataset_location_cache[mp_id][dataset_id] = res
    return res

dataset_exists_cache = {}

dataset_exists = (self, dataset_id) ->
  mp_id = self.mp_id
  if dataset_exists_cache[mp_id]? and dataset_exists_cache[mp_id][dataset_id]?
    return dataset_exists_cache[mp_id][dataset_id]
  else
    dataset = get_dataset self, dataset_id 
    if id < datasets.length
      inputs_exists = _.all dataset.input, (file) -> return (path.existsSync file)
      output_exists = path.existsSync dataset.output
      if inputs_exists and output_exists
        if !dataset_exists_cache[mp_id]?
          dataset_exists_cache[mp_id] = {}
        dataset_exists_cache[mp_id][dataset_id] = true
        return true
    return false

grade_program = (self, dataset_id, prev, call_back) ->
  if dataset_exists self, dataset_id
    self.data_id = dataset_id
    run_program self, (err, self, res) ->
      next = prev
      next.push res
      grade_program self, dataset_id + 1, next, call_back
  else 
    call_back self, prev

result_is_correct = (data) ->
  data.Correctness == true

compute_correctness = (self, run_data) ->
  dataset_id = 0
  correctness = {}
  correctness_score = 0
  _.each run_data,
       (data) ->
        if result_is_correct data
          score = self.mp_config.data[dataset_id].score
          correctness[dataset_id] = score
          correctness_score += score
        dataset_id++
  {
    correctness_grade: correctness,
    correctness_score: correctness_score
  }

if !String.prototype.contains
    String.prototype.contains = (arg) ->
        !!~this.indexOf(arg)

compute_keywords = (self) ->
  program = self.program
  mp_config = self.mp_config
  if mp_config.required_key_words?
    keyword_id = 0
    keywords_grade = {}
    keywords_score = 0
    _.each mp_config.required_key_words, (key_config) ->
      key = key_config.data
      score = key_config.score
      if program.contains key
        keywords_score += score
        keywords_grade[keyword_id] = score
      keyword_id++
    return {
      keywords_grade: keywords_grade,
      keywords_score: keywords_score
    }
  else
    return null

compile_run.on 'grade-program', (self) ->
  grade_program self, 0, [], (self, run_data) ->
    self.run_data = run_data
    
    grades = compute_correctness self, run_data
    self.correctness_score = grades.correctness_score
    self.correctness_grade = grades.correctness_grade

    grades = compute_keywords self
    if grades
      self.keyword_score = grades.keyword_score
      self.keyword_grade = grades.keyword_grade

    compile_run.emit 'respond_grades', self 


compile_run.on 'run-program', (self) ->
  run_program self,
              (err, self, res) ->
                logger = self.logger
                if res.ProgramElapsedTime?
                  logger.log.info {err: 'ProgramElapsedTime'}, res.ProgramElapsedTime
                if res.ProgramStdoutOutput?
                  logger.log.info {err: 'ProgramStdoutOutput'}, res.ProgramStdoutOutput
                if res.ProgramStderrOutput?
                  logger.log.error {err: 'ProgramStderrOutput'}, res.ProgramStderrOutput
                if res.ProgramKilled?
                  logger.log.error {err: 'ProgramKilled'}, res.ProgramKilled
                if res.ProgramFailed?
                  logger.log.error {err: 'ProgramFailed'}, res.ProgramFailed
                if res.ProgramTimer?
                  logger.log.error {err: 'ProgramTimer'}, res.ProgramTimer
                if res.ProgramLogger?
                  logger.log.error {err: 'ProgramLogger'}, res.ProgramLogger
                if res.SolutionData?
                  logger.log.error {err: 'SolutionData'}, JSON.stringify res.SolutionData
                if res.Correctness?
                  logger.log.error {err: 'Correctness'}, res.Correctness
                if err
                  compile_run.emit 'error', self
                else
                  compile_run.emit 'respond', self
  

compile_run.on 'compile-program', (self) ->
  logger = self.logger
  dir = self.dir
  tic = process.hrtime()
  batch_file = self.batch_file

  execFile batch_file,
    {
      'cwd': dir,
      'timeout': config.compile_timeout
    },
    (err, stdout, stderr) ->
      toc = process.hrtime tic
      logger.log.info {err: 'CompileElapsedTime'}, toc
      logger.log.info {err: 'CompilerStdoutOutput'}, stdout
      logger.log.error {err: 'CompilerStderrOutput'}, stderr

      if err
        if err.killed
          logger.log.error {err: 'CompileFailed'}, 'Compilation was terminated based on timeout policy.'
        else
          logger.log.error {err: 'CompileFailed'}, 'Was not able to compile input program.'
        compile_run.emit 'error', self
      else if self.mode == 'grade'
        compile_run.emit 'grade-program', self
      else
        compile_run.emit 'run-program', self

getExtension = (filename) ->
  if filename == ''
    ''
  else
      ext = (path.extname filename || '').split '.';
      ext[ext.length - 1]

# **TODO:** handle more systems in the future
system_id = if process.platform == 'win32' then 'Windows-x86-64' else 'Linux-x86-64'
lib_extension = if process.platform == 'win32' then 'dll' else 'a'

get_compile_command = (self) ->
  cmd = ''
  new_line = '\n'
  logger = self.logger
  dir = self.dir
  program_file = self.program_file

  wb_dir = path.join dir, 'c-tools'
  jansson_dir = path.join dir, 'c-tools', 'jansson'

  wb_lib_name = 'wb'
  #wb_lib_name = 'lib' + wb_lib_name if system_id == 'Linux-x86-64'
  wb_lib_path = (path.join wb_dir, system_id, 'lib' + wb_lib_name + '.so')
  if system_id == 'Linux-x86-64' and (fs.existsSync wb_lib_path)
    #wb_files = path.join wb_dir, system_id, 'lib' + wb_lib_name + '.so'
    #wb_files = [wb_files]
    wb_files = ['-l' + wb_lib_name, '-L' + (path.join wb_dir, system_id)]
    if system_id == 'Linux-x86-64'
        copyfn = fs.symlink
    else
        copyfn = fs.copy
    copyfn wb_lib_path, (path.join dir, 'lib' + wb_lib_name + '.so'), (err) => console.log err if err
  else
    wb_files = fs.readdirSync wb_dir
    wb_files = _.filter wb_files, (file) -> getExtension(file) == 'cpp'
    wb_files = _.map wb_files, (file) -> path.join wb_dir, file
  
  jansson_lib_name = 'jansson.'
  jansson_lib_name = 'lib' + jansson_lib_name if system_id == 'Linux-x86-64'
  if system_id? and (fs.existsSync (path.join jansson_dir, system_id, jansson_lib_name + lib_extension))
    jansson_files = path.join jansson_dir, system_id, jansson_lib_name + lib_extension
    jansson_files = [jansson_files]
  else
    jansson_files = fs.readdirSync jansson_dir
    jansson_files = _.filter jansson_files, (file) -> getExtension(file) == 'c'
    jansson_files = _.map jansson_files, (file) -> path.join jansson_dir, file

  if process.platform == 'win32'
    new_line = '\r\n'
    # cmd += 'echo Setting Visual Studio Environment.' + new_line
    cmd += 'call \"c:\\Program Files (x86)\\Microsoft Visual Studio 10.0\\VC\\vcvarsall.bat\" amd64' + new_line
  else
    cmd += '#!/bin/sh' + new_line
    cmd += 'chmod 777 libwb.so' + new_line

  # cmd += 'echo Calling NVCC Compiler.' + new_line
  defines = ' -DWB_USE_JSON ' + '-DWB_USE_COURSERA '
  if process.platform == 'linux'
    defines += '-DWB_USE_SANDBOX ' # + '-DWB_USE_SANDBOX_DEBUG '
    defines += '-DWB_USE_CUSTOM_MALLOC '

  cmd += (quote nvcc_exe) + defines + ' -arch=sm_20 -O3 -I. ' + ' -I ' + wb_dir + ' -I ' + jansson_dir +
         ' ' + (wb_files.join ' ') + ' ' + (jansson_files.join ' ') + ' ' + program_file 

  if process.platform != 'win32'
    cmd += " -lrt -lstdc++ -lm "

  cmd += ' -o ' + 'program' + ' 2>&1' + new_line

  cmd

compile_run.on 'write-compile-command', (self) ->
  dir = self.dir
  logger = self.logger

  build_file_base_name = if process.platform == 'win32' then 'build.bat' else 'build.sh'

  file = path.join dir, build_file_base_name

  fs.open file, 'w+', (err, fd) ->
    if err
      logger.log.err 'Failed to open ' + file
      compile_run.emit 'error', self

    logger.log.info 'Opened ' + file
    
    compile_command = get_compile_command self

    buffer = new Buffer compile_command

    fs.write fd, buffer, 0, buffer.length, null, (err, written, buffer) ->
      if err
        logger.log.err 'Failed to write to ' + file
        compile_run.emit 'error', self

      logger.log.info 'Wrote ' + compile_command + ' to file ' + file

      fs.close fd, (err) ->
        if err
          logger.log.err 'Failed to close ' + file
          compile_run.emit 'error', self
        if process.platform != 'win32'
          fs.chmodSync(file, '777')
        logger.log.info 'Closed ' + file
        self.batch_file = file
        compile_run.emit 'compile-program', self

compile_run.on 'copy-support-files', (self) ->
  if system_id == 'Linux-x86-64'
      reccopyfn = fs.symlink
  else
      reccopyfn = fs.copyRecursive
  reccopyfn (path.join config.c_tools_dir), (path.join self.dir, 'c-tools'), (err) ->
    if err && err.Error
      logger.log.err {err: 'CopySupportFiles'}, 'Failed to copy support files to ' + self.dir
      compile_run.emit 'error', self
    else if self.inputs? && self.output?
      inputs_and_outputs = []
      _.each self.inputs, (ii) -> inputs_and_outputs.push ii
      inputs_and_outputs.push self.output
      if system_id == 'Linux-x86-64'
        copyfn = fs.symlink
      else
        copyfn = fs.copy
      _.each inputs_and_outputs, (file) ->
        copyfn file, path.join(self.dir, path.basename file), (err) -> null
      compile_run.emit 'write-compile-command', self
    else
      compile_run.emit 'write-compile-command', self

compile_run.on 'write-program-file', (self) ->
  dir = self.dir
  program = self.program
  logger = self.logger

  file = path.join dir, 'program.cu'
  
  console.log "Compiling new program in " + dir
          
  fs.open file, 'w+', (err, fd) ->
    if err
      logger.log.err 'Failed to open ' + file
      compile_run.emit 'error', self

    logger.log.info 'Opened ' + file
    
    buffer = new Buffer program

    fs.write fd, buffer, 0, buffer.length, null, (err, written, buffer) ->

      if err
        logger.log.err 'Failed to write to ' + file
        compile_run.emit 'error', self

      logger.log.info 'Wrote ' + program + ' to file ' + file

      fs.close fd, (err) ->
        if err
          logger.log.err 'Failed to close ' + file
          compile_run.emit 'error', self

        logger.log.info 'Closed ' + file
        self.program_file = file
        compile_run.emit 'copy-support-files', self


compile_run.on 'check-sandbox', (self) ->
  _self = self
  logger = self.logger
  program = self.program
  sandbox.allow_program program, (err, keyword) =>
    if err == null
      compile_run.emit 'write-program-file', _self
    else
      logger.log.error {err: 'SandboxedKeyword'}, keyword
      logger.log.error {err: 'Sandboxed'}, 'The keyword ' + keyword + ' is not allowed in this sandboxed environment.'
      compile_run.emit 'sandbox-error', _self


compile_run.start = (params) ->
  if nvcc_exe?
      temp.mkdir config.tmpdir_prefix, (err, dir) ->
        if !err
          current_process_count++
          served_processes++
          log = Logger dir
          compile_run.emit 'check-sandbox', {
            mp_id: params.mp_id,
            tic: process.hrtime(),
            dir: dir,
            logger: log,
            request: params.request,
            response: params.response,
            program: params.program,
            data_id: params.data_id,
            mp_config: params.mp_config,
            mode: params.mode
          }
        else
          console.log "Was not able to create temporary directory"
          process.exit 1
  else
    console.log "Was not able to find nvcc compiler"
    process.exit 1

module.exports = {
  compile_run: compile_run,
  current_process_count: () -> current_process_count,
  served_processes: () -> served_processes
}


