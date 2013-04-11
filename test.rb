#encoding: utf-8

root_directory = File.expand_path(File.dirname(__FILE__)) # change this if you move this file
Dir.chdir root_directory

require 'cuba'
require 'rack/protection'
require 'mongoid'
require 'rack/logger'
require 'securerandom'
require 'rack/post-body-to-params'
require 'date'
require 'rest-client'
require 'payson_api'
require_relative 'lib/getenvironment'
require_relative 'helpers'
require_from_directory 'extensions'
require_from_directory 'models'
require_from_directory 'models/packages'


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

module Packages
  PACKAGE_BY_SKU = {}
  Package.all.each do |package| 
    self.const_set(package.name, package)
    PACKAGE_BY_SKU[package.sku] = package
  end
end
require 'pp'
# pp Packages::PACKAGE_BY_SKU

pp Packages::Standard.as_document
