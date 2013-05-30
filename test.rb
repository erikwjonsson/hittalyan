#encoding: utf-8

require_relative 'init'

user = User.find_by(email: 'robin.edman@gmail.com')
user.send(:shoot_welcome_email)
#Mailer.shoot_email(user, 'I am an unwanted email', 'I talk shite.')
