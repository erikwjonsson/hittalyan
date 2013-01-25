class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (0..0)
  field :rent, type: Integer, default: 0
  field :area, type: Range, default: (0..0)

  def to_hash
    hashified = {roomsMin: user.filter.rooms.first,
                 roomsMax: user.filter.rooms.last,
                 rent: user.filter.rent,
                 areaMin: user.filter.area.first,
                 areaMax: user.filter.area.last}
  end
end