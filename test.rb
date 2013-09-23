#encoding: utf-8

require_relative 'init'

p User.where(email: "whomever")
p User.find_by(email: "joke_a_87@hotmail.com")
