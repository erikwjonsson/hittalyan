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
require 'rest-client'
require 'payson_api'

def get_environment
  raise RackEnvNotSet unless ENV['RACK_ENV']
  environment = ENV['RACK_ENV'].to_sym

  allowed_environments = [:development, :test, :production]
  if allowed_environments.include?(environment)
    environment
  else
    raise UnallowedEnvironmentException.new(ENV['RACK_ENV'], allowed_environments)
  end
end

class UnallowedEnvironmentError < StandardError
  def initialize(incorrent_environment, allowed_environments)
    @incorrent_environment = incorrent_environment
    @allowed_environments = allowed_environments
  end

  def message
    "The environment #{@incorrent_environment} is not allowed. Allowed"\
    "environments are #{@allowed_environments.join(', ')}."
  end
end

class RackEnvNotSet < StandardError
  def message
    "The environment variable RACK_ENV is not set."
  end
end

ENVIRONMENT = get_environment

if ENVIRONMENT == :development
  #require 'rake-pipeline'
  #require 'rake-pipeline/middleware'
  #Cuba.use Rake::Pipeline::Middleware, 'Assetfile'
  #require 'rack-livereload'
  #Cuba.use Rack::LiveReload
end

require_relative 'helpers'
require_from_directory 'extensions'
require_from_directory 'models'

Mongoid.load!('mongoid.yml')

PUBLIC_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'public/'))

def application_css
  '/' + Dir["#{PUBLIC_PATH}/application*.css"].first.split('/')[-1]
end

def application_js
  '/' + Dir["#{PUBLIC_PATH}/application*.js"].first.split('/')[-1]
end

Cuba.use Rack::Session::Cookie, :expire_after => 60*60*24*60 #sec*min*h*day two months
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer
Cuba.use Rack::Logger
Cuba.use Rack::Static, :urls => ['/images',
                                 '/fonts',
                                 application_css,
                                 application_js,
                                 '/favicon.ico'],
                        :root => PUBLIC_PATH
Cuba.use Rack::PostBodyToParams

PaysonAPI.configure do |config|
  config.api_user_id = '1'
  config.api_password = 'fddb19ac-7470-42b6-a91d-072cb1495f0a'
end

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


def send_view(view)
  res.write File.read(File.join('public', "#{view}.html"))
end

def send_json(document)
  res['Content-Type'] = 'application/json; charset=utf-8'
  res.write document
end

def filtered_apartments(filter)
  apartments = Apartment.all
  apartments.select do |apartment|
    (filter.rent >= apartment.rent &&
    filter.rooms === apartment.rooms &&
    filter.area  === apartment.area)
  end
end

