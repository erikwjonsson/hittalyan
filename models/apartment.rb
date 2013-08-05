# encoding: UTF-8

class Apartment
  include Mongoid::Document
  include Mongoid::Timestamps

  ###
  # Descriptive fields
  field :landlord, type: String
  field :city, type: String
  field :address, type: String
  field :region, type: String # e.g. which part of city
  field :rent, type: Integer
  field :rooms, type: Integer
  field :area, type: Integer # e.g. in square meters
  field :url, type: String
  field :short_url, type: String
  
  ###
  # State
  field :advertised, type: Boolean, default: true

  field :advertisement_found_at, type: Time, default: nil
  field :advertisement_removed_at, type: Time, default: nil

	validates :url, presence: true, uniqueness: true
	validates :address, :region, :rent, :rooms, :area, :landlord, :city,
						presence: true

  ###
  # Indexes
  index({url: 1 }, {unique: true})
  index({advertised: 1})

  # For remove_apartments_no_longer_advertised()
  index({url: 1, advertised: 1, city: 1, landlord: 1}, {unique: true})

  before_create do |document|
    self.advertisement_found_at = Time.now
    self.short_url = shorten(self.url)
  end

  private

  def shorten(long_url)
    uri = URI.parse("https://www.googleapis.com/urlshortener/v1/url")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = ActiveSupport::JSON.encode({"longUrl" => long_url, "key" => GOOGLE_API_KEY})
    response = http.request(request)
    short_url = ActiveSupport::JSON.decode(response.body)['id']
    short_url
  end

end

