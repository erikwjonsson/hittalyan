class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (1..999)
  field :rent, type: Integer, default: 999999
  field :area, type: Range, default: (10..9999)

  # Deprecated, see user.settings_to_hash.
  # def to_hash
  #   hashified = {roomsMin: self.rooms.first,
  #                roomsMax: self.rooms.last,
  #                rent: self.rent,
  #                areaMin: self.area.first,
  #                areaMax: self.area.last}
  # end
end