Cuba.define do

  #GET-----------------------------------------
  on get do
    on "test" do
      send_view "test"
    end
  
    on "" do
      send_view "index"
    end
    
    on  "loggedin" do
      res.status = 401 unless current_user(req)
    end
    
    on "landing" do
      send_view "landing"
    end
    
    on "vanliga-fragor" do
      send_view "faq"
    end
    
    on "om" do
      send_view "about"
    end
    
    on "medlemssidor" do
      user = current_user(req)
      if user == nil
        res.status = 401
      else
        on "notify_by" do
          notify_by = {email: user.notify_by_email,
                       sms: user.notify_by_sms,
                       push: user.notify_by_push_note}
          send_json ActiveSupport::JSON.encode(notify_by)
        end
        on "installningar" do
          send_view "filtersettings"
        end

        on "get_settings" do
          send_json ActiveSupport::JSON.encode(user.settings_to_hash)
        end
        
        on "lagenheter" do
          send_view "apartments"
        end
        
        on "apartments_list" do
          user = current_user(req)
          filt_apts = filtered_apartments(user.filter)
          send_json ActiveSupport::JSON.encode(filt_apts)
        end

        on "change_password" do
          send_view "change_password"
        end
        send_view "medlemssidor"
      end
    end
    
    on "login" do
      send_view "login"
    end
    
    on "signup" do
      send_view "signup"
    end

    on "passwordreset" do
      on "confirmation" do
        send_view "passwordresetconfirmation"
      end
      send_view "passwordreset"
    end

    on ":catchall" do
      puts "Nu kom nån jävel allt fel"
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
  
  #POST----------------------------------------
  on post do
    on "test", param('mobile_number') do |mobile_number|
      user = current_user(req)
      user.change_mobile_number(mobile_number)
      res.write user.mobile_number

      # return_url = 'http://localhost:4856/#/test'
      # cancel_url = 'http://localhost:4856/#/login'
      # ipn_url = 'http://localhost:4856/#/test'
      # memo = 'Thi be teh deskription foh de thigy'

      # receivers = []
      # receivers << PaysonAPI::Receiver.new(
      #   email = 'testagent-1@payson.se',
      #   amount = 125,
      #   first_name = 'Sven',
      #   last_name = 'Svensson',
      #   primary = true)

      # sender = PaysonAPI::Sender.new(
      #   email = 'lingonberyyprod@gmail.org',
      #   first_name = 'Thunar',
      #   last_name = 'Rolfsson')

      # order_items = []
      # order_items << PaysonAPI::OrderItem.new(
      #   description = 'Hittalyan månads dakjdkah',
      #   unit_price = 100,
      #   quantity = 1,
      #   tax = 0.25,
      #   sku = 'MY-ITEM-1')

      # payment = PaysonAPI::Request::Payment.new(
      #   return_url,
      #   cancel_url,
      #   ipn_url,
      #   memo,
      #   sender,
      #   receivers)
      # payment.order_items = order_items

      # response = PaysonAPI::Client.initiate_payment(payment)

      # if response.success?
      #   res.write response.forward_url
      #   puts "Successful payment be done, sire."
      # else
      #   puts response.errors
      #   res.status = 400
      #   res.write "Payment failed"
      # end
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
        user.create_filter()
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

    on "account_termination", param('password') do |password|
      user = current_user(req)
      if user.has_password?(password)
        user.session.delete
        user.delete
      else
        res.status = 401 #Unathorized
      end
    end
    
    on "filter", param('roomsMin'), param('roomsMax'), param('rent'),
                 param('areaMin'), param('areaMax') do |rooms_min, rooms_max, rent, area_min, area_max|
      res.write "Filter POST UN-nested<br/>
                 Rooms_min: #{rooms_min}<br/>
                 Rent: #{rent}<br/>
                 Area_max: #{area_max}<br/>"
      user = current_user(req)
      user.create_filter(rooms: Range.new(rooms_min.to_i, rooms_max.to_i),
                         rent: rent,
                         area: Range.new(area_min.to_i, area_max.to_i))
    end

    on "notify_by", param('email'), param('sms'), param('push') do |email, sms, push|
      user = current_user(req)
      user.update_attributes!(notify_by_email: email,
                              notify_by_sms: sms,
                              notify_by_push_note: push)
    end

    on "mobile_number", param('mobile_number') do |mobile_number|
      user = current_user(req)
      user.change_mobile_number(mobile_number)
      res.write user.mobile_number
    end

    on "passwordreset" do
      on param('email') do |email|
        if User.find_by(email: email)
          if reset = Reset.find_by(email: email) #If reset exists, refresh.
            reset.refresh
          else
            reset = Reset.create!(email: email)
          end
          body = ["Klicka länken inom 12 timmar, annars...",
                  "Länk: http://cubancabal.aws.af.cm/#/losenordsaterstallning/#{reset.hashed_link}"].join("\n")
          shoot_email(email,
                      "Lösenordsåterställning",
                      body)
        end
          res.write "Mail skickat, kan du tro."
      end

      on param('hash'), param('new_password') do |hash, new_pass|
        if reset = Reset.find_by(hashed_link: hash)
          if (Time.now - reset.created_at) < 43200 # 12 hours
            user = User.find_by(email: reset.email)
            user.change_password(new_pass)
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
      user.change_password(new_password)

      res.write "Lösenord ändrat"
    end

    on ":catchall" do
      log.info('Nu kom nån jävel allt fel')
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
end
