class Filter
  include Mongoid::Document
  belongs_to :user
  field :rent, type: Range
  field :rooms, type: Range
  field :area, type: Range  
end