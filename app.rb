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

def init_mobile_session(user)
  sid = SecureRandom.uuid
  Session.create!(sid: sid, user: user)
  sid
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

# Very basic way of rendering Angular serverside
# Only supports ng-view and presupposes the view should be included in
# index.html.
def send_serverside_rendered_view(view)
  superview = File.read(File.join('public', "index.html"))
  subview = File.read(File.join('public', "#{view}.html"))
  subview_declaration = '<div ng-view></div>'
  res.write superview.sub(subview_declaration, subview)
end

# filter - Filter object
# days_ago - int
def filtered_apartments_since(filter, days_ago)
  apartments = Apartment.all
  apartments.select do |apartment|
    (filter.rent >= apartment.rent &&
    filter.rooms === apartment.rooms &&
    filter.area  === apartment.area) &&
    filter.cities.include?(apartment.city) &&
    apartment.advertisement_found_at >= days_ago.days.ago
  end
end

Cuba.define do
  # Mobile Specials
  on "mobile" do
    on "login", param('email'), param('password') do |email, password|
      on post do
        user = User.authenticate(email, password)
        if user
          sid = init_mobile_session(user)
          send_json({sid: sid})
        else
          res.status = 401 # unauthorized
          res.write "Ogiltig e-postadress eller lösenord."
        end
      end
    end
    
    on ":sid" do |sid|
      on get do
        send_json User.all.map { |u| u.as_external_document}
      end
      
      on post do
        res.write "Made successful post"
      end
      
      on put do
        res.write "Made successful put"
      end
      
      on delete do
        res.write "Made successful delete"
      end
    end
  end
  #GET-----------------------------------------
  on get do
    # Support for Google's AJAX crawling scheme.
    # Route and filename has to match.
    on env['REQUEST_URI'].include?("_escaped_fragment_=") do
      fragment = env['REQUEST_URI']
      view_name = fragment.split('/').last
      view_name = 'landing' if view_name == ''
      send_serverside_rendered_view(view_name)
    end

    on "test" do
      puts "Putsing: #{Time.now}"
      send_view "test"
    end
  
    on "" do
      user_agent = env['HTTP_USER_AGENT'].downcase
      if ['google', 'msnbot', 'yahoo'].any? {|bot| user_agent.include?(bot)}
        # To make sure AJAX parsing works on the root url.
        LOG.info "Visit from search bot: #{user_agent}"
        send_serverside_rendered_view('landing')
      else
        # The usual case, when real people visit.
        send_view "index"
      end
    end
    
    on "environment" do
      res.write ENVIRONMENT.to_s
    end
    
    on "loggedin" do
      res.status = 401 unless current_user(req)
    end
    
    on "landing" do
      send_view "landing"
    end
    
    on "vanliga-fragor" do
      send_view "vanliga-fragor"
    end
    
    on "om" do
      send_view "om"
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
          external_packages = Packages::PACKAGES.select do |package|
            # Unselect packages the user should never see. These are to be kept
            # behind locked doors and closed windows at all times. Always.
            criteria_a = package.show
            
            # Unselect packages that the user shouldn't be interested in seeing
            criteria_b = package.show_to_premium == user.active
            
            # Unselect if trial
            criteria_c = package.show_to_trial == user.trial

            # Fulhack to show startpackage to trial users
            if package.show_to_trial && user.trial
              true
            else
              criteria_a && criteria_b && criteria_c
            end
          end
          
          external_packages.map! do |package|
            package.as_external_document
          end
          
          send_json(external_packages)
        end
        
        on "coupon/:code" do |code|
          begin
            coupon = Coupon.where(code: code, valid: true).first.as_external_document
          rescue StandardError => e
            coupon = Coupon.where(code: "NONE").first.as_external_document
          end
          send_json(coupon)
        end
        
        on "installningar" do
          send_view "filtersettings"
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
        
        on "prenumeration" do
          on "betalningsbekraftning" do
            send_view "betalningsbekraftning"
          end
          send_view "prenumeration"
        end
        send_view "medlemssidor"
      end
    end
    
    on "login" do
      send_view "login"
    end
    
    on "registrera" do
      send_view "registrera"
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

    on ":user_id/aktivera_testperiod" do |user_id|
      user = User.find(user_id)
      unless user.trial
        # Giving the user her free trial period
        package = Packages::PACKAGE_BY_SKU["TRIAL7"]
        user.apply_package(package)
        LOG.info "Applied trial package to the user #{user.email}"
      end
      res.write 'Din testperiod har aktiverats. <a href="/#!/medlemssidor">Till HittaLyan</a>'
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

    on "payson_pay", param('sku'), param('code') do |sku, code|
      user = current_user(req)
      payment = PaysonPayment.create!(user_email: user.email,
                                      package_sku: sku,
                                      promotional_code: code)
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
          res.status = 400 # unauthorized
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
        
        # Giving the user her free trial period
        package = Packages::PACKAGE_BY_SKU["TRIAL7"]
        user.apply_package(package)
        
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
          begin
            user.external_update!(client_user_model)
          rescue StandardError => e
            res.status = 400 #Bad request
          end
        end
        
        on "account_termination", param('password') do |password|
          if user.has_password?(password)
            user.session.delete
            user.delete
          else
            res.status = 400 #Bad request
          end
        end
        
        on "change_password", param('new_password'), param('old_password') do |new_password, old_password|
          begin
            user.change_password(new_password, old_password)
          rescue User::WrongPassword
            res.status = 400 #Bad request
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
          body = ["<p>Hej!</p>",
                  %[<p>Klicka <a href="#{WEBSITE_ADDRESS}/#!/losenordsaterstallning/#{reset.hashed_link}">här</a> för att sätta ett nytt lösenord.</p>],
                  "<p>Observera att länken endast är giltig i 12 timmar och att du måste klicka på länken i det senaste e-postmeddelandet om du tryckt flera gånger på att återställa ditt lösenord.</p>",
                  "<p>Med vänlig hälsning,<br/>",
                  "HittaLyan</p>"].join("\n")
          Mailer.shoot_email(email,
                      "Lösenordsåterställning",
                      body,
                      'html')
        else
          puts "Password reset request for non-existent user #{email}."
        end
      end

      on param('hash'), param('new_password') do |hash, new_pass|
        if reset = Reset.find_by(hashed_link: hash)
          if (Time.now - reset.created_at) < 43200 # 12 hours
            user = User.find_by(email: reset.email)
            user.change_password!(new_pass)
            reset.delete # So the link cannot be used anymore
            send_json(user.as_external_document)
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
      Mailer.shoot_email(Mailer::OUR_STANDARD_EMAIL, "Meddelande via kontaktformulär", message, 'text', email)
    end

    on ":catchall" do
      LOG.info "Nu kom nån jävel allt fel post"
      res.status = 404 # not found
      res.write "Nu kom du allt fel din javel!"
    end
  end
end
