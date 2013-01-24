class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (0..0)
  field :rent, type: Integer, default: 0
  field :area, type: Range, default: (0..0)

  def to_hash
    hashified = {roomsMin: user.filter.rooms.min,
                 roomsMax: user.filter.rooms.max,
                 rent: user.filter.rent,
                 areaMin: user.filter.area.min,
                 areaMax: user.filter.area.max}
  end
end