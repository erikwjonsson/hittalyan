class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range
  field :rent, type: Integer
  field :area, type: Range
end