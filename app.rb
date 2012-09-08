#encoding: utf-8
require 'cuba'
require 'rack/protection'
require 'mongoid'
require 'rack/logger'
require 'haml'
require 'cuba/render'
require 'securerandom'

Cuba.plugin Cuba::Render

require_relative 'helpers'
require_from_directory 'extensions'
require_from_directory 'models'

Mongoid.load!('mongoid.yml')


Cuba.use Rack::Session::Cookie
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer
Cuba.use Rack::Logger

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

def render_haml(view, content = nil)
  res.write render(File.join('views', "#{view}.haml"), content: content)
end

Cuba.define do

  #GET-----------------------------------------
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
        on "filtersettings" do
          render_haml "filtersettings"
        end
        #res.write "Hej #{user.name}. Ditt sessionsid är: #{req.session[:sid]}"
        render_haml "medlemssidor"
      end
      
    end
    
    on "login" do
      user = current_user(req)
      if user
        res.redirect '/medlemssidor'
      else
        render_haml "login"
      end
    end
    
    on "signup" do
      render_haml "signup"
    end
    
    on "logout" do
      user = current_user(req)
      user.session.delete if user
      res.redirect "login"
    end
    
    on ":catchall" do
      res.write "Nu kom du allt fel din jävel!"
    end
  end
  
  #POST----------------------------------------
  on post do
		on "login" do
			on param('email'), param('password') do |email, password|
				user = User.authenticate(email, password)
				if user
					init_session(req, user)
					res.redirect "/medlemssidor"
				else
					res.write "Ogiltig e-postadress eller lösenord."
				end
			end
			
			res.write "E-post och lösenord är OBLIGATORISKT!"
		end
    
    on "signup", param('email'), param('password'), param('name') do |email, password, name|
      user = User.create!(email: email,
                   hashed_password: password, # becomes hashed when created
                   name: name,
                   notify_by: [:email, :sms])
      init_session(req, user)
      res.redirect "/medlemssidor"
    end
    
    on "medlemssidor" do
      res.write "POST on medlemssidor"
    end
    
    on "filter", param('rooms') do |rooms|
      res.write "Filter UN-nested<br/>Rooms: #{rooms}"
    end
  end
  
end