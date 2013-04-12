#encoding: utf-8

require_relative 'init'

json_data = %[{"mobile_number":"+70malaria","first_name":"Hawaii","last_name":""}]

puts ActiveSupport::JSON.decode(json_data).class