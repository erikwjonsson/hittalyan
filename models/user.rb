require 'digest'

class User
  include Mongoid::Document
  field :email, type: String
  field :hashed_password, type: String
	field :notify_by_email, type: Boolean, default: false
	field :notify_by_sms, type: Boolean, default: false
	field :notify_by_push_note, type: Boolean, default: false
  field :active, type: Boolean, default: false # normally equivalent to "has paid"
  has_one :session
  embeds_one :filter
  @@salt = 'aa2c2c739ba0c61dc84345b1c2dc222f'
  
  validates_presence_of :email, :hashed_password
  validates_length_of :hashed_password, maximum: 64
  validates_uniqueness_of :email
  
  before_validation do |document|
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
