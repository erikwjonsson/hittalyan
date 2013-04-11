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
      puts "Nu kom nån jävel allt fel get"
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
  
  #POST----------------------------------------
  on post do
    on "test" do
      
    end

    on "payson_pay" do
      return_url = 'http://cubancabal.aws.af.cm/#/medlemssidor/premiumtjanster'
      cancel_url = 'http://cubancabal.aws.af.cm/#/medlemssidor/premiumtjanster'
      ipn_url = 'http://cubancabal.aws.af.cm/ipn'
      unless production?
        return_url = 'http://localhost:4856/#/medlemssidor/premiumtjanster'
        cancel_url = 'http://localhost:4856/#/medlemssidor/premiumtjanster'
        ipn_url = 'http://localhost:4856/ipn'
      end
      memo = 'Thi be teh deskription foh de thigy'
      user = current_user(req)

      receivers = []
      receivers << PaysonAPI::Receiver.new(
        email = 'testagent-1@payson.se',
        amount = (Packages::Standard.unit_price_in_ore/100)*(Packages::Standard.tax_in_percentage_units/100 + 1),
        first_name = 'Sven',
        last_name = 'Svensson',
        primary = true)

      sender = PaysonAPI::Sender.new(
        email = user.email,
        first_name = 'Thunar',
        last_name = 'Rolfsson')

      order_items = []
      order_items << Packages::Standard.as_order_item

      payment = PaysonAPI::Request::Payment.new(
        return_url,
        cancel_url,
        ipn_url,
        memo,
        sender,
        receivers)
      payment.order_items = order_items

      response = PaysonAPI::Client.initiate_payment(payment)

      if response.success?
        res.write response.forward_url
        puts "Payment from #{user.email} initiated"
      else
        puts response.errors
        res.status = 400
        res.write response.errors
      end
    end

    on "ipn" do
      request_body = req.body.read
      ipn_response = PaysonAPI::Response::IPN.new(request_body)
      ipn_request = PaysonAPI::Request::IPN.new(ipn_response.raw)
      validate = PaysonAPI::Client.validate_ipn(ipn_request)
      if validate.verified? && req.POST['status'] == "COMPLETED"
        puts "Payment verified and COMPLETED"
        email = req.POST['senderEmail']
        puts "Fetching user #{email}..."
        user = User.find_by(email: email)
        puts user.class
        puts user
        puts "Found user: #{user.email}"
        puts "Crediting days to user..."
        sku = ipn_response.order_items.first.sku

        package = Packages::PACKAGE_BY_SKU[sku]
        user.inc(:premium_days, package.premium_days)
        user.inc(:sms_account, package.sms_account)

        # user.update_attribute(:premium_days, (user.premium_days + 30))
        puts "Days credited"
      else
        puts "Something went wrong"
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
      puts "Nu kom nån jävel allt fel post"
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
end
