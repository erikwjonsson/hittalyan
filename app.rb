#encoding: utf-8
require 'cuba'
require "rack/protection"
require 'mongoid'

require 'securerandom'

require_relative 'user'
require_relative 'session'

Mongoid.load!('mongoid.yml')


Cuba.use Rack::Session::Cookie
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

def init_session(req, user)
  sid = SecureRandom.uuid
  req.session[:sid] = sid
  Session.create!(sid: sid, user: user)
end

def current_user(req)
  user = Session.authenticate(req.session[:sid])
  if user
    user
  else
    nil
  end
end

def render_view(view)
  res.write File.read(File.join('views', "#{view}.html"))
end

Cuba.define do
  on get do
    on "" do
      res.write "Hej värld!"
      res.write "Sessionsid: #{req.session[:sid]}"
    end
    
    on "vanliga-fragor" do
      res.write "Vanliga frågor"
    end
    
    on "om" do
      res.write "Om oss"
    end
    
    on "medlemssidor" do
      user = current_user(req)
      if user == nil
        res.redirect "/login"
      else
        res.write "Hej #{user.name}. Ditt sessionsid är: #{req.session[:sid]}"
      end
    end
    
    on "login" do
      render_view "login"
    end
    
    on "signup" do
      render_view "signup"
    end
    
    on "logout" do
      user = current_user(req)
      user.session.delete if user
      res.redirect "/"
    end
    
    on ":catchall" do
      res.write "Nu kom du allt fel din jävel!"
    end
  end
  
  on post do
    on "login", param('email'), param('password') do |email, password|
      user = User.authenticate(email, password)
      if user
        init_session(req, user)
        res.redirect "/medlemssidor"
      else
        res.write "Ogiltig e-postadress eller lösenord."
      end
    end
    
    on "signup", param('email'), param('password'), param('name') do |email, password, name|
      user = User.create!(email: email,
                   hashed_password: password, # becomes hashed when created
                   name: name)
      init_session(req, user)
      res.redirect "/medlemssidor"
    end
  end
  
end