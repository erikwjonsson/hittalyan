#encoding: utf-8
require_relative 'init'

if ENVIRONMENT == :development
  # If environment do this shit, otherwise do something else. Shit.
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
  res.write ActiveSupport::JSON.encode(document)
end

# filter - Filter object
# days_ago - int
def filtered_apartments_since(filter, days_ago)
  apartments = Apartment.all
  apartments.select do |apartment|
    (filter.rent >= apartment.rent &&
    filter.rooms === apartment.rooms &&
    filter.area  === apartment.area) &&
    apartment.advertisement_found_at >= days_ago.days.ago
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
    
    on "loggedin" do
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
        on "user" do
          send_json(user.as_external_document)
        end

        on "packages" do
          external_packages = Packages::PACKAGE_BY_SKU.each_with_object({}) do |(k, v), h|
            h[k] = v.as_external_document
          end
          p external_packages
          p user.as_external_document
          send_json(external_packages)
        end
        
        on "installningar" do
          send_view "filtersettings"
        end

        on "settings" do
          require 'pp'
          pp user.as_external_document
          send_json(user.as_external_document)
        end
        
        on "lagenheter" do
          send_view "apartments"
        end
        
        on "apartments_list" do
          user = current_user(req)
          filt_apts = filtered_apartments_since(user.filter, 7)
          send_json(filt_apts.reverse!)
        end

        on "change_password" do
          send_view "change_password"
        end
        on "premiumtjanster" do
          send_view "premiumtjanster"
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

    on "emails" do
      on "unsubscribe" do
        on "notifications/:unsubscribe_id" do |unsubscribe_id|
          user = User.find_by(unsubscribe_id: unsubscribe_id)
          user.update_attributes(notify_by_email: false)
          res.write "E-postutskick om lägenheter har avaktiverats."
        end
      
        on "communications/:unsubscribe_id" do |unsubscribe_id|
          user = User.find_by(unsubscribe_id: unsubscribe_id)
          user.update_attributes(permits_to_be_emailed: false)
          res.write "Du kommer ej längre få e-postutskick med information från oss."
        end

        on "all/:unsubscribe_id" do |unsubscribe_id| 
          user = User.find_by(unsubscribe_id: unsubscribe_id)
          user.update_attributes(notify_by_email: false)
          user.update_attributes(permits_to_be_emailed: false)
          res.write "Du kommer inte få någon mer e-post från oss."
        end
      end
    end

    on ":catchall" do
      LOG.info "Nu kom nån jävel allt fel get"
      res.status = 404 # not found
    end
  end
  
  #POST----------------------------------------
  on post do
    on "test" do
      
    end

    on "payson_pay", param('sku') do |sku|
      user = current_user(req)
      payment = PaysonPayment.create!(user_email: user.email,
                                      package_sku: sku)
      begin
        payment.initiate_payment
      rescue Payment::InitiationError => e
        log_exception(e)
        res.status = 400
      end
      res.write(payment.forward_url) unless res.status == 400
    end

    on "ipn" do
      ipn_response = PaysonAPI::Response::IPN.new(req.body.read)
      ipn_request = PaysonAPI::Request::IPN.new(ipn_response.raw)

      payment = PaysonPayment.find_by(payment_uuid: req.POST['custom'])
      case payment.validate(ipn_response, ipn_request)
      when true
        user = User.find_by(email: payment.user_email)
        package = Packages::PACKAGE_BY_SKU[payment.package_sku]
        user.apply_package(package)
      when false
        puts "Something went wrong."
        res.status = 400
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
        user.create_filter()
        # test user for unit testing purposes
        if email == 'hank@rug.burn'
          user.delete
          res.write 'You\'ve got Hank!'
        end
      rescue Mongoid::Errors::Validations => ex
        error_codes = MongoidExceptionCodifier.codify(ex)
        res.status = 400 # bad request
        res.write "#{error_codes}" unless production?
      end
    end
    
    on "medlemssidor" do
      user = current_user(req)
      if user == nil
        res.status = 401
      else
        on "user", param('data') do |client_user_model|
          user.external_update!(client_user_model)
        end

        on "settings", param('data') do |data|
          user.update_settings(data)
        end

        on "personal_information", param('data') do |data|
          user.update_attributes!(first_name: data['first_name'],
                                  last_name: data['last_name'],
                                  mobile_number: data['mobile_number'])
          res.write "'#{user.as_document}'" unless production?
        end
        on "account_termination", param('password') do |password|
          if user.has_password?(password)
            user.session.delete
            user.delete
          else
            res.status = 401 #Unathorized
          end
        end
        on "change_password", param('new_password'), param('old_password') do |new_password, old_password|
          begin
            user.change_password(new_password, old_password)
          rescue User::WrongPassword
            res.status = 401
            res.write ""
          end
        end
      end
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
            user.change_password!(new_pass)
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

    on "message", param('email'), param('message') do |email, message|
      Mailer.shoot_email(Mailer::OUR_STANDARD_EMAIL, "Meddelande via kontaktformulär", message, email)
    end 

    on ":catchall" do
      LOG.info "Nu kom nån jävel allt fel post"
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
end
