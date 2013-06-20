#encoding: utf-8

require_relative 'init'

User.all.each do |u|
  puts "#{u.trial}    #{u.email}: #{u._id}, #{u.premium_until}, #{u.first_name}"
end
