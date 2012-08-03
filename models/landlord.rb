class Landlord
  include Mongoid::Document
  field :name, type: String
  field :city, type: Symbol
  field :url, type: URI::HTTP
  has_many :apartments
end