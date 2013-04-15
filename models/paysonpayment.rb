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
  
  validates :user_email, presence: true
  validates :package_sku, presence: true

  before_create do |document|
    document.payment_uuid = generate_payment_uuid
    document.time = Time.now
    document.amount = amount
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
      [receiver])
    payment.order_items = [@package.as_order_item]

    response = PaysonAPI::Client.initiate_payment(payment) # Response
    raise PaymentProcessingError.new(response) unless response.success?
    @forward_url = response.forward_url
  end

  private

  def amount
    @package ||= Packages::PACKAGE_BY_SKU[self.package_sku]
    (@package.unit_price_in_ore/100)*(@package.tax_in_percentage_units/100.0 + 1)
  end

  def generate_payment_uuid
    SecureRandom.uuid
  end
end
