class Filter
  include Mongoid::Document
  embedded_in :user
  field :rent, type: Range
  field :rooms, type: Range
  field :area, type: Range  
end