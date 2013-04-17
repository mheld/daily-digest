require 'open-uri'
require 'json'
require 'yaml'
require 'gmail'

yaml = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), "credentials.yml"))
WUNDERGROUND_KEY = yaml["wunderground_key"]
GMAIL_USERNAME = yaml["gmail_username"]
GMAIL_PASSWORD = yaml["gmail_password"]
GMAIL_TO_EMAIL = yaml["gmail_to_email"]


@time = Time.now.strftime("%a %b %d")

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

  "<h2>#{city_name}</h2> \n " +
  "<b>now:</b> #{now_weather} and #{now_temp} <br /> \n "+
  "<b>today:</b> #{today_weather} <br /> \n "+
  "<img src=\"#{today_icon}\">"
end


def generate_email
  "<h1>Daily Digest for #{@time}</h1> <br /> <br /> \n \n " +
  get_now_and_later_for("San_Francisco") + " <br /> \n \n " +
  get_now_and_later_for("Palo_Alto")
end

def email
  Gmail.new(GMAIL_USERNAME, GMAIL_PASSWORD) do |gmail|
    gmail.deliver do
      to GMAIL_TO_EMAIL
      subject "Daily Digest #{@time}"
      html_part do
        content_type 'text/html; charset=UTF-8'
        body generate_email
      end
    end
  end
end

puts generate_email


