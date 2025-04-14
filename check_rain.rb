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

def debug(msg)
  puts(msg) if ENV["DEBUG"] == "true"
end

def weather_uri
  uri = URI("https://api.open-meteo.com/v1/forecast")
  uri.query = URI.encode_www_form(
    latitude: LATITUDE,
    longitude: LONGITUDE,
    hourly: "precipitation",
    timezone: TIMEZONE,
    models: WEATHER_MODEL,
    forecast_days: 3
  )
  uri
end

def fetch_weather
  uri = weather_uri
  JSON.parse(Net::HTTP.get_response(uri).body)
end

def current_hour
  tz = TZInfo::Timezone.get(TIMEZONE)
  now = tz.now
  Time.new(now.year, now.month, now.day, now.hour)
end

def find_rain_start(precip, times, start_idx)
  precip[start_idx, 24].each_with_index do |p, i|
    return i if p > 0.0
  end
  nil
end

def find_start_idx(times, hour)
  idx = times.find_index { |t| Time.parse(t) >= hour }
  debug "Current hour index: #{idx}" if idx
  idx
end

def create_rain_info(precip, times, start_idx, hour)
  debug "Precipitation for next 24 hours: #{precip[start_idx, 24]}"

  rain_idx = find_rain_start(precip, times, start_idx)
  return unless rain_idx

  start_time = Time.parse(times[start_idx + rain_idx])
  hours_until = ((start_time - hour) / 3600).round

  {will_rain: true, start_time: start_time, hours_until: hours_until}
end

def rain_info(weather_data)
  precip = weather_data.dig("hourly", "precipitation") || []
  times = weather_data.dig("hourly", "time") || []
  hour = current_hour

  debug "Current time in #{TIMEZONE} (rounded down): #{hour}"

  start_idx = find_start_idx(times, hour)
  return unless start_idx

  create_rain_info(precip, times, start_idx, hour)
end

def notify(rain_info)
  uri = URI("https://ntfy.sh/#{NTFY_TOPIC}")
  request = Net::HTTP::Post.new(uri)

  time = rain_info[:start_time].strftime("%-I%p").downcase
  hours = rain_info[:hours_until]
  request.body = "Rain expected in #{hours} #{(hours == 1) ? "hour" : "hours"} at #{time}. Cover the bike!"

  debug "Sending: #{request.body}"
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
end

def ping_snitch
  uri = URI("https://nosnch.in/#{ENv["SNITCH_ID"]}")
  debug "Pinging snitch."
  Net::HTTP.get_response(uri)
end

if (info = rain_info(fetch_weather))
  notify(info)
  ping_snitch if ENV["SNITCH_ID"]
else
  debug "No rain expected in the next 24 hours."
end
