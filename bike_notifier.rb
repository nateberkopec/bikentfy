require "net/http"
require "json"
require "uri"
require "time"
require "tzinfo"

class BikeNotifier
  LATITUDE = ENV.fetch("LATITUDE")
  LONGITUDE = ENV.fetch("LONGITUDE")
  NTFY_TOPIC = ENV.fetch("NTFY_TOPIC")
  TIMEZONE = ENV.fetch("TIMEZONE")
  WEATHER_MODEL = ENV.fetch("WEATHER_MODEL")
  NOTIFY_URL = URI("https://ntfy.sh/#{NTFY_TOPIC}")
  METEO_URL = "https://api.open-meteo.com/v1/forecast"

  attr_accessor :weather_data
  attr_writer :now

  def weather_uri
    URI(METEO_URL).tap do |uri|
      uri.query = URI.encode_www_form(
        latitude: LATITUDE,
        longitude: LONGITUDE,
        hourly: "precipitation",
        timezone: TIMEZONE,
        models: WEATHER_MODEL,
        forecast_days: 3 # AFAIK the only options are 1 and 3, we really only need 2
      )
    end
  end

  def fetch_weather = @weather_data ||= JSON.parse(Net::HTTP.get_response(weather_uri).body)

  def now = @now ||= TZInfo::Timezone.get(TIMEZONE).now

  # returns number of hours until rain starts
  # if nil, no rain in next 24h
  def hours_until_rain(weather_data)
    weather_data.dig("hourly", "precipitation")[now.hour, 24].find_index { |i| i > 0.0 }
  end

  def notify(notification_body)
    request = Net::HTTP::Post.new(NOTIFY_URL)
    request.body = notification_body
    Net::HTTP.start(NOTIFY_URL.hostname, NOTIFY_URL.port, use_ssl: true) { |http| http.request(request) }
  end

  def notification_body(hours_until)
    time_of_rain = now + 3600 * hours_until
    formatted_time = time_of_rain.strftime("%-I%p").downcase
    formatted_until = case hours_until
    when 0
      "now"
    when 1
      "in 1 hour at #{formatted_time}"
    else
      "in #{hours_until} hours at #{formatted_time}"
    end

    "Rain expected #{formatted_until}. Cover the bike!"
  end

  def ping_snitch = Net::HTTP.get_response(URI("https://nosnch.in/#{ENV["SNITCH_ID"]}"))

  def run
    fetch_weather
    result = hours_until_rain(weather_data)
    notification = "No rain in next 24h"

    if result
      notification = notification_body(result)
      notify(notification)
    end

    ping_snitch if ENV["SNITCH_ID"]
    puts notification
  end
end
