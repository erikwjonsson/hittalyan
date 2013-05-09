class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (1..999)
  field :rent, type: Integer, default: 999999
  field :area, type: Range, default: (10..9999)
  field :cities, type: Array, default: ["Stockholm"]
end
