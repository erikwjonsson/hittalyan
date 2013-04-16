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
  res.write document
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

        on "packages" do
          packages = Packages::PACKAGE_BY_SKU.values
          pretty_packages = {}
          packages.each do |p|
            pretty_packages[p.sku] = {name: p.name,
                                      description: p.description,
                                      unit_price_in_ore: p.unit_price_in_ore}
          end
          send_json ActiveSupport::JSON.encode(pretty_packages)
        end
        
        on "lagenheter" do
          send_view "apartments"
        end
        
        on "apartments_list" do
          user = current_user(req)
          filt_apts = filtered_apartments_since(user.filter, 7)
          send_json ActiveSupport::JSON.encode(filt_apts.reverse!)
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
      res.write "Nu kom du allt fel din javel!"
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
      rescue PaymentInitiationError => e
        log_exception(e)
        res.status = 400
      end
      res.write(payment.forward_url) unless res.status == 400
    end

    on "ipn" do
      payment_uuid = req.POST['custom']
      payment = Payment.find_by(payment_uuid: payment_uuid)
      payment.ipn_response(req)

      if payment.validate
        email = req.POST['senderEmail']
        user = User.find_by(email: email)
        sku = payment.package_sku
        package = Packages::PACKAGE_BY_SKU[sku]
        user.inc(:premium_days, package.premium_days)
        user.inc(:sms_account, package.sms_account)
        payment.update_attribute(:status, "EXECUTED")
      else
        LOG.error "Something went wrong"
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

    on "personal_information", param('data') do |data|
      user = current_user(req)
      user.change_mobile_number(data['mobile_number'])
      user.update_attributes!(first_name: data['first_name'],
                              last_name: data['last_name'])
      res.write "'#{user.as_document}'"
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
      LOG.info "Nu kom nån jävel allt fel post"
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
end
