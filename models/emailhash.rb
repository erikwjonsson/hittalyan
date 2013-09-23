#encoding: UTF-8

class EmailHash
  include Mongoid::Document
  include Mongoid::Timestamps

  field :hashed_email, type: String

  index({hashed_email: 1 }, {unique: true})

  validates :hashed_email, presence: true
  validates :hashed_email, uniqueness: true
end
