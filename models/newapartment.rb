class NewApartment
	include Mongoid::Document
	field :apartment_id, type: String
	
	validates :apartment_id, presence: true, uniqueness: true
end