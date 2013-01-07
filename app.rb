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
require 'date'


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
Cuba.use Rack::Static, :urls => ["/js", "/css", "/images", "/libs", "/favicon.ico"], :root => ROOT_PATH

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
        
        on "apartments" do
          render_haml "apartments"
        end
        
        on "apartments_list" do
          user = current_user(req)
          filt_apts = filtered_apartments(user.filter)
          res.write ActiveSupport::JSON.encode(filt_apts)
        end

        on "change_password" do
          render_haml "change_password"
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
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
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
          res.status = 401 # unauthorized
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
                            hashed_password: password) # becomes hashed when created
        # test user for unit testing purposes
        if email == 'hank@rug.burn'
          user.delete
          res.write 'You\'ve got Hank!'
        end
      rescue Mongoid::Errors::Validations => ex
        error_codes = MongoidExceptionCodifier.codify(ex)
        res.status = 400 # bad request
        res.write "#{error_codes}"
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
        if reset = Reset.find_by(email: email)
          reset.refresh
        else
          reset = Reset.create!(email: email)
        end
        body = ["Klicka länken inom 12 timmar, annars...",
                "Länk: http://localhost:4856/#/losenordsaterstallning/#{reset.hashed_link}"].join("\n")
        shoot_email(email,
                    "Lösenordsåterställning",
                    body)
        res.write "Mail skickat"
      end

      on param('hash'), param('new_password') do |hash, new_pass|
        if reset = Reset.find_by(hashed_link: hash)
          if (Time.now - reset.created_at) < 43200 # 12 hours
            user = User.find_by(email: reset.email)
            user.update_attributes!(hashed_password: new_pass)
            reset.delete # So the link cannot be used anymore
            res.write "Lösen ändrat till #{new_pass}"
          else
            res.status = 404 # For lack of a better status code
            res.write "Länk förlegad"
          end # Yes, looks like crap. But it works. There's nothing a few if's cant't fix.
        else
          res.status = 404 # For lack of a better status code
          res.write "Länk förlegad"
        end
      end
    end

    on "change_password", param('old_password'), param('new_password') do |old_password, new_password|
      # There should be some sort of extra check here against old_password
      # to make sure the user hasn't simply forgotten to log out and some opportunistic
      # bastard is trying to change the password.
      # Also, appropriate action taken, status codes etc.
      # Should obviously not allow the change of password unless old_password checks out.
      user = current_user(req)
      user.update_attributes!(hashed_password: new_password)

      res.write "Lösenord ändrat"
    end

    on ":catchall" do
      log.info('Nu kom nån jävel allt fel')
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
end
