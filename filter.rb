class Filter
  include Mongoid::Document
  belongs_to :user
  field :rent, type: Integer
  field :rooms, type: Integer
  field :area, type: Integer  
end