# encoding: utf-8

# ====================
# Requires everything
# ====================

root_directory = File.expand_path(File.dirname(__FILE__)) # change this if you move this file

Dir.chdir root_directory do
  require 'cuba'
  require 'rack/protection'
  require 'mongoid'
  require 'rack/logger'
  require 'haml'
  require 'cuba/render'
  require 'securerandom'
  require 'rack/post-body-to-params'
  require 'date'
  require 'rest-client'
  require 'payson_api'
  require_relative 'lib/getenvironment'
  require_relative 'helpers'
  require_from_directory 'extensions'
  require_from_directory 'models'
end

# ===============================
# Global constants and variables
# ===============================

ENVIRONMENT = get_environment
PUBLIC_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'public/'))


# ===================
# Configures Mongoid
# ===================

Mongoid.load!('mongoid.yml')

# =====================
# Configures PaysonAPI
# =====================

PaysonAPI.configure do |config|
  config.api_user_id = '1'
  config.api_password = 'fddb19ac-7470-42b6-a91d-072cb1495f0a'
end

# ================
# Configures Cuba
# ================
application_css = '/' + Dir["#{PUBLIC_PATH}/application-*.css"].first.split('/')[-1]
application_js = '/' + Dir["#{PUBLIC_PATH}/application-*.js"].first.split('/')[-1]

Cuba.use Rack::Session::Cookie, :expire_after => 60*60*24*60, #sec*min*h*day two months
                                :secret => "Even a potato in a dark cellar has a certain low cunning about him."
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer
Cuba.use Rack::Logger
Cuba.use Rack::Static, :urls => ['/images',
                                 '/fonts',
                                 application_css,
                                 application_js,
                                 '/favicon.ico'],
                        :root => PUBLIC_PATH
Cuba.use Rack::PostBodyToParams

# ================
# Sets up logging
# ================

LOG = Logger.new(STDOUT)
LOG.level = Logger::INFO
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"
LOG.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{severity} -- #{msg}\n"
end

def change_log_level(level)
  LOG.level = Kernel.qualified_const_get("Logger::#{level.upcase}")
  puts "Log level set to #{level.upcase}."
end

# ==============
# Time and date
# ==============

# ActiveSupport monkey patches Time to add timezone support. Here we specify
# the time zone that will be used. Mongoid respects this and acts the same
# way as the standard mapper in Rails (ActiveRecord) does, which means that
# in the database it stores all times in UTC and then in the application it
# automatically converts the time for you when you read from the database.
Time.zone = "Europe/Stockholm"
