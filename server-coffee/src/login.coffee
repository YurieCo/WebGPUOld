# This file interacts with the server, abstracting
# some common login tasks


#### Imports

crypto = require 'crypto'

config = require './config'
db = (require './db').AuthProvider

# We never store the password in the database,
# instead, using a very simple hashing function
hash = (msg) ->
	crypto.createHash('md5').update(msg).digest("hex")

# Add a user to the database
add_user = (user, pass, call_back) ->
	db.new_user user,
				(hash pass),
				(err, obj) ->
					call_back err, obj

# Update the user's password, if in the
# database
update_user = (user, pass, call_back) ->
	db.update user,
			  (hash pass),
			  (err, obj) ->
			  	call_back err, obj

# Find a user in the database
find_user = (user, call_back) ->
	db.find_user user,
				 (err, obj) ->
				 	call_back err, obj

# Validate the password for a user in the database
valid_password = (user, pass, call_back) ->
	db.find_user user,
				 (err, obj) ->
				 	if err
				 		call_back err
				 	else
				 		if obj && obj.pass == (hash pass)
				 			call_back null, true
				 		else
				 			call_back null, false
	null

# Check if a user is in the database
user_exists = (user, pass, call_back) ->
	db.find_user user,
				 (err, obj) ->
				 	if err
				 		call_back err
				 	else
				 		if obj && obj.user
				 			call_back null, true
				 		else
				 			call_back null, false
	null


#### Exports

exports.add_user = add_user
exports.new_user = update_user
exports.find_user = find_user
exports.valid_password = valid_password
exports.user_exists = user_exists


