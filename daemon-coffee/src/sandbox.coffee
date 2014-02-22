

_ = require 'underscore'
SlicedBloomFilter = (require './bloom_filter').BloomFilter
sandbox_black_list = (require './sandbox_blacklist').list

boom_filter = null

build_filter = () =>
  black_list = sandbox_black_list
  boom_filter = new SlicedBloomFilter black_list.length
  _.each black_list, (keyword) =>
    boom_filter.add keyword


in_filter = (keyword) =>
  if boom_filter
    has = boom_filter.has keyword
    if has
      _.any sandbox_black_list, (elem) =>
        elem == keyword
    else
      false
  else
    true

trim = (str0) =>
  str = str0
  (str.replace /^\s\s*/, '').replace /\s\s*$/, ''

remove_special_chars = (str0) =>
  str = str0
  str.replace /[();]/, ''

normalize = (str0) =>
  str = trim str0
  str = remove_special_chars str
  str

allow_keyword = (keyword0) =>
  keyword = normalize keyword0
  if keyword == ''
    true
  else
    (in_filter keyword) == false

split_program = (prog0) =>
  prog = prog0.replace /\".*\"/, ""
  prog = prog.split "\n"
  prog = _.flatten prog
  prog = _.map prog, (line) => line.split("\r")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("\t")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split(";")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split(",")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("(")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split(")")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("[")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("]")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("*")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("\"")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split("<<<")
  prog = _.flatten(prog)
  prog = _.map prog, (line) => line.split(">>>")
  prog = _.flatten prog
  prog = _.map prog, (line) => line.split(" ")
  _.flatten prog

contains_invalid_include = (prog) =>
  prog = prog.split "\n"
  prog = _.flatten prog
  prog = _.map prog, (line) => line.split("\r")
  prog = _.flatten prog
  prog = _.map prog, (line) => trim(line)
  prog = _.flatten prog
  bad_include = null
  res = _.any prog, (line) =>
    if line.indexOf("#include") != -1
      if line.indexOf("wb.h") != -1
        return false
      else
        bad_include = line
        return true
    else
      return false
  if res
    bad_include
  else
    null


allow_program = (prog, call_back) =>
  if !prog?
    return false
  if boom_filter == null
    build_filter()
  bad_include = contains_invalid_include prog
  if bad_include
    call_back true, bad_include
  else
    keywords = split_program prog
    keyword = _.filter keywords, (keyword) => allow_keyword(keyword) == false

    if keyword.length == 0
      call_back null
    else
      call_back true, keyword[0]


module.exports = {
  allow_program: allow_program
}

