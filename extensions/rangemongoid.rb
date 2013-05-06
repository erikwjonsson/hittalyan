# Fixes issue when mongoid runs mongoize on a hash-like object.
# Example of code which caused an error to be raised:
#   document_from_client = {'active' => false, 'notify_by_push_note' => true, 'filter' => {'rooms'=> {'min' => 2, 'max' => 3} }  }
#   user.external_update!(document_from_client)
class Range
  def self.mongoize(object)
    return nil if object.nil?
    
    if object.respond_to?(:last)
      { "min" => object.first, "max" => object.last }
    else # seems we have a Hash-like object. Just return it.
      object
    end
  end
end