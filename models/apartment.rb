# encoding: UTF-8

class Apartment
  include Mongoid::Document
  field :address, type: String
  field :region, type: String # e.g. which part of city
  field :rent, type: Integer
  field :rooms, type: Integer
  field :area, type: Integer # e.g. in square meters
  field :url, type: URI::HTTP
  field :landlord, type: String
	
	validates :url, presence: true, uniqueness: true
	validates :address, :region, :rent, :rooms, :area, :landlord,
						presence: true
end

