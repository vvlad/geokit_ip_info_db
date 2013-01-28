class GeoKit::Geocoders::IpInfoDbGeocoder < Geokit::Geocoders::Geocoder

  cattr_accessor :api_key
  cattr_accessor :api_timeout
  self.api_timeout = 2

  private

  def self.do_geocode(ip, options = {})
    return GeoKit::GeoLoc.new if '0.0.0.0' == ip
    return GeoKit::GeoLoc.new if '127.0.0.1' == ip
    return GeoKit::GeoLoc.new unless /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/.match(ip)
    url = "http://api.ipinfodb.com/v2/ip_query.php?key=#{api_key}&ip=#{ip}&timezone=false&output=json"
    response = begin
      timeout(api_timeout) do
        self.call_geocoder_service(url)
      end
    rescue TimeoutError
      response = nil
    end
    return GeoKit::GeoLoc.new if !response.is_a?(Net::HTTPSuccess)

    response.is_a?(Net::HTTPSuccess) ? parse_body(response.body) : GeoKit::GeoLoc.new
  rescue
    if defined? logger
      logger.error "Caught an error during IpInfoDbGeocoder geocoding call: #{$!}"
    else
      warn "Caught an error during IpInfoDbGeocoder geocoding call: #{$!}"
    end

    return GeoKit::GeoLoc.new
  end

  def self.parse_body(body) # :nodoc:
    json = JSON.parse(body)
    res = GeoKit::GeoLoc.new
    res.provider = 'ipinfodb'
    res.city = json['City']
    res.state = json['RegionName']
    res.country = json['CountryName']
    res.country_code = json['CountryCode']
    res.lat = json['Latitude']
    res.lng = json['Longitude']
    res.success = json['Status'] == 'OK'
    res
  end

end
