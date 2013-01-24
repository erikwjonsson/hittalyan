class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (0..0)
  field :rent, type: Integer, default: 0
  field :area, type: Range, default: (0..0)
end