require 'open-uri'
require 'json'
require 'yaml'
require 'gmail'
require 'feedzirra'

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

  "<h3>#{city_name}</h3> \n " +
  "<b>Now:</b> #{now_weather} and #{now_temp} <br /> \n "+
  "<b>Today:</b> #{today_weather} <br /> \n "+
  "<img src=\"#{today_icon}\">"
end

NEW_LINE = "<br /> \n \n"

def generate_email
  "<h1>Daily Digest for #{@time}</h1> <br /> " + NEW_LINE +
  "<h1>Weather</h1>" + NEW_LINE +
  get_now_and_later_for("San_Francisco") + NEW_LINE +
  get_now_and_later_for("Palo_Alto") + NEW_LINE +
  "<h1>News</h1>" + NEW_LINE +
  get_rss_for("American Shipper", ["http://americanshipper.com/Rss.aspx?sn=News1", "http://americanshipper.com/Rss.aspx?sn=ASDaily", "http://americanshipper.com/Rss.aspx?sn=AmericanShipperMagazineLogistics", "http://americanshipper.com/Rss.aspx?sn=AmericanShipperMagazine"])
end

def send_email
  to_send = generate_email
  puts to_send
  Gmail.new(GMAIL_USERNAME, GMAIL_PASSWORD) do |gmail|
    gmail.deliver do
      to GMAIL_TO_EMAIL
      subject "Good morning!"
      html_part do
        content_type 'text/html; charset=UTF-8'
        body to_send
      end
    end
  end
end

def entry_to_html(entry)
  "<div><a href=\"#{entry.url}\"><h3>#{entry.title}</h3></a> " +
  if !entry.content.nil? and entry.content.length > 0
    entry.content
  else
    "\n"
  end + "</div>"
end

def get_rss_for(category, feeds)
  "<h2>In #{category}:</h2> " +
  feeds.map{|feed| Feedzirra::Feed.fetch_and_parse(feed).entries}.inject([]) do |acc, entries|
    entries.each do |entry|
      acc << entry unless acc.detect{|existing| existing.title == entry.title }
    end
    acc
  end.map{|entry| entry_to_html(entry) }.inject(""){|acc, entry| acc << entry}
end

send_email


