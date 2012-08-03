class Apartment
  include Mongoid::Document
  field :address, type: String
  field :region, type: String # e.g. which part of city
  field :rent, type: Integer
  field :rooms, type: Integer
  field :area, type: Integer # e.g. in square meters
  field :url, type: URI::HTTP
  field :marked_as_read, type: Boolean
  belongs_to :landlord
end