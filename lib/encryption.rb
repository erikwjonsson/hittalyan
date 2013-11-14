module Encryption
  def self.encrypt(salt, s)
    hash_string(salt + s)
  end
  
  def self.hash_string(s)
    Digest::SHA2.hexdigest(s)
  end
end
