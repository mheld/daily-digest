require 'open-uri'
require 'json'

WUNDERGROUND_KEY = ""

def get_now_and_later_for(city)
  res = open("http://api.wunderground.com/api/#{WUNDERGROUND_KEY}/conditions/forecast/q/CA/#{city}.json", 'UserAgent' => 'Ruby-open-uri', 'Accept-Encoding' => 'gzip')
  unless res.content_encoding == ['gzip'] then
    str = res.read
  else
    str = Zlib::GzipReader.new(res).read
  end
  json = JSON.parse(str)
  current = json["current_observation"]
  today = json["forecast"]["txt_forecast"]["forecastday"][0]

  city_name = current["display_location"]["full"]

  now_weather = current["weather"]
  now_temp = current["temperature_string"]
  
  today_weather = today["fcttext"]
  today_icon = today["icon_url"]

  puts "#{city_name} -> now #{now_weather} and #{now_temp} \n will be #{today_weather}"
end

get_now_and_later_for("San_Francisco")
get_now_and_later_for("Palo_Alto")