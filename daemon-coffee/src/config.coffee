
path = require 'path'

c_tools_dir = path.join process.cwd(), '..', '..', 'c-tools'
mp_dir = path.join process.cwd(), '.', 'mp'
mp_data_dir = path.join mp_dir, 'data'

module.exports = {
	master_address: 'localhost',
	master_port: 8000,
	master_path: 'register_slave',
	port: 8081,
	look_port: 8082,
	max_processes: 10,
	tmpdir_prefix: 'wbCUDA-',
	log_file_path: './app.log',
	c_tools_dir: c_tools_dir,
	mp_dir: mp_dir,
	mp_data_dir: mp_data_dir,
	process_timeout: 5000
	compile_timeout: 100000
}

