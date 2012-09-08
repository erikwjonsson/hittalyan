# encoding: UTF-8
class Landlord
  attr_reader :city, :url, :apartments, :new_apartments
  
  def name
    "#{self.class} in #{city.to_s.gsub('_', ' ').capitalize}"
  end
  
  def initialize(city, url)
    @url = url
    @city = city
  end
  
  def refresh
    fetch_new_apartments(listing)
  end
  
  
  private
  
    def fetch_new_apartments(rows)
			rows.each do |row|
				row_to_apartment(row)
			end
		end
  
    # Navigate to list of apartments and return it in a form that
    # fetch_new_apartments can process, e.g. html table rows as an array of
    # strings.
    def listing
    end
  
    # Convert a row (e.g. a html tr) into an Apartment object and returns it.
    def row_to_apartment
    end
end