# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_ops_session',
  :secret      => 'c43b4963cf87e6cf56d5fa3aff265d605c542cbba9a6a06ce186284b80f947f442d89275ec2e087ab03e19d86369785cb25b916c0595c992b71ae14230e4d756'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
