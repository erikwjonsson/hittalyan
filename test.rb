#encoding: utf-8

require_relative 'init'
require 'pp'

rooms = 1..2
area = 0..100
rent = 10000
cities = ["Stockholm"]
puts Apartment.all.count
puts Apartment.where(rooms: rooms, 
                     area: area, 
                     rent: 0..rent, 
                     :city.in => cities,
                     advertisement_found_at: 30.days.ago..Time.now
                     ).all
puts Apartment.all.count == Apartment.where(rooms: rooms).all.count
