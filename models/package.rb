class Package
  include Mongoid::Document
  include LingonberryMongoidImportExport

  externally_readable :name,
                      :description,
                      :unit_price_in_ore,
                      :sku,
                      :priority,
                      :show_to_premium

  field :name, type: String
  field :description, type: String
  field :payson_description, type: String
  field :unit_price_in_ore, type: Integer
  field :priority, type: Integer
  field :show_to_premium, type: Boolean

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

  def as_order_item
    PaysonAPI::OrderItem.new(self.payson_description,
                             self.unit_price_in_ore/100,
                             self.quantity,
                             self.tax_in_percentage_units/100.0,
                             self.sku)
    end
end
