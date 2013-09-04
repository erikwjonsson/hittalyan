require_relative '../init'

token = ARGV[0]

payment_details = PaysonAPI::Request::PaymentDetails.new(token)

response = PaysonAPI::Client.get_payment_details(payment_details)

require 'pp'

puts "Payment details for token: #{token}" 
pp response
