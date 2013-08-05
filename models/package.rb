class Package
  include Mongoid::Document
  include Mongoid::Timestamps
  include LingonberryMongoidImportExport

  externally_readable :name,
                      :description,
                      :unit_price_in_ore,
                      :sku,
                      :priority

  field :name, type: String
  field :description, type: String
  field :payson_description, type: String
  field :unit_price_in_ore, type: Integer
  field :priority, type: Integer
  field :show_to_premium, type: Boolean
  field :show, type: Boolean, default: true
  field :trial, type: Boolean, default: false
  field :show_to_trial, type: Boolean, default: false

  field :premium_days, type: Integer, default: 0
  field :sms_account, type: Integer, default: 0
  field :active, type: Boolean, default: false
  
  field :tax_in_percentage_units, type: Integer, default: 25
  field :quantity, type: Integer, default: 1
  field :sku, type: String

  validates :name, uniqueness: true, presence: true
  validates :description, uniqueness: true, presence: true
  validates :payson_description, uniqueness: true, presence: true
  validates :quantity, numericality: {equal_to: 1}
  validates :unit_price_in_ore, presence: true
  validates :tax_in_percentage_units, numericality: {equal_to: 25}
  validates :sku, uniqueness: true, presence: true

  def as_order_item(coupon)
    package_price = self.unit_price_in_ore/100.0
    tax = self.tax_in_percentage_units/100.0 + 1
    discount = coupon.discount_in_percentage_units/100.0
    PaysonAPI::OrderItem.new(self.payson_description,
                             correct_for_flooring_and_tax(package_price, tax, discount),
                             self.quantity,
                             self.tax_in_percentage_units/100.0,
                             self.sku)
  end
  
  private
  
  def correct_for_flooring_and_tax(package_price, tax, discount)
    end_sum_we_want = (package_price*tax*(1-discount)).floor
    new_package_price = end_sum_we_want/tax
  end
end
