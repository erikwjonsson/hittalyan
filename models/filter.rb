class Filter
  include Mongoid::Document
  embedded_in :user
  field :rooms, type: Range, default: (1..1)
  field :rent, type: Integer, default: 1000
  field :area, type: Range, default: (10..10)

  def to_hash
    hashified = {roomsMin: user.filter.rooms.first,
                 roomsMax: user.filter.rooms.last,
                 rent: user.filter.rent,
                 areaMin: user.filter.area.first,
                 areaMax: user.filter.area.last}
  end
end