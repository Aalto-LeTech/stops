source 'http://rubygems.org'

gem 'rails', '3.2.11'
#gem 'rake'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'pg'
# We need 'em arrays; this shouldn't be needed in Rails 4.0 >=
gem 'postgres_ext'

# For PostgreSQL’s full text search
gem 'pg_search'

# For the Thinking Sphinx search engine
# sudo apt-get install sphinxsearch
# sudo apt-get install libmysqlclient-dev
gem 'mysql2',          '0.3.12b4' #b5 ?
gem 'thinking-sphinx', '3.0.0'
# NB. for the engine to work you need to do
#   be rake ts:index
#   be rake ts:start

# Use unicorn as the web server
# gem 'unicorn'
#gem 'mongrel', '>= 1.2.0.pre2'

group :assets do
  #gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'

  # For Bootstrap & Less (incl. Sass)
  gem 'therubyracer'             # See https://github.com/sstephenson/execjs#readme
  gem 'jquery-rails', '~> 2.1'
  gem 'jquery-ui-rails', '~> 3.0'
  #gem 'less-rails'
  #gem 'less-rails-bootstrap'
  gem 'less-rails-bootstrap', git: 'git://github.com/metaskills/less-rails-bootstrap.git'

  gem 'eco'
end


group :test do
  gem 'shoulda'
  gem 'factory_girl', '~> 4.0'
end


# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'
# gem 'debugger'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'
gem 'authlogic'
gem 'cancan'
gem 'fastercsv'
gem 'acts_as_list'
gem 'deep_cloneable', :git => 'git://github.com/moiristo/deep_cloneable.git'

gem 'delayed_job_active_record', :git => 'git://github.com/collectiveidea/delayed_job_active_record.git'
gem 'daemons'

# For model object serialization
gem 'active_model_serializers'


# development
#group :development do
#  gem "rails-erd"  # entity relationship diagrams
#end

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
