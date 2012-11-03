# encoding: UTF-8

require 'digest'

class Reset
  include Mongoid::Document
  field :email, type: String # User
  field :created_at, type: DateTime # So we can know age
  field :hashed_link, type: String # Unique, based on created_at and email
  @@salt = '106c8556d820df55f45a18b999eeca45'

	validates :email, :created_at, :hashed_link, presence: true
  validates :hashed_link, uniqueness: true

	before_validation do |document|
    document.created_at = Time.now
    document.hashed_link = encrypt(document.email, document.created_at.to_s)
  end

  def refresh()
    self.created_at = Time.now
    self.hashed_link = encrypt(self.email, self.created_at.to_s)
    save
  end

  private
    
    def encrypt(email, created_at)
      hash_string(email + created_at + @@salt)
    end
    
    def hash_string(s)
      Digest::SHA2.hexdigest(s)
    end
end