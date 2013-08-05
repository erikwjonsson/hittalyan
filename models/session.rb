class Session
  include Mongoid::Document
  include Mongoid::Timestamps
  field :sid, type: String
  belongs_to :user
  
  def self.authenticate(sid)
    session = self.find_by(sid: sid)
    if session
      session.user
    else
      false
    end
  end
end