#encoding: utf-8
require 'cuba'
require 'rack/protection'
require 'mongoid'
require 'rack/logger'
require 'haml'
require 'cuba/render'
require 'securerandom'
require 'rack/post-body-to-params'
require 'pony'


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
Cuba.use Rack::Static, :urls => ["/js", "/css", "/libs", "/favicon.ico"], :root => ROOT_PATH

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
  res.write render(File.join('views', "#{view}.haml"), {content: content}, {format: :html5})
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
      render_haml "about"
    end
    
    on "medlemssidor" do
      user = current_user(req)
      if user == nil
        res.status = 401
      else
        on "filtersettings" do
          render_haml "filtersettings", user.filter
        end
        
        on "apartments_template" do
          render_haml "apartments"
        end
        
        on "apartments_list" do
          user = current_user(req)
          filt_apts = filtered_apartments(user.filter)
          res.write ActiveSupport::JSON.encode(filt_apts)
        end
        render_haml "medlemssidor"
      end
    end
    
    on "login" do
      render_haml "login"
    end
    
    on "signup" do
      render_haml "signup"
    end

    on "passwordreset" do
      on "confirmation" do
        render_haml "passwordresetconfirmation"
      end
      render_haml "passwordreset"
    end
    
    on ":catchall" do
      puts "Nu kom nån jävel allt fel"
      res.status = 404 #not found
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
		end
    
    on "logout" do
      user = current_user(req)
      user.session.delete if user
    end
    
    on "signup", param('email'), param('password') do |email, password|
      begin
        user = User.create!(email: email,
                    hashed_password: password, # becomes hashed when created
                    notify_by: [:email, :sms])
      rescue
        res.status = 400
      end
    end
    
    on "filter", param('rooms'), param('rent'), param('area') do |rooms, rent, area|
      res.write "Filter POST UN-nested<br/>
                 Rooms: #{rooms.class}<br/>
                 Rent: #{rent}<br/>
                 Area: #{area}<br/>"
      user = current_user(req)
      user.create_filter(rooms: rooms,
                         rent: rent,
                         area: area)
    end

    on "passwordreset" do
      on param('email') do |email|
        reset = Reset.create!(email: email)
        body = ["Klicka länken inom 12 timmar, annars...",
                "Länk: http://localhost:4856/#/losenordsaterstallning/#{reset.hashed_link}"].join("\n")
        shoot_email(email,
                    "Lösenordsåterställning",
                    body)
        res.write "Mail skickat"
      end

      on param('hash') do |hash|
        user = User.find_by(email: Reset.find_by(hashed_link: hash).email)
        new_pass = SecureRandom.hex
        user.update_attributes!(hashed_password: new_pass)
        body = ["Ditt nya lösenord: #{new_pass}",
                "Vi rekommenderar att du ändrar lösenordet till något lättare, och kanske kortare, att komma ihåg.",
                "Det kan du göra via din medlemssida."].join("\n")
        shoot_email(user.email,
                    "Nytt lösenord",
                    body)
        res.write "Mail skickat"
      end
    end

    on ":catchall" do
      puts "Nu kom nån jävel allt fel"
      res.status = 404 #not found
      res.write "Nu kom du allt fel din jävel!"
    end
  end
end