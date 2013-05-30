# encoding: utf-8

# ====================
# Requires everything
# ====================

root_directory = File.expand_path(File.dirname(__FILE__)) # change this if you move this file
Dir.chdir root_directory

require 'cuba'
require 'rack/protection'
require 'mongoid'
require_relative 'lib/lingonberrymongoidimportexport'
require 'rack/logger'
require 'securerandom'
require 'rack/post-body-to-params'
require 'date'
require 'rest-client'
require 'payson_api'
require 'erb'
require 'rack/rewrite'

require_relative 'lib/getenvironment'
require_relative 'lib/mailer'
ENVIRONMENT = get_environment
require_relative 'helpers'
WEBSITE_ADDRESS = website_address
BRAND_NAME = "HittaLyan"
require_from_directory 'middleware'
require_from_directory 'extensions'
require_from_directory 'models'
require_from_directory 'models/packages'

# ===============================
# Global constants and variables
# ===============================

PUBLIC_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'public/'))

# ===================
# Configures Mongoid
# ===================

Mongoid.load!('mongoid.yml')

# =====================
# Configures PaysonAPI
# =====================

PaysonAPI.configure do |config|
  if production?
    config.api_user_id = '17355'
    config.api_password = '9b235fc5-3e21-4362-a3be-0d498d47f5ad'
  else
    config.api_user_id = '1'
    config.api_password = 'fddb19ac-7470-42b6-a91d-072cb1495f0a'
  end
end

# =================
# Fetches Packages
# =================
# I really don't know why this line doesn't work
# EXTERNAL_PACKAGES = Package.all.map! { |p| p.as_external_document }

module Packages
  PACKAGE_BY_SKU = {}
  PACKAGES = Package.all
  PACKAGES.all.each do |package|
    self.const_set(package.sku, package)
    PACKAGE_BY_SKU[package.sku] = package
  end
end

# =================
# Fetches Coupons
# =================

module Coupons
  COUPON_BY_CODE = {}
  COUPONS = Coupon.all
  COUPONS.all.each do |coupon|
    # Make sure coupon codes don't start with a number and all letter are capital
    self.const_set(coupon.code, coupon)
    COUPON_BY_CODE[coupon.code] = coupon
  end
end

# ================
# Configures Cuba
# ================

application_css = '/' + Dir["#{PUBLIC_PATH}/application-*.css"].first.split('/')[-1]
application_js = '/' + Dir["#{PUBLIC_PATH}/application-*.js"].first.split('/')[-1]

Cuba.use Rack::Rewrite do
  # Redirect non-www requests (e.g. hittalyan.se) to www (e.g. www.hittalyan.se),
  # but only in production.
  r301 /.*/,  Proc.new {|path, rack_env| "http://www.#{rack_env['SERVER_NAME']}#{path}" },
    :if => Proc.new {|rack_env| production? && !(rack_env['SERVER_NAME'] =~ /www\./i)}
end
Cuba.use Rack::Session::Cookie, :expire_after => 60*60*24*60, #sec*min*h*day two months
                                :secret => "Even a potato in a dark cellar has a certain low cunning about him."
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer
Cuba.use Rack::Logger
Cuba.use DeathToMing
Cuba.use Rack::Static, :urls => ['/images',
                                 '/fonts',
                                 application_css,
                                 application_js,
                                 '/favicon.ico',
                                 '/google718389522c114c98.html'],
                        :root => PUBLIC_PATH
Cuba.use Rack::PostBodyToParams
Cuba.use Rack::CommonLogger

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
