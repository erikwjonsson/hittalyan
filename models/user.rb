#encoding: utf-8

require 'digest'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include LingonberryMongoidImportExport

  externally_accessible :filter, # embedded document, all fields
                        :email, 
                        :first_name,
                        :last_name,
                        :referee,
                        :mobile_number,
                        :notify_by_email,
                        :notify_by_sms,
                        :notify_by_push_note,
                        :permits_to_be_emailed,
                        :notification_times,
                        :stop_sending_notifications_at,
                        :start_sending_notifications_at,
                        '_id'

  externally_readable   :active,
                        :sms_account,
                        :premium_until

  field :email, type: String
  field :first_name, type: String, default: ""
  field :last_name, type: String, default: ""
  field :referee, type: String, default: ""
  field :mobile_number, type: String
  field :hashed_password, type: String
  field :notify_by_email, type: Boolean, default: true
  field :notify_by_sms, type: Boolean, default: false
  field :notify_by_push_note, type: Boolean, default: false
  field :stop_sending_notifications_at, type: Integer, default: 2359
  field :start_sending_notifications_at, type: Integer, default: 0
  field :permits_to_be_emailed, type: Boolean, default: true
  field :active, type: Boolean, default: false # normally equivalent to "has paid"
  field :premium_until, type: Time
  field :sms_until, type: Time
  field :sms_account, type: Integer, default: 0
  field :unsubscribe_id, type: String
  field :trial, type: Boolean, default: false

  # Diagnostic fields
  field :has_received_welcome_email, type: Boolean, default: false
  field :greeted_by_apartmentor, type: Boolean, default: false
  field :has_been_reminded, type: Boolean, default: false
  field :has_been_reminded_again, type: Boolean, default: false
  # To prevent SubscriptionEnd emails if user has never had an active subscription
  field :has_been_notified_that_subscription_has_expired, type: Boolean, default: true
  field :has_been_enquired_about_gotten_startedness, type: Boolean, default: false

  has_one :session
  embeds_one :filter
  SALT = 'aa2c2c739ba0c61dc84345b1c2dc222f'
  UNSUBSCRIBE_SALT = 'lu5rnzg9wgly9a2l1ftbdij7edb6e6'
  
  validates :email, presence: true, uniqueness: true, length: { maximum: 64 }
  # Note that hashed_password isn't hashed at the point of validation
  validates :hashed_password, presence: true, length: { minimum: 6, maximum: 64}
  
  validate :validate_and_coerce_mobile_number_format
  
  before_validation do |document|
    # When a user registers, downcase the email address.
    # This will downcase the email unnecessarily whenever the document
    # is updated. But life is life, what to do? 
    document.email.downcase!
  end

  # This is where hashed_password becomes true to it's name
  before_create do |document|
    document.hashed_password = Encryption.encrypt(SALT, document.hashed_password)
    generate_unsubscribe_id
  end

  def validate_and_coerce_mobile_number_format
    return unless self.mobile_number
    # Removes whitespace and dashes
    self.mobile_number = self.mobile_number.gsub(/\s+|\-+/, "")

    if self.mobile_number == ""
    elsif self.mobile_number[0..1] == '00'
      # International number, same meaning as +.
      self.mobile_number.sub!('00', '+')
    elsif self.mobile_number[0] == '0'
      # Starts with 0 but isn't a country code, default to Swedish number.
      self.mobile_number.sub!('0', '+46')
    elsif self.mobile_number[0] != '+'
      # Comment for humans: If we got this far the number didn't start with a
      # single or double 0 and... it didn't even start with a plus.
      # Gasp! It must be from outer space, yao.
      raise MalformedMobileNumber
    end
  end

  def unsubscribe_from_email_notifications_link
    unsubscribe_link(:notifications)
  end

  def unsubscribe_from_email_communications_link
    unsubscribe_link(:communications)
  end

  def unsubscribe_from_all_emails_link
    unsubscribe_link(:all)
  end
  
  def has_password?(submitted_password)
    self.hashed_password == Encryption.encrypt(SALT, submitted_password)
  end

  def self.authenticate(email, submitted_password)
    user = self.find_by(email: email.downcase)
    return nil unless user
    return user if user.has_password?(submitted_password)
  end
  
  # Needs both a new_password (duh) and old_password for extra security
  def change_password(new_password, old_password)
    raise WrongPassword unless has_password?(old_password)
    change_password!(new_password)
  end
  
  # Only needs new_password. Use with care since possibly someone without proper
  # authority could arbitrarily change the password.
  def change_password!(new_password)
    # We really want to validate the new_passord before it gets hashed.
    # We jut don't know how. Crap.
    if new_password.length >= 6 && new_password.length <= 64 
      self.update_attribute(:hashed_password, Encryption.encrypt(SALT, new_password))
    else
      raise NewPasswordFailedValidation
    end
  end
  
  class WrongPassword < StandardError
    def message
      "Submitted password does not match."
    end
  end

  def apply_package(package)
    if package.sku.include?('TRIAL7') && EmailHash.find_by(hashed_email: Encryption.encrypt(SALT, self.email))
      LOG.info "Old deleted user re-registered. User will not get TRIAL7 package."
      shoot_welcome_email
      return
    else
      EmailHash.create(hashed_email: Encryption.encrypt(SALT, self.email))
    end
    add_premium_days(package.premium_days) if package.premium_days && package.premium_days > 0
    # New model where each user has an infinite amount of sms to spend/use
    add_sms_days(package.sms_days) if package.sms_days
    # Old model where each user has a finite amount of sms to spend/use
    # self.inc(:sms_account, package.sms_account) if package.sms_account
    if package.active
      self.update_attribute(:active, package.active)
      self.update_attribute(:has_been_reminded, false)
      self.update_attribute(:has_been_reminded_again, false)
      self.update_attribute(:has_been_notified_that_subscription_has_expired, false)
    end
    self.update_attribute(:trial, package.trial)
    begin
      shoot_welcome_email if package.sku.include?('START')
      shoot_welcome_email if package.sku.include?('TRIAL7')
    rescue Exception => e
      puts "Failed to send welcome email to #{self.email}."
      log_exception(e)
    end
  end

  class NewPasswordFailedValidation < StandardError
    def message
      "New password failed validation."
    end
  end
  
  class MalformedMobileNumber < StandardError
    def message
      "We do not accept extra-terrestrial phone numbers. Sorry."
    end
  end
  
  def subtract_sms
    self.inc(:sms_account, -1) if self.sms_account > 0
  end
  
  # Shitty_code_begin >>>
  def needs_reminding
    trial_days = 2
    active_days = 4
    self.premium_until ||= Time.zone.now
    
    # For trial users
    # If user is active and trial and hasn't been reminded and has less than #{trial_days} left
    if self.active && self.trial && self.has_been_reminded != true && (self.premium_until - Time.zone.now) < trial_days*24*60*60
      return true
    end
    
    # For non-trial users
    # If user is active and isn't trial and hasn't been reminded and has less than #{active_days} left
    if self.active && self.trial != true && self.has_been_reminded != true && (self.premium_until - Time.zone.now) < active_days*24*60*60
      return true
    end
    false
  end
  # <<< Shitty_code_end

  private
    def shoot_welcome_email
      Mailer.shoot_email(self,
                         'Välkommen - startinstruktioner och tips',
                          render_mail("welcome_as_premium_member", binding),
                         'html')
      self.update_attribute(:has_received_welcome_email, true)
    end

    def add_premium_days(days_to_add)
      time_from = if self.active && self.premium_until > 1.day.from_now.midnight
                    self.premium_until
                  else
                    1.day.from_now.midnight
                  end
      # LOG.debug "TIME FROM #{time_from}"
      self.update_attribute(:premium_until, (time_from + days_to_add.days))
    end

    def add_sms_days(days_to_add)
      time_from = if self.sms_until && self.sms_until > 1.day.from_now.midnight
                    self.sms_until
                  else
                    1.day.from_now.midnight
                  end
      self.update_attribute(:sms_until, (time_from + days_to_add.days))
    end

    def generate_unsubscribe_id
      self.unsubscribe_id = Encryption.encrypt(SALT, (email + Time.now.to_s + UNSUBSCRIBE_SALT))
    end

    # from_what - all/notifications/
    def unsubscribe_link(from_what)
      generate_unsubscribe_id unless self.unsubscribe_id
      URI::join(WEBSITE_ADDRESS, "/emails/unsubscribe/#{from_what.to_s}/#{self.unsubscribe_id}").to_s
    end
end
