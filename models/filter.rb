class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (1..999)
  field :rent, type: Integer, default: 999999
  field :area, type: Range, default: (10..9999)

  def to_hash
    hashified = {roomsMin: user.filter.rooms.first,
                 roomsMax: user.filter.rooms.last,
                 rent: user.filter.rent,
                 areaMin: user.filter.area.first,
                 areaMax: user.filter.area.last}
  end
end