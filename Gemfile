source 'http://rubygems.org'
gem 'rack-protection'
gem 'mongoid', '~>3.0.0'
gem 'bson_ext', '~>1.6.4'
gem 'cuba', '~>3.1.0'
gem 'rack-post-body-to-params', '~>0.1.5'
gem 'thin', '~>1.5.0'
gem 'rest-client', '~>1.6.7'
gem 'payson_api', '0.3.0'
gem 'af'
gem 'rack-rewrite', '~> 1.2.1'

# Do not change the following comment. Rakefile uses it for deployment to AppFog.

# --DEVELOPMENT GEMS--
if ENV['RACK_ENV'] == 'development'
  # puts 'Development environment on scanners, captain. Engaging gem tractor.'
  # Asset pipeline
  gem 'rack-livereload', '0.3.12'
  gem 'guard-livereload', '1.1.3'
  gem 'rake-pipeline', '0.7.0'
  gem 'rake-pipeline-web-filters', '0.7.0'
  gem 'yui-compressor', '0.9.6'
  gem 'uglifier', '1.3.0'
  gem 'sass', '3.2.7'
  gem 'compass', '0.12.2'
  gem 'tilt', '1.3.3'
  gem 'haml', '3.1.7'
  gem 'rdiscount', '1.6.8'
end
