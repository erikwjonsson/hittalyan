#encoding: utf-8

class Payment
  include Mongoid::Document
  include LingonberryMongoidImportExport
  class InitiationError < StandardError
    def initialize(response)
      @response = response
    end

    def message
      "There was an error initiating payment.\n#{@response.errors}"
    end
  end
end

class PaysonPayment < Payment
  attr_reader :forward_url

  externally_readable   :user_email,
                        :package_sku,
                        :amount,
                        :status,
                        :promotional_code
  
  RETURN_URL = WEBSITE_ADDRESS + '#!/medlemssidor/prenumeration/betalningsbekraftning'
  CANCEL_URL = WEBSITE_ADDRESS + '#!/medlemssidor/prenumeration'
  IPN_URL = WEBSITE_ADDRESS + 'ipn'
  MEMO = "Medlemspaket för #{BRAND_NAME}."
  
  field :payment_uuid, type: String # Set on create
  field :user_email, type: String
  field :package_sku, type: String
  field :promotional_code, type: String
  field :time , type: Time # Set on create
  field :amount, type: Integer # Set on create
  field :status, type: String # Set on create
  
  validates :user_email, presence: true
  validates :package_sku, presence: true
  validates :promotional_code, presence: true
  validate :validate_coupon
  
  before_create do |document|
    document.payment_uuid = generate_payment_uuid
    document.time = Time.now
    document.amount = amount
    document.status = "CREATED"
  end
  
  def validate_coupon
    raise InvalidCoupon unless Coupons::COUPON_BY_CODE[self.promotional_code].valid
  end
  
  class InvalidCoupon < StandardError
    def message
      "This coupon is not valid"
    end
  end
  
  def receiver
    PaysonAPI::Receiver.new(
    'betalningar@lingonberryproductions.se', # Email
    amount,  # Amount
    'Joachim', # First name
    'Karlsson', # Last name
    true)    # Primary
  end
  
  def sender
    @user ||= User.find_by(email: self.user_email) 
    PaysonAPI::Sender.new(
    @user.email,
    @user.first_name,
    @user.last_name)
  end
  
  def initiate_payment
    payment = PaysonAPI::Request::Payment.new(
      RETURN_URL,
      CANCEL_URL,
      IPN_URL,
      MEMO,
      sender,
      [receiver],
      self.payment_uuid) # Comment
    payment.order_items = [@package.as_order_item(Coupons::COUPON_BY_CODE[self.promotional_code])]

    response = PaysonAPI::Client.initiate_payment(payment) # Response
    raise Payment::InitiationError.new(response) unless response.success?
    self.update_attribute(:status, "INITIALIZED")
    @forward_url = response.forward_url
  end
  
  def validate(ipn_response, ipn_request)
    validation = PaysonAPI::Client.validate_ipn(ipn_request)
    if validation.verified? && ipn_response.status == "COMPLETED"
      self.update_attribute(:status, "COMPLETED")
      return true
    else
      self.update_attribute(:status, "FAIL")
      return false
    end
  end
  
  private

  def amount
    @package ||= Packages::PACKAGE_BY_SKU[self.package_sku]
    @coupon ||= Coupons::COUPON_BY_CODE[self.promotional_code]
    package_price = @package.unit_price_in_ore/100.0
    tax = @package.tax_in_percentage_units/100.0 + 1
    discount = @coupon.discount_in_percentage_units/100.0
    (package_price*tax*(1-discount)).floor
  end

  def generate_payment_uuid
    SecureRandom.uuid
  end
end
