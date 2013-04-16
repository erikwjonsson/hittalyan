#encoding: utf-8

class PaymentInitiationError < StandardError
  def initialize(response)
    @response = response
  end

  def message
    "There was an error initiating payment.\n#{@response.errors}"
  end
end

class Payment
  include Mongoid::Document

end

class PaysonPayment < Payment
  attr_reader :forward_url
  include Mongoid::Document
  
  RETURN_URL = WEBSITE_ADDRESS + '#/medlemssidor/premiumtjanster'
  CANCEL_URL = WEBSITE_ADDRESS + '#/medlemssidor/premiumtjanster'
  IPN_URL = WEBSITE_ADDRESS + 'ipn'
  MEMO = "Medlemspaket för #{BRAND_NAME}."
  
  field :payment_uuid, type: String # Set on create
  field :user_email, type: String
  field :package_sku, type: String
  field :time , type: Time # Set on create
  field :amount, type: Integer # Set on create
  field :status, type: String # Set on create
  
  validates :user_email, presence: true
  validates :package_sku, presence: true
  
  before_create do |document|
    document.payment_uuid = generate_payment_uuid
    document.time = Time.now
    document.amount = amount
    document.status = "CREATED"
  end
  
  def receiver
    PaysonAPI::Receiver.new(
    'testagent-1@payson.se', # Email
    amount,  # Amount
    'Pablo', # First name
    'Gonza', # Last name
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
    payment.order_items = [@package.as_order_item]

    response = PaysonAPI::Client.initiate_payment(payment) # Response
    raise PaymentInitiationError.new(response) unless response.success?
    self.update_attribute(:status, "INITIALIZED")
    @forward_url = response.forward_url
  end
  
  def ipn_response(req=nil)
    if req
      @ipn_response = PaysonAPI::Response::IPN.new(req.body.read)
    elsif @ipn_response
      return @ipn_response
    else
      return nil
    end
  end
  
  def ipn_request(ipn_response=nil)
    if ipn_response
      @ipn_request = PaysonAPI::Request::IPN.new(ipn_response.raw)
    elsif @ipn_request
      return @ipn_request
    elsif @ipn_response
      @ipn_request = PaysonAPI::Request::IPN.new(@ipn_response.raw)
    else
      return nil
    end
  end

  def validate
    validation = PaysonAPI::Client.validate_ipn(ipn_request)
    if validation.verified? && completed?
      self.update_attribute(:status, "COMPLETED")
      return true
    else
      self.update_attribute(:status, "FAIL")
      return false
    end
  end
  
  private
  
  def completed?
    @ipn_response.status == "COMPLETED"
  end

  def amount
    @package ||= Packages::PACKAGE_BY_SKU[self.package_sku]
    (@package.unit_price_in_ore/100)*(@package.tax_in_percentage_units/100.0 + 1)
  end

  def generate_payment_uuid
    SecureRandom.uuid
  end
end
