# To let us use URI as a type with Mongoid
# For more info, see http://mongoid.org/en/mongoid/docs/documents.html#fields
class URI::HTTP
  def mongoize
    self.to_s
  end
  
  class << self
    
    def demongoize(object)
      URI(object)
    end
    
    def mongoize(object)
      case object
      when URI::HTTP then object.mongoize
      when String then URI(object).mongoize
      else object
      end
    end
    
    def evolve(object)
      case object
      when URI::HTTP then object.mongoize
      else object 
      end
    end
  end

  def as_json
    self.to_s
  end
end
