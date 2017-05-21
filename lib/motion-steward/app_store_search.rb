require 'net/http'
require 'json'
require 'open-uri'
require 'pp'
require 'date'

class String
  def underscore
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
end

class MotionSteward::AppStoreSearch
  def self.search_for_app term
    results = get 'search',
                  media: 'software',
                  term: URI.encode(term),
                  country: 'us',
                  limit: 15

    pluck results['results'],
          %w(genres price track_name track_id average_user_rating user_rating_count release_date current_version_release_date price)
  end

  def self.pluck json, values
    if json.is_a? Array
      json.map do |o|
        to_hash(o).select { |k, _| values.include? k.to_s }
      end
    else
      to_hash(json).select { |k, _| values.include? k }
    end
  end

  def self.construct_uri(path)
    URI.parse('https://itunes.apple.com/' + path)
  end

  def self.convert_to_date_maybe k, v
    return v if k !~ /date/i

    begin
      Date.parse(v).to_date
    rescue
      v
    end
  end

  def self.to_hash h
    h.inject({}) do |memo, (k, v)|
      new_v = convert_to_date_maybe(k, v)
      memo[k.underscore.to_sym] = new_v
      memo
    end
  end

  def self.get path, querystring
    first = true
    querystring.each do |k, v|
      if first
        path += '?'
        first = false
      else
        path += '&'
      end
      path += "#{k}=#{v}"
    end

    uri = construct_uri path
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(req)
    JSON.parse(response.body)
  end
end
