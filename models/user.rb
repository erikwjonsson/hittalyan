require 'digest'

class User
  include Mongoid::Document
  field :email, type: String
  field :hashed_password, type: String
  field :name, type: String
  field :notify_by, type: Array # e.g. :email, :sms etc.
  field :active, type: Boolean, default: false # normally equivalent to "has paid"
  has_one :session
  has_one :filter
  @@salt = 'aa2c2c739ba0c61dc84345b1c2dc222f'
  
  validates_presence_of :email, :hashed_password, :name, :notify_by
  validates_length_of :hashed_password, minimum: 6, maximum: 16
  validates_length_of :name, minimum: 2, maximum: 50
  
  before_create do |document|
    document.hashed_password = encrypt(document.hashed_password)
  end
  
  def self.authenticate(email, submitted_password)
    user = self.find_by(email: email)
    return nil unless user
    return user if user.has_password?(submitted_password)
  end
  
  def has_password?(submitted_password)
    self.hashed_password == encrypt(submitted_password)
  end
  
  private
    
    def encrypt(s)
      hash_string(@@salt + s)
    end
    
    def hash_string(s)
      Digest::SHA2.hexdigest(s)
    end
    
end