#encoding: utf-8
require 'cuba'
require 'rack/protection'
require 'mongoid'
require 'rack/logger'
require 'haml'
require 'cuba/render'
require 'securerandom'
require 'rack/post-body-to-params'

Cuba.plugin Cuba::Render

require_relative 'helpers'
require_from_directory 'extensions'
require_from_directory 'models'

Mongoid.load!('mongoid.yml')

ROOT_PATH = File.expand_path(File.dirname(__FILE__))
Cuba.use Rack::Session::Cookie
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer
Cuba.use Rack::Logger
Cuba.use Rack::PostBodyToParams
Cuba.use Rack::Static, :urls => ["/js", "/libs", "/favicon.ico"], :root => ROOT_PATH

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
  res.write render(File.join('views', "#{view}.haml"), {}, {format: :html5})
end

def filtered_apartments(filter)
  apartments = Apartment.all
  apartments.select do |apartment|
    (filter.rent === apartment.rent &&
    filter.rooms === apartment.rooms &&
    filter.area  === apartment.area)
  end
end

Cuba.define do

  #GET-----------------------------------------
  on get do
    on "test" do
      render_haml "test"
    end
  
    on "" do
      render_haml "index"
    end
    
    on  "loggedin" do
      res.status = 401 unless current_user(req)
    end
    
    on "landing" do
      render_haml "landing"
    end
    
    on "vanliga-fragor" do
      render_haml "faq"
    end
    
    on "om" do
      res.write "Om oss"
    end
    
    on "medlemssidor" do
      user = current_user(req)
      if user == nil
        render_haml "/login"
      else
        on "filtersettings" do
          render_haml "filtersettings", user.filter
        end
        
        on "apartments" do
          user = current_user(req)
          filt_apts = filtered_apartments(user.filter)
          content = {apts: filt_apts,
                     user: user}
          render_haml "apartments", content
        end
        #res.write "Hej #{user.name}. Ditt sessionsid är: #{req.session[:sid]}"
        # render_haml "medlemssidor"
        render_haml "medlemssidor"
      end
      
    end
    
    on "login" do
      user = current_user(req)
      if user
        render_haml "medlemssidor"
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
      render_haml "login"
    end
    
    on ":catchall" do
      puts "Nu kom nån jävel allt fel"
      res.status = 404
      res.write "Nu kom du allt fel din jävel!"
    end
  end
  
  #POST----------------------------------------
  on post do
    on "test", param('message') do |m|
      if m == "moo"
        res.status = 200
      else
        res.status = 401
      end
    end
  
		on "login" do
			on param('email'), param('password') do |email, password|
				user = User.authenticate(email, password)
				if user
					init_session(req, user)
				else
          res.status = 401 #unauthorized
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
      render_haml "/medlemssidor"
    end
    
    on "medlemssidor" do
      res.write "POST on medlemssidor"
    end
    
    on "filter", param('rooms'), param('rent'), param('area') do |rooms, rent, area|
      res.write "Filter POST UN-nested<br/>
                 Rooms: #{rooms}<br/>
                 Rent: #{rent}<br/>
                 Area: #{area}<br/>
                 <a href=\"/medlemssidor\">Medlemssidor</a>"
      user = current_user(req)
      user.create_filter(
                        rooms: rooms,
                        rent: rent,
                        area: area)
    end
    
    on ":catchall" do
      puts "Nu kom nån jävel allt fel"
      res.status = 404
      res.write "Nu kom du allt fel din jävel!"
    end
  end
  
end