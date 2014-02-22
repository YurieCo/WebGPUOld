
config = require './config'
_ = require 'underscore'

fmt = require 'fmt'
awssum = require 'awssum'
amazon = awssum.load 'amazon/amazon'
Ec2 = (awssum.load 'amazon/ec2').Ec2;
scp = require './scp'
ssh = require './ssh'
Logger = require 'bunyan'

ring_buffer = new Logger.RingBuffer limit: 200

ec2 = new Ec2 {
    'accessKeyId'     : config.aws_key_id,
    'secretAccessKey' : config.aws_key_secret,
    'region'          : config.aws_region
}

log = new Logger {
	name: 'wbAWS',
	streams: [
		{
			stream: process.stdout,
			level: 'debug'
		},
		{
			path: config.aws_log_file_path,
			level: 'trace'
		},
		{
	        type: 'raw',
	        stream: ring_buffer,
	        level: 'trace'
		}
	],
	src: true
}

get_instances = (err, data) ->
	instances = [];
	if err and err.Body and err.Body.Response
		log.error {err: 'GetInstance'}, err.Body.Response.Errors
	else if err?
		log.error {err: 'GetInstance'}, 'Failed to get instances.'
	else
		item = data.Body.DescribeInstancesResponse.reservationSet.item
		add_instance = (inst) ->
			if inst.item?
				add_instance inst.item
			else if _.isArray inst
				add_instance(ii) for ii in inst
			else
				try 
					instances.push inst
				catch e
					log.error {err: 'Exception'}, 'While getting instances.'
		add_instance(iter.instancesSet) for iter in item
	instances

for_each_instance = (call_back) ->
	ec2.DescribeInstances (err, data) ->
		instances = get_instances err, data
		call_back(inst) for inst in instances

for_instances = (call_back) ->
	ec2.DescribeInstances (err, data) ->
		instances = get_instances err, data
		call_back instances

for_each_running_instance = (call_back) ->
	for_each_instance (instance) ->
		try 
			if instance.instanceState.name == 'running'
				call_back null, instance
		catch e
			log.error {err: 'Exception'}, 'While iterating over running instance.'
			call_back true

for_running_instances = (call_back) ->
	for_instances (instances) ->
		try
			running_instances = _.filter instances, (instance) ->
				instance.instanceState.name == 'running'
			call_back null, instances
		catch e
			log.error {err: 'Exception'}, 'While iterating over instances.'
			call_back true


for_each_instance_id = (call_back) ->
	for_each_instance (instance) ->
		call_back instance.instanceId

for_instance_ids = (call_back) ->
	for_instances (instance) ->
		ids = _.map instances, (instance) ->
			instance.instanceId
		call_back ids

for_each_running_instance_id = (call_back) ->
	for_each_running_instance (instance) ->
		call_back instance.instanceId

for_running_instance_ids = (call_back) ->
	for_running_instances (instance) ->
		ids = _.map instances, (instance) ->
			instance.instanceId
		call_back ids

for_each_instance_dns_name = (call_back) ->
	for_each_instance (instance) ->
		call_back instance.dnsName

for_instance_dns_names = (call_back) ->
	for_instances (instances) ->
		dnsNames = _.map instances, (instance) ->
			instance.dnsName
		call_back dnsNames

for_each_running_instance_dns_name = (call_back) ->
	for_each_running_instance (instance) ->
		call_back instance.dnsName

for_running_instance_dns_names = (call_back) ->
	for_running_instances (instances) ->
		dnsNames = _.map instances, (instance) ->
			instance.dnsName
		call_back dnsNames

copy_file_to_instance = (host, file, destination_directory, call_back) ->
	scp.send {
			 	key: config.aws_ssh_key_file,
			 	user: config.aws_user,
			 	host: host,
			 	file: file,
			 	path: destination_directory,
			 },
			 (err, stdout, stderr) ->
			 	if err
			 		log.error {err: 'SendingFile'}, "Failed to send file " + file + " to " + host + " (" + stderr + ")."
			 	else
			 		log.info {err: 'SendingFile'}, "Sending file " + file + " to " + host
			 	call_back err, stdout, stderr

copy_file_to_instances = (file, destination_directory, call_back) ->
	for_each_running_instance_dns_name (addr) ->
		copy_file_to_instance(addr, file, destination_directory, call_back)

execute_command_on_instances = (cmd, call_back) ->
	for_each_running_instance_dns_name (addr) ->
		ssh.exec cmd,
				 {
				 	key: config.aws_ssh_key_file,
				 	user: config.aws_user,
				 	host: addr
				 },
				 (err, stdout, stderr) ->
				 	if err
				 		log.error {err: 'ExecutingCommand'}, "Failed to execute command " + cmd + " on " + addr + " (" + stderr + ")."
				 	else
				 		log.info {err: 'ExecutingCommand'}, "Executed command " + cmd + " on " + addr + " (" + stdout + ")."
				 	call_back err, stdout, stderr
	

terminate_running_instances = (n) ->
	if !n?
		n = Infinity;
	else if n <= 0
		return
	for_each_running_instance (instance) ->
		if n == Infinity || n-- > 0
    		ec2.TerminateInstances {'InstanceId': instance.instanceId}, (err, data) ->
	    		log.info {err: 'TerminateInstance'}, "Terminating instance " + instance.instanceId

terminate_instance = (host) ->
	for_each_running_instance (instance) ->
		if instance.dnsName == host
    		ec2.TerminateInstances {'InstanceId': instance.instanceId}, (err, data) ->
	    		log.info {err: 'TerminateInstance'}, "Terminating host " + instance.dnsName

run_instances = (n) ->
	n = n ? 1
	ec2.RunInstances {
						'ImageId': config.aws_ami_name,
						'MinCount': n,
						'MaxCount': n,
						'KeyName': config.aws_key_name,
						'InstanceType': config.aws_instance_type,
						'SecurityGroup': config.aws_security_group
					},
					(err, data) ->
						if err
							log.error {err: 'RunInstance'}, err.Body.Response.Errors
						else
							instances = data.Body.RunInstancesResponse.instancesSet.item;
							logInstance = (inst) ->
								if _.isArray inst
									_.each inst, logInstance
								else
									log.info {err: 'RunInstance'}, 'Started instance ' + inst.instanceId
							logInstance instances
							# add to scheduler and start the daemon


module.exports = {
	aws_run_instances: run_instances,
	aws_terminate_instances: terminate_running_instances,
	aws_terminate_instance: terminate_instance,
	copy_file_to_instances: copy_file_to_instances,
	copy_file_to_instance: copy_file_to_instance
}

