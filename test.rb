#encoding: utf-8

require_relative 'init'

user = User.find_by(email: 'robin.edman@gmail.com')
puts user._id.generation_time