source 'http://rubygems.org'
gem 'rack-protection'
gem 'mongoid', '~>3.0.0'
gem 'bson_ext'
gem 'cuba'
gem 'rack-post-body-to-params'
gem 'thin'
gem 'rest-client'
gem 'payson_api', '0.3.0'
gem 'af'


# Do not change the following comment. Rakefile uses it for deployment to AppFog.

# --DEVELOPMENT GEMS--
if ENV['RACK_ENV'] == 'development'
  # puts 'Development environment on scanners, captain. Engaging gem tractor.'
  # Asset pipeline
  gem 'rack-livereload'
  gem 'guard-livereload'
  gem 'rake-pipeline'
  gem 'rake-pipeline-web-filters'
  gem 'coffee-script'
  gem 'yui-compressor'
  gem 'uglifier'
  gem 'sass'
  gem 'compass'
  gem 'tilt'
  gem 'haml'
  gem 'rdiscount'
end
