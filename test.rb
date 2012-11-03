#encoding: utf-8
# require 'cuba'
# require 'rack/protection'
require 'mongoid'
# require 'rack/logger'
# require 'haml'
# require 'cuba/render'
# require 'securerandom'

# Cuba.plugin Cuba::Render

require_relative 'helpers'
# require_from_directory 'extensions'
require_from_directory 'models'

# Mongoid.load!('mongoid.yml')
Mongoid.load!('mongoid.yml', :development)


# Cuba.use Rack::Session::Cookie
# Cuba.use Rack::Protection
# Cuba.use Rack::Protection::RemoteReferrer
# Cuba.use Rack::Logger
<<<<<<< Updated upstream

def filtered_apartments(filter)
  apartments = Apartment.all
  apartments.select do |apartment|
    (filter.rent === apartment.rent &&
    filter.rooms === apartment.rooms &&
    filter.area  === apartment.area)
  end
=======
# Cuba.use Rack::PostBodyToParams
# Cuba.use Rack::Static, :urls => ["/js", "/css", "/libs", "/favicon.ico"], :root => ROOT_PATH

(1..5).each do |i|
  ResetTest.create!(name: "Number #{i}",
                    created_at: Time.now.utc)
  puts i
  puts Time.now.utc
  sleep(2)
>>>>>>> Stashed changes
end

user = User.find_by(name: "kermit")
puts "user.class: #{user.class}"
puts "user.name: #{user.name}"
filter = user.filter
puts "filter.class: #{filter.class}"
filter.update_attributes(
              rooms: 1..3,
              area: 1..1000,
              rent: 1..99999)
filt_apts = filtered_apartments(filter)
puts "filt_apts.class: #{filt_apts.class}"
filt_apts.each_with_index do |apt, index|
  puts "##{index}: #{apt.rooms}"
end


