# encoding: UTF-8

class Coupon
  include Mongoid::Document
  include Mongoid::Timestamps
  include LingonberryMongoidImportExport

  externally_readable   :code,
                        :description,
                        :discount_in_percentage_units,
                        :valid
                        
  field :code, type: String
  field :description, type: String
  field :discount_in_percentage_units, type: Integer
  field :valid, type: Boolean
end
