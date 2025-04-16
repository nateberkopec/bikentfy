#!/usr/bin/env ruby

require "net/http"
require "json"
require "uri"
require "time"
require "tzinfo"

LATITUDE = ENV.fetch("LATITUDE")
LONGITUDE = ENV.fetch("LONGITUDE")
NTFY_TOPIC = ENV.fetch("NTFY_TOPIC")
TIMEZONE = ENV.fetch("TIMEZONE")
WEATHER_MODEL = ENV.fetch("WEATHER_MODEL")
NOTIFY_URL = URI("https://ntfy.sh/#{NTFY_TOPIC}")
METEO_URL = "https://api.open-meteo.com/v1/forecast"

def debug(msg)
  puts(msg) if ENV["DEBUG"] == "true"
end

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

def fetch_weather = JSON.parse(Net::HTTP.get_response(weather_uri).body)

def find_rain_start(precip, times, hour)
  debug "Precipitation for next 24 hours: #{precip[hour, 24]}"
  precip[hour, 24].each_with_index do |p, i|
    return i if p > 0.0
  end
  nil
end

def rain_info(weather_data)
  hour = TZInfo::Timezone.get(TIMEZONE).now.hour
  debug "Current hour in #{TIMEZONE}: #{hour}"

  precip = weather_data.dig("hourly", "precipitation") || []
  times = weather_data.dig("hourly", "time") || []

  create_rain_info(precip, times, hour)
end

def create_rain_info(precip, times, hour)
  rain_hour = find_rain_start(precip, times, hour)
  hours_until = rain_hour ? rain_hour - hour : nil

  {will_rain: !!rain_hour, start_time: start_time, hours_until: hours_until}
end

def notify(time, hours)
  request = Net::HTTP::Post.new(NOTIFY_URL)

  request.body = notification_body(time, hours)

  debug "Sending: #{request.body}"
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
end

def notification_body(time, hours)
  formatted_time = time.strftime("%-I%p").downcase
  hour_word = hours == 1 ? "hour" : "hours"

  "Rain expected in #{hours} #{hour_word} at #{formatted_time}. Cover the bike!"
end

def ping_snitch
  uri = URI("https://nosnch.in/#{ENV["SNITCH_ID"]}")
  debug "Pinging snitch."
  Net::HTTP.get_response(uri)
end

if (info = rain_info(fetch_weather))
  time = info[:start_time]
  hours = info[:hours_until]
  notify(time, hours)
  ping_snitch if ENV["SNITCH_ID"]
else
  debug "No rain expected in the next 24 hours."
end
