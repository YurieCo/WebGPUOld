
from boto.ec2.connection import EC2Connection

AWS_ACCESS_KEY_ID = 'AKIAI4RGCVMXUDD3CCXA'
AWS_SECRET_ACCESS_KEY = '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'


class AmazonConnection:

	connection = None
	instances = []


	def connect(self):
		connection = EC2Connection(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)

	def start_instance(self):
		return

	def stop_instance(self):
		return

	def terminate_instance(self):
		return

	def bid_on_instance(self):
		return


